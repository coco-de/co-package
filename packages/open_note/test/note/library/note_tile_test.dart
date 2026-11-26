import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/library/library.dart';

import '../support/note_test_host.dart';
import 'library_test_support.dart';

/// Returns a keyed preview for the notes in [ids].
class _FakeThumbnails implements NoteThumbnailProvider {
  _FakeThumbnails(this.ids);

  final Set<String> ids;
  static const Key previewKey = ValueKey('preview');

  @override
  Widget? thumbnailFor(BuildContext context, NoteSummary note) =>
      ids.contains(note.id)
      ? const ColoredBox(key: previewKey, color: Color(0xFF00FF00))
      : null;
}

final _note = summary(
  'n',
  title: 'Algebra',
  modifiedAt: DateTime(2026, 3, 4, 12),
  createdAt: DateTime(2026, 1, 2, 12),
  tags: ['math', 'exam'],
  pageCount: 3,
);

Widget _host(Widget tile, {double width = 160, double height = 240}) =>
    noteTestHost(
      Center(
        child: SizedBox(width: width, height: height, child: tile),
      ),
    );

Widget _row(Widget tile) => noteTestHost(
  Align(
    alignment: Alignment.topCenter,
    child: SizedBox(
      width: 400,
      child: Column(mainAxisSize: MainAxisSize.min, children: [tile]),
    ),
  ),
);

void main() {
  group('drawer tile', () {
    testWidgets('shows the cover, title and modification date', (tester) async {
      await tester.pumpWidget(_host(NoteTile(note: _note)));

      expect(find.byType(NoteCoverView), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('2026-03-04'), findsOneWidget);
      expect(find.byKey(NoteTile.pinKey('n')), findsNothing);
      expect(find.byKey(NoteTile.checkMarkKey('n')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the cover in its own proportions', (tester) async {
      await tester.pumpWidget(_host(NoteTile(note: _note)));

      final cover = tester.getSize(find.byType(NoteCoverView));
      expect(
        cover.width / cover.height,
        closeTo(_note.cover.aspectRatio, 0.01),
      );
    });

    testWidgets('can show another date and translated texts', (tester) async {
      await tester.pumpWidget(
        _host(
          NoteTile(
            note: _note.copyWith(title: ''),
            date: DateTime(2025, 12, 31, 12),
            strings: NoteLibraryStrings(
              untitled: '제목 없음',
              formatDate: (date) => '${date.year}년',
            ),
          ),
        ),
      );

      expect(find.text('제목 없음'), findsOneWidget);
      expect(find.text('2025년'), findsOneWidget);
    });

    testWidgets('marks pinned notes', (tester) async {
      await tester.pumpWidget(
        _host(NoteTile(note: _note.copyWith(pinned: true))),
      );

      expect(find.byKey(NoteTile.pinKey('n')), findsOneWidget);
    });

    testWidgets('shows a mark and says whether the note is selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(NoteTile(note: _note, selectionMode: true)),
      );
      expect(find.byKey(NoteTile.checkMarkKey('n')), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(NoteTile)),
        isSemantics(isSelected: false),
      );

      await tester.pumpWidget(
        _host(NoteTile(note: _note, selectionMode: true, selected: true)),
      );

      expect(find.byKey(NoteTile.checkMarkKey('n')), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(NoteTile)),
        isSemantics(isSelected: true),
      );
      handle.dispose();
    });

    testWidgets('reports taps and long presses', (tester) async {
      var taps = 0;
      var presses = 0;
      await tester.pumpWidget(
        _host(
          NoteTile(
            note: _note,
            onTap: () => taps++,
            onLongPress: () => presses++,
          ),
        ),
      );

      await tester.tap(find.byType(NoteTile));
      await tester.longPress(find.byType(NoteTile));

      expect(taps, 1);
      expect(presses, 1);
    });

    testWidgets('fits a very small tile', (tester) async {
      await tester.pumpWidget(
        _host(
          NoteTile(note: _note.copyWith(pinned: true), selectionMode: true),
          width: 60,
          height: 120,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('thumbnails', () {
    testWidgets('replace the cover, in the cover proportions', (tester) async {
      await tester.pumpWidget(
        _host(NoteTile(note: _note, thumbnailProvider: _FakeThumbnails({'n'}))),
      );

      expect(find.byKey(_FakeThumbnails.previewKey), findsOneWidget);
      expect(find.byType(NoteCoverView), findsNothing);
      final size = tester.getSize(find.byKey(_FakeThumbnails.previewKey));
      expect(size.width / size.height, closeTo(_note.cover.aspectRatio, 0.01));
    });

    testWidgets('fall back to the cover when there is none', (tester) async {
      await tester.pumpWidget(
        _host(NoteTile(note: _note, thumbnailProvider: _FakeThumbnails({}))),
      );

      expect(find.byType(NoteCoverView), findsOneWidget);
      expect(find.byKey(_FakeThumbnails.previewKey), findsNothing);
    });
  });

  group('list row', () {
    testWidgets('shows the title and a line of details', (tester) async {
      await tester.pumpWidget(
        _row(NoteTile(note: _note, layout: NoteLibraryLayout.list)),
      );

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('2026-03-04 · 3 pages · #math #exam'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is at least the row height and grows with large text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _row(NoteTile(note: _note, layout: NoteLibraryLayout.list)),
      );
      final normal = tester.getSize(find.byType(NoteTile)).height;
      expect(normal, greaterThanOrEqualTo(64));

      await tester.pumpWidget(
        _row(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(3)),
            child: NoteTile(note: _note, layout: NoteLibraryLayout.list),
          ),
        ),
      );

      expect(tester.getSize(find.byType(NoteTile)).height, greaterThan(normal));
      expect(tester.takeException(), isNull);
    });

    testWidgets('singular and pinned details', (tester) async {
      await tester.pumpWidget(
        _row(
          NoteTile(
            note: _note.copyWith(pageCount: 1, tags: [], pinned: true),
            layout: NoteLibraryLayout.list,
            selectionMode: true,
            selected: true,
          ),
        ),
      );

      expect(find.text('2026-03-04 · 1 page'), findsOneWidget);
      expect(find.byKey(NoteTile.pinKey('n')), findsOneWidget);
      expect(find.byKey(NoteTile.checkMarkKey('n')), findsOneWidget);
    });
  });

  group('semantics', () {
    testWidgets('announces the title, pages, pin and selection', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          NoteTile(
            note: _note.copyWith(pinned: true),
            selectionMode: true,
            selected: true,
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(NoteTile)),
        isSemantics(
          label: 'Algebra, 3 pages, Pinned',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
          hasLongPressAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('can be activated by assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(NoteTile(note: _note, onTap: () => taps++)),
      );

      tester.semantics.tap(find.semantics.byLabel('Algebra, 3 pages'));

      expect(taps, 1);
      handle.dispose();
    });
  });
}
