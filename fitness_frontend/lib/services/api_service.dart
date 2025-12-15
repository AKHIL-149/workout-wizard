import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/recommendation.dart';

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
          return data.entries.map((entry) {
            final programId = entry.key;
            final programData = entry.value as Map<String, dynamic>;
            return Recommendation.fromJson(programId, programData);
          }).toList();
        } else if (data is List) {
          // If backend returns list with program_id field
          return data.map((json) {
            final programId = json['program_id'] ?? 'UNKNOWN';
            return Recommendation.fromJson(programId, json as Map<String, dynamic>);
          }).toList();
        } else {
          throw Exception('Unexpected response format from API');
        }
      } else {
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to API: $e');
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

