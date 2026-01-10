/// Konfigurasi API Backend
class ApiConfig {
  /// Base URL untuk API backend
  /// Ubah ke IP server production saat deploy
  static const String baseUrl = 'http://localhost:3000/api';

  /// Timeout untuk request (dalam detik)
  static const int timeoutSeconds = 30;

  /// Headers default
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
