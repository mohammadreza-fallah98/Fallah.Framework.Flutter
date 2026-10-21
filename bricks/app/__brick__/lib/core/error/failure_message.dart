import 'package:fallah_core/fallah_core.dart';

import 'package:{{project_name.snakeCase()}}/l10n/app_localizations.dart';

/// User-facing text for a [Failure]. Local conditions (offline, timeout, ...)
/// come from the app's ARB files; validation and business errors carry the
/// server's message, which is already localized through `X-Language`.
String failureMessage(AppLocalizations l10n, Failure failure) {
  return switch (failure) {
    NetworkFailure(code: 'timeout') => l10n.errorTimeout,
    NetworkFailure() => l10n.errorOffline,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    ForbiddenFailure() => l10n.errorForbidden,
    NotFoundFailure() => l10n.errorNotFound,
    ConflictFailure() => l10n.errorConflict,
    RateLimitFailure() => l10n.errorRateLimit,
    ServerFailure(statusCode: >= 500) => l10n.errorServer,
    ValidationFailure() || ServerFailure() => failure.message,
    UnknownFailure() => l10n.errorUnknown,
  };
}
