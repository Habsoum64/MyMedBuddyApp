import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medication.dart';
import '../models/appointment.dart';
import '../models/health_tip.dart';
import '../models/user_profile.dart';
import 'database_service.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }

  // Base URL for your API - update this to your actual API endpoint
  static const String _baseUrl = 'https://your-api-endpoint.com/api';
  
  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (AuthService().currentUserId != null)
      'Authorization': 'Bearer ${AuthService().currentUserId}',
  };

  // Generic HTTP request handler
  Future<ApiResponse<T>> _makeRequest<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(List<dynamic>)? fromJsonList,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: _headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: _headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJsonList != null && responseData['data'] is List) {
          return ApiResponse.success(fromJsonList(responseData['data']));
        } else if (fromJson != null && responseData['data'] is Map) {
          return ApiResponse.success(fromJson(responseData['data']));
        } else {
          return ApiResponse.success(responseData['data']);
        }
      } else {
        return ApiResponse.error(
          responseData['message'] ?? 'Request failed',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        // No internet connection - fall back to local database
        return await _handleOfflineRequest<T>(method, endpoint, body);
      }
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Handle requests when offline by using local database
  Future<ApiResponse<T>> _handleOfflineRequest<T>(
    String method,
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    try {
      final db = DatabaseService();
      final currentUserId = AuthService().currentUserId;

      if (currentUserId == null) {
        return ApiResponse.error('User not authenticated');
      }

      // Handle different endpoints offline
      if (endpoint.contains('/medications')) {
        if (method == 'GET') {
          final medications = await _getLocalMedications(currentUserId);
          return ApiResponse.success(medications as T);
        } else if (method == 'POST' && body != null) {
          await _saveLocalMedication(currentUserId, body);
          return ApiResponse.success(body as T);
        }
      } else if (endpoint.contains('/appointments')) {
        if (method == 'GET') {
          final appointments = await _getLocalAppointments(currentUserId);
          return ApiResponse.success(appointments as T);
        } else if (method == 'POST' && body != null) {
          await _saveLocalAppointment(currentUserId, body);
          return ApiResponse.success(body as T);
        }
      } else if (endpoint.contains('/health-tips')) {
        if (method == 'GET') {
          final healthTips = await _getLocalHealthTips();
          return ApiResponse.success(healthTips as T);
        }
      }

      return ApiResponse.error('Offline mode: Operation not supported');
    } catch (e) {
      return ApiResponse.error('Offline error: ${e.toString()}');
    }
  }

  // User Authentication API calls
  Future<ApiResponse<UserProfile>> registerUser({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    return await _makeRequest<UserProfile>(
      'POST',
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
        if (gender != null) 'gender': gender,
      },
      fromJson: (json) => UserProfile.fromMap(json),
    );
  }

  Future<ApiResponse<UserProfile>> loginUser({
    required String email,
    required String password,
  }) async {
    return await _makeRequest<UserProfile>(
      'POST',
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      fromJson: (json) => UserProfile.fromMap(json),
    );
  }

  // Medications API calls
  Future<ApiResponse<List<Medication>>> getUserMedications() async {
    return await _makeRequest<List<Medication>>(
      'GET',
      '/medications',
      fromJsonList: (jsonList) => jsonList
          .map((json) => Medication.fromMap(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<Medication>> addMedication(Medication medication) async {
    return await _makeRequest<Medication>(
      'POST',
      '/medications',
      body: medication.toMap(),
      fromJson: (json) => Medication.fromMap(json),
    );
  }

  Future<ApiResponse<Medication>> updateMedication(Medication medication) async {
    return await _makeRequest<Medication>(
      'PUT',
      '/medications/${medication.id}',
      body: medication.toMap(),
      fromJson: (json) => Medication.fromMap(json),
    );
  }

  Future<ApiResponse<void>> deleteMedication(String medicationId) async {
    return await _makeRequest<void>('DELETE', '/medications/$medicationId');
  }

  // Medications catalog API calls
  Future<ApiResponse<List<Medication>>> searchMedicationsCatalog(String query) async {
    return await _makeRequest<List<Medication>>(
      'GET',
      '/medications/catalog/search?q=$query',
      fromJsonList: (jsonList) => jsonList
          .map((json) => Medication.fromMap(json as Map<String, dynamic>))
          .toList(),
    );
  }

  // Appointments API calls
  Future<ApiResponse<List<Appointment>>> getUserAppointments() async {
    return await _makeRequest<List<Appointment>>(
      'GET',
      '/appointments',
      fromJsonList: (jsonList) => jsonList
          .map((json) => Appointment.fromMap(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<Appointment>> addAppointment(Appointment appointment) async {
    return await _makeRequest<Appointment>(
      'POST',
      '/appointments',
      body: appointment.toMap(),
      fromJson: (json) => Appointment.fromMap(json),
    );
  }

  Future<ApiResponse<Appointment>> updateAppointment(Appointment appointment) async {
    return await _makeRequest<Appointment>(
      'PUT',
      '/appointments/${appointment.id}',
      body: appointment.toMap(),
      fromJson: (json) => Appointment.fromMap(json),
    );
  }

  Future<ApiResponse<void>> deleteAppointment(String appointmentId) async {
    return await _makeRequest<void>('DELETE', '/appointments/$appointmentId');
  }

  // Health Tips API calls
  Future<ApiResponse<List<HealthTip>>> getHealthTips({
    String? category,
    String? searchQuery,
  }) async {
    String endpoint = '/health-tips';
    final queryParams = <String>[];
    
    if (category != null) queryParams.add('category=$category');
    if (searchQuery != null) queryParams.add('search=$searchQuery');
    
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    return await _makeRequest<List<HealthTip>>(
      'GET',
      endpoint,
      fromJsonList: (jsonList) => jsonList
          .map((json) => HealthTip.fromMap(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<String>>> getHealthTipCategories() async {
    final response = await _makeRequest<List<String>>(
      'GET',
      '/health-tips/categories',
      fromJsonList: (jsonList) => jsonList.cast<String>(),
    );
    return response;
  }

  // Local database methods for offline functionality
  Future<List<Medication>> _getLocalMedications(String userId) async {
    // Implementation would get user-specific medications from local database
    // For now, return empty list - you can implement this based on your needs
    return [];
  }

  Future<void> _saveLocalMedication(String userId, Map<String, dynamic> medicationData) async {
    // Implementation would save medication to local database
    // You can implement this based on your needs
  }

  Future<List<Appointment>> _getLocalAppointments(String userId) async {
    // Implementation would get user-specific appointments from local database
    // For now, return empty list - you can implement this based on your needs
    return [];
  }

  Future<void> _saveLocalAppointment(String userId, Map<String, dynamic> appointmentData) async {
    // Implementation would save appointment to local database
    // You can implement this based on your needs
  }

  Future<List<HealthTip>> _getLocalHealthTips() async {
    // Implementation would get health tips from local database
    // For now, return empty list - you can implement this based on your needs
    return [];
  }

  // Sync methods to sync local data with server when online
  Future<ApiResponse<void>> syncLocalData() async {
    // Implementation would sync all local changes with the server
    // This is called when the app comes back online
    return ApiResponse.success(null);
  }
}

// API Response wrapper class
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
    );
  }

  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse._(
      isSuccess: false,
      error: error,
      statusCode: statusCode,
    );
  }
}
