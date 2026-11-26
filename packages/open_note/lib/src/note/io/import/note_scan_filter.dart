import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// What a scan filter does.
enum NoteScanFilterKind {
  /// The picture as captured.
  none,

  /// Shades of grey.
  grayscale,

  /// Pure black and white, split at a threshold.
  blackWhite,
}

/// A pure pixel filter applied to scanned pages.
///
/// Brightness is `(299 R + 587 G + 114 B) / 1000` (0–255). Alpha is kept.
///
/// JSON schema: `{"kind": "none"|"grayscale"|"blackWhite", "threshold": 0–255}`.
@immutable
class NoteScanFilter {
  const NoteScanFilter._(this.kind, this.threshold);

  /// Black and white: a pixel at least [threshold] (clamped to 0–255) bright
  /// turns white, any darker pixel black.
  factory NoteScanFilter.blackWhite([int threshold = defaultThreshold]) =>
      NoteScanFilter._(NoteScanFilterKind.blackWhite, threshold.clamp(0, 255));

  /// Lenient decoding: unknown kinds become [none], thresholds are clamped.
  factory NoteScanFilter.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? <String, Object?>{};

    return switch (NoteJson.enumByName(
      NoteScanFilterKind.values,
      json['kind'],
      NoteScanFilterKind.none,
    )) {
      NoteScanFilterKind.none => none,
      NoteScanFilterKind.grayscale => grayscale,
      NoteScanFilterKind.blackWhite => NoteScanFilter.blackWhite(
        NoteJson.integer(json, 'threshold', defaultThreshold),
      ),
    };
  }

  /// Leaves the picture alone.
  static const NoteScanFilter none = NoteScanFilter._(
    NoteScanFilterKind.none,
    defaultThreshold,
  );

  /// Converts to grey.
  static const NoteScanFilter grayscale = NoteScanFilter._(
    NoteScanFilterKind.grayscale,
    defaultThreshold,
  );

  /// The default black/white split.
  static const int defaultThreshold = 128;

  /// What the filter does.
  final NoteScanFilterKind kind;

  /// The black/white split, used by [NoteScanFilterKind.blackWhite] only.
  final int threshold;

  /// Whether [apply] would change nothing.
  bool get isNone => kind == NoteScanFilterKind.none;

  /// A filtered copy of straight-alpha [rgba] pixels (the input is not
  /// modified). Throws [ArgumentError] unless the length is a multiple of 4.
  Uint8List apply(Uint8List rgba) {
    if (rgba.length % 4 != 0) {
      throw ArgumentError.value(rgba.length, 'rgba', 'is not RGBA data');
    }
    final result = Uint8List.fromList(rgba);
    if (isNone) return result;
    final isBinary = kind == NoteScanFilterKind.blackWhite;
    for (var i = 0; i < result.length; i += 4) {
      var value =
          (299 * result[i] + 587 * result[i + 1] + 114 * result[i + 2]) ~/ 1000;
      if (isBinary) value = value >= threshold ? 255 : 0;
      result[i] = value;
      result[i + 1] = value;
      result[i + 2] = value;
    }

    return result;
  }

  /// The persisted form (see the class comment).
  JsonMap toJson() => {'kind': kind.name, 'threshold': threshold};

  @override
  bool operator ==(Object other) =>
      other is NoteScanFilter &&
      other.kind == kind &&
      (kind != NoteScanFilterKind.blackWhite || other.threshold == threshold);

  @override
  int get hashCode => Object.hash(
    kind,
    kind == NoteScanFilterKind.blackWhite ? threshold : null,
  );

  @override
  String toString() => kind == NoteScanFilterKind.blackWhite
      ? 'NoteScanFilter.blackWhite($threshold)'
      : 'NoteScanFilter.${kind.name}';
}
