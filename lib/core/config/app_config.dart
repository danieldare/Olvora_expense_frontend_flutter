/// Application configuration
///
/// For production deployment, set the API URL using dart-define:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://your-api.com/api
/// flutter build apk --dart-define=API_BASE_URL=https://your-api.com/api
/// ```
///
/// **Physical device not connecting?** Emulator can use the same URL as host.
/// Your phone must use your computer's current LAN IP (not localhost). Backend
/// logs it at startup: "Application (LAN): http://X.X.X.X:4000/api". Update
/// defaultValue below to that IP, or run:
///   flutter run --dart-define=API_BASE_URL=http://YOUR_IP:4000/api
/// Ensure phone and computer are on the same Wi‑Fi.
class AppConfig {
  // Environment-based API URL with fallback
  // Physical device: use your machine's current LAN IP (see backend startup log).
  static const String backendBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://olvoraexpense-dev.up.railway.app/api',
    // defaultValue: 'http://192.168.1.20:4000/api',
  );

  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String authGoogleEndpoint = '/auth/google';
  static const String authLoginEndpoint = '/auth/login';
  static const String authRegisterEndpoint = '/auth/register';
  static const String authRefreshEndpoint = '/auth/refresh';
  // Note: Use /users/me to verify token (protected endpoint)
  static const String usersMeEndpoint = '/users/me';
  static const String usersEndpoint = '/users';
  static const String expensesEndpoint = '/expenses';
  static const String categoriesEndpoint = '/categories';
  static const String receiptsEndpoint = '/receipts';

  // Timeouts
  // Connection timeout: Time to establish connection
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Check if running in production mode
  static bool get isProduction =>
      const String.fromEnvironment(
        'FLUTTER_ENV',
        defaultValue: 'development',
      ) ==
      'production';
}
