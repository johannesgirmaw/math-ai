/// Expected failure from a repository call.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// The session is missing or rejected.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sign in required.']);
}

/// The request was rejected as invalid.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// The device could not reach the API.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Check your connection.']);
}

/// An HTTP status the sync worker can classify.
final class HttpFailure extends Failure {
  const HttpFailure({
    required this.statusCode,
    String message = 'Request failed.',
  }) : super(message);

  final int statusCode;
}

/// An unexpected failure.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}
