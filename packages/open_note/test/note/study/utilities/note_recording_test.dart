import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

final _time = DateTime.utc(2026, 3, 4, 5, 6, 7);

NoteRecording _recording({int? pageNumber, double playbackSpeed = 1}) =>
    NoteRecording(
      id: 'r1',
      title: 'Lecture',
      source: 'audio/r1.m4a',
      createdAt: _time,
      duration: const Duration(minutes: 3, seconds: 5),
      pageNumber: pageNumber,
      playbackSpeed: playbackSpeed,
    );

void main() {
  group('NoteRecording', () {
    test('round-trips through JSON', () {
      final recording = _recording(pageNumber: 4, playbackSpeed: 1.25);

      expect(recording.toJson(), {
        'id': 'r1',
        'title': 'Lecture',
        'source': 'audio/r1.m4a',
        'createdAt': '2026-03-04T05:06:07.000Z',
        'durationMs': 185000,
        'pageNumber': 4,
        'playbackSpeed': 1.25,
      });
      final restored = NoteRecording.fromJson(recording.toJson());
      expect(restored, recording);
      expect(restored.hashCode, recording.hashCode);
    });

    test('omits an unattached page', () {
      expect(_recording().toJson().containsKey('pageNumber'), isFalse);
      expect(NoteRecording.fromJson(_recording().toJson()).pageNumber, isNull);
    });

    test('keeps a local time local', () {
      final local = _recording().copyWith(createdAt: DateTime(2026, 1, 2, 3));

      expect(NoteRecording.fromJson(local.toJson()), local);
    });

    test('reads malformed values leniently', () {
      for (final bad in [null, 3, 'text', <Object?>[]]) {
        final read = NoteRecording.fromJson(bad);
        expect(read.id, '');
        expect(read.duration, Duration.zero);
        expect(read.playbackSpeed, 1);
        expect(read.createdAt.millisecondsSinceEpoch, 0);
      }
      final read = NoteRecording.fromJson({
        'id': 5,
        'durationMs': -100,
        'createdAt': 'yesterday',
        'pageNumber': 0,
        'playbackSpeed': 'fast',
      });
      expect(read.id, '');
      expect(read.duration, Duration.zero);
      expect(read.pageNumber, isNull);
      expect(read.playbackSpeed, 1);
      expect(read.createdAt.isUtc, isTrue);
    });

    test('clamps speed and huge durations', () {
      expect(
        NoteRecording.fromJson({'playbackSpeed': 9}).playbackSpeed,
        NoteRecording.maxSpeed,
      );
      expect(
        NoteRecording.fromJson({'playbackSpeed': 0}).playbackSpeed,
        NoteRecording.minSpeed,
      );
      final huge = NoteRecording.fromJson({'durationMs': 1e300});
      expect(huge.duration.isNegative, isFalse);
      expect(huge.duration.inHours, 100000);
      expect(NoteRecording.fromJson({'pageNumber': -3}).pageNumber, isNull);
    });

    test('copies, and detaches the page on request', () {
      final attached = _recording(pageNumber: 2);

      expect(attached.copyWith().pageNumber, 2);
      expect(attached.copyWith(pageNumber: 3).pageNumber, 3);
      expect(attached.copyWith(detachFromPage: true).pageNumber, isNull);
      expect(attached.copyWith(title: 'New'), isNot(attached));
    });
  });

  group('FakeNoteAudioRecorder', () {
    test('records a deterministic recording', () async {
      var id = 0;
      final recorder = FakeNoteAudioRecorder(
        idFactory: () => 'rec-${++id}',
        clock: () => _time,
      );
      addTearDown(recorder.dispose);
      final reports = <Duration>[];
      recorder.elapsed.listen(reports.add);

      recorder.advance(const Duration(seconds: 1));
      await recorder.start();
      expect(recorder.isRecording, isTrue);
      recorder
        ..advance(const Duration(seconds: 2))
        ..advance(const Duration(seconds: 3));
      final result = await recorder.stop();

      expect(recorder.isRecording, isFalse);
      expect(reports, [const Duration(seconds: 2), const Duration(seconds: 5)]);
      expect(
        result,
        NoteRecording(
          id: 'rec-1',
          title: 'Recording 1',
          source: 'fake:recording-1',
          createdAt: _time,
          duration: const Duration(seconds: 5),
        ),
      );
    });

    test('rejects stopping or starting twice', () async {
      final recorder = FakeNoteAudioRecorder();
      addTearDown(recorder.dispose);

      await expectLater(recorder.stop(), throwsA(isA<NoteAudioException>()));
      await recorder.start();
      await expectLater(recorder.start(), throwsA(isA<NoteAudioException>()));
    });
  });

  group('FakeNoteAudioPlayer', () {
    late FakeNoteAudioPlayer player;
    late List<Duration> positions;

    setUp(() {
      player = FakeNoteAudioPlayer(
        durations: {'short': const Duration(seconds: 4)},
        failingSources: {'broken'},
      );
      positions = [];
      player.position.listen(positions.add);
    });

    tearDown(() => player.dispose());

    test('starts idle and rejects playing nothing', () async {
      expect(player.state, NoteAudioPlayerState.idle);
      expect(player.duration, Duration.zero);

      await expectLater(player.play(), throwsA(isA<NoteAudioException>()));
      await expectLater(
        player.seek(Duration.zero),
        throwsA(isA<NoteAudioException>()),
      );
    });

    test('advances at its speed only while playing', () async {
      await player.load('short');
      expect(player.state, NoteAudioPlayerState.ready);
      player.advance(const Duration(seconds: 1));
      expect(player.currentPosition, Duration.zero);

      await player.setSpeed(2);
      await player.play();
      player.advance(const Duration(seconds: 1));

      expect(player.currentPosition, const Duration(seconds: 2));
      expect(positions.last, const Duration(seconds: 2));
    });

    test('completes at the end and restarts when played again', () async {
      await player.load('short');
      await player.play();

      player.advance(const Duration(seconds: 10));

      expect(player.state, NoteAudioPlayerState.completed);
      expect(player.currentPosition, const Duration(seconds: 4));
      await player.play();
      expect(player.currentPosition, Duration.zero);
      expect(player.state, NoteAudioPlayerState.playing);
    });

    test('pauses and seeks within the source', () async {
      await player.load('short');
      await player.pause();
      expect(player.state, NoteAudioPlayerState.ready);

      await player.play();
      await player.pause();
      expect(player.state, NoteAudioPlayerState.paused);

      await player.seek(const Duration(seconds: -2));
      expect(player.currentPosition, Duration.zero);
      await player.seek(const Duration(seconds: 99));
      expect(player.currentPosition, const Duration(seconds: 4));
      expect(player.calls, [
        'load short',
        'pause',
        'play',
        'pause',
        'seek -2000',
        'seek 99000',
      ]);
    });

    test('seeking back from the end leaves it paused', () async {
      await player.load('short');
      await player.play();
      player.advance(const Duration(seconds: 10));

      await player.seek(const Duration(seconds: 1));

      expect(player.state, NoteAudioPlayerState.paused);
    });

    test('fails the sources it is told to', () async {
      await expectLater(
        player.load('broken'),
        throwsA(isA<NoteAudioException>()),
      );

      expect(player.state, NoteAudioPlayerState.idle);
      expect(player.source, isNull);
    });

    test('rejects a nonsense speed', () async {
      await expectLater(player.setSpeed(0), throwsA(isA<NoteAudioException>()));
      expect(player.speed, 1);
    });

    test('uses the default length for unknown sources', () async {
      await player.load('other');

      expect(player.duration, const Duration(seconds: 10));
    });
  });
}
