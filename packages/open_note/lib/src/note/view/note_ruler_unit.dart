/// Unit shown on the ruler. All ruler geometry stays in page units (PDF points,
/// 1/72 inch); the unit only changes the tick marks and the length label.
///
/// [code] is the persisted and displayed short name: `pt`, `mm`, `cm`, `in`
/// (the Dart name of the inch is [inch] because `in` is a reserved word).
enum NoteRulerUnit {
  /// PDF points: a tick every 10 pt, a numbered one every 50 pt.
  pt(
    code: 'pt',
    pointsPerUnit: 1,
    minorStep: 10,
    minorPerMajor: 5,
    decimals: 0,
  ),

  /// Millimetres: a tick every 1 mm, a numbered one every 10 mm.
  mm(
    code: 'mm',
    pointsPerUnit: 72 / 25.4,
    minorStep: 1,
    minorPerMajor: 10,
    decimals: 0,
  ),

  /// Centimetres: a tick every 1 mm, a numbered one every 1 cm.
  cm(
    code: 'cm',
    pointsPerUnit: 72 / 2.54,
    minorStep: 0.1,
    minorPerMajor: 10,
    decimals: 1,
  ),

  /// Inches: a tick every 1/8 in, a numbered one every inch.
  inch(
    code: 'in',
    pointsPerUnit: 72,
    minorStep: 0.125,
    minorPerMajor: 8,
    decimals: 2,
  );

  const NoteRulerUnit({
    required this.code,
    required this.pointsPerUnit,
    required this.minorStep,
    required this.minorPerMajor,
    required this.decimals,
  });

  /// Persisted and displayed short name.
  final String code;

  /// Page units (points) in one of this unit.
  final double pointsPerUnit;

  /// Distance between two ticks, in this unit.
  final double minorStep;

  /// Every this-many ticks is a numbered (major) one.
  final int minorPerMajor;

  /// Fraction digits used by [format].
  final int decimals;

  /// The unit whose [code] is [code], or [fallback] (unknown codes written by a
  /// newer version must not fail).
  static NoteRulerUnit fromCode(
    Object? code, [
    NoteRulerUnit fallback = NoteRulerUnit.cm,
  ]) {
    for (final unit in values) {
      if (unit.code == code) return unit;
    }

    return fallback;
  }

  /// [points] expressed in this unit.
  double fromPoints(double points) => points / pointsPerUnit;

  /// [value] of this unit expressed in points.
  double toPoints(double value) => value * pointsPerUnit;

  /// [points] expressed in this unit with [decimals] fraction digits
  /// (`12.5`), without the unit name.
  String format(double points) => fromPoints(points).toStringAsFixed(decimals);

  /// The tick marks of a ruler [length] page units long, from 0 at one end up
  /// to [length]. Bad or non-positive lengths give no ticks.
  List<NoteRulerTick> ticks(double length) {
    if (!length.isFinite || length <= 0) return const [];
    final spacing = toPoints(minorStep);
    final count = (length / spacing + 1e-9).floor();

    return [
      for (var i = 0; i <= count; i++)
        NoteRulerTick(
          position: i * spacing,
          label: i % minorPerMajor == 0
              ? _majorLabel(i ~/ minorPerMajor)
              : null,
        ),
    ];
  }

  String _majorLabel(int majorIndex) {
    final value = majorIndex * minorStep * minorPerMajor;

    return value.round().toString();
  }
}

/// One tick mark of a ruler, measured from its start.
class NoteRulerTick {
  /// A tick at [position]; a [label] makes it a major one.
  const NoteRulerTick({required this.position, this.label});

  /// Distance from the start of the ruler, in page units.
  final double position;

  /// Number printed next to a major tick, or `null` for a minor one.
  final String? label;

  /// Whether this is a numbered tick.
  bool get isMajor => label != null;

  @override
  bool operator ==(Object other) =>
      other is NoteRulerTick &&
      other.position == position &&
      other.label == label;

  @override
  int get hashCode => Object.hash(position, label);

  @override
  String toString() => 'NoteRulerTick($position, $label)';
}
