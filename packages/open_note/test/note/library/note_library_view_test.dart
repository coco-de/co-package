import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/library/library.dart';

import '../support/note_test_host.dart';
import 'library_test_support.dart';

class _Thumbnails implements NoteThumbnailProvider {
  static const Key previewKey = ValueKey('thumbnail');

  @override
  Widget? thumbnailFor(BuildContext context, NoteSummary note) => note.id == 'a'
      ? const ColoredBox(key: previewKey, color: Color(0xFF00FF00))
      : null;
}

const _byName = NoteLibraryViewState(
  sortField: NoteSortField.name,
  sortOrder: NoteSortOrder.ascending,
);

NoteLibrary _library({
  NoteLibraryViewState viewState = _byName,
  List<NoteSummary>? notes,
}) => testLibrary(
  viewState: viewState,
  notes:
      notes ??
      [
        summary('a', title: 'Apple'),
        summary('b', title: 'Banana'),
        summary('c', title: 'Cherry'),
      ],
);

List<NoteSummary> _many(int count) => [
  for (var i = 1; i <= count; i++) summary('m$i', title: 'Note $i'),
];

Finder _tile(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(NoteTile));

/// Two fingers around the centre of the view whose distance changes from
/// [from] to [to], along [axis].
Future<void> _pinch(
  WidgetTester tester, {
  required double from,
  required double to,
  Axis axis = Axis.horizontal,
}) async {
  final center = tester.getCenter(find.byType(NoteLibraryView));
  Offset half(double gap) =>
      axis == Axis.horizontal ? Offset(gap / 2, 0) : Offset(0, gap / 2);
  final first = await tester.startGesture(center - half(from), pointer: 1);
  final second = await tester.startGesture(center + half(from), pointer: 2);
  const steps = 8;
  for (var step = 1; step <= steps; step++) {
    final gap = from + (to - from) * step / steps;
    await first.moveTo(center - half(gap));
    await second.moveTo(center + half(gap));
    await tester.pump();
  }
  await first.up();
  await second.up();
  await tester.pumpAndSettle();
}

/// How many of the notes [ids] show a check mark.
int _checkMarks(Iterable<String> ids) => ids
    .where((id) => find.byKey(NoteTile.checkMarkKey(id)).evaluate().isNotEmpty)
    .length;

bool _tileSelected(WidgetTester tester, String title) =>
    tester.widget<NoteTile>(_tile(title)).selected;

double _scrollOffset(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

void main() {
  group('content', () {
    testWidgets('shows a tile for every visible note in order', (tester) async {
      await tester.pumpWidget(
        noteTestHost(NoteLibraryView(library: _library())),
      );

      expect(find.byType(NoteTile), findsNWidgets(3));
      final left = [
        for (final title in ['Apple', 'Banana', 'Cherry'])
          tester.getTopLeft(find.text(title)).dx,
      ];
      expect(left[0], lessThan(left[1]));
      expect(left[1], lessThan(left[2]));
      expect(find.byType(NoteCoverView), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('says when there are no notes', (tester) async {
      await tester.pumpWidget(
        noteTestHost(NoteLibraryView(library: _library(notes: []))),
      );

      expect(find.text('No notes yet'), findsOneWidget);
    });

    testWidgets('says when the filters hide everything', (tester) async {
      final library = _library()
        ..viewState = _byName.copyWith(query: () => 'zzz');
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      expect(find.text('No matching notes'), findsOneWidget);
    });

    testWidgets('uses the given strings', (tester) async {
      await tester.pumpWidget(
        noteTestHost(
          NoteLibraryView(
            library: _library(notes: []),
            strings: const NoteLibraryStrings(emptyLibrary: '노트가 없습니다'),
          ),
        ),
      );

      expect(find.text('노트가 없습니다'), findsOneWidget);
    });

    testWidgets('puts pinned notes in a section of their own', (tester) async {
      final library = _library()..pin(['c']);
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      final pinnedHeader = tester.getTopLeft(find.text('Pinned')).dy;
      final cherry = tester.getTopLeft(_tile('Cherry')).dy;
      final othersHeader = tester.getTopLeft(find.text('Notes')).dy;
      final apple = tester.getTopLeft(_tile('Apple')).dy;
      expect(pinnedHeader, lessThan(cherry));
      expect(cherry, lessThan(othersHeader));
      expect(othersHeader, lessThan(apple));
    });

    testWidgets('has no headings without pinned notes', (tester) async {
      await tester.pumpWidget(
        noteTestHost(NoteLibraryView(library: _library())),
      );

      expect(find.text('Pinned'), findsNothing);
      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('needs no second heading when everything is pinned', (
      tester,
    ) async {
      final library = _library()..pin(['a', 'b', 'c']);
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('shows only the shown folder and follows changes', (
      tester,
    ) async {
      final library = testLibrary(
        folders: [folder('f')],
        viewState: _byName,
        notes: [summary('a', title: 'Apple', folderId: 'f')],
      )..showFolder('f');
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));
      library.createNote(title: 'Elsewhere');
      await tester.pump();
      expect(find.text('Elsewhere'), findsNothing);

      library.createNote(title: 'Inside', folderId: 'f');
      library.renameNote('a', 'Apricot');
      await tester.pump();

      expect(find.text('Inside'), findsOneWidget);
      expect(find.text('Apricot'), findsOneWidget);
    });

    testWidgets('shows the creation date when sorted by it', (tester) async {
      final library = _library(
        viewState: _byName.copyWith(sortField: NoteSortField.created),
        notes: [
          summary(
            'a',
            createdAt: DateTime(2026, 2, 3, 12),
            modifiedAt: DateTime(2026, 4, 5, 12),
          ),
        ],
      );
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));
      expect(find.text('2026-02-03'), findsOneWidget);

      library.viewState = library.viewState.copyWith(
        sortField: NoteSortField.modified,
      );
      await tester.pump();

      expect(find.text('2026-04-05'), findsOneWidget);
    });

    testWidgets('passes thumbnails to the tiles', (tester) async {
      await tester.pumpWidget(
        noteTestHost(
          NoteLibraryView(
            library: _library(),
            thumbnailProvider: _Thumbnails(),
          ),
        ),
      );

      expect(find.byKey(_Thumbnails.previewKey), findsOneWidget);
      expect(find.byType(NoteCoverView), findsNWidgets(2));
    });

    testWidgets('scrolls with the given controller', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        noteTestHost(
          NoteLibraryView(
            library: _library(notes: _many(40)),
            scrollController: controller,
          ),
        ),
      );

      controller.jumpTo(200);
      await tester.pump();

      expect(_scrollOffset(tester), 200);
    });
  });

  group('drawer layout', () {
    testWidgets('fits more columns into a smaller zoom', (tester) async {
      final library = _library(notes: _many(12));
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));
      int firstRowLength() {
        final top = tester.getTopLeft(find.byType(NoteTile).first).dy;

        return find
            .byType(NoteTile)
            .evaluate()
            .where(
              (element) =>
                  (element.renderObject! as RenderBox)
                      .localToGlobal(Offset.zero)
                      .dy ==
                  top,
            )
            .length;
      }

      // 800 wide, 16 padding: floor((768 + 16) / (132 + 16)) = 5.
      expect(firstRowLength(), 5);
      final width = tester.getSize(find.byType(NoteTile).first).width;
      library.zoomDrawer(2);
      await tester.pump();
      expect(firstRowLength(), 2);
      expect(
        tester.getSize(find.byType(NoteTile).first).width,
        greaterThan(width),
      );
      library.zoomDrawer(0.25);
      await tester.pump();
      expect(firstRowLength(), 9);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays usable on a narrow screen', (tester) async {
      tester.view
        ..physicalSize = const Size(220, 500)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        noteTestHost(NoteLibraryView(library: _library()..zoomDrawer(2))),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(NoteTile), findsWidgets);
    });
  });

  group('list layout', () {
    testWidgets('shows one row per note', (tester) async {
      await tester.pumpWidget(
        noteTestHost(
          NoteLibraryView(
            library: _library(
              viewState: _byName.copyWith(layout: NoteLibraryLayout.list),
            ),
          ),
        ),
      );

      final tiles = tester.widgetList<NoteTile>(find.byType(NoteTile));
      expect(tiles.map((tile) => tile.layout), [
        NoteLibraryLayout.list,
        NoteLibraryLayout.list,
        NoteLibraryLayout.list,
      ]);
      final rects = [
        for (var i = 0; i < 3; i++) tester.getRect(find.byType(NoteTile).at(i)),
      ];
      expect(rects.every((rect) => rect.width == 800), isTrue);
      expect(rects[0].bottom, lessThanOrEqualTo(rects[1].top));
      expect(rects[1].bottom, lessThanOrEqualTo(rects[2].top));
    });
  });

  group('taps and selection', () {
    testWidgets('a tap opens a note', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        noteTestHost(
          NoteLibraryView(
            library: _library(),
            onOpenNote: (note) => opened.add(note.id),
          ),
        ),
      );

      await tester.tap(_tile('Banana'));

      expect(opened, ['b']);
    });

    testWidgets('a long press starts selecting, then taps toggle', (
      tester,
    ) async {
      final library = _library();
      final opened = <String>[];
      await tester.pumpWidget(
        noteTestHost(
          NoteLibraryView(
            library: library,
            onOpenNote: (note) => opened.add(note.id),
          ),
        ),
      );

      await tester.longPress(_tile('Banana'));
      await tester.pump();

      expect(library.selectionMode, isTrue);
      expect(library.selection, {'b'});
      expect(_checkMarks(['a', 'b', 'c']), 3);

      await tester.tap(_tile('Apple'));
      await tester.pump();
      expect(library.selection, {'a', 'b'});
      await tester.tap(_tile('Banana'));
      await tester.pump();
      expect(library.selection, {'a'});
      expect(opened, isEmpty);
      expect(_tileSelected(tester, 'Apple'), isTrue);
      expect(_tileSelected(tester, 'Banana'), isFalse);

      library.selectionMode = false;
      await tester.pump();
      expect(_checkMarks(['a', 'b', 'c']), 0);
      await tester.tap(_tile('Apple'));
      expect(opened, ['a']);
    });

    testWidgets('a long press can be taken over by the host', (tester) async {
      final library = _library();
      final pressed = <String>[];
      await tester.pumpWidget(
        noteTestHost(
          NoteLibraryView(
            library: library,
            onLongPressNote: (note) => pressed.add(note.id),
          ),
        ),
      );

      await tester.longPress(_tile('Cherry'));

      expect(pressed, ['c']);
      expect(library.selectionMode, isFalse);
    });

    testWidgets('selecting works in the list layout too', (tester) async {
      final library = _library(
        viewState: _byName.copyWith(layout: NoteLibraryLayout.list),
      )..toggleSelect('a');
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      await tester.tap(_tile('Cherry'));
      await tester.pump();

      expect(library.selection, {'a', 'c'});
      expect(_checkMarks(['a', 'b', 'c']), 3);
    });
  });

  group('pinch', () {
    testWidgets('spreading two fingers zooms the drawer in', (tester) async {
      final library = _library();
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      await _pinch(tester, from: 100, to: 160);

      expect(library.viewState.drawerZoom, closeTo(1.6, 0.05));
    });

    testWidgets('closing two fingers zooms it out', (tester) async {
      final library = _library();
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      await _pinch(tester, from: 200, to: 140);

      expect(library.viewState.drawerZoom, closeTo(0.7, 0.05));
    });

    testWidgets('stops at the limits', (tester) async {
      final library = _library();
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      await _pinch(tester, from: 40, to: 400);
      expect(library.viewState.drawerZoom, 2);

      await _pinch(tester, from: 400, to: 20);
      expect(library.viewState.drawerZoom, 0.5);
    });

    testWidgets('changes the size of the covers', (tester) async {
      final library = _library(notes: _many(8));
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));
      final before = tester.getSize(find.byType(NoteTile).first).width;

      await _pinch(tester, from: 100, to: 200);

      expect(
        tester.getSize(find.byType(NoteTile).first).width,
        greaterThan(before),
      );
    });

    testWidgets('works along the scroll direction without scrolling', (
      tester,
    ) async {
      final library = _library(notes: _many(40));
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      await _pinch(tester, from: 100, to: 220, axis: Axis.vertical);

      expect(library.viewState.drawerZoom, greaterThan(1.5));
      expect(_scrollOffset(tester), 0);
    });

    testWidgets('wins over scrolling when one finger stays put', (
      tester,
    ) async {
      final library = _library(notes: _many(40));
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));
      final center = tester.getCenter(find.byType(NoteLibraryView));

      final still = await tester.startGesture(
        center + const Offset(0, 50),
        pointer: 1,
      );
      final moving = await tester.startGesture(
        center - const Offset(0, 50),
        pointer: 2,
      );
      // Upwards, which is also how one scrolls on to the next notes.
      for (var step = 0; step < 16; step++) {
        await moving.moveBy(const Offset(0, -5));
        await tester.pump();
      }
      await still.up();
      await moving.up();
      await tester.pumpAndSettle();

      expect(library.viewState.drawerZoom, greaterThan(1.5));
      expect(_scrollOffset(tester), 0);
    });

    testWidgets('does not open or select a note', (tester) async {
      final library = _library();
      final opened = <NoteSummary>[];
      await tester.pumpWidget(
        noteTestHost(NoteLibraryView(library: library, onOpenNote: opened.add)),
      );
      final tile = tester.getCenter(_tile('Banana'));

      final first = await tester.startGesture(
        tile - const Offset(20, 0),
        pointer: 1,
      );
      final second = await tester.startGesture(
        tile + const Offset(20, 0),
        pointer: 2,
      );
      await tester.pump(const Duration(milliseconds: 600));
      await first.up();
      await second.up();
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
      expect(library.selectionMode, isFalse);
    });

    testWidgets('leaves one finger to scroll', (tester) async {
      final library = _library(notes: _many(40));
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      await tester.drag(find.byType(NoteLibraryView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(_scrollOffset(tester), greaterThan(0));
      expect(library.viewState.drawerZoom, 1);
    });

    testWidgets('one finger moving sideways does not zoom', (tester) async {
      final library = _library();
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      await tester.drag(find.byType(NoteLibraryView), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(library.viewState.drawerZoom, 1);
    });

    testWidgets('does nothing in the list layout', (tester) async {
      final library = _library(
        viewState: _byName.copyWith(layout: NoteLibraryLayout.list),
      );
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      await _pinch(tester, from: 100, to: 300);

      expect(library.viewState.drawerZoom, 1);
    });

    testWidgets('keeps working after switching layouts', (tester) async {
      final library = _library(
        viewState: _byName.copyWith(layout: NoteLibraryLayout.list),
      );
      await tester.pumpWidget(noteTestHost(NoteLibraryView(library: library)));

      library.viewState = library.viewState.copyWith(
        layout: NoteLibraryLayout.drawer,
      );
      await tester.pump();
      await _pinch(tester, from: 100, to: 150);

      expect(library.viewState.drawerZoom, closeTo(1.5, 0.05));
    });
  });
}
