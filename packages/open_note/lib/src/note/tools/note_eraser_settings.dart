import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/internal/note_tools_numbers.dart';
import 'package:open_note/src/note/tools/note_eraser_mode.dart';

/// Eraser settings.
///
/// Values read from this object are inside their ranges: [size] is clamped into
/// [minSize]–[maxSize] and [pressureThreshold] into
/// [minPressureThreshold]–[maxPressureThreshold]; NaN or infinity reads as the
/// default.
///
/// JSON: `{"mode": "stroke" | "pixel", "size": number,
/// "pressureSwitchEnabled": bool, "pressureThreshold": number}`.
@immutable
class NoteEraserSettings {
  /// Smallest [size].
  static const double minSize = 2;

  /// Largest [size].
  static const double maxSize = 80;

  /// Default [size].
  static const double defaultSize = 12;

  /// Smallest [pressureThreshold].
  static const double minPressureThreshold = 0.1;

  /// Largest [pressureThreshold].
  static const double maxPressureThreshold = 1;

  /// Default [pressureThreshold].
  static const double defaultPressureThreshold = 0.8;

  /// Stroke or pixel eraser. Default stroke.
  final NoteEraserMode mode;

  /// Whether pressing hard with the pen erases. Default off.
  final bool pressureSwitchEnabled;

  final double _size;

  final double _pressureThreshold;

  /// Creates settings; see the members for ranges and defaults.
  const NoteEraserSettings({
    this.mode = NoteEraserMode.stroke,
    double size = defaultSize,
    this.pressureSwitchEnabled = false,
    double pressureThreshold = defaultPressureThreshold,
  }) : _size = size,
       _pressureThreshold = pressureThreshold;

  /// Reads the JSON form; never throws.
  factory NoteEraserSettings.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};

    return NoteEraserSettings(
      mode: NoteJson.enumByName(
        NoteEraserMode.values,
        map['mode'],
        NoteEraserMode.stroke,
      ),
      size: NoteJson.number(map, 'size', defaultSize),
      pressureSwitchEnabled: NoteJson.boolean(map, 'pressureSwitchEnabled'),
      pressureThreshold: NoteJson.number(
        map,
        'pressureThreshold',
        defaultPressureThreshold,
      ),
    );
  }

  /// Eraser diameter in page units. Default 12.
  double get size =>
      noteClampOr(_size, min: minSize, max: maxSize, fallback: defaultSize);

  /// Normalised pen pressure (0–1) that switches to erasing. Default 0.8.
  double get pressureThreshold => noteClampOr(
    _pressureThreshold,
    min: minPressureThreshold,
    max: maxPressureThreshold,
    fallback: defaultPressureThreshold,
  );

  @override
  int get hashCode =>
      Object.hash(mode, size, pressureSwitchEnabled, pressureThreshold);

  /// Whether a pen touch with [pressure] erases: the switch is on and the
  /// pressure reaches [pressureThreshold].
  bool switchesAt(double pressure) =>
      pressureSwitchEnabled && pressure >= pressureThreshold;

  /// A copy with the given values replaced.
  NoteEraserSettings copyWith({
    NoteEraserMode? mode,
    double? size,
    bool? pressureSwitchEnabled,
    double? pressureThreshold,
  }) => NoteEraserSettings(
    mode: mode ?? this.mode,
    size: size ?? this.size,
    pressureSwitchEnabled: pressureSwitchEnabled ?? this.pressureSwitchEnabled,
    pressureThreshold: pressureThreshold ?? this.pressureThreshold,
  );

  /// The JSON form described on the class.
  JsonMap toJson() => {
    'mode': mode.name,
    'size': size,
    'pressureSwitchEnabled': pressureSwitchEnabled,
    'pressureThreshold': pressureThreshold,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteEraserSettings &&
      other.mode == mode &&
      other.size == size &&
      other.pressureSwitchEnabled == pressureSwitchEnabled &&
      other.pressureThreshold == pressureThreshold;

  @override
  String toString() => 'NoteEraserSettings(${toJson()})';
}
