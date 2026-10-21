import 'failure.dart';

/// Either a value ([Success]) or a [Failure] ([Error]). Repositories return
/// this instead of throwing, so callers must handle both cases.
///
/// Note: [Error] intentionally follows the project convention and shadows
/// `dart:core`'s `Error` wherever this library is imported.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.error(Failure failure) = Error<T>;

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Error<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Error<T>(:final failure) => failure,
      };

  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onError,
  ) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Error<T>(:final failure) => onError(failure),
      };

  /// The value, or throws the [Failure]. Use inside AsyncValue-based
  /// providers, where the UI receives the Failure as the error object.
  T getOrThrow() => switch (this) {
        Success<T>(:final value) => value,
        Error<T>(:final failure) => throw failure,
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Result.success(transform(value)),
        Error<T>(:final failure) => Result.error(failure),
      };

  /// Runs [action], converting any thrown error through [onError]
  /// (defaults to [UnknownFailure]).
  static Future<Result<T>> guard<T>(
    Future<T> Function() action, {
    Failure Function(Object error, StackTrace stack)? onError,
  }) async {
    try {
      return Result.success(await action());
    } on Object catch (e, s) {
      return Result.error(onError?.call(e, s) ?? UnknownFailure('$e', e));
    }
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}
