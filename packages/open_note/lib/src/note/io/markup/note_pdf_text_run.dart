import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// A piece of selectable text on a PDF page, as reported by the host.
///
/// JSON schema: `{"text": String, "rect": {"x", "y", "w", "h"}}`.
@immutable
class NotePdfTextRun {
  /// A run of [text] covering [rect].
  const NotePdfTextRun({required this.text, required this.rect});

  /// Lenient decoding: a malformed rect becomes empty.
  factory NotePdfTextRun.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? <String, Object?>{};

    return NotePdfTextRun(
      text: NoteJson.string(json, 'text'),
      rect: NoteJson.rect(json, 'rect'),
    );
  }

  /// The text.
  final String text;

  /// Its box in page coordinates (points, origin at the top left).
  final Rect rect;

  /// A copy with the given fields replaced.
  NotePdfTextRun copyWith({String? text, Rect? rect}) =>
      NotePdfTextRun(text: text ?? this.text, rect: rect ?? this.rect);

  /// The persisted form (see the class comment).
  JsonMap toJson() => {'text': text, 'rect': NoteJson.rectToJson(rect)};

  @override
  bool operator ==(Object other) =>
      other is NotePdfTextRun && other.text == text && other.rect == rect;

  @override
  int get hashCode => Object.hash(text, rect);

  @override
  String toString() => 'NotePdfTextRun($text, $rect)';
}
