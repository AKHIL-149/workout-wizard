import 'dart:io';

/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final int? statusCode;

  AppException(this.message, {this.details, this.statusCode});

  @override
  String toString() => message;

  String get userMessage => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.details, super.statusCode});

  @override
  String get userMessage => 'Network error. Please check your connection and try again.';
}

/// API call timeout
class TimeoutException extends NetworkException {
  TimeoutException()
      : super('Request timed out', details: 'The server took too long to respond');

  @override
  String get userMessage => 'Request timed out. Please try again.';
}

/// Server returned an error response
class ServerException extends AppException {
  ServerException(super.message, {super.details, super.statusCode});

  @override
  String get userMessage {
    if (statusCode == 500) {
      return 'Server error. Please try again later.';
    } else if (statusCode == 503) {
      return 'Service temporarily unavailable. Please try again later.';
    } else if (statusCode == 404) {
      return 'Requested resource not found.';
    }
    return 'Server error: $message';
  }
}

/// API returned invalid/unexpected data
class DataFormatException extends AppException {
  DataFormatException(super.message, {super.details});

  @override
  String get userMessage => 'Invalid data received. Please try again.';
}

/// No recommendations found
class NoRecommendationsException extends AppException {
  NoRecommendationsException()
      : super('No programs match your criteria',
            details: 'Try adjusting your preferences');

  @override
  String get userMessage => 'No matching programs found. Try adjusting your filters.';
}

/// Storage/persistence exceptions
class StorageException extends AppException {
  StorageException(super.message, {super.details});

  @override
  String get userMessage => 'Error saving data. Please try again.';
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(super.message, {this.fieldErrors, super.details});

  @override
  String get userMessage => message;
}

/// User cancelled operation
class CancelledException extends AppException {
  CancelledException() : super('Operation cancelled');

  @override
  String get userMessage => 'Operation cancelled.';
}

/// Helper to convert platform exceptions to app exceptions
AppException fromException(dynamic error) {
  if (error is AppException) {
    return error;
  } else if (error is TimeoutException) {
    return TimeoutException();
  } else if (error is SocketException) {
    return NetworkException(
      'Network error',
      details: error.message,
    );
  } else if (error is HttpException) {
    return ServerException(
      'Server error',
      details: error.message,
    );
  } else if (error is FormatException) {
    return DataFormatException(
      'Invalid data format',
      details: error.message,
    );
  } else {
    return UnknownException(
      error.toString(),
    );
  }
}

/// Generic exception for unknown errors
class UnknownException extends AppException {
  UnknownException(super.message, {super.details});

  @override
  String get userMessage => 'An unexpected error occurred. Please try again.';
}
