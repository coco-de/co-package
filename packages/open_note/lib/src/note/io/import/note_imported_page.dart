import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// One page produced by an importer: its size in points and its picture, to be
/// used as the page background.
///
/// JSON schema: `{"size": {"w", "h"}, "backgroundSource"?: String,
/// "backgroundPng"?: base64 String, "pdf"?: NotePdfOrigin}`.
@immutable
class NoteImportedPage {
  /// A page of [size] with a picture given as [backgroundPng] bytes and/or an
  /// opaque [backgroundSource] string.
  const NoteImportedPage({
    required this.size,
    this.backgroundPng,
    this.backgroundSource,
    this.pdf,
  });

  /// Lenient decoding: a bad size becomes A4, bad base64 is dropped.
  factory NoteImportedPage.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? <String, Object?>{};
    final encoded = NoteJson.stringOrNull(json, 'backgroundPng');

    return NoteImportedPage(
      size: NotePageSize.fromJson(json['size']),
      backgroundPng: encoded == null ? null : _decodePng(encoded),
      backgroundSource: NoteJson.stringOrNull(json, 'backgroundSource'),
      pdf: NotePdfOrigin.fromJson(json['pdf']),
    );
  }

  /// Page size in points.
  final NotePageSize size;

  /// The page picture as PNG bytes, if the importer produced one. Hosts
  /// usually save it in their store and set [backgroundSource]. Do not mutate.
  final Uint8List? backgroundPng;

  /// A path, URL or store key of the page picture, if already stored.
  final String? backgroundSource;

  /// The PDF page pictured, so its text can still be selected.
  final NotePdfOrigin? pdf;

  /// A copy with the given fields replaced.
  NoteImportedPage copyWith({
    NotePageSize? size,
    Uint8List? backgroundPng,
    String? backgroundSource,
    NotePdfOrigin? pdf,
  }) => NoteImportedPage(
    size: size ?? this.size,
    backgroundPng: backgroundPng ?? this.backgroundPng,
    backgroundSource: backgroundSource ?? this.backgroundSource,
    pdf: pdf ?? this.pdf,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'size': size.toJson(),
    if (backgroundSource != null) 'backgroundSource': backgroundSource,
    if (backgroundPng != null) 'backgroundPng': base64Encode(backgroundPng!),
    if (pdf != null) 'pdf': pdf!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is NoteImportedPage &&
      other.size == size &&
      other.backgroundSource == backgroundSource &&
      other.pdf == pdf &&
      listEquals(other.backgroundPng, backgroundPng);

  @override
  int get hashCode =>
      Object.hash(size, backgroundSource, backgroundPng?.length, pdf);

  static Uint8List? _decodePng(String encoded) {
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }
}
