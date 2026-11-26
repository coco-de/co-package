import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

import '../../support/note_test_host.dart';
import 'support/utility_test_helpers.dart';

const _playA = ValueKey('recording-play-a');
const _speedA = ValueKey('recording-speed-a');
const _deleteA = ValueKey('recording-delete-a');

NoteRecording _recording(
  String id, {
  int? page,
  String? title,
  String? source,
}) => NoteRecording(
  id: id,
  title: title ?? 'Recording $id',
  source: source ?? '$id.m4a',
  createdAt: DateTime.utc(2026),
  duration: const Duration(seconds: 42),
  pageNumber: page,
);

void main() {
  late FakeNoteAudioPlayer player;
  late NoteRecordingController controller;

  setUp(() {
    player = FakeNoteAudioPlayer(
      defaultDuration: const Duration(seconds: 42),
      failingSources: {'broken.m4a'},
    );
    controller = NoteRecordingController(
      player: player,
      recordings: [
        _recording('a', title: 'Lecture'),
        _recording('b', page: 3),
      ],
    );
  });

  tearDown(() async {
    controller.dispose();
    await player.dispose();
  });

  Future<void> pumpList(
    WidgetTester tester, {
    int? pageNumber,
    ValueChanged<NoteRecording>? onRemoved,
  }) => tester.pumpWidget(
    noteTestHost(
      NoteRecordingList(
        controller: controller,
        pageNumber: pageNumber,
        onRemoved: onRemoved,
      ),
    ),
  );

  testWidgets('shows titles, durations and pages', (tester) async {
    await pumpList(tester);

    expect(find.text('Lecture'), findsOneWidget);
    expect(find.text('00:42'), findsOneWidget);
    expect(find.text('00:42 · Page 3'), findsOneWidget);
    expect(find.text('1×'), findsNWidgets(2));
  });

  testWidgets('shows an empty state', (tester) async {
    controller
      ..remove('a')
      ..remove('b');

    await pumpList(tester);

    expect(find.text('No recordings yet'), findsOneWidget);
  });

  testWidgets('filters by page', (tester) async {
    await pumpList(tester, pageNumber: 3);

    expect(find.text('Recording b'), findsOneWidget);
    expect(find.text('Lecture'), findsNothing);
  });

  testWidgets('plays and pauses, showing the progress', (tester) async {
    await pumpList(tester);
    expect(semanticLabelOf(tester, _playA), 'Play Lecture');

    await tapKey(tester, _playA);
    await tester.pump();
    expect(controller.isPlaying, isTrue);
    expect(semanticLabelOf(tester, _playA), 'Pause Lecture');

    player.advance(const Duration(seconds: 12));
    await tester.pump();
    expect(find.text('00:12 / 00:42'), findsOneWidget);
    expect(find.byType(FractionallySizedBox), findsOneWidget);

    await tapKey(tester, _playA);
    await tester.pump();
    expect(controller.isPlaying, isFalse);
    expect(semanticLabelOf(tester, _playA), 'Play Lecture');
  });

  testWidgets('cycles the playback speed', (tester) async {
    await pumpList(tester);
    expect(semanticLabelOf(tester, _speedA), 'Playback speed 1×');

    for (final label in ['1.25×', '1.5×', '2×', '0.5×', '0.75×', '1×']) {
      await tapKey(tester, _speedA);
      expect(semanticLabelOf(tester, _speedA), 'Playback speed $label');
    }

    expect(controller.find('a')?.playbackSpeed, 1);
  });

  testWidgets('deletes and tells the host', (tester) async {
    final removed = <NoteRecording>[];
    await pumpList(tester, onRemoved: removed.add);

    await tapKey(tester, _deleteA);

    expect(removed.map((r) => r.id), ['a']);
    expect(controller.recordings.map((r) => r.id), ['b']);
    expect(find.text('Lecture'), findsNothing);
  });

  testWidgets('says when a recording cannot be played', (tester) async {
    controller.add(_recording('c', source: 'broken.m4a'));
    await pumpList(tester);

    await tapKey(tester, const ValueKey('recording-play-c'));
    await tester.pump();

    expect(find.text("Can't play this recording"), findsOneWidget);
  });

  testWidgets('can be sized to its rows inside a scrollable', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        SingleChildScrollView(
          child: NoteRecordingList(controller: controller, shrinkWrap: true),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Lecture'), findsOneWidget);
  });
}
