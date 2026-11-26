import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

import 'overlay_test_support.dart';

void main() {
  const bounds = Rect.fromLTWH(0, 0, 200, 100);

  test('registers masks and tapes', () {
    final registry = NoteObjectRegistry();

    registerNoteStudyObjects(registry);

    expect(registry.kinds, containsAll(['mask', 'tape']));
    expect(
      registry.decodeAll([
        NoteMaskObject(id: 'a', bounds: bounds).toJson(),
        NoteTapeObject(id: 'b', bounds: bounds).toJson(),
      ]),
      [isA<NoteMaskObject>(), isA<NoteTapeObject>()],
    );
  });

  testWidgets('builds the matching widgets with the given strings', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final registry = NoteObjectRegistry();
    registerNoteStudyObjects(
      registry,
      strings: const NoteStudyOverlayStrings(revealMask: '가리개 열기'),
    );
    final changes = <NoteObject>[];

    await tester.pumpWidget(
      boxed(
        Builder(
          builder: (context) => registry.buildView(
            context,
            NoteMaskObject(id: 'a', bounds: bounds),
            NoteObjectViewScope(onChanged: changes.add),
          ),
        ),
      ),
    );
    expect(find.byType(NoteMaskView), findsOneWidget);
    expect(find.bySemanticsLabel('가리개 열기'), findsOneWidget);
    await tester.tapAt(const Offset(100, 50));
    expect(changes, hasLength(1));

    await tester.pumpWidget(
      boxed(
        Builder(
          builder: (context) => registry.buildView(
            context,
            NoteTapeObject(id: 'b', bounds: bounds),
            const NoteObjectViewScope(),
          ),
        ),
      ),
    );

    expect(find.byType(NoteTapeView), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('an object of the wrong class draws nothing', (tester) async {
    final registry = NoteObjectRegistry();
    registerNoteStudyObjects(registry);

    await tester.pumpWidget(
      boxed(
        Builder(
          builder: (context) => registry.buildView(
            context,
            const NoteUnknownObject(
              id: 'x',
              bounds: bounds,
              unknownKind: 'mask',
              payload: {},
            ),
            const NoteObjectViewScope(),
          ),
        ),
      ),
    );

    expect(find.byType(NoteMaskView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
