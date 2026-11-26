import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/utilities/internal/note_utility_json.dart';

/// One lap of a stopwatch.
///
/// JSON: `{"number": int >= 1, "totalMs": int >= 0, "splitMs": int >= 0}`;
/// bad values read as 1 and 0.
@immutable
class NoteStopwatchLap {
  /// Creates a lap; [number] is 1-based.
  const NoteStopwatchLap({
    required this.number,
    required this.total,
    required this.split,
  }) : assert(number >= 1, 'laps are numbered from 1');

  /// Reads [value] leniently (see the class comment).
  factory NoteStopwatchLap.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteStopwatchLap(
      number: math.max(NoteJson.integer(json, 'number', 1), 1),
      total: NoteUtilityJson.duration(json, 'totalMs'),
      split: NoteUtilityJson.duration(json, 'splitMs'),
    );
  }

  /// 1-based position in the run.
  final int number;

  /// Stopwatch time when the lap was recorded.
  final Duration total;

  /// Time since the previous lap (since the start for lap 1).
  final Duration split;

  /// A copy with the given values replaced.
  NoteStopwatchLap copyWith({int? number, Duration? total, Duration? split}) =>
      NoteStopwatchLap(
        number: number ?? this.number,
        total: total ?? this.total,
        split: split ?? this.split,
      );

  /// The JSON form described in the class comment.
  JsonMap toJson() => {
    'number': number,
    'totalMs': total.inMilliseconds,
    'splitMs': split.inMilliseconds,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteStopwatchLap &&
      other.number == number &&
      other.total == total &&
      other.split == split;

  @override
  int get hashCode => Object.hash(number, total, split);

  @override
  String toString() => 'NoteStopwatchLap($number, $split of $total)';
}
