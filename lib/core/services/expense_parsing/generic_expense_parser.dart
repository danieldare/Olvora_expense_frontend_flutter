import 'package:flutter/foundation.dart';
import 'parsed_expense_result.dart';

/// Currency information for parsing
class CurrencyInfo {
  final String code;
  final String symbol;
  final List<String> aliases;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    this.aliases = const [],
  });
}

/// Generic expense parser that works with any bank/payment service globally
///
/// This parser uses pattern matching to extract expense information from
/// text without relying on bank-specific templates. It supports multiple
/// currencies and common transaction formats.
class GenericExpenseParser {
  /// Supported currencies with their symbols and aliases
  static const List<CurrencyInfo> supportedCurrencies = [
    // Major world currencies
    CurrencyInfo(
      code: 'USD',
      symbol: '\$',
      aliases: ['dollars', 'dollar', 'usd', 'us\$'],
    ),
    CurrencyInfo(code: 'EUR', symbol: '€', aliases: ['euros', 'euro', 'eur']),
    CurrencyInfo(
      code: 'GBP',
      symbol: '£',
      aliases: ['pounds', 'pound', 'gbp', 'sterling'],
    ),
    CurrencyInfo(code: 'JPY', symbol: '¥', aliases: ['yen', 'jpy']),
    CurrencyInfo(code: 'CNY', symbol: '¥', aliases: ['yuan', 'rmb', 'cny']),

    // African currencies
    CurrencyInfo(code: 'NGN', symbol: '₦', aliases: ['naira', 'ngn']),
    CurrencyInfo(code: 'ZAR', symbol: 'R', aliases: ['rand', 'zar']),
    CurrencyInfo(
      code: 'KES',
      symbol: 'KSh',
      aliases: ['shilling', 'shillings', 'kes'],
    ),
    CurrencyInfo(code: 'GHS', symbol: 'GH₵', aliases: ['cedi', 'cedis', 'ghs']),
    CurrencyInfo(code: 'EGP', symbol: 'E£', aliases: ['egyptian pound', 'egp']),

    // Asian currencies
    CurrencyInfo(
      code: 'INR',
      symbol: '₹',
      aliases: ['rupees', 'rupee', 'inr', 'rs'],
    ),
    CurrencyInfo(code: 'PKR', symbol: '₨', aliases: ['pakistani rupee', 'pkr']),
    CurrencyInfo(code: 'BDT', symbol: '৳', aliases: ['taka', 'bdt']),
    CurrencyInfo(code: 'PHP', symbol: '₱', aliases: ['peso', 'pesos', 'php']),
    CurrencyInfo(code: 'IDR', symbol: 'Rp', aliases: ['rupiah', 'idr']),
    CurrencyInfo(code: 'MYR', symbol: 'RM', aliases: ['ringgit', 'myr']),
    CurrencyInfo(
      code: 'SGD',
      symbol: 'S\$',
      aliases: ['singapore dollar', 'sgd'],
    ),
    CurrencyInfo(code: 'THB', symbol: '฿', aliases: ['baht', 'thb']),
    CurrencyInfo(code: 'VND', symbol: '₫', aliases: ['dong', 'vnd']),
    CurrencyInfo(code: 'KRW', symbol: '₩', aliases: ['won', 'krw']),

    // Middle Eastern currencies
    CurrencyInfo(
      code: 'AED',
      symbol: 'د.إ',
      aliases: ['dirham', 'dirhams', 'aed'],
    ),
    CurrencyInfo(code: 'SAR', symbol: '﷼', aliases: ['riyal', 'riyals', 'sar']),

    // American currencies
    CurrencyInfo(
      code: 'CAD',
      symbol: 'C\$',
      aliases: ['canadian dollar', 'cad'],
    ),
    CurrencyInfo(code: 'BRL', symbol: 'R\$', aliases: ['real', 'reais', 'brl']),
    CurrencyInfo(code: 'MXN', symbol: 'MX\$', aliases: ['mexican peso', 'mxn']),

    // Other currencies
    CurrencyInfo(
      code: 'AUD',
      symbol: 'A\$',
      aliases: ['australian dollar', 'aud'],
    ),
    CurrencyInfo(
      code: 'NZD',
      symbol: 'NZ\$',
      aliases: ['new zealand dollar', 'nzd'],
    ),
    CurrencyInfo(
      code: 'CHF',
      symbol: 'CHF',
      aliases: ['franc', 'francs', 'swiss franc'],
    ),
    CurrencyInfo(code: 'RUB', symbol: '₽', aliases: ['ruble', 'rubles', 'rub']),
    CurrencyInfo(code: 'TRY', symbol: '₺', aliases: ['lira', 'try']),
  ];

  /// Universal debit/transaction keywords (multi-language)
  static const List<String> debitKeywords = [
    // English
    'debited', 'debit', 'spent', 'paid', 'payment', 'purchase', 'purchased',
    'withdrawal', 'withdrawn', 'charged', 'sent', 'transferred', 'transfer',
    'transaction', 'txn', 'dr', 'deducted', 'used', 'bought', 'expense',
    // Common abbreviations
    'amt', 'amount', 'trx', 'trf',
    // Additional patterns
    'successful', 'completed', 'confirmed',
  ];

  /// Universal credit keywords
  static const List<String> creditKeywords = [
    'credited',
    'credit',
    'received',
    'deposit',
    'deposited',
    'incoming',
    'cr',
    'added',
    'refund',
    'refunded',
    'cashback',
  ];

  /// Parse text and extract expense information
  ParsedExpenseResult parse(String text, ParsingSource source) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return ParsedExpenseResult(
        rawText: text,
        confidence: 0.0,
        source: source,
      );
    }

    final lowerText = normalizedText.toLowerCase();

    // Extract all fields
    final amountResult = _extractAmount(normalizedText);
    final currencyResult = _extractCurrency(normalizedText);
    final merchant = _extractMerchant(normalizedText);
    final date = _extractDate(normalizedText);
    final accountId = _extractAccountIdentifier(normalizedText);
    final balance = _extractBalance(normalizedText);
    final transactionType = _determineTransactionType(lowerText);
    final description = _extractDescription(normalizedText, merchant);

    // Generate suggested title
    String? suggestedTitle;
    if (merchant != null) {
      suggestedTitle = merchant;
    } else if (description != null && description.length <= 50) {
      suggestedTitle = description;
    }

    // Build result
    final result = ParsedExpenseResult(
      amount: amountResult?.amount,
      currency: currencyResult?.code ?? amountResult?.currencyCode,
      currencySymbol: currencyResult?.symbol ?? amountResult?.currencySymbol,
      merchant: merchant,
      date: date,
      description: description,
      accountIdentifier: accountId,
      balance: balance,
      transactionType: transactionType,
      rawText: text,
      confidence: 0.0, // Will be calculated by ConfidenceScorer
      source: source,
      suggestedTitle: suggestedTitle,
    );

    if (kDebugMode) {
      debugPrint('🔍 GenericParser extracted:');
      debugPrint(
        '   Amount: ${result.amount} ${result.currency ?? result.currencySymbol ?? ""}',
      );
      debugPrint('   Merchant: ${result.merchant ?? "not found"}');
      debugPrint('   Date: ${result.date ?? "not found"}');
      debugPrint('   Type: ${result.transactionType ?? "unknown"}');
    }

    return result;
  }

  /// Check if text contains debit transaction indicators
  bool isDebitTransaction(String text) {
    final lowerText = text.toLowerCase();

    // Check for debit keywords
    final hasDebitKeyword = debitKeywords.any((k) => lowerText.contains(k));

    // Check for credit keywords (to exclude credits)
    final hasCreditKeyword = creditKeywords.any((k) => lowerText.contains(k));

    // If has debit keyword and no credit keyword, it's likely a debit
    // If has both, check context more carefully
    if (hasDebitKeyword && !hasCreditKeyword) return true;
    if (hasCreditKeyword && !hasDebitKeyword) return false;

    // If has both or neither, look at context
    // Prioritize debit if amount pattern is present
    return hasDebitKeyword;
  }

  /// Determine transaction type from text
  String? _determineTransactionType(String lowerText) {
    if (creditKeywords.any((k) => lowerText.contains(k))) {
      return 'credit';
    }
    if (debitKeywords.any((k) => lowerText.contains(k))) {
      return 'debit';
    }
    return null;
  }

  /// Extract amount from text with currency detection
  _AmountResult? _extractAmount(String text) {
    // Pattern 1: Currency symbol before amount (most common)
    // Matches: $50.00, £30, €25.50, ₦5,000.00, ₹500
    final symbolBeforePattern = RegExp(
      r'([\$£€₦₹¥₩₽₺฿₫₱৳₨])\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    var match = symbolBeforePattern.firstMatch(text);
    if (match != null) {
      final symbol = match.group(1)!;
      final amountStr = match.group(2)!.replaceAll(',', '');
      final amount = double.tryParse(amountStr);
      if (amount != null && amount > 0 && amount < 1000000000) {
        final currency = _getCurrencyFromSymbol(symbol);
        return _AmountResult(
          amount: amount,
          currencySymbol: symbol,
          currencyCode: currency?.code,
        );
      }
    }

    // Pattern 2: Currency code before amount
    // Matches: USD 50.00, NGN 5000, EUR 25.50
    final codeBeforePattern = RegExp(
      r'\b(USD|EUR|GBP|NGN|INR|JPY|CAD|AUD|CHF|CNY|KES|ZAR|GHS|AED|SAR|BRL|MXN|PHP|IDR|MYR|SGD|THB|VND|KRW|PKR|BDT|EGP|TRY|RUB|NZD)\s*:?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    match = codeBeforePattern.firstMatch(text);
    if (match != null) {
      final code = match.group(1)!.toUpperCase();
      final amountStr = match.group(2)!.replaceAll(',', '');
      final amount = double.tryParse(amountStr);
      if (amount != null && amount > 0 && amount < 1000000000) {
        final currency = supportedCurrencies.firstWhere(
          (c) => c.code == code,
          orElse: () => CurrencyInfo(code: code, symbol: code),
        );
        return _AmountResult(
          amount: amount,
          currencyCode: currency.code,
          currencySymbol: currency.symbol,
        );
      }
    }

    // Pattern 3: Amount followed by currency code
    // Matches: 50.00 USD, 5000 NGN
    final codeAfterPattern = RegExp(
      r'([\d,]+\.?\d*)\s*(USD|EUR|GBP|NGN|INR|JPY|CAD|AUD|CHF|CNY|KES|ZAR|GHS|AED|SAR|BRL|MXN|PHP|IDR|MYR|SGD|THB|VND|KRW|PKR|BDT|EGP|TRY|RUB|NZD)\b',
      caseSensitive: false,
    );

    match = codeAfterPattern.firstMatch(text);
    if (match != null) {
      final amountStr = match.group(1)!.replaceAll(',', '');
      final code = match.group(2)!.toUpperCase();
      final amount = double.tryParse(amountStr);
      if (amount != null && amount > 0 && amount < 1000000000) {
        final currency = supportedCurrencies.firstWhere(
          (c) => c.code == code,
          orElse: () => CurrencyInfo(code: code, symbol: code),
        );
        return _AmountResult(
          amount: amount,
          currencyCode: currency.code,
          currencySymbol: currency.symbol,
        );
      }
    }

    // Pattern 4: Amount with currency word
    // Matches: 50 dollars, 5000 naira, 30 pounds
    final wordPattern = RegExp(
      r'([\d,]+\.?\d*)\s*(dollars?|euros?|pounds?|naira|rupees?|yen|yuan|ringgit|peso|pesos|dirham|dirhams|franc|francs|rand|shillings?|cedis?|baht|dong|won|lira|ruble|rubles|taka|real|reais)\b',
      caseSensitive: false,
    );

    match = wordPattern.firstMatch(text);
    if (match != null) {
      final amountStr = match.group(1)!.replaceAll(',', '');
      final word = match.group(2)!.toLowerCase();
      final amount = double.tryParse(amountStr);
      if (amount != null && amount > 0 && amount < 1000000000) {
        final currency = _getCurrencyFromAlias(word);
        return _AmountResult(
          amount: amount,
          currencyCode: currency?.code,
          currencySymbol: currency?.symbol,
        );
      }
    }

    // Pattern 5: Shorthand amounts (5k = 5000)
    final shorthandPattern = RegExp(
      r'([\d,]+\.?\d*)\s*k\b',
      caseSensitive: false,
    );
    match = shorthandPattern.firstMatch(text);
    if (match != null) {
      final amountStr = match.group(1)!.replaceAll(',', '');
      final baseAmount = double.tryParse(amountStr);
      if (baseAmount != null && baseAmount > 0 && baseAmount < 1000000) {
        return _AmountResult(amount: baseAmount * 1000);
      }
    }

    // Pattern 6: Plain number with context (last resort)
    // Only if near transaction keywords
    final lowerText = text.toLowerCase();
    if (debitKeywords.any((k) => lowerText.contains(k)) ||
        creditKeywords.any((k) => lowerText.contains(k))) {
      final plainPattern = RegExp(r'\b([\d,]+\.\d{2})\b');
      match = plainPattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 1000000000) {
          return _AmountResult(amount: amount);
        }
      }
    }

    return null;
  }

  /// Extract currency from text (without amount)
  CurrencyInfo? _extractCurrency(String text) {
    final lowerText = text.toLowerCase();

    // Check for currency codes
    for (final currency in supportedCurrencies) {
      if (lowerText.contains(currency.code.toLowerCase())) {
        return currency;
      }
      for (final alias in currency.aliases) {
        if (lowerText.contains(alias)) {
          return currency;
        }
      }
    }

    // Check for currency symbols
    for (final currency in supportedCurrencies) {
      if (text.contains(currency.symbol)) {
        return currency;
      }
    }

    return null;
  }

  /// Get currency info from symbol
  CurrencyInfo? _getCurrencyFromSymbol(String symbol) {
    return supportedCurrencies.cast<CurrencyInfo?>().firstWhere(
      (c) => c!.symbol == symbol,
      orElse: () => null,
    );
  }

  /// Get currency info from alias/word
  CurrencyInfo? _getCurrencyFromAlias(String alias) {
    final lowerAlias = alias.toLowerCase();
    return supportedCurrencies.cast<CurrencyInfo?>().firstWhere(
      (c) => c!.aliases.any((a) => lowerAlias.contains(a)),
      orElse: () => null,
    );
  }

  /// Extract merchant name from text
  String? _extractMerchant(String text) {
    // Pattern 1: "at [Merchant]"
    var pattern = RegExp(
      '(?:at|@)\\s+([A-Za-z0-9][A-Za-z0-9\\s&\\-\'\\.]+?)(?:\\s+(?:on|for|dated|via|using|with|ref|txn)|[.,;]|\\s*\\\$)',
      caseSensitive: false,
    );
    var match = pattern.firstMatch(text);
    if (match != null) {
      final merchant = _cleanMerchantName(match.group(1)!);
      if (merchant != null) return merchant;
    }

    // Pattern 2: "from [Merchant]"
    pattern = RegExp(
      '(?:from)\\s+([A-Za-z][A-Za-z0-9\\s&\\-\'\\.]+?)(?:\\s+(?:on|for|dated|at|via|using|with|ref|txn)|[.,;]|\\s*\\\$)',
      caseSensitive: false,
    );
    match = pattern.firstMatch(text);
    if (match != null) {
      final merchant = _cleanMerchantName(match.group(1)!);
      if (merchant != null) return merchant;
    }

    // Pattern 3: "to [Merchant]"
    pattern = RegExp(
      '(?:to)\\s+([A-Za-z][A-Za-z0-9\\s&\\-\'\\.]+?)(?:\\s+(?:on|for|dated|at|via|using|with|ref|txn)|[.,;]|\\s*\\\$)',
      caseSensitive: false,
    );
    match = pattern.firstMatch(text);
    if (match != null) {
      final merchant = _cleanMerchantName(match.group(1)!);
      if (merchant != null) return merchant;
    }

    // Pattern 4: "via [Merchant]"
    pattern = RegExp(
      '(?:via)\\s+([A-Za-z][A-Za-z0-9\\s&\\-\'\\.]+?)(?:\\s+(?:on|for|dated|at|using|with|ref|txn)|[.,;]|\\s*\\\$)',
      caseSensitive: false,
    );
    match = pattern.firstMatch(text);
    if (match != null) {
      final merchant = _cleanMerchantName(match.group(1)!);
      if (merchant != null) return merchant;
    }

    // Pattern 5: "merchant: [Name]" or "payee: [Name]"
    pattern = RegExp(
      '(?:merchant|payee|vendor|beneficiary)[:\\s]+([A-Za-z][A-Za-z0-9\\s&\\-\'\\.]+)',
      caseSensitive: false,
    );
    match = pattern.firstMatch(text);
    if (match != null) {
      final merchant = _cleanMerchantName(match.group(1)!);
      if (merchant != null) return merchant;
    }

    return null;
  }

  /// Clean and validate merchant name
  String? _cleanMerchantName(String name) {
    // Remove extra whitespace
    var cleaned = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Skip if too short or too long
    if (cleaned.length < 2 || cleaned.length > 60) return null;

    // Skip if it's just numbers
    if (RegExp(r'^\d+$').hasMatch(cleaned)) return null;

    // Skip common non-merchant words
    final skipWords = [
      'your',
      'account',
      'bank',
      'card',
      'balance',
      'available',
      'transaction',
      'payment',
      'debit',
      'credit',
      'alert',
    ];
    if (skipWords.contains(cleaned.toLowerCase())) return null;

    // Capitalize first letter of each word
    cleaned = cleaned
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          // Keep all caps for short words (likely acronyms)
          if (word.length <= 3 && word == word.toUpperCase()) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');

    return cleaned;
  }

  /// Extract date from text
  DateTime? _extractDate(String text) {
    final now = DateTime.now();
    final lowerText = text.toLowerCase();

    // Check for relative dates
    if (lowerText.contains('today')) {
      return now;
    }
    if (lowerText.contains('yesterday')) {
      return now.subtract(const Duration(days: 1));
    }

    // Pattern: "X days ago"
    var pattern = RegExp(r'(\d+)\s*days?\s*ago', caseSensitive: false);
    var match = pattern.firstMatch(lowerText);
    if (match != null) {
      final days = int.tryParse(match.group(1)!);
      if (days != null && days >= 0 && days <= 365) {
        return now.subtract(Duration(days: days));
      }
    }

    // Pattern: DD/MM/YYYY or DD-MM-YYYY
    pattern = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})');
    match = pattern.firstMatch(text);
    if (match != null) {
      final part1 = int.tryParse(match.group(1)!);
      final part2 = int.tryParse(match.group(2)!);
      var year = int.tryParse(match.group(3)!);

      if (part1 != null && part2 != null && year != null) {
        // Handle 2-digit year
        if (year < 100) year += 2000;

        // Try DD/MM/YYYY first (more common globally)
        if (part1 >= 1 && part1 <= 31 && part2 >= 1 && part2 <= 12) {
          try {
            return DateTime(year, part2, part1);
          } catch (_) {}
        }
        // Try MM/DD/YYYY
        if (part1 >= 1 && part1 <= 12 && part2 >= 1 && part2 <= 31) {
          try {
            return DateTime(year, part1, part2);
          } catch (_) {}
        }
      }
    }

    // Pattern: DD-Mon-YYYY (e.g., 15-Jan-2024)
    pattern = RegExp(
      r'(\d{1,2})[/\-\s](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[/\-\s,]*(\d{2,4})',
      caseSensitive: false,
    );
    match = pattern.firstMatch(text);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase();
      var year = int.tryParse(match.group(3)!);

      final months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };

      final month = months[monthStr];
      if (day != null && month != null && year != null) {
        if (year < 100) year += 2000;
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    // Pattern: YYYY-MM-DD (ISO format)
    pattern = RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})');
    match = pattern.firstMatch(text);
    if (match != null) {
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);

      if (year != null && month != null && day != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    return null;
  }

  /// Extract account identifier (last 4 digits)
  String? _extractAccountIdentifier(String text) {
    // Pattern: Account ending/ending with XXXX
    var pattern = RegExp(
      r'(?:account|acc|a/c|acct|card)(?:\s+(?:no|number|ending|ending\s+with))?\s*[:\s*#]*\**(\d{4})\b',
      caseSensitive: false,
    );
    var match = pattern.firstMatch(text);
    if (match != null) {
      return match.group(1);
    }

    // Pattern: ***XXXX or ****XXXX
    pattern = RegExp(r'\*{2,}(\d{4})\b');
    match = pattern.firstMatch(text);
    if (match != null) {
      return match.group(1);
    }

    // Pattern: XXXX (standalone 4 digits after "account" context)
    if (text.toLowerCase().contains('account') ||
        text.toLowerCase().contains('card')) {
      pattern = RegExp(r'\b(\d{4})\b(?!\d)');
      final matches = pattern.allMatches(text).toList();
      // Return last match (usually account number comes after amounts)
      if (matches.isNotEmpty) {
        return matches.last.group(1);
      }
    }

    return null;
  }

  /// Extract balance from text
  double? _extractBalance(String text) {
    // Pattern: "balance: XXX" or "bal: XXX" or "avl bal: XXX"
    final pattern = RegExp(
      r'(?:available\s+)?(?:balance|bal)[:\s]+[\$£€₦₹¥]?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match != null) {
      final balanceStr = match.group(1)!.replaceAll(',', '');
      return double.tryParse(balanceStr);
    }
    return null;
  }

  /// Extract description from text
  String? _extractDescription(String text, String? merchant) {
    // Pattern: "for [description]"
    var pattern = RegExp(
      '(?:for)\\s+([A-Za-z][A-Za-z0-9\\s&\\-\'\\.]+?)(?:\\s+(?:on|at|dated|via|using|with|ref)|[.,;]|\\s*\\\$)',
      caseSensitive: false,
    );
    var match = pattern.firstMatch(text);
    if (match != null) {
      final desc = match.group(1)!.trim();
      // Don't return if it's the same as merchant
      if (desc.toLowerCase() != merchant?.toLowerCase() && desc.length >= 3) {
        return desc;
      }
    }

    // Pattern: "narration: XXX" or "desc: XXX"
    pattern = RegExp(
      r'(?:narration|narr|description|desc|remarks?)[:\s]+([^\n]+)',
      caseSensitive: false,
    );
    match = pattern.firstMatch(text);
    if (match != null) {
      final desc = match.group(1)!.trim();
      if (desc.length >= 3 && desc.length <= 200) {
        return desc;
      }
    }

    return null;
  }
}

/// Internal class to hold amount extraction result
class _AmountResult {
  final double amount;
  final String? currencyCode;
  final String? currencySymbol;

  _AmountResult({required this.amount, this.currencyCode, this.currencySymbol});
}
