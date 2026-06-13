import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed exception surfaced from all repository calls.
class FirestoreException implements Exception {
  final String code;
  final String message;
  final bool isRetryable;

  const FirestoreException({
    required this.code,
    required this.message,
    required this.isRetryable,
  });

  @override
  String toString() => 'FirestoreException($code): $message';
}

class FirebaseErrorHandler {
  FirebaseErrorHandler._();

  /// Converts a [FirebaseException] into a user-facing [FirestoreException].
  static FirestoreException handle(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const FirestoreException(
          code: 'permission-denied',
          message: 'You do not have permission to access this data.',
          isRetryable: false,
        );
      case 'not-found':
        return const FirestoreException(
          code: 'not-found',
          message: 'The requested data could not be found.',
          isRetryable: false,
        );
      case 'unavailable':
        return const FirestoreException(
          code: 'unavailable',
          message: 'Service is temporarily unavailable. Please try again.',
          isRetryable: true,
        );
      case 'deadline-exceeded':
        return const FirestoreException(
          code: 'deadline-exceeded',
          message: 'The request timed out. Check your connection and retry.',
          isRetryable: true,
        );
      case 'resource-exhausted':
        return const FirestoreException(
          code: 'resource-exhausted',
          message: 'Too many requests. Please wait a moment and try again.',
          isRetryable: true,
        );
      case 'cancelled':
        return const FirestoreException(
          code: 'cancelled',
          message: 'The operation was cancelled.',
          isRetryable: true,
        );
      case 'failed-precondition':
        return const FirestoreException(
          code: 'failed-precondition',
          message: 'Database index is still being built. Please wait a moment and try again.',
          isRetryable: true,
        );
      default:
        return FirestoreException(
          code: e.code,
          message: 'Something went wrong. Please try again.',
          isRetryable: true,
        );
    }
  }

  /// Wraps any exception into a [FirestoreException].
  static FirestoreException handleUnknown(Object e) {
    if (e is FirebaseException) return handle(e);
    if (e is FirestoreException) return e;
    return FirestoreException(
      code: 'unknown',
      message: 'An unexpected error occurred.',
      isRetryable: true,
    );
  }
}
