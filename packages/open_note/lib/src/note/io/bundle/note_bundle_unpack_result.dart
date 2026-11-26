import 'package:flutter/foundation.dart';

/// What `NoteBundleCodec.unpack` did.
@immutable
class NoteBundleUnpackResult {
  /// A result listing the full store keys that were [written] and [skipped].
  const NoteBundleUnpackResult({
    this.written = const <String>[],
    this.skipped = const <String>[],
  });

  /// Store keys written, ascending.
  final List<String> written;

  /// Store keys left untouched because they already existed and `overwrite` was
  /// false, ascending.
  final List<String> skipped;

  @override
  bool operator ==(Object other) =>
      other is NoteBundleUnpackResult &&
      listEquals(other.written, written) &&
      listEquals(other.skipped, skipped);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(written), Object.hashAll(skipped));

  @override
  String toString() =>
      'NoteBundleUnpackResult(written: $written, skipped: $skipped)';
}
