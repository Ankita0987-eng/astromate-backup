import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Custom exception for app-wide use
class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  AppException(
    this.message, {
    this.code,
    this.originalException,
  });

  @override
  String toString() => message;
}

/// Error handler for Firestore operations
class FirestoreErrorHandler {
  static String handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action';
        case 'not-found':
          return 'The requested data was not found';
        case 'already-exists':
          return 'This resource already exists';
        case 'failed-precondition':
          return 'Operation failed. Please try again';
        case 'aborted':
          return 'Operation was aborted. Please try again';
        case 'out-of-range':
          return 'The value is out of range';
        case 'unauthenticated':
          return 'Please log in to continue';
        case 'unavailable':
          return 'Service is temporarily unavailable. Please try again later';
        case 'internal':
          return 'An internal error occurred. Please try again';
        case 'data-loss':
          return 'Unrecoverable data loss or corruption';
        default:
          return 'Database error: ${error.message}';
      }
    }
    return 'An unexpected error occurred';
  }
}

/// Error handler for Firebase Authentication
class AuthErrorHandler {
  static String handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'email-already-in-use':
          return 'An account with this email already exists';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters with uppercase, lowercase, and numbers';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later';
        case 'operation-not-allowed':
          return 'This operation is not allowed';
        case 'invalid-credential':
          return 'Invalid credentials provided';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'An authentication error occurred';
  }
}

/// Error handler for Network errors
class NetworkErrorHandler {
  static String handleNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket')) {
      return 'No internet connection. Please check your network';
    }
    if (errorString.contains('timeout')) {
      return 'Request timeout. Please try again';
    }
    if (errorString.contains('connection')) {
      return 'Connection error. Please check your network';
    }
    
    return 'Network error occurred. Please try again';
  }
}

/// Centralized error handler
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    
    if (error is FirebaseAuthException) {
      return AuthErrorHandler.handleAuthError(error);
    }
    
    if (error is FirebaseException) {
      return FirestoreErrorHandler.handleFirestoreError(error);
    }
    
    if (error.toString().contains('Socket') ||
        error.toString().contains('timeout')) {
      return NetworkErrorHandler.handleNetworkError(error);
    }
    
    return 'An unexpected error occurred. Please try again';
  }

  /// Log error to console and analytics
  static void logError(
    dynamic error, {
    String? context,
    String? userId,
  }) {
    final message = getErrorMessage(error);
    
    print('❌ Error${context != null ? ' in $context' : ''}: $message');
    if (error is Exception && error is! AppException) {
      print('Details: ${error.toString()}');
    }
    
    // TODO: Send to analytics service
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'error_occurred',
    //   parameters: {
    //     'error_message': message,
    //     'error_context': context ?? 'unknown',
    //     'user_id': userId ?? 'anonymous',
    //   },
    // );
  }

  /// Safely execute async operation with error handling
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? context,
    String? userId,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e) {
      logError(e, context: context, userId: userId);
      return defaultValue;
    }
  }

  /// Validate data before operations
  static void validate(
    bool condition,
    String errorMessage, {
    String? code,
  }) {
    if (!condition) {
      throw AppException(errorMessage, code: code);
    }
  }
}

/// Retry logic helper
class RetryHelper {
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    
    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(delay * attempt);
      }
    }
    
    throw AppException('Operation failed after $maxAttempts attempts');
  }
}

/// Exception for specific business logic errors
class BusinessLogicException extends AppException {
  BusinessLogicException(String message) : super(message);
}

/// Exception for validation errors
class ValidationException extends AppException {
  ValidationException(String message) : super(message);
}

/// Exception for network errors
class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

/// Exception for authentication errors
class AuthenticationException extends AppException {
  AuthenticationException(String message) : super(message);
}

/// Exception for authorization errors
class AuthorizationException extends AppException {
  AuthorizationException(String message) : super(message);
}

/// Exception for not found errors
class NotFoundException extends AppException {
  NotFoundException(String message) : super(message);
}
