import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

import 'support/utility_test_helpers.dart';

NoteRecording _recording(String id, {int? page, double speed = 1}) =>
    NoteRecording(
      id: id,
      title: 'Title $id',
      source: '$id.m4a',
      createdAt: DateTime.utc(2026),
      duration: const Duration(seconds: 10),
      pageNumber: page,
      playbackSpeed: speed,
    );

const _ten = Duration(seconds: 10);

class _ExplodingPlayer extends FakeNoteAudioPlayer {
  bool explode = true;

  @override
  Future<void> play() async {
    if (explode) throw StateError('plugin bug');

    return super.play();
  }
}

/// Like some plugins, reports a left-over "completed" position while the
/// restart of a finished source is still in progress.
class _StaleCompletionPlayer extends FakeNoteAudioPlayer {
  bool echoCompletion = false;

  @override
  Future<void> seek(Duration position) async {
    // Seeking to the end keeps the "completed" state and reports it.
    if (echoCompletion) await super.seek(duration);
    await super.seek(position);
  }
}

class _SlowPlayPlayer extends FakeNoteAudioPlayer {
  final Completer<void> gate = Completer<void>();

  @override
  Future<void> play() async {
    await gate.future;

    return super.play();
  }
}

/// Lets queued player calls start.
Future<void> _pumpEvents() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeNoteAudioPlayer player;
  late NoteRecordingController controller;

  setUp(() {
    player = FakeNoteAudioPlayer(failingSources: {'broken.m4a'});
    controller = NoteRecordingController(
      player: player,
      recordings: [_recording('a'), _recording('b', page: 2)],
    );
  });

  tearDown(() async {
    controller.dispose();
    await player.dispose();
  });

  group('the list', () {
    test('keeps order and skips unusable entries', () {
      final other = NoteRecordingController(
        player: player,
        recordings: [
          _recording('x'),
          _recording('x'),
          _recording(''),
          _recording('y').copyWith(source: ''),
          _recording('z'),
        ],
      );
      addTearDown(other.dispose);

      expect(other.recordings.map((r) => r.id), ['x', 'z']);
      expect(other.recordings.removeLast, throwsUnsupportedError);
    });

    test('adds unique, usable recordings', () {
      final calls = countNotifications(controller);

      expect(controller.add(_recording('c')), isTrue);
      expect(controller.add(_recording('c')), isFalse);
      expect(controller.add(_recording('')), isFalse);
      expect(controller.recordings, hasLength(3));
      expect(calls, hasLength(1));
    });

    test('renames, ignoring blank and unchanged titles', () {
      final calls = countNotifications(controller);

      expect(controller.rename('a', '  Intro  '), isTrue);
      expect(controller.rename('a', 'Intro'), isFalse);
      expect(controller.rename('a', '   '), isFalse);
      expect(controller.rename('nope', 'X'), isFalse);
      expect(controller.find('a')?.title, 'Intro');
      expect(calls, hasLength(1));
    });

    test('attaches and detaches pages', () {
      expect(controller.forPage(2).map((r) => r.id), ['b']);

      expect(controller.attachToPage('a', 2), isTrue);
      expect(controller.forPage(2).map((r) => r.id), ['a', 'b']);
      expect(controller.attachToPage('a', 2), isFalse);
      expect(controller.attachToPage('a', 0), isFalse);
      expect(controller.attachToPage('a', null), isTrue);
      expect(controller.find('a')?.pageNumber, isNull);
      expect(controller.attachToPage('nope', 1), isFalse);
    });

    test('removes recordings', () {
      expect(controller.remove('a'), isTrue);
      expect(controller.remove('a'), isFalse);
      expect(controller.recordings.map((r) => r.id), ['b']);
    });

    test('round-trips through JSON, skipping bad entries', () {
      final json = controller.toJson();
      final other = NoteRecordingController(player: player);
      addTearDown(other.dispose);

      other.loadJson(json);
      expect(other.recordings, controller.recordings);

      other.loadJson({
        'recordings': [
          'junk',
          {'title': 'no id or source'},
          _recording('c').toJson(),
          _recording('c').toJson(),
        ],
      });
      expect(other.recordings.map((r) => r.id), ['c']);

      other.loadJson('nonsense');
      expect(other.recordings, isEmpty);
    });
  });

  group('playback', () {
    test('loads, sets the speed and plays', () async {
      await controller.play('a');

      expect(player.calls, ['load a.m4a', 'speed 1.0', 'play']);
      expect(controller.currentId, 'a');
      expect(controller.current?.title, 'Title a');
      expect(controller.isPlaying, isTrue);
      expect(controller.error, isNull);
    });

    test('follows the position', () async {
      await controller.play('a');
      final calls = countNotifications(controller);

      player.advance(const Duration(seconds: 3));

      expect(controller.position, const Duration(seconds: 3));
      expect(calls, hasLength(1));
    });

    test('pauses and resumes without loading again', () async {
      await controller.play('a');
      player.advance(const Duration(seconds: 2));

      await controller.pause();
      expect(controller.isPlaying, isFalse);
      expect(controller.currentId, 'a');
      expect(controller.position, const Duration(seconds: 2));

      await controller.play('a');
      expect(controller.isPlaying, isTrue);
      expect(controller.position, const Duration(seconds: 2));
      expect(player.calls.where((call) => call.startsWith('load')), [
        'load a.m4a',
      ]);
    });

    test('toggle alternates between playing and paused', () async {
      await controller.toggle('a');
      expect(controller.isPlaying, isTrue);
      await controller.toggle('a');
      expect(controller.isPlaying, isFalse);
      await controller.toggle('a');
      expect(controller.isPlaying, isTrue);
    });

    test('toggle replays an interrupted recording', () async {
      await controller.play('a');
      await player.pause();
      expect(controller.isPlaying, isFalse);

      await controller.toggle('a');

      expect(controller.isPlaying, isTrue);
    });

    test('switching recordings stops the previous one first', () async {
      await controller.play('a');
      player.calls.clear();

      await controller.play('b');

      expect(player.calls, ['pause', 'load b.m4a', 'speed 1.0', 'play']);
      expect(controller.currentId, 'b');
      expect(controller.position, Duration.zero);
    });

    test('stops at the end and plays again from the start', () async {
      await controller.play('a');

      player.advance(const Duration(seconds: 30));

      expect(controller.isPlaying, isFalse);
      expect(controller.currentId, 'a');
      expect(controller.position, _ten);
      player.calls.clear();
      await controller.toggle('a');
      expect(player.calls, ['seek 0', 'speed 1.0', 'play']);
      expect(controller.position, Duration.zero);
      expect(controller.isPlaying, isTrue);
    });

    test('stop leaves nothing current', () async {
      await controller.play('a');

      await controller.stop();

      expect(controller.currentId, isNull);
      expect(controller.isPlaying, isFalse);
      expect(controller.position, Duration.zero);
      expect(player.state, NoteAudioPlayerState.paused);
      await controller.stop();
    });

    test('playing again after stop starts from the beginning', () async {
      await controller.play('a');
      player.advance(const Duration(seconds: 3));
      await controller.stop();

      await controller.play('a');

      expect(controller.position, Duration.zero);
      expect(player.currentPosition, Duration.zero);
      expect(controller.isPlaying, isTrue);
    });

    test('a stale "completed" while restarting does not stop it', () async {
      final stale = _StaleCompletionPlayer();
      final other = NoteRecordingController(
        player: stale,
        recordings: [_recording('a')],
      );
      addTearDown(() async {
        other.dispose();
        await stale.dispose();
      });
      await other.play('a');
      stale.advance(const Duration(seconds: 30));
      expect(other.isPlaying, isFalse);

      stale.echoCompletion = true;
      await other.play('a');

      expect(other.isPlaying, isTrue);
    });

    test('seeks within the current recording', () async {
      await controller.seek(const Duration(seconds: 1));
      expect(player.calls, isEmpty);
      await controller.play('a');

      await controller.seek(const Duration(seconds: 4));
      expect(player.currentPosition, const Duration(seconds: 4));
      expect(controller.position, const Duration(seconds: 4));

      await controller.seek(const Duration(seconds: 99));
      expect(controller.position, _ten);
      await controller.seek(const Duration(seconds: -5));
      expect(controller.position, Duration.zero);
    });

    test('ignores unknown recordings', () async {
      await controller.play('nope');
      await controller.toggle('nope');
      await controller.cycleSpeed('nope');
      await controller.setSpeed('nope', 2);

      expect(player.calls, isEmpty);
      expect(controller.currentId, isNull);
    });

    test('removing the current recording stops it', () async {
      await controller.play('a');

      expect(controller.remove('a'), isTrue);
      await _pumpEvents();

      expect(controller.currentId, isNull);
      expect(player.state, NoteAudioPlayerState.paused);
    });

    test('a failed load reports the error and can be retried', () async {
      controller.add(_recording('c').copyWith(source: 'broken.m4a'));

      await controller.play('c');

      expect(controller.error, isA<NoteAudioException>());
      expect(controller.failedId, 'c');
      expect(controller.currentId, isNull);
      expect(controller.isPlaying, isFalse);

      await controller.play('a');
      expect(controller.error, isNull);
      expect(controller.failedId, isNull);
      expect(controller.isPlaying, isTrue);
    });

    test('a pause during a slow load keeps it from playing', () async {
      final gate = Completer<void>();
      player.loadGates['a.m4a'] = gate;
      final playing = controller.play('a');
      await _pumpEvents();
      expect(controller.currentId, 'a');
      expect(controller.isPlaying, isFalse);

      final pausing = controller.toggle('a');
      gate.complete();
      await Future.wait([playing, pausing]);

      expect(player.calls, ['load a.m4a']);
      expect(controller.isPlaying, isFalse);
      await controller.play('a');
      expect(controller.isPlaying, isTrue);
      expect(player.calls.where((c) => c.startsWith('load')), hasLength(1));
    });

    test('only the newest of two quick requests plays', () async {
      final gate = Completer<void>();
      player.loadGates['a.m4a'] = gate;
      final first = controller.play('a');
      await _pumpEvents();

      final second = controller.play('b');
      gate.complete();
      await Future.wait([first, second]);

      expect(player.calls, ['load a.m4a', 'load b.m4a', 'speed 1.0', 'play']);
      expect(player.source, 'b.m4a');
      expect(controller.currentId, 'b');
      expect(controller.isPlaying, isTrue);
    });

    test('a request made before the previous one ran drops it', () async {
      final first = controller.play('a');
      final second = controller.play('b');
      await Future.wait([first, second]);

      expect(player.calls, ['load b.m4a', 'speed 1.0', 'play']);
    });

    test('a slow load that fails later does not clobber a newer one', () async {
      controller.add(_recording('c').copyWith(source: 'broken.m4a'));
      final gate = Completer<void>();
      player.loadGates['broken.m4a'] = gate;
      final first = controller.play('c');
      await _pumpEvents();
      final second = controller.play('b');
      gate.complete();
      await Future.wait([first, second]);

      expect(controller.error, isNull);
      expect(controller.currentId, 'b');
      expect(controller.isPlaying, isTrue);
    });

    test('a programming error is reported and playback recovers', () async {
      final exploding = _ExplodingPlayer();
      final other = NoteRecordingController(
        player: exploding,
        recordings: [_recording('a')],
      );
      addTearDown(other.dispose);
      final reported = <Object>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) => reported.add(details.exception);
      addTearDown(() => FlutterError.onError = previous);

      await expectLater(other.play('a'), throwsStateError);
      expect(reported.single, isStateError);

      exploding.explode = false;
      await other.play('a');
      expect(other.isPlaying, isTrue);
    });
  });

  group('speed', () {
    test('offers the presets', () {
      expect(NoteRecordingController.speedPresets, [
        0.5,
        0.75,
        1,
        1.25,
        1.5,
        2,
      ]);
    });

    test('snaps to the nearest preset', () {
      expect(NoteRecordingController.nearestSpeed(1.1), 1);
      expect(NoteRecordingController.nearestSpeed(1.2), 1.25);
      expect(NoteRecordingController.nearestSpeed(9), 2);
      expect(NoteRecordingController.nearestSpeed(0), 0.5);
    });

    test('cycles through the presets, wrapping around', () {
      expect(NoteRecordingController.nextSpeed(0.5), 0.75);
      expect(NoteRecordingController.nextSpeed(1), 1.25);
      expect(NoteRecordingController.nextSpeed(1.1), 1.25);
      expect(NoteRecordingController.nextSpeed(2), 0.5);
    });

    test('applies to the current recording only', () async {
      await controller.setSpeed('b', 1.6);
      expect(controller.find('b')?.playbackSpeed, 1.5);
      expect(player.calls, isEmpty);

      await controller.play('a');
      player.calls.clear();
      await controller.cycleSpeed('a');

      expect(controller.find('a')?.playbackSpeed, 1.25);
      expect(player.calls, ['speed 1.25']);
      expect(player.speed, 1.25);
    });

    test('is used when playing starts', () async {
      await controller.setSpeed('b', 2);

      await controller.play('b');

      expect(player.speed, 2);
      player.advance(const Duration(seconds: 1));
      expect(controller.position, const Duration(seconds: 2));
    });

    test('changed while loading is applied', () async {
      final gate = Completer<void>();
      player.loadGates['a.m4a'] = gate;
      final playing = controller.play('a');
      await _pumpEvents();
      final changing = controller.setSpeed('a', 0.75);
      gate.complete();
      await Future.wait([playing, changing]);

      expect(player.speed, 0.75);
      expect(controller.isPlaying, isTrue);
    });
  });

  group('dispose', () {
    test('pauses and ignores later calls and events', () async {
      final disposed = NoteRecordingController(
        player: player,
        recordings: [_recording('a')],
      );
      await disposed.play('a');

      disposed.dispose();
      await _pumpEvents();

      expect(player.state, NoteAudioPlayerState.paused);
      await player.play();
      player.advance(const Duration(seconds: 1));
      await disposed.play('a');
      await disposed.pause();
      await disposed.stop();
      await disposed.seek(Duration.zero);
      expect(disposed.add(_recording('z')), isFalse);
      expect(disposed.remove('a'), isFalse);
      expect(disposed.rename('a', 'x'), isFalse);
      disposed
        ..loadJson(null)
        ..dispose();
      expect(disposed.recordings, hasLength(1));
    });

    test('silences a play that was still starting', () async {
      final slow = _SlowPlayPlayer();
      final disposed = NoteRecordingController(
        player: slow,
        recordings: [_recording('a')],
      );
      final playing = disposed.play('a');
      await _pumpEvents();

      disposed.dispose();
      slow.gate.complete();
      await playing;

      expect(slow.state, NoteAudioPlayerState.paused);
      await slow.dispose();
    });
  });
}
