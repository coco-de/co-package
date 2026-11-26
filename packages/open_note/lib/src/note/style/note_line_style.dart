import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/style/note_line_style_kind.dart';
import 'package:open_note/src/note/style/note_style_values.dart';

/// An immutable description of how a stroke is decorated.
///
/// Every length is a **multiple of the stroke width**, so a style keeps its
/// look when the pen gets thicker.
///
/// | field        | range     | default          | used by        |
/// |--------------|-----------|------------------|----------------|
/// | `dashLength` | 0.2 – 10  | 1.4 (dotted 0.1) | dashed, dotted |
/// | `gap`        | 0.2 – 10  | 1.6              | dashed, dotted |
/// | `amplitude`  | 0.2 – 6   | 1.5              | wavy, zigzag   |
/// | `wavelength` | 1 – 20    | 8                | wavy, zigzag   |
/// | `doubleGap`  | 0.3 – 6   | 1.2              | double         |
///
/// A dotted line is a very short dash drawn with round caps, so the `dotted`
/// kind alone accepts a `dashLength` down to 0.1 (its default).
///
/// ## Encoded form (stored in a protobuf string field)
///
/// ```text
/// style  = kind [ ":" dashLength [ ":" gap [ ":" amplitude
///               [ ":" wavelength [ ":" doubleGap ] ] ] ] ]
/// kind   = "solid" / "dashed" / "dotted" / "wavy" / "zigzag" / "double"
/// number = a decimal number with "." as separator, e.g. "2" or "0.25"
/// ```
///
/// Examples: `solid`, `dashed:2:3`, `wavy:1.4:1.6:2:10`, `double:1.4:1.6:1.5:8:2`.
/// [encode] writes parameters only up to the last one that differs from the
/// kind's default. [NoteLineStyle.decode] fills omitted parameters with the
/// defaults, clamps out-of-range numbers, ignores parameters after the fifth
/// (so a newer version may append some) and returns [solid] for an unknown
/// kind or a parameter that is not a finite number. It never throws.
///
/// JSON ([toJson]): `{kind, dashLength, gap, amplitude, wavelength,
/// doubleGap}`; [NoteLineStyle.fromJson] also accepts the encoded string.
@immutable
class NoteLineStyle {
  /// The plain continuous line, and the result for every missing or unreadable
  /// style.
  static const NoteLineStyle solid = NoteLineStyle._(
    kind: NoteLineStyleKind.solid,
    dashLength: dashedDashLength,
    gap: defaultGap,
    amplitude: defaultAmplitude,
    wavelength: defaultWavelength,
    doubleGap: defaultDoubleGap,
  );

  /// Default `dashLength` of every kind except `dotted`.
  static const double dashedDashLength = 1.4;

  /// Default (and smallest) `dashLength` of the `dotted` kind.
  static const double dottedDashLength = 0.1;

  /// Default `gap`.
  static const double defaultGap = 1.6;

  /// Default `amplitude`.
  static const double defaultAmplitude = 1.5;

  /// Default `wavelength`.
  static const double defaultWavelength = 8;

  /// Default `doubleGap`.
  static const double defaultDoubleGap = 1.2;

  /// Smallest `dashLength` (except for `dotted`) and `gap`.
  static const double minDash = 0.2;

  /// Largest `dashLength` and `gap`.
  static const double maxDash = 10;

  /// Smallest `amplitude`.
  static const double minAmplitude = 0.2;

  /// Largest `amplitude`.
  static const double maxAmplitude = 6;

  /// Smallest `wavelength`.
  static const double minWavelength = 1;

  /// Largest `wavelength`.
  static const double maxWavelength = 20;

  /// Smallest `doubleGap`.
  static const double minDoubleGap = 0.3;

  /// Largest `doubleGap`.
  static const double maxDoubleGap = 6;

  /// Which decoration is drawn.
  final NoteLineStyleKind kind;

  /// Length of one dash, in stroke widths (`dashed` and `dotted`).
  final double dashLength;

  /// Space between two dashes or dots, in stroke widths. With round dot caps
  /// the visible space is smaller by about one stroke width.
  final double gap;

  /// Distance from the base line to a wave peak, in stroke widths.
  final double amplitude;

  /// Length of one full wave along the base line, in stroke widths. Renderers
  /// stretch it slightly so a line ends exactly on its end point.
  final double wavelength;

  /// Clear space between the two lines of a `double` style, in stroke widths.
  final double doubleGap;

  const NoteLineStyle._({
    required this.kind,
    required this.dashLength,
    required this.gap,
    required this.amplitude,
    required this.wavelength,
    required this.doubleGap,
  });

  /// Creates a style. Omitted or non-finite parameters take the kind's
  /// default and out-of-range ones are clamped.
  NoteLineStyle({
    this.kind = NoteLineStyleKind.solid,
    double? dashLength,
    double? gap,
    double? amplitude,
    double? wavelength,
    double? doubleGap,
  }) : dashLength = NoteStyleValues.clamped(
         dashLength,
         defaultDashLength(kind),
         _minDashLength(kind),
         maxDash,
       ),
       gap = NoteStyleValues.clamped(gap, defaultGap, minDash, maxDash),
       amplitude = NoteStyleValues.clamped(
         amplitude,
         defaultAmplitude,
         minAmplitude,
         maxAmplitude,
       ),
       wavelength = NoteStyleValues.clamped(
         wavelength,
         defaultWavelength,
         minWavelength,
         maxWavelength,
       ),
       doubleGap = NoteStyleValues.clamped(
         doubleGap,
         defaultDoubleGap,
         minDoubleGap,
         maxDoubleGap,
       );

  /// Reads the encoded form (see the class documentation); never throws.
  factory NoteLineStyle.decode(String? source) {
    if (source == null || source.isEmpty) return solid;
    final tokens = source.split(':');
    final kind = NoteLineStyleKind.values.asNameMap()[tokens.first];
    if (kind == null) return solid;
    final numbers = <double>[];
    for (final token in tokens.skip(1).take(_parameterCount)) {
      final value = double.tryParse(token);
      if (value == null || !value.isFinite) return solid;
      numbers.add(value);
    }
    double? at(int index) => index < numbers.length ? numbers[index] : null;

    return NoteLineStyle(
      kind: kind,
      dashLength: at(0),
      gap: at(1),
      amplitude: at(2),
      wavelength: at(3),
      doubleGap: at(4),
    );
  }

  /// Reads the [toJson] map or the encoded string; anything else is [solid].
  /// Unknown kind names read as `solid`.
  factory NoteLineStyle.fromJson(Object? value) {
    if (value is String) return NoteLineStyle.decode(value);
    final json = NoteJson.asMap(value);
    if (json == null) return solid;
    double? read(String key) => _numberOrNull(json[key]);

    return NoteLineStyle(
      kind: NoteJson.enumByName(
        NoteLineStyleKind.values,
        json['kind'],
        NoteLineStyleKind.solid,
      ),
      dashLength: read('dashLength'),
      gap: read('gap'),
      amplitude: read('amplitude'),
      wavelength: read('wavelength'),
      doubleGap: read('doubleGap'),
    );
  }

  /// The style of [kind] with every parameter at its default.
  static NoteLineStyle of(NoteLineStyleKind kind) => NoteLineStyle(kind: kind);

  /// The default `dashLength` of [kind].
  static double defaultDashLength(NoteLineStyleKind kind) =>
      kind == NoteLineStyleKind.dotted ? dottedDashLength : dashedDashLength;

  static const int _parameterCount = 5;

  static double _minDashLength(NoteLineStyleKind kind) =>
      kind == NoteLineStyleKind.dotted ? dottedDashLength : minDash;

  static double? _numberOrNull(Object? value) =>
      value is num ? value.toDouble() : null;

  /// The compact one-string form; `NoteLineStyle.decode(encode())` equals
  /// `this`.
  String encode() {
    final values = [dashLength, gap, amplitude, wavelength, doubleGap];
    final defaults = [
      defaultDashLength(kind),
      defaultGap,
      defaultAmplitude,
      defaultWavelength,
      defaultDoubleGap,
    ];
    var count = values.length;
    while (count > 0 && values[count - 1] == defaults[count - 1]) {
      count--;
    }

    return [
      kind.name,
      for (final value in values.take(count))
        NoteStyleValues.formatNumber(value),
    ].join(':');
  }

  /// A copy with some fields replaced. When [kind] changes and `dashLength`
  /// still has the old kind's default (and none is given), it moves to the new
  /// kind's default, so `dashed` becomes dots when switched to `dotted`.
  NoteLineStyle copyWith({
    NoteLineStyleKind? kind,
    double? dashLength,
    double? gap,
    double? amplitude,
    double? wavelength,
    double? doubleGap,
  }) {
    final nextKind = kind ?? this.kind;
    final followsDefault = this.dashLength == defaultDashLength(this.kind);

    return NoteLineStyle(
      kind: nextKind,
      dashLength:
          dashLength ??
          (followsDefault ? defaultDashLength(nextKind) : this.dashLength),
      gap: gap ?? this.gap,
      amplitude: amplitude ?? this.amplitude,
      wavelength: wavelength ?? this.wavelength,
      doubleGap: doubleGap ?? this.doubleGap,
    );
  }

  /// The JSON map form.
  JsonMap toJson() => {
    'kind': kind.name,
    'dashLength': dashLength,
    'gap': gap,
    'amplitude': amplitude,
    'wavelength': wavelength,
    'doubleGap': doubleGap,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteLineStyle &&
      other.kind == kind &&
      other.dashLength == dashLength &&
      other.gap == gap &&
      other.amplitude == amplitude &&
      other.wavelength == wavelength &&
      other.doubleGap == doubleGap;

  @override
  int get hashCode =>
      Object.hash(kind, dashLength, gap, amplitude, wavelength, doubleGap);

  @override
  String toString() => 'NoteLineStyle(${encode()})';
}
