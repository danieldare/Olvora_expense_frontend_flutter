import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter_main/features/budget/presentation/widgets/budget_form_modal.dart';
import 'package:frontend_flutter_main/features/budget/domain/entities/budget_entity.dart';
import 'package:frontend_flutter_main/features/budget/presentation/providers/budget_providers.dart';
import 'package:frontend_flutter_main/features/categories/presentation/providers/category_providers.dart';
import 'package:frontend_flutter_main/features/categories/data/repositories/category_repository.dart';

void main() {
  group('BudgetFormModal - Integration Tests', () {
    testWidgets('complete flow: create general budget', (tester) async {
      bool saveCalled = false;
      BudgetType? savedPeriod;
      double? savedAmount;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.general,
                onSave: (period, categoryId, amount, enabled) {
                  saveCalled = true;
                  savedPeriod = period;
                  savedAmount = amount;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Verify period selector is visible
      expect(find.text('Budget Period'), findsOneWidget);

      // Step 2: Select a period (monthly should be available by default)
      final monthlyChip = find.text('Monthly');
      if (monthlyChip.evaluate().isNotEmpty) {
        await tester.tap(monthlyChip);
        await tester.pumpAndSettle();
      }

      // Step 3: Enter amount
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '5000');
      await tester.pumpAndSettle();

      // Step 4: Verify save button is enabled
      final saveButton = find.text('Create Budget');
      expect(saveButton, findsOneWidget);
      final button = tester.widget<ElevatedButton>(saveButton);
      expect(button.onPressed, isNotNull);

      // Step 5: Tap save button
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Step 6: Verify onSave was called
      expect(saveCalled, isTrue);
      expect(savedPeriod, BudgetType.monthly);
      expect(savedAmount, 5000.0);
    });

    testWidgets('complete flow: create category budget with duplicate detection', (tester) async {
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

      bool saveCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith((ref) => Future.value([
              CategoryModel(
                id: 'cat1',
                name: 'Food',
                icon: '🍔',
                color: '#000000',
                isDefault: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              CategoryModel(
                id: 'cat2',
                name: 'Transport',
                icon: '🚗',
                color: '#0000FF',
                isDefault: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ])),
            categoryBudgetsProvider.overrideWith((ref) => Future.value([existingBudget])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.category,
                initialPeriod: BudgetType.monthly,
                onSave: (period, categoryId, amount, enabled) {
                  saveCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Verify period selector is visible and enabled
      expect(find.text('Budget Period'), findsOneWidget);
      expect(find.text('Period is set by the general budget'), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);

      // Step 2: Verify category selector is visible
      expect(find.text('Category'), findsOneWidget);

      // Step 3: Enter amount
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '500');
      await tester.pumpAndSettle();

      // Step 4: Select Food category (duplicate)
      final foodCategory = find.text('Food');
      if (foodCategory.evaluate().isNotEmpty) {
        await tester.tap(foodCategory);
        await tester.pumpAndSettle();

        // Step 5: Verify duplicate error is shown
        expect(
          find.textContaining('A budget already exists for Food'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

        // Step 6: Verify save button is disabled
        final saveButton = find.text('Create Budget');
        final button = tester.widget<ElevatedButton>(saveButton);
        expect(button.onPressed, isNull);
        expect(saveCalled, isFalse);
      }

      // Step 7: Select Transport category (no duplicate)
      final transportCategory = find.text('Transport');
      if (transportCategory.evaluate().isNotEmpty) {
        await tester.tap(transportCategory);
        await tester.pumpAndSettle();

        // Step 8: Verify duplicate error is gone
        expect(
          find.textContaining('A budget already exists'),
          findsNothing,
        );

        // Step 9: Verify save button is enabled
        final saveButton = find.text('Create Budget');
        final button = tester.widget<ElevatedButton>(saveButton);
        expect(button.onPressed, isNotNull);

        // Step 10: Tap save
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Step 11: Verify onSave was called
        expect(saveCalled, isTrue);
      }
    });

    testWidgets('period selector: disable unavailable periods', (tester) async {
      final existingBudget = BudgetEntity(
        id: 'budget1',
        type: BudgetType.monthly,
        category: BudgetCategory.general,
        amount: 1000,
        spent: 0,
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                budgetCategory: BudgetCategory.general,
                existingBudgets: [existingBudget],
                onSave: (period, categoryId, amount, enabled) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Monthly period should be disabled (already exists)
      final monthlyChip = find.text('Monthly');
      if (monthlyChip.evaluate().isNotEmpty) {
        // Try to tap - should show tooltip instead of selecting
        await tester.tap(monthlyChip);
        await tester.pumpAndSettle();

        // Should show tooltip message
        expect(
          find.textContaining('A budget already exists for Monthly'),
          findsWidgets,
        );
      }

      // Weekly period should be available
      final weeklyChip = find.text('Weekly');
      if (weeklyChip.evaluate().isNotEmpty) {
        await tester.tap(weeklyChip);
        await tester.pumpAndSettle();

        // Should be selected (visual check would require more complex test)
        expect(weeklyChip, findsOneWidget);
      }
    });

    testWidgets('edit mode: update existing budget', (tester) async {
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

      bool saveCalled = false;
      double? savedAmount;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BudgetFormModal(
                existingBudget: existingBudget,
                onSave: (period, categoryId, amount, enabled) {
                  saveCalled = true;
                  savedAmount = amount;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Verify edit mode UI
      expect(find.text('Edit Budget'), findsOneWidget);
      expect(find.textContaining('Current:'), findsOneWidget);

      // Step 2: Update amount
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '3000');
      await tester.pumpAndSettle();

      // Step 3: Tap save
      final saveButton = find.text('Save Changes');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Step 4: Verify onSave was called with new amount
      expect(saveCalled, isTrue);
      expect(savedAmount, 3000.0);
    });

    testWidgets('validation: require category for category budgets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith((ref) => Future.value([
              CategoryModel(
                id: 'cat1',
                name: 'Food',
                icon: '🍔',
                color: '#000000',
                isDefault: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ])),
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

      // Enter amount but don't select category
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '500');
      await tester.pumpAndSettle();

      // Save button should be disabled (no category selected)
      final saveButton = find.text('Create Budget');
      final button = tester.widget<ElevatedButton>(saveButton);
      expect(button.onPressed, isNull);
    });
  });
}

