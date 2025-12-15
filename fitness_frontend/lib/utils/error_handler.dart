import 'package:flutter/material.dart';
import 'exceptions.dart';
import '../widgets/error_display.dart';

/// Global error handler utilities
class ErrorHandler {
  /// Execute an async operation with error handling
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    required BuildContext context,
    bool showSnackbar = true,
    bool showDialog = false,
    VoidCallback? onError,
  }) async {
    try {
      return await operation();
    } on AppException catch (e) {
      if (showDialog) {
        await ErrorDialog.show(context, e);
      } else if (showSnackbar) {
        ErrorSnackbar.show(context, e);
      }
      onError?.call();
      return null;
    } catch (e) {
      final unknownError = UnknownException(
        'An unexpected error occurred',
        details: e.toString(),
      );
      if (showDialog) {
        await ErrorDialog.show(context, unknownError);
      } else if (showSnackbar) {
        ErrorSnackbar.show(context, unknownError);
      }
      onError?.call();
      return null;
    }
  }

  /// Execute an async operation and return error if it fails
  static Future<ErrorResult<T>> executeWithResult<T>(
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      return ErrorResult.success(result);
    } on AppException catch (e) {
      return ErrorResult.failure(e);
    } catch (e) {
      return ErrorResult.failure(
        UnknownException(
          'An unexpected error occurred',
          details: e.toString(),
        ),
      );
    }
  }

  /// Wrap a widget that might throw errors during build
  static Widget wrapWidget({
    required Widget Function() builder,
    Widget Function(AppException error)? errorBuilder,
  }) {
    try {
      return builder();
    } on AppException catch (e) {
      return errorBuilder?.call(e) ??
          ErrorDisplay(
            error: e,
          );
    } catch (e) {
      final unknownError = UnknownException(
        'Error building widget',
        details: e.toString(),
      );
      return errorBuilder?.call(unknownError) ??
          ErrorDisplay(
            error: unknownError,
          );
    }
  }
}

/// Result wrapper for operations that can fail
class ErrorResult<T> {
  final T? data;
  final AppException? error;
  final bool isSuccess;

  ErrorResult.success(this.data)
      : error = null,
        isSuccess = true;

  ErrorResult.failure(this.error)
      : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;

  /// Get data or throw error
  T get dataOrThrow {
    if (isSuccess) {
      return data as T;
    } else {
      throw error!;
    }
  }

  /// Get data or return default value
  T dataOr(T defaultValue) {
    return data ?? defaultValue;
  }

  /// Transform data if successful
  ErrorResult<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      try {
        return ErrorResult.success(transform(data as T));
      } catch (e) {
        return ErrorResult.failure(
          UnknownException(
            'Error transforming data',
            details: e.toString(),
          ),
        );
      }
    } else {
      return ErrorResult.failure(error!);
    }
  }

  /// Execute callback based on result
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return failure(error!);
    }
  }
}

/// State management helper for async operations with loading/error states
class AsyncState<T> {
  final bool isLoading;
  final T? data;
  final AppException? error;

  const AsyncState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  const AsyncState.loading() : this(isLoading: true);

  const AsyncState.success(T data) : this(data: data);

  const AsyncState.error(AppException error) : this(error: error);

  bool get hasData => data != null;
  bool get hasError => error != null;
  bool get isIdle => !isLoading && !hasData && !hasError;

  /// Build widget based on state
  Widget when({
    required Widget Function() idle,
    required Widget Function() loading,
    required Widget Function(T data) success,
    required Widget Function(AppException error) error,
  }) {
    if (isLoading) {
      return loading();
    } else if (hasError) {
      return error(this.error!);
    } else if (hasData) {
      return success(data as T);
    } else {
      return idle();
    }
  }
}
