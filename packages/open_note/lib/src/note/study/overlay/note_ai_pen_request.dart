import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_kind.dart';

/// One job for the AI pen: what to do ([kind]) with which input.
///
/// The input is a picture of the selected region ([imagePng]), recognised or
/// typed [text], or both. [targetLocale] is a BCP-47 tag such as `ko` or
/// `en-US`, mainly for [NoteAiPenKind.translate]. Do not mutate [imagePng]
/// after creating the request.
///
/// JSON: `{"kind": "solve"|"explain"|"translate", "imagePng": base64 string,
/// "text": string, "targetLocale": string}`; absent inputs are left out.
/// [NoteAiPenRequest.fromJson] never throws: an unknown kind becomes `solve`
/// and broken base64 gives no picture.
@immutable
class NoteAiPenRequest {
  /// Creates a request.
  const NoteAiPenRequest({
    required this.kind,
    this.imagePng,
    this.text,
    this.targetLocale,
  });

  /// Reads [toJson] output.
  factory NoteAiPenRequest.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteAiPenRequest(
      kind: NoteJson.enumByName(
        NoteAiPenKind.values,
        json['kind'],
        NoteAiPenKind.solve,
      ),
      imagePng: _decodeImage(NoteJson.stringOrNull(json, 'imagePng')),
      text: NoteJson.stringOrNull(json, 'text'),
      targetLocale: NoteJson.stringOrNull(json, 'targetLocale'),
    );
  }

  /// What to do.
  final NoteAiPenKind kind;

  /// PNG bytes of the selected region.
  final Uint8List? imagePng;

  /// The selected or recognised text.
  final String? text;

  /// The language to answer in or translate into.
  final String? targetLocale;

  /// Whether there is a picture or some non-blank text to work on.
  bool get hasInput =>
      (imagePng?.isNotEmpty ?? false) || (text?.trim().isNotEmpty ?? false);

  static Uint8List? _decodeImage(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  /// A copy with the given fields replaced (a field cannot be cleared).
  NoteAiPenRequest copyWith({
    NoteAiPenKind? kind,
    Uint8List? imagePng,
    String? text,
    String? targetLocale,
  }) => NoteAiPenRequest(
    kind: kind ?? this.kind,
    imagePng: imagePng ?? this.imagePng,
    text: text ?? this.text,
    targetLocale: targetLocale ?? this.targetLocale,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() {
    final image = imagePng;

    return {
      'kind': kind.name,
      'imagePng': ?(image == null ? null : base64Encode(image)),
      'text': ?text,
      'targetLocale': ?targetLocale,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is NoteAiPenRequest &&
      other.kind == kind &&
      listEquals(other.imagePng, imagePng) &&
      other.text == text &&
      other.targetLocale == targetLocale;

  @override
  int get hashCode => Object.hash(kind, imagePng?.length, text, targetLocale);

  @override
  String toString() =>
      'NoteAiPenRequest(${kind.name}, image: ${imagePng?.length ?? 0} bytes, '
      'text: $text, locale: $targetLocale)';
}
