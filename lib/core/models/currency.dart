/// Currency model representing supported currencies
class Currency {
  final String code;
  final String name;
  final String symbol;
  final String country;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.country,
  });

  /// All supported currencies
  static const List<Currency> all = [
    Currency(
      code: 'NGN',
      name: 'Nigerian Naira',
      symbol: '₦',
      country: 'Nigeria',
    ),
    Currency(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      country: 'United States',
    ),
    Currency(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      country: 'United Kingdom',
    ),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', country: 'European Union'),
    Currency(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      country: 'Canada',
    ),
    Currency(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      country: 'Australia',
    ),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', country: 'Japan'),
    Currency(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'Fr',
      country: 'Switzerland',
    ),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', country: 'China'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', country: 'India'),
    Currency(
      code: 'ZAR',
      name: 'South African Rand',
      symbol: 'R',
      country: 'South Africa',
    ),
    Currency(
      code: 'KES',
      name: 'Kenyan Shilling',
      symbol: 'KSh',
      country: 'Kenya',
    ),
    Currency(code: 'GHS', name: 'Ghanaian Cedi', symbol: '₵', country: 'Ghana'),
  ];

  /// Default currency (NGN)
  static const Currency defaultCurrency = Currency(
    code: 'NGN',
    name: 'Nigerian Naira',
    symbol: '₦',
    country: 'Nigeria',
  );

  /// Find currency by code
  static Currency? findByCode(String code) {
    try {
      return all.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => '$name ($symbol)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
