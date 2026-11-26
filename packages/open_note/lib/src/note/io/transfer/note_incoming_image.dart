import 'package:flutter/foundation.dart';

/// A picture received from another device. Transient, no JSON form.
@immutable
class NoteIncomingImage {
  /// A picture called [name] with the encoded file content [bytes].
  const NoteIncomingImage({required this.name, required this.bytes});

  /// The sender's file name.
  final String name;

  /// The encoded picture. Do not mutate.
  final Uint8List bytes;

  @override
  bool operator ==(Object other) =>
      other is NoteIncomingImage &&
      other.name == name &&
      listEquals(other.bytes, bytes);

  @override
  int get hashCode => Object.hash(name, bytes.length);

  @override
  String toString() => 'NoteIncomingImage($name, ${bytes.length} bytes)';
}
