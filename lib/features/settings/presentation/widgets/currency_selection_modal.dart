import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/providers/currency_providers.dart';

class CurrencySelectionModal extends ConsumerStatefulWidget {
  const CurrencySelectionModal({super.key});

  @override
  ConsumerState<CurrencySelectionModal> createState() =>
      _CurrencySelectionModalState();
}

class _CurrencySelectionModalState
    extends ConsumerState<CurrencySelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Currency> _getFilteredCurrencies(List<Currency> allCurrencies) {
    if (_searchQuery.isEmpty) return allCurrencies;
    final query = _searchQuery.toLowerCase();
    return allCurrencies.where((currency) {
      return currency.name.toLowerCase().contains(query) ||
          currency.code.toLowerCase().contains(query) ||
          currency.country.toLowerCase().contains(query) ||
          currency.symbol.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currencyNotifier = ref.watch(currencyNotifierProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: AppFonts.textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search currencies...',
              hintStyle: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : AppTheme.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.textSecondary,
                size: 16,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.textSecondary,
                        size: 14,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        // Currency list
        selectedCurrencyAsync.when(
          data: (selectedCurrency) {
            final filteredCurrencies = _getFilteredCurrencies(Currency.all);
            if (filteredCurrencies.isEmpty) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 36,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppTheme.textSecondary.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No currencies found',
                        style: AppFonts.textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Try a different search term',
                        style: AppFonts.textStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredCurrencies.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.borderColor.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) {
                final currency = filteredCurrencies[index];
                final isSelected = currency.code == selectedCurrency.code;

                return InkWell(
                  onTap: () {
                    currencyNotifier.setCurrency(currency);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppTheme.primaryColor.withValues(alpha: 0.15)
                              : AppTheme.primaryColor.withValues(alpha: 0.08))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // Currency symbol
                        SizedBox(
                          width: 24,
                          child: Text(
                            currency.symbol,
                            style: AppFonts.textStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 8),
                        // Currency info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currency.name,
                                style: AppFonts.textStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 0),
                              Text(
                                '${currency.code} • ${currency.country}',
                                style: AppFonts.textStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Selected indicator
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Failed to load currencies',
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

