import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/recommendation.dart';
import '../utils/exceptions.dart';

class ApiService {
  // Environment-based API URL configuration
  // Set via --dart-define=API_URL=http://your-api-url:8000 during build
  // Or defaults to platform-specific localhost
  static String get baseUrl {
    // Check for environment variable first (production/staging)
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Platform-specific defaults for local development
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android emulator localhost
    } else if (Platform.isIOS) {
      return 'http://localhost:8000'; // iOS simulator localhost
    } else {
      return 'http://localhost:8000'; // Desktop/other platforms
    }
  }

  // API timeout configuration
  static const Duration requestTimeout = Duration(seconds: 30);

  // Get recommendations from the API
  Future<List<Recommendation>> getRecommendations(
    UserProfile profile, {
    int numRecommendations = 5,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/recommend/simple'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(profile.toJson()),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // Backend can return either a Map (like on-device) or a List
        if (data is Map<String, dynamic>) {
          // Map structure: {"FP000001": {...}, "FP000002": {...}}
          final recommendations = data.entries.map((entry) {
            final programId = entry.key;
            final programData = entry.value as Map<String, dynamic>;
            return Recommendation.fromJson(programId, programData);
          }).toList();

          if (recommendations.isEmpty) {
            throw NoRecommendationsException();
          }
          return recommendations;
        } else if (data is List) {
          // If backend returns list with program_id field
          final recommendations = data.map((json) {
            final programId = json['program_id'] ?? 'UNKNOWN';
            return Recommendation.fromJson(programId, json as Map<String, dynamic>);
          }).toList();

          if (recommendations.isEmpty) {
            throw NoRecommendationsException();
          }
          return recommendations;
        } else {
          throw DataFormatException(
            'Unexpected response format from API',
            details: 'Expected Map or List, got ${data.runtimeType}',
          );
        }
      } else if (response.statusCode == 404) {
        throw ServerException(
          'Endpoint not found',
          statusCode: 404,
          details: 'The API endpoint may have changed',
        );
      } else if (response.statusCode == 503) {
        throw ServerException(
          'Service unavailable',
          statusCode: 503,
          details: 'The recommendation service is temporarily down',
        );
      } else if (response.statusCode >= 500) {
        throw ServerException(
          'Server error',
          statusCode: response.statusCode,
          details: response.body,
        );
      } else {
        throw ServerException(
          'Request failed',
          statusCode: response.statusCode,
          details: response.body,
        );
      }
    } on TimeoutException {
      throw TimeoutException();
    } on SocketException catch (e) {
      throw NetworkException(
        'Network connection failed',
        details: e.message,
      );
    } on FormatException catch (e) {
      throw DataFormatException(
        'Invalid JSON response',
        details: e.message,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        'Failed to get recommendations',
        details: e.toString(),
      );
    }
  }

  // Health check endpoint
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get API info
  Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}

