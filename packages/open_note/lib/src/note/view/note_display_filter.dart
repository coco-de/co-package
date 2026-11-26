import 'package:flutter/widgets.dart';

/// Reading comfort filter applied over a whole page view.
enum NoteDisplayMode {
  /// Colours unchanged.
  normal,

  /// Dark mode: lightness inverted, hues kept.
  night,

  /// A warm tint that takes out some blue light.
  eyeProtect,
}

/// Applies a [NoteDisplayMode] to [child] with a [ColorFiltered].
///
/// [NoteDisplayMode.night] inverts the luminance (Rec. 709 weights) and keeps
/// the hue and chroma: white paper turns black, black ink turns white, a red
/// pen stays reddish. [NoteDisplayMode.eyeProtect] scales green and blue down
/// by up to 12 % and 40 % at full [strength]. The child keeps its state when
/// the mode changes.
class NoteDisplayFilter extends StatefulWidget {
  /// Filters [child] according to [mode].
  const NoteDisplayFilter({
    required this.child,
    super.key,
    this.mode = NoteDisplayMode.normal,
    this.strength = defaultStrength,
  });

  /// [strength] when none is given.
  static const double defaultStrength = 0.5;

  static const double _greenCut = 0.12;
  static const double _blueCut = 0.4;
  static const double _red = 0.2126;
  static const double _green = 0.7152;
  static const double _blue = 0.0722;

  /// The view to filter.
  final Widget child;

  /// The filter to apply.
  final NoteDisplayMode mode;

  /// Warmth of [NoteDisplayMode.eyeProtect], 0 (none) to 1, clamped. The other
  /// modes ignore it.
  final double strength;

  /// The 5×4 colour matrix (row-major, offsets in 0–255) of [mode], or `null`
  /// when nothing needs filtering (normal, or eye protection at strength 0).
  static List<double>? matrixFor(
    NoteDisplayMode mode, {
    double strength = defaultStrength,
  }) {
    switch (mode) {
      case NoteDisplayMode.normal:
        return null;
      case NoteDisplayMode.night:
        return const [
          1 - 2 * _red, -2 * _green, -2 * _blue, 0, 255, //
          -2 * _red, 1 - 2 * _green, -2 * _blue, 0, 255, //
          -2 * _red, -2 * _green, 1 - 2 * _blue, 0, 255, //
          0, 0, 0, 1, 0,
        ];
      case NoteDisplayMode.eyeProtect:
        final amount = strength.isFinite
            ? strength.clamp(0.0, 1.0)
            : defaultStrength;
        if (amount == 0) return null;

        return [
          1, 0, 0, 0, 0, //
          0, 1 - _greenCut * amount, 0, 0, 0, //
          0, 0, 1 - _blueCut * amount, 0, 0, //
          0, 0, 0, 1, 0,
        ];
    }
  }

  /// The [ColorFilter] of [mode], or `null` when nothing needs filtering.
  static ColorFilter? colorFilterFor(
    NoteDisplayMode mode, {
    double strength = defaultStrength,
  }) {
    final matrix = matrixFor(mode, strength: strength);

    return matrix == null ? null : ColorFilter.matrix(matrix);
  }

  @override
  State<NoteDisplayFilter> createState() => _NoteDisplayFilterState();
}

class _NoteDisplayFilterState extends State<NoteDisplayFilter> {
  /// Keeps the child's state when the filter is added or removed.
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final content = KeyedSubtree(key: _contentKey, child: widget.child);
    final filter = NoteDisplayFilter.colorFilterFor(
      widget.mode,
      strength: widget.strength,
    );

    return filter == null
        ? content
        : ColorFiltered(colorFilter: filter, child: content);
  }
}
