import 'dart:async';
import 'package:flutter/foundation.dart';

/// API helper with retry logic and error handling
class ApiHelper {
  /// Execute an async operation with retry logic
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delayBetweenRetries = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        attempts++;
        
        // Check if we should retry this error
        final retry = shouldRetry?.call(e) ?? _isRetryableError(e);
        
        if (!retry || attempts >= maxAttempts) {
          break;
        }

        // Wait before retrying
        await Future.delayed(delayBetweenRetries * attempts);
        debugPrint('Retry attempt $attempts for operation after error: $e');
      }
    }

    throw lastError;
  }

  /// Check if an error is retryable (network errors, timeouts, etc.)
  static bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504');
  }

  /// Parse API error message for user display
  static String parseErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    // Common Supabase/PostgreSQL errors
    if (errorString.contains('duplicate key')) {
      return 'This item already exists.';
    }
    if (errorString.contains('violates foreign key')) {
      return 'Cannot delete: this item is referenced by other records.';
    }
    if (errorString.contains('violates not-null')) {
      return 'Required field is missing.';
    }
    if (errorString.contains('row-level security')) {
      return 'You do not have permission to perform this action.';
    }
    if (errorString.contains('JWT expired')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    // Generic fallback
    return 'An error occurred. Please try again.';
  }
}

/// Result wrapper for operations that can fail
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result._({this.data, this.error, required this.isSuccess});

  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.failure(String error) => Result._(error: error, isSuccess: false);

  /// Map success value
  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      return Result.success(mapper(data));
    }
    return Result.failure(error ?? 'Unknown error');
  }
}
