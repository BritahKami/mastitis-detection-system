/// API and Networking Constants for Mastitis Detection System (MDS)
class ApiConstants {
  ApiConstants._();

  /// API Base URL configured for physical phone & Android emulator connectivity via hotspot
  static const String baseUrl = 'http://10.193.177.15:8000';

  // Authentication endpoints
  static const String loginEndpoint = '$baseUrl/api/auth/login';
  static const String loginStep1Endpoint = '$baseUrl/api/auth/login-step1';
  static const String loginStep2Endpoint = '$baseUrl/api/auth/login-step2';
  static const String forgotPasswordEndpoint = '$baseUrl/api/auth/forgot-password';
  static const String verifyResetCodeEndpoint = '$baseUrl/api/auth/verify-reset-code';
  static const String resetPasswordEndpoint = '$baseUrl/api/auth/reset-password';
  static const String registerEndpoint = '$baseUrl/api/auth/register';
  static const String profileEndpoint = '$baseUrl/api/auth/profile';

  // Cow management endpoints
  static const String cowsEndpoint = '$baseUrl/api/cows';
  static const String nextCowTagEndpoint = '$baseUrl/api/cows/next-tag';
  static String cowDetailsEndpoint(dynamic cowId) => '$baseUrl/api/cows/$cowId';

  // Diagnostic testing endpoints
  static String initiateTestEndpoint(dynamic cowId) => '$baseUrl/api/cows/$cowId/initiate-test';
  static String latestResultEndpoint(dynamic cowId) => '$baseUrl/api/cows/$cowId/latest-result';

  // Alerts endpoints
  static const String alertsEndpoint = '$baseUrl/api/alerts';
  static String markAlertReadEndpoint(dynamic alertId) => '$baseUrl/api/alerts/$alertId/read';
  static const String markAllAlertsReadEndpoint = '$baseUrl/api/alerts/mark-all-read';

  // Storage keys
  static const String authTokenKey = 'mds_auth_token';
  static const String authUserEmailKey = 'mds_auth_user_email';
}
