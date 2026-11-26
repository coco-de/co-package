/// A bundle that cannot be read: not a bundle at all, a newer version, a
/// malformed entry or an unsafe key.
class NoteBundleException implements Exception {
  /// An error described by [message], optionally caused by [cause].
  const NoteBundleException(this.message, {this.cause});

  /// What is wrong with the bundle.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  @override
  String toString() => 'NoteBundleException: $message';
}
