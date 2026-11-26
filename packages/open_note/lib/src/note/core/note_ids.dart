import 'package:open_note/src/core/utils/stroke_id.dart';

/// Produces a fresh identifier. Models take one in their constructor so tests
/// can pass a deterministic factory.
typedef NoteIdFactory = String Function();

/// Produces "now". Models take one in their constructor so tests can freeze
/// time.
typedef NoteClock = DateTime Function();

/// Default [NoteIdFactory] — an RFC 4122 v4 UUID from `Random.secure`, the same
/// generator the engine uses for [Stroke.id] (never time-based: offline
/// devices must not collide).
String generateNoteId() => generateStrokeId();

/// Default [NoteClock] — the wall clock.
DateTime systemNoteClock() => DateTime.now();
