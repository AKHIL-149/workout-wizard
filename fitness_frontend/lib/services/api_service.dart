import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/recommendation.dart';

class ApiService {
  // Update this URL based on your environment
  
  // For web development (localhost):
  // static const String baseUrl = 'http://localhost:8000';
  
  // For Android emulator (localhost from emulator's perspective):
  // static const String baseUrl = 'http://10.0.2.2:8000';
  
  // For iOS simulator (localhost):
  // static const String baseUrl = 'http://localhost:8000';
  
  // For physical device on same network (replace with your computer's IP):
  // static const String baseUrl = 'http://192.168.1.XXX:8000';
  
  // For production (update after deploying to Render/Railway):
  static const String baseUrl = 'http://10.0.2.2:8000'; // Default: Android emulator

  // Get recommendations from the API
  Future<List<Recommendation>> getRecommendations(
    UserProfile profile, {
    int numRecommendations = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommend/simple'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(profile.toJson()),
      );

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
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get API info
  Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}

