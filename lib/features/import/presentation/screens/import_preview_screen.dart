import 'package:flutter/material.dart';
import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import 'dart:typed_data';
import '../../domain/usecases/parse_import_file.dart';
import '../../domain/usecases/detect_file_structure.dart';
import '../../domain/usecases/transform_to_expenses.dart';
import '../../domain/usecases/match_categories.dart';
import '../../domain/usecases/execute_import.dart';
import '../../domain/entities/import_file.dart';
import '../../domain/entities/import_preview.dart';
import '../../domain/entities/parsed_expense.dart';
import '../../domain/entities/category_mapping.dart';
import '../../domain/entities/detected_structure.dart';
import '../../data/detectors/currency_detector.dart';
import '../providers/import_providers.dart';
import '../../../../features/expenses/domain/entities/expense_entity.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../utils/error_parser.dart';
import 'import_success_screen.dart';

/// Magical import preview - simple, beautiful, one-click import
class ImportPreviewScreen extends ConsumerStatefulWidget {
  final PlatformFile file;

  const ImportPreviewScreen({super.key, required this.file});

  @override
  ConsumerState<ImportPreviewScreen> createState() =>
      _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen>
    with SingleTickerProviderStateMixin {
  ImportPreview? _preview;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _processingMessage = 'Analyzing your file...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _parseFile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _parseFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _processingMessage = 'Analyzing your file...';
    });

    try {
      // Simulate progress for better UX
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _processingMessage = 'Detecting structure...');

      // 1. Parse file
      final parseUseCase = ParseImportFile();
      final sheets = await parseUseCase.execute(widget.file);

      if (sheets.isEmpty) {
        throw Exception('No data found in file');
      }

      final sheet = sheets.first;
      setState(() => _processingMessage = 'Mapping categories...');

      // 2. Detect structure
      final detectUseCase = DetectFileStructure();
      final structure = detectUseCase.execute(sheet);

      if (structure.type == FileStructureType.unknown) {
        throw Exception('Could not detect file structure');
      }

      // 3. Determine year
      int year = structure.detectedYear ?? DateTime.now().year;
      if (structure.needsYearInput) {
        year = DateTime.now().year;
      }

      setState(() => _processingMessage = 'Processing expenses...');

      // 4. Transform to expenses
      final transformUseCase = TransformToExpenses();
      final expenses = transformUseCase.execute(
        sheet: sheet,
        structure: structure,
        year: year,
      );

      if (expenses.isEmpty) {
        throw Exception('No expenses found in file');
      }

      // 5. Detect currency
      final currencyDetector = CurrencyDetector();
      final detectedCurrency = currencyDetector.detectCurrency(
        sheet,
        structure.columnMapping?.currencyColumn,
      );

      final preferenceCurrency =
          ref.read(selectedCurrencyProvider).valueOrNull ??
          Currency.defaultCurrency;
      final currencyToUse = detectedCurrency ?? preferenceCurrency.code;

      final expensesWithCurrency = expenses
          .map(
            (e) => ParsedExpense(
              id: e.id,
              title: e.title,
              amount: e.amount,
              originalCategory: e.originalCategory,
              mappedCategoryName: e.mappedCategoryName,
              date: e.date,
              merchant: e.merchant,
              notes: e.notes,
              sourceRow: e.sourceRow,
              sourceMonth: e.sourceMonth,
              currency: currencyToUse,
            ),
          )
          .toList();

      setState(() => _processingMessage = 'Finalizing...');

      // 6. Match categories (now always returns a category - defaults to "other")
      final uniqueCategories = expensesWithCurrency
          .map((e) => e.originalCategory)
          .toSet()
          .toList();

      final categoryMatcher = ref.read(categoryMatcherProvider);
      final matchUseCase = MatchCategories(matcher: categoryMatcher);
      final categoryMappings = await matchUseCase.execute(uniqueCategories);

      // 7. Update expenses with matched categories (always mapped now)
      final updatedExpenses = expensesWithCurrency.map((e) {
        final mapping = categoryMappings.firstWhere(
          (m) => m.originalName == e.originalCategory,
          orElse: () => CategoryMapping(
            originalName: e.originalCategory,
            mappedCategoryName: ExpenseCategory.other.name,
            confidence: 0.5,
            source: MappingSource.fuzzyMatch,
          ),
        );
        return e.copyWithCategory(
          mapping.mappedCategoryName ?? ExpenseCategory.other.name,
        );
      }).toList();

      // 8. Create preview
      final bytes = widget.file.bytes != null
          ? Uint8List.fromList(widget.file.bytes!)
          : Uint8List(0);

      final importFile = ImportFile(
        name: widget.file.name,
        extension: widget.file.extension ?? '',
        bytes: bytes,
        sizeBytes: widget.file.size,
        pickedAt: DateTime.now(),
      );

      final preview = ImportPreview(
        file: importFile,
        structure: structure,
        expenses: updatedExpenses,
        categoryMappings: categoryMappings,
        selectedYear: year,
        selectedSheetName: sheet.sheetName,
      );

      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Smooth transition

      setState(() {
        _preview = preview;
        _isLoading = false;
      });

      ref.read(importNotifierProvider.notifier).setPreview(preview);
    } catch (e) {
      final friendlyError = ImportErrorParser.parseError(e);
      setState(() {
        _error = friendlyError;
        _isLoading = false;
      });
      ref.read(importNotifierProvider.notifier).setError(friendlyError);
    }
  }

  Future<void> _executeImport() async {
    if (_preview == null) return;

    final notifier = ref.read(importNotifierProvider.notifier);
    notifier.setImporting(true);

    try {
      final repository = ref.read(importRepositoryProvider);
      final executeUseCase = ExecuteImport(repository: repository);

      final result = await executeUseCase.execute(
        expenses: _preview!.expenses,
        fileName: _preview!.file.name,
      );

      notifier.setResult(result);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ImportSuccessScreen(result: result),
          ),
        );
      }
    } catch (e) {
      final friendlyError = ImportErrorParser.parseError(e);
      notifier.setError(friendlyError);
      if (mounted) {
        // Show error in a dialog instead of snackbar for better visibility
        _showErrorDialog(friendlyError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;

    if (_isLoading) {
      return _buildProcessingScreen(isDark, bgColor);
    }

    if (_error != null) {
      return _buildErrorScreen(isDark, bgColor);
    }

    if (_preview == null) {
      return const SizedBox.shrink();
    }

    return _buildPreviewScreen(isDark, bgColor);
  }

  Widget _buildProcessingScreen(bool isDark, Color bgColor) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenHorizontal * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated magic icon
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 120.scaled(context),
                    height: 120.scaled(context),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 30.scaled(context),
                          spreadRadius: 5.scaled(context),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 60.scaled(context),
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 40.scaledVertical(context)),
                Text(
                  _processingMessage,
                  style: AppFonts.textStyle(
                    fontSize: 20.scaledText(context),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.scaledVertical(context)),
                Text(
                  'We\'re automatically mapping everything for you',
                  style: AppFonts.textStyle(
                    fontSize: 14.scaledText(context),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(bool isDark, Color bgColor) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenHorizontal * 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon with gradient
                Container(
                  width: 100.scaled(context),
                  height: 100.scaled(context),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.errorColor,
                        AppTheme.errorColor.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.errorColor.withValues(alpha: 0.3),
                        blurRadius: 20.scaled(context),
                        spreadRadius: 2.scaled(context),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 50.scaled(context),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 32.scaledVertical(context)),
                Text(
                  'Unable to Import',
                  style: AppFonts.textStyle(
                    fontSize: 28.scaledText(context),
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.scaledVertical(context)),
                Container(
                  padding: EdgeInsets.all(20.scaled(context)),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppTheme.errorColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.scaled(context)),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: AppFonts.textStyle(
                      fontSize: 15.scaledText(context),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.textPrimary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 32.scaledVertical(context)),
                AppButton(
                  label: 'Try Again',
                  onPressed: () => Navigator.pop(context),
                  variant: AppButtonVariant.primary,
                  isFullWidth: true,
                  icon: Icons.refresh_rounded,
                ),
                SizedBox(height: 12.scaledVertical(context)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Go Back',
                    style: AppFonts.textStyle(
                      fontSize: 15.scaledText(context),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.scaled(context)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.scaled(context)),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.scaled(context)),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 24.scaled(context),
                color: AppTheme.errorColor,
              ),
            ),
            SizedBox(width: 12.scaled(context)),
            Expanded(
              child: Text(
                'Import Failed',
                style: AppFonts.textStyle(
                  fontSize: 20.scaledText(context),
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          errorMessage,
          style: AppFonts.textStyle(
            fontSize: 15.scaledText(context),
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: AppFonts.textStyle(
                fontSize: 15.scaledText(context),
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewScreen(bool isDark, Color bgColor) {
    final currency =
        ref.watch(selectedCurrencyProvider).valueOrNull ??
        Currency.defaultCurrency;
    final expenseCurrency =
        _preview!.expenses.isNotEmpty &&
            _preview!.expenses.first.currency != null
        ? Currency.findByCode(_preview!.expenses.first.currency!) ?? currency
        : currency;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.screenHorizontal,
                  AppSpacing.screenHorizontal,
                  AppSpacing.bottomNavPadding,
                ),
                child: Column(
                  children: [
                    // Success icon
                    Container(
                      width: 100.scaled(context),
                      height: 100.scaled(context),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.successColor,
                            AppTheme.successColor.withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successColor.withValues(alpha: 0.3),
                            blurRadius: 20.scaled(context),
                            spreadRadius: 2.scaled(context),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 50.scaled(context),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 32.scaledVertical(context)),

                    // Title
                    Text(
                      'Ready to Import!',
                      style: AppFonts.textStyle(
                        fontSize: 28.scaledText(context),
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.scaledVertical(context)),
                    Text(
                      'We\'ve automatically mapped everything for you',
                      style: AppFonts.textStyle(
                        fontSize: 15.scaledText(context),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.scaledVertical(context)),

                    // Summary card - minimal and beautiful
                    Container(
                      padding: EdgeInsets.all(24.scaled(context)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppTheme.darkCardBackground,
                                  AppTheme.darkCardBackground.withValues(
                                    alpha: 0.8,
                                  ),
                                ]
                              : [
                                  Colors.white,
                                  AppTheme.primaryColor.withValues(alpha: 0.03),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(24.scaled(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            blurRadius: 20.scaled(context),
                            offset: Offset(0, 8.scaled(context)),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // File name
                          Row(
                            children: [
                              Icon(
                                _preview!.file.isExcel
                                    ? Icons.table_chart_rounded
                                    : Icons.description_rounded,
                                size: 20.scaled(context),
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(width: 12.scaled(context)),
                              Expanded(
                                child: Text(
                                  _preview!.file.name,
                                  style: AppFonts.textStyle(
                                    fontSize: 16.scaledText(context),
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.scaledVertical(context)),

                          // Key stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  context,
                                  isDark,
                                  '${_preview!.totalExpenses}',
                                  'Expenses',
                                  Icons.receipt_long_rounded,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40.scaled(context),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppTheme.borderColor,
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  context,
                                  isDark,
                                  CurrencyFormatter.format(
                                    _preview!.totalAmount,
                                    expenseCurrency,
                                  ),
                                  'Total',
                                  Icons.account_balance_wallet_rounded,
                                ),
                              ),
                            ],
                          ),

                          // Date range
                          if (_preview!.earliestDate != null &&
                              _preview!.latestDate != null) ...[
                            SizedBox(height: 20.scaledVertical(context)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.scaled(context),
                                vertical: 12.scaledVertical(context),
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  12.scaled(context),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16.scaled(context),
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 8.scaled(context)),
                                  Text(
                                    '${DateFormat('MMM d').format(_preview!.earliestDate!)} - ${DateFormat('MMM d, yyyy').format(_preview!.latestDate!)}',
                                    style: AppFonts.textStyle(
                                      fontSize: 13.scaledText(context),
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Import button - one click!
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                20.scaledVertical(context),
                AppSpacing.screenHorizontal,
                AppSpacing.screenHorizontal +
                    MediaQuery.of(context).viewPadding.bottom,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.borderColor,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10.scaled(context),
                    offset: Offset(0, -2.scaled(context)),
                  ),
                ],
              ),
              child: AppButton(
                label:
                    'Import ${_preview!.totalExpenses} ${_preview!.totalExpenses == 1 ? 'Expense' : 'Expenses'}',
                onPressed: _executeImport,
                variant: AppButtonVariant.primary,
                isFullWidth: true,
                isLoading: ref.watch(importNotifierProvider).isImporting,
                icon: Icons.file_download_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    bool isDark,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24.scaled(context), color: AppTheme.primaryColor),
        SizedBox(height: 8.scaledVertical(context)),
        Text(
          value,
          style: AppFonts.textStyle(
            fontSize: 24.scaledText(context),
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4.scaledVertical(context)),
        Text(
          label,
          style: AppFonts.textStyle(
            fontSize: 12.scaledText(context),
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
