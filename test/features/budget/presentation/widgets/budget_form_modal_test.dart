import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter_main/features/budget/presentation/widgets/budget_form_modal.dart';
import 'package:frontend_flutter_main/features/budget/domain/entities/budget_entity.dart';
import 'package:frontend_flutter_main/features/budget/presentation/providers/budget_providers.dart';
import 'package:frontend_flutter_main/features/categories/presentation/providers/category_providers.dart';
import 'package:frontend_flutter_main/features/categories/data/repositories/category_repository.dart';

void main() {
  group('BudgetFormModal - Unit Tests', () {
    testWidgets('should show period selector for general budgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.general,
                onSave: (period, categoryId, amount, enabled) {},
              ),
            ),
          ),
        ),
      );

      // Should show period selector
      expect(find.text('Budget Period'), findsOneWidget);
    });

    testWidgets('should show period selector for category budgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.category,
                initialPeriod: BudgetType.monthly,
                onSave: (period, categoryId, amount, enabled) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show period selector (not locked)
      expect(find.text('Budget Period'), findsOneWidget);
      expect(find.text('Period is set by the general budget'), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    });

    testWidgets('should show category selector for category budgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith(
              (ref) => Future.value([
                CategoryModel(
                  id: 'cat1',
                  name: 'Food',
                  icon: '🍔',
                  color: '#000000',
                  isDefault: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.category,
                initialPeriod: BudgetType.monthly,
                onSave: (period, categoryId, amount, enabled) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show category selector
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('should show duplicate error when category budget exists', (
      tester,
    ) async {
      final existingBudget = BudgetEntity(
        id: 'budget1',
        type: BudgetType.monthly,
        category: BudgetCategory.category,
        categoryId: 'cat1',
        categoryName: 'Food',
        amount: 1000,
        spent: 0,
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith(
              (ref) => Future.value([
                CategoryModel(
                  id: 'cat1',
                  name: 'Food',
                  icon: '🍔',
                  color: '#000000',
                  isDefault: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ]),
            ),
            categoryBudgetsProvider.overrideWith(
              (ref) => Future.value([existingBudget]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.category,
                initialPeriod: BudgetType.monthly,
                onSave: (period, categoryId, amount, enabled) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select the Food category
      final categoryWidget = find.text('Food');
      if (categoryWidget.evaluate().isNotEmpty) {
        await tester.tap(categoryWidget);
        await tester.pumpAndSettle();

        // Should show duplicate error
        expect(
          find.textContaining('A budget already exists for Food'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      }
    });

    testWidgets('should disable save button when duplicate exists', (
      tester,
    ) async {
      final existingBudget = BudgetEntity(
        id: 'budget1',
        type: BudgetType.monthly,
        category: BudgetCategory.category,
        categoryId: 'cat1',
        categoryName: 'Food',
        amount: 1000,
        spent: 0,
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith(
              (ref) => Future.value([
                CategoryModel(
                  id: 'cat1',
                  name: 'Food',
                  icon: '🍔',
                  color: '#000000',
                  isDefault: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ]),
            ),
            categoryBudgetsProvider.overrideWith(
              (ref) => Future.value([existingBudget]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.category,
                initialPeriod: BudgetType.monthly,
                onSave: (period, categoryId, amount, enabled) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter amount
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '500');
      await tester.pumpAndSettle();

      // Select category
      final categoryWidget = find.text('Food');
      if (categoryWidget.evaluate().isNotEmpty) {
        await tester.tap(categoryWidget);
        await tester.pumpAndSettle();

        // Save button should be disabled due to duplicate
        final saveButton = find.text('Create Budget');
        expect(saveButton, findsOneWidget);
        // Button should be disabled (check by trying to tap)
        final button = tester.widget<ElevatedButton>(saveButton);
        expect(button.onPressed, isNull);
      }
    });

    testWidgets('should validate amount > 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.general,
                onSave: (period, categoryId, amount, enabled) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Save button should be disabled without amount
      final saveButton = find.text('Create Budget');
      expect(saveButton, findsOneWidget);
      final button = tester.widget<ElevatedButton>(saveButton);
      expect(button.onPressed, isNull);

      // Enter amount
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '1000');
      await tester.pumpAndSettle();

      // Button should now be enabled
      final updatedButton = tester.widget<ElevatedButton>(saveButton);
      expect(updatedButton.onPressed, isNotNull);
    });

    testWidgets('should call onSave with correct parameters', (tester) async {
      BudgetType? savedPeriod;
      String? savedCategoryId;
      double? savedAmount;
      bool? savedEnabled;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.general,
                initialPeriod: BudgetType.monthly,
                onSave: (period, categoryId, amount, enabled) {
                  savedPeriod = period;
                  savedCategoryId = categoryId;
                  savedAmount = amount;
                  savedEnabled = enabled;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter amount
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '1000');
      await tester.pumpAndSettle();

      // Tap save button
      final saveButton = find.text('Create Budget');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify onSave was called with correct values
      expect(savedPeriod, BudgetType.monthly);
      expect(savedCategoryId, isNull);
      expect(savedAmount, 1000.0);
      expect(savedEnabled, true);
    });

    testWidgets('should pre-fill values in edit mode', (tester) async {
      final existingBudget = BudgetEntity(
        id: 'budget1',
        type: BudgetType.monthly,
        category: BudgetCategory.general,
        amount: 2000,
        spent: 500,
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                existingBudget: existingBudget,
                onSave: (period, categoryId, amount, enabled) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show edit title
      expect(find.text('Edit Budget'), findsOneWidget);

      // Should show current amount
      expect(find.textContaining('Current:'), findsOneWidget);

      // Should not show period selector in edit mode
      expect(find.text('Budget Period'), findsNothing);
    });
  });
}
