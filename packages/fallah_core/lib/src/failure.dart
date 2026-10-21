/// One validation problem, optionally tied to a form field.
final class FieldError {
  const FieldError({this.field, required this.message, this.code});

  final String? field;
  final String message;
  final String? code;

  @override
  String toString() => field == null ? message : '$field: $message';
}

/// Standard, UI-friendly error model. Infrastructure layers map their
/// exceptions into one of these so presentation code never depends on Dio,
/// HTTP codes, etc.
sealed class Failure {
  const Failure(this.message, {this.code, this.cause});

  /// Message already safe to show (server-translated or local).
  final String message;

  /// Stable backend error code, useful for app-side localization.
  final String? code;

  /// Original exception, kept for logging only.
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';
}

/// No connectivity, DNS failure, timeout, ...
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.cause});
}

/// HTTP 401 - missing/expired session. The app should route to login.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized', Object? cause])
      : super(cause: cause);
}

/// HTTP 403.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Forbidden', Object? cause])
      : super(cause: cause);
}

/// HTTP 404.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found', Object? cause])
      : super(cause: cause);
}

/// HTTP 400 / 422, or local validation.
final class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    this.errors = const [],
    super.code,
    super.cause,
  });

  final List<FieldError> errors;

  /// Messages for one field, handy for form fields.
  List<String> errorsFor(String field) => [
        for (final e in errors)
          if (e.field == field) e.message,
      ];
}

/// HTTP 409.
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.code, super.cause});
}

/// HTTP 429.
final class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message, {this.retryAfter, super.cause});

  final Duration? retryAfter;
}

/// Other non-2xx responses (5xx, ...).
final class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    required this.statusCode,
    super.code,
    super.cause,
  });

  final int statusCode;
}

/// Anything unexpected.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error', Object? cause])
      : super(cause: cause);
}
