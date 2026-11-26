import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// Portrait or landscape. A square page counts as portrait.
enum NotePageOrientation { portrait, landscape }

/// Logical page size in PDF points (1 unit = 1/72 inch).
///
/// The unit is chosen so a page maps 1:1 onto a PDF page on export. Stroke
/// coordinates of a page are always expressed in this space.
@immutable
class NotePageSize {
  const NotePageSize(this.width, this.height)
    : assert(width > 0, 'width must be positive'),
      assert(height > 0, 'height must be positive');

  /// Decodes `{w, h}`; a malformed value falls back to [a4].
  factory NotePageSize.fromJson(Object? value) {
    final map = NoteJson.asMap(value);
    if (map == null) return a4;
    final width = NoteJson.number(map, 'w');
    final height = NoteJson.number(map, 'h');
    if (width <= 0 || height <= 0) return a4;

    return NotePageSize(width, height);
  }

  /// A4 portrait.
  static const NotePageSize a4 = NotePageSize(595, 842);

  /// A5 portrait.
  static const NotePageSize a5 = NotePageSize(420, 595);

  /// US Letter portrait.
  static const NotePageSize letter = NotePageSize(612, 792);

  /// 600 x 600 square.
  static const NotePageSize square = NotePageSize(600, 600);

  final double width;
  final double height;

  NotePageOrientation get orientation => width > height
      ? NotePageOrientation.landscape
      : NotePageOrientation.portrait;

  /// The same page turned 90 degrees (width and height swapped).
  NotePageSize get rotated => NotePageSize(height, width);

  /// This size, turned if needed to match [orientation].
  NotePageSize withOrientation(NotePageOrientation orientation) =>
      this.orientation == orientation ? this : rotated;

  double get aspectRatio => width / height;

  Size toSize() => Size(width, height);

  Rect toRect() => Rect.fromLTWH(0, 0, width, height);

  NotePageSize copyWith({double? width, double? height}) =>
      NotePageSize(width ?? this.width, height ?? this.height);

  JsonMap toJson() => {'w': width, 'h': height};

  @override
  bool operator ==(Object other) =>
      other is NotePageSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'NotePageSize($width x $height)';
}
