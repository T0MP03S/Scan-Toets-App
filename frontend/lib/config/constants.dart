class AppConstants {
  static const String appName = 'Toets Scan';
  static const String appVersion = '0.1.0';

  // API - loaded from environment
  // Voor localhost: http://localhost:8000
  // Voor netwerk testing: http://192.168.2.33:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.2.33:8000',
  );

  // Grade scale
  static const double gradeMin = 1.0;
  static const double gradeMax = 10.0;

  // Upload limits
  static const int maxPhotosPerStudent = 4;
  static const int maxFileSizeMb = 10;
}
