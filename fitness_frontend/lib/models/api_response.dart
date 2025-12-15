/// API response models that match backend schema exactly
library;

import 'dart:convert';

/// API version information
class ApiVersion {
  final String apiVersion;
  final String minSupportedClient;
  final Map<String, String> responseFormat;
  final List<ApiEndpoint> endpoints;

  ApiVersion({
    required this.apiVersion,
    required this.minSupportedClient,
    required this.responseFormat,
    required this.endpoints,
  });

  factory ApiVersion.fromJson(Map<String, dynamic> json) {
    return ApiVersion(
      apiVersion: json['api_version'] as String,
      minSupportedClient: json['min_supported_client'] as String,
      responseFormat: Map<String, String>.from(json['response_format'] as Map),
      endpoints: (json['endpoints'] as List)
          .map((e) => ApiEndpoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool isCompatibleWith(String clientVersion) {
    final minParts = minSupportedClient.split('.');
    final clientParts = clientVersion.split('.');

    for (var i = 0; i < minParts.length && i < clientParts.length; i++) {
      final minNum = int.tryParse(minParts[i]) ?? 0;
      final clientNum = int.tryParse(clientParts[i]) ?? 0;

      if (clientNum < minNum) return false;
      if (clientNum > minNum) return true;
    }

    return true;
  }
}

/// API endpoint information
class ApiEndpoint {
  final String path;
  final String method;

  ApiEndpoint({
    required this.path,
    required this.method,
  });

  factory ApiEndpoint.fromJson(Map<String, dynamic> json) {
    return ApiEndpoint(
      path: json['path'] as String,
      method: json['method'] as String,
    );
  }
}

/// Health check response
class HealthCheckResponse {
  final String status;
  final String version;
  final bool modelLoaded;

  HealthCheckResponse({
    required this.status,
    required this.version,
    required this.modelLoaded,
  });

  factory HealthCheckResponse.fromJson(Map<String, dynamic> json) {
    return HealthCheckResponse(
      status: json['status'] as String,
      version: json['version'] as String,
      modelLoaded: json['model_loaded'] as bool,
    );
  }

  bool get isHealthy => status == 'healthy';
}

/// API error response
class ApiErrorResponse {
  final String detail;
  final List<ValidationError>? errors;

  ApiErrorResponse({
    required this.detail,
    this.errors,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    return ApiErrorResponse(
      detail: json['detail'] as String,
      errors: json['errors'] != null
          ? (json['errors'] as List)
              .map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  String get userMessage {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.map((e) => '${e.field}: ${e.message}').join('\n');
    }
    return detail;
  }
}

/// Validation error
class ValidationError {
  final String field;
  final String message;
  final String type;

  ValidationError({
    required this.field,
    required this.message,
    required this.type,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
    );
  }
}

/// Constants for API values (matching backend)
class ApiConstants {
  static const List<String> validFitnessLevels = [
    'Beginner',
    'Novice',
    'Intermediate',
    'Advanced',
  ];

  static const List<String> validGoals = [
    'General Fitness',
    'Weight Loss',
    'Strength',
    'Hypertrophy',
    'Bodybuilding',
    'Powerlifting',
    'Athletics',
    'Endurance',
    'Muscle & Sculpting',
    'Bodyweight Fitness',
    'Athletic Performance',
  ];

  static const List<String> validEquipment = [
    'At Home',
    'Dumbbell Only',
    'Full Gym',
    'Garage Gym',
  ];

  static const List<String> validDurations = [
    '30-45 min',
    '45-60 min',
    '60-75 min',
    '75-90 min',
    '90+ min',
  ];

  static const List<String> validTrainingStyles = [
    'Full Body',
    'Upper/Lower',
    'Push/Pull/Legs',
    'Body Part Split',
    'No preference',
  ];

  static bool isValidFitnessLevel(String level) =>
      validFitnessLevels.contains(level);

  static bool isValidGoal(String goal) => validGoals.contains(goal);

  static bool isValidEquipment(String equipment) =>
      validEquipment.contains(equipment);

  static bool isValidDuration(String duration) =>
      validDurations.contains(duration);

  static bool isValidTrainingStyle(String style) =>
      validTrainingStyles.contains(style);
}
