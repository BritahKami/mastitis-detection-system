import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/mds_models.dart';

/// Centralized API and Networking Service for Mastitis Detection System
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  http.Client _client = http.Client();

  // Test helper to allow injecting mock HTTP client during tests if needed
  void setClientForTesting(http.Client client) {
    _client = client;
  }

  // ===========================================================================
  // Token & Storage Management (shared_preferences)
  // ===========================================================================

  /// Retrieves the stored JWT authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.authTokenKey);
  }

  /// Securely stores the JWT token in shared_preferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.authTokenKey, token);
  }

  /// Clears stored authentication data on logout
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.authTokenKey);
    await prefs.remove(ApiConstants.authUserEmailKey);
  }

  /// Checks if a valid auth token is present
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Builds standard authorization headers with Bearer token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ===========================================================================
  // Authentication & Registration APIs
  // ===========================================================================

  /// Authenticates farmer credentials against POST /api/auth/login
  /// Stores access_token in SharedPreferences upon 200 OK
  Future<String> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final data = _parseResponseBody(response);

      if (response.statusCode == 200) {
        final token = data['access_token']?.toString();
        if (token == null || token.isEmpty) {
          throw const ApiException('Invalid authentication response from server.');
        }

        // Save token in shared_preferences
        await saveToken(token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.authUserEmailKey, email.trim().toLowerCase());

        return token;
      } else {
        final message = data['detail'] ?? data['message'] ?? 'Authentication failed.';
        throw ApiException(message.toString());
      }
    } on SocketException {
      throw const ApiException(
        'Unable to connect to server at ${ApiConstants.baseUrl}. Please check your connection.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Login request failed: ${e.toString()}');
    }
  }

  /// Registers a new farmer account via POST /api/auth/register
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fname': firstName.trim(),
          'lname': lastName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final data = _parseResponseBody(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else {
        final message = data['detail'] ?? data['message'] ?? 'Registration failed.';
        throw ApiException(message.toString());
      }
    } on SocketException {
      throw const ApiException(
        'Unable to connect to server at ${ApiConstants.baseUrl}. Please check your connection.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Registration failed: ${e.toString()}');
    }
  }

  // ===========================================================================
  // Profile & User Details APIs
  // ===========================================================================

  /// Fetches the authenticated farmer's profile via GET /api/auth/profile
  Future<FarmerProfile> getProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.get(
        Uri.parse(ApiConstants.profileEndpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return FarmerProfile.fromJson(data);
      } else if (response.statusCode == 401) {
        await clearAuth();
        throw const ApiException('Session expired. Please log in again.');
      } else {
        final data = _parseResponseBody(response);
        final message = data['detail'] ?? data['message'] ?? 'Failed to load profile.';
        throw ApiException(message.toString());
      }
    } on SocketException {
      throw const ApiException(
        'Cannot reach server. Please ensure backend is active on ${ApiConstants.baseUrl}.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching profile: ${e.toString()}');
    }
  }

  // ===========================================================================
  // Dairy Cow Management APIs
  // ===========================================================================

  /// Retrieves list of all registered cows owned by the authenticated farmer
  Future<List<Cow>> getCows() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.get(
        Uri.parse(ApiConstants.cowsEndpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) => Cow.fromJson(item as Map<String, dynamic>)).toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        await clearAuth();
        throw const ApiException('Session expired. Please log in again.');
      } else {
        final data = _parseResponseBody(response);
        final message = data['detail'] ?? data['message'] ?? 'Failed to load cows.';
        throw ApiException(message.toString());
      }
    } on SocketException {
      throw const ApiException(
        'Cannot reach server. Please ensure backend is active on ${ApiConstants.baseUrl}.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching cows: ${e.toString()}');
    }
  }

  /// Registers a new cow via POST /api/cows
  Future<Cow> addCow({
    required String cowTag,
    required String breed,
    required int age,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.post(
        Uri.parse(ApiConstants.cowsEndpoint),
        headers: headers,
        body: jsonEncode({
          'cow_tag': cowTag.trim(),
          'breed': breed.trim(),
          'age': age,
        }),
      );

      final data = _parseResponseBody(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Cow.fromJson(data);
      } else if (response.statusCode == 401) {
        await clearAuth();
        throw const ApiException('Session expired. Please log in again.');
      } else {
        final message = data['detail'] ?? data['message'] ?? 'Failed to register cow.';
        throw ApiException(message.toString());
      }
    } on SocketException {
      throw const ApiException('Cannot reach server. Please check your network connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error saving cow: ${e.toString()}');
    }
  }

  /// Fetches a specific cow's full profile including historical test records
  Future<Cow> getCowDetails(String cowId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.get(
        Uri.parse(ApiConstants.cowDetailsEndpoint(cowId)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Cow.fromJson(data);
      } else {
        final data = _parseResponseBody(response);
        final message = data['detail'] ?? data['message'] ?? 'Failed to load cow details.';
        throw ApiException(message.toString());
      }
    } on SocketException {
      throw const ApiException('Cannot reach server. Please check your network connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error loading cow details: ${e.toString()}');
    }
  }

  // ===========================================================================
  // Diagnostic Testing & Polling APIs
  // ===========================================================================

  /// Initiates a diagnostic test for a specific cow
  Future<void> initiateTest(String cowId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.post(
        Uri.parse(ApiConstants.initiateTestEndpoint(cowId)),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = _parseResponseBody(response);
        final message = data['detail'] ?? data['message'] ?? 'Failed to initiate test.';
        throw ApiException(message.toString());
      }
    } on SocketException {
      throw const ApiException('Cannot reach server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error initiating test: ${e.toString()}');
    }
  }

  /// Polls the latest diagnostic test result (returns 202 if pending, 200 if completed)
  Future<Map<String, dynamic>> pollLatestResult(String cowId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.get(
        Uri.parse(ApiConstants.latestResultEndpoint(cowId)),
        headers: headers,
      );

      final data = _parseResponseBody(response);
      return {
        'statusCode': response.statusCode,
        'data': data,
      };
    } on SocketException {
      throw const ApiException('Cannot reach server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error polling test result: ${e.toString()}');
    }
  }

  // ===========================================================================
  // Alerts APIs
  // ===========================================================================

  /// Retrieves all notifications for the authenticated farmer
  Future<List<AlertNotification>> getAlerts() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.get(
        Uri.parse(ApiConstants.alertsEndpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => AlertNotification.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        final data = _parseResponseBody(response);
        final message = data['detail'] ?? data['message'] ?? 'Failed to load alerts.';
        throw ApiException(message.toString());
      }
    } on SocketException {
      throw const ApiException('Cannot reach server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching alerts: ${e.toString()}');
    }
  }

  /// Marks a single alert as read
  Future<void> markAlertRead(String alertId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.put(
        Uri.parse(ApiConstants.markAlertReadEndpoint(alertId)),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = _parseResponseBody(response);
        final message = data['detail'] ?? data['message'] ?? 'Failed to update alert.';
        throw ApiException(message.toString());
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error updating alert: ${e.toString()}');
    }
  }

  /// Marks all unread alerts as read
  Future<void> markAllAlertsRead() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.put(
        Uri.parse(ApiConstants.markAllAlertsReadEndpoint),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = _parseResponseBody(response);
        final message = data['detail'] ?? data['message'] ?? 'Failed to mark all alerts read.';
        throw ApiException(message.toString());
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error updating alerts: ${e.toString()}');
    }
  }

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  Map<String, dynamic> _parseResponseBody(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'message': response.body};
    }
  }
}

/// Custom Exception for MDS API errors
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
