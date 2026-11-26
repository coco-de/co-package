import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/utilities/internal/note_utility_json.dart';

/// One audio recording.
///
/// JSON: `{"id": String, "title": String, "source": String,
/// "durationMs": int >= 0, "createdAt": ISO-8601 String, "pageNumber"?: int >= 1,
/// "playbackSpeed": num 0.5–2}`. Reading never fails: a missing or bad value
/// becomes `''`, zero, the Unix epoch, no page or speed 1 (a speed out of range
/// is clamped).
@immutable
class NoteRecording {
  /// Creates a recording. [pageNumber] must be at least 1 and
  /// [playbackSpeed] within [minSpeed]–[maxSpeed].
  const NoteRecording({
    required this.id,
    required this.title,
    required this.source,
    required this.createdAt,
    this.duration = Duration.zero,
    this.pageNumber,
    this.playbackSpeed = 1,
  }) : assert(pageNumber == null || pageNumber >= 1, 'pages are 1-based'),
       assert(playbackSpeed >= minSpeed && playbackSpeed <= maxSpeed);

  /// Reads [value] leniently (see the class comment).
  factory NoteRecording.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};
    final page = NoteJson.integer(json, 'pageNumber');

    return NoteRecording(
      id: NoteJson.string(json, 'id'),
      title: NoteJson.string(json, 'title'),
      source: NoteJson.string(json, 'source'),
      createdAt: NoteUtilityJson.time(json, 'createdAt'),
      duration: NoteUtilityJson.duration(json, 'durationMs'),
      pageNumber: page >= 1 ? page : null,
      playbackSpeed: NoteJson.number(
        json,
        'playbackSpeed',
        1,
      ).clamp(minSpeed, maxSpeed),
    );
  }

  /// Slowest accepted [playbackSpeed].
  static const double minSpeed = 0.5;

  /// Fastest accepted [playbackSpeed].
  static const double maxSpeed = 2;

  /// Unique within a recording list.
  final String id;

  /// Display name.
  final String title;

  /// Where the audio is, as the host defines it (a path, URL or key).
  final String source;

  /// When recording started.
  final DateTime createdAt;

  /// Length of the audio; zero when unknown.
  final Duration duration;

  /// The 1-based page it is attached to, or `null`.
  final int? pageNumber;

  /// Playback rate this recording is played at.
  final double playbackSpeed;

  /// Pass [detachFromPage] to remove the page.
  NoteRecording copyWith({
    String? id,
    String? title,
    String? source,
    DateTime? createdAt,
    Duration? duration,
    int? pageNumber,
    bool detachFromPage = false,
    double? playbackSpeed,
  }) => NoteRecording(
    id: id ?? this.id,
    title: title ?? this.title,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    duration: duration ?? this.duration,
    pageNumber: detachFromPage ? null : pageNumber ?? this.pageNumber,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
  );

  /// The JSON form described in the class comment.
  JsonMap toJson() => {
    'id': id,
    'title': title,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
    'durationMs': duration.inMilliseconds,
    if (pageNumber != null) 'pageNumber': pageNumber,
    'playbackSpeed': playbackSpeed,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteRecording &&
      other.id == id &&
      other.title == title &&
      other.source == source &&
      other.createdAt == createdAt &&
      other.duration == duration &&
      other.pageNumber == pageNumber &&
      other.playbackSpeed == playbackSpeed;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    source,
    createdAt,
    duration,
    pageNumber,
    playbackSpeed,
  );

  @override
  String toString() => 'NoteRecording($id, $title, $duration)';
}
