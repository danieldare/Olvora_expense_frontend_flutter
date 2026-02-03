import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/pre_app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/providers/currency_providers.dart';
import 'notification_permission_screen.dart';

/// Currency Selection Screen for onboarding
///
/// Allows users to select their preferred currency during onboarding.
class CurrencySelectionScreen extends ConsumerStatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  ConsumerState<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState
    extends ConsumerState<CurrencySelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Currency? _selectedCurrency;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();

    // Set default selection
    _selectedCurrency = Currency.defaultCurrency;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Currency> get _filteredCurrencies {
    if (_searchQuery.isEmpty) return Currency.all;
    final query = _searchQuery.toLowerCase();
    return Currency.all.where((currency) {
      return currency.name.toLowerCase().contains(query) ||
          currency.code.toLowerCase().contains(query) ||
          currency.country.toLowerCase().contains(query) ||
          currency.symbol.contains(query);
    }).toList();
  }

  void _onContinue() async {
    HapticFeedback.mediumImpact();
    if (_selectedCurrency != null) {
      // Save the selected currency
      await ref
          .read(currencyNotifierProvider.notifier)
          .setCurrency(_selectedCurrency!);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NotificationPermissionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Block back navigation - users should complete currency selection
      },
      child: Semantics(
        label: 'Currency Selection - Choose your preferred currency',
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: PreAppColors.authGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header (compact)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  16.scaledVertical(context),
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          Container(
                            width: 56.scaled(context),
                            height: 56.scaled(context),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.currency_exchange_rounded,
                              size: 28.scaled(context),
                              color: PreAppColors.warningColor,
                            ),
                          ),
                          SizedBox(height: 12.scaledVertical(context)),
                          Text(
                            'Choose Your',
                            textAlign: TextAlign.center,
                            style: AppFonts.textStyle(
                              fontSize: 22.scaledText(context),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Currency',
                            textAlign: TextAlign.center,
                            style: AppFonts.textStyle(
                              fontSize: 22.scaledText(context),
                              fontWeight: FontWeight.w700,
                              color: PreAppColors.warningColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4.scaledVertical(context)),
                          Text(
                            'Select your preferred currency for tracking expenses',
                            textAlign: TextAlign.center,
                            style: AppFonts.textStyle(
                              fontSize: 13.scaledText(context),
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 12.scaledVertical(context)),

              // Search field
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: AppFonts.textStyle(
                          fontSize: 14.scaledText(context),
                          color: Colors.white,
                        ),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: 'Search currency...',
                          hintStyle: AppFonts.textStyle(
                            fontSize: 14.scaledText(context),
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 18.scaled(context),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    size: 18.scaled(context),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.scaled(context),
                            vertical: 10.scaledVertical(context),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.scaled(context)),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.scaled(context)),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 10.scaledVertical(context)),

              // Currency list (compact)
              Expanded(
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: _filteredCurrencies.isEmpty
                          ? _EmptySearchState(
                              searchQuery: _searchQuery,
                              onClear: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenHorizontal,
                              ),
                              itemCount: _filteredCurrencies.length,
                              itemBuilder: (context, index) {
                                final currency = _filteredCurrencies[index];
                                final isSelected = _selectedCurrency == currency;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 4.scaledVertical(context),
                                  ),
                                  child: _CurrencyTile(
                                    currency: currency,
                                    isSelected: isSelected,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      // Dismiss keyboard when selecting a currency
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        _selectedCurrency = currency;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    );
                  },
                ),
              ),

              // Continue button (compact)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  10.scaledVertical(context),
                  AppSpacing.screenHorizontal,
                  24.scaledVertical(context),
                ),
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedCurrency != null ? _onContinue : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PreAppColors.warningColor,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            disabledForegroundColor:
                                Colors.white.withValues(alpha: 0.5),
                            padding: EdgeInsets.symmetric(
                              vertical: 14.scaledVertical(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12.scaled(context)),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Continue',
                            style: AppFonts.textStyle(
                              fontSize: 16.scaledText(context),
                              fontWeight: FontWeight.w700,
                              color: _selectedCurrency != null
                                  ? Colors.black
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final Currency currency;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyTile({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 12.scaled(context),
          vertical: 10.scaledVertical(context),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? PreAppColors.warningColor.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.scaled(context)),
          border: Border.all(
            color: isSelected
                ? PreAppColors.warningColor.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Currency symbol (no container)
            Text(
              currency.symbol,
              style: AppFonts.textStyle(
                fontSize: 18.scaledText(context),
                fontWeight: FontWeight.w700,
                color: isSelected ? PreAppColors.warningColor : Colors.white,
              ),
            ),
            SizedBox(width: 12.scaled(context)),

            // Currency info (compact)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.name,
                    style: AppFonts.textStyle(
                      fontSize: 14.scaledText(context),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1.scaledVertical(context)),
                  Text(
                    '${currency.code} • ${currency.country}',
                    style: AppFonts.textStyle(
                      fontSize: 12.scaledText(context),
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark (no container)
            if (isSelected)
              Icon(
                Icons.check_rounded,
                size: 20.scaled(context),
                color: PreAppColors.warningColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onClear;

  const _EmptySearchState({
    required this.searchQuery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40.scaled(context),
              color: Colors.white.withValues(alpha: 0.4),
            ),
            SizedBox(height: 12.scaledVertical(context)),
            Text(
              'No currencies found',
              style: AppFonts.textStyle(
                fontSize: 16.scaledText(context),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.scaledVertical(context)),
            Text(
              'No results for "$searchQuery"',
              textAlign: TextAlign.center,
              style: AppFonts.textStyle(
                fontSize: 13.scaledText(context),
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 16.scaledVertical(context)),
            TextButton.icon(
              onPressed: onClear,
              icon: Icon(
                Icons.close_rounded,
                size: 16.scaled(context),
                color: PreAppColors.warningColor,
              ),
              label: Text(
                'Clear search',
                style: AppFonts.textStyle(
                  fontSize: 14.scaledText(context),
                  fontWeight: FontWeight.w600,
                  color: PreAppColors.warningColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
