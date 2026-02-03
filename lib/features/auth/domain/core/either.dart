/// Either type for functional error handling - Domain Layer
///
/// Represents a value that is either a failure (Left) or success (Right).
/// Used throughout the auth feature for explicit error handling.
///
/// Convention:
/// - Left = Failure
/// - Right = Success
///
/// No Flutter dependencies.
sealed class Either<L, R> {
  const Either();

  /// Transform the Either by applying one of two functions
  T fold<T>(
    T Function(L left) onLeft,
    T Function(R right) onRight,
  );

  /// Check if this is a Left (failure)
  bool get isLeft;

  /// Check if this is a Right (success)
  bool get isRight;

  /// Get the left value if present
  L? get leftOrNull;

  /// Get the right value if present
  R? get rightOrNull;

  /// Map the right value
  Either<L, T> map<T>(T Function(R right) fn);

  /// FlatMap the right value
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) fn);
}

/// Left side of Either - represents failure
class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);

  @override
  T fold<T>(
    T Function(L left) onLeft,
    T Function(R right) onRight,
  ) =>
      onLeft(value);

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  L? get leftOrNull => value;

  @override
  R? get rightOrNull => null;

  @override
  Either<L, T> map<T>(T Function(R right) fn) => Left<L, T>(value);

  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) fn) => Left<L, T>(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Left && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Left($value)';
}

/// Right side of Either - represents success
class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);

  @override
  T fold<T>(
    T Function(L left) onLeft,
    T Function(R right) onRight,
  ) =>
      onRight(value);

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  L? get leftOrNull => null;

  @override
  R? get rightOrNull => value;

  @override
  Either<L, T> map<T>(T Function(R right) fn) => Right<L, T>(fn(value));

  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) fn) => fn(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Right && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Right($value)';
}
