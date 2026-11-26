import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/template/template.dart';

import '../support/note_test_host.dart';

void main() {
  final builtIns = NotePaperCatalog.builtInTemplates();
  late List<NotePaperTemplate> reported;

  setUp(() => reported = []);

  Finder tile(String id) => find.byKey(ValueKey('note-paper-tile-$id'));

  NotePaperTemplate previewOf(WidgetTester tester, String id) => tester
      .widget<NotePaperView>(
        find.descendant(of: tile(id), matching: find.byType(NotePaperView)),
      )
      .template;

  Finder slider(String name) => find.descendant(
    of: find.byKey(ValueKey('note-paper-$name')),
    matching: find.byType(NoteSlider),
  );

  Widget picker({
    List<NotePaperTemplate>? templates,
    String? selectedId,
    bool spacing = true,
    bool width = true,
    NotePaperStrings strings = const NotePaperStrings(),
  }) => noteTestHost(
    NotePaperPicker(
      templates: templates ?? builtIns,
      selectedId: selectedId,
      showLineSpacingControl: spacing,
      showLineWidthControl: width,
      strings: strings,
      onSelected: reported.add,
    ),
  );

  testWidgets('shows a live preview with a name per paper', (tester) async {
    await tester.pumpWidget(picker());
    for (final paper in builtIns) {
      expect(tile(paper.id), findsOneWidget);
      expect(previewOf(tester, paper.id), paper);
    }
    for (final name in [
      'Blank',
      'Lined',
      'Grid',
      'Dotted',
      'Cornell',
      'Music',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.byType(NoteSlider), findsNothing, reason: 'nothing selected');
  });

  testWidgets('tapping a preview selects and reports it', (tester) async {
    await tester.pumpWidget(picker());
    await tester.tap(tile(NotePaperCatalog.gridId));
    await tester.pump();
    expect(reported, [builtIns[2]]);
    expect(find.byType(NoteSlider), findsNWidgets(2));
    expect(find.text('24 pt'), findsOneWidget);
    expect(find.text('0.6 pt'), findsOneWidget);
  });

  testWidgets('unruled papers have no line controls', (tester) async {
    await tester.pumpWidget(picker(selectedId: NotePaperCatalog.gridId));
    expect(find.byType(NoteSlider), findsNWidgets(2));
    await tester.tap(tile(NotePaperCatalog.blankId));
    await tester.pump();
    expect(find.byType(NoteSlider), findsNothing);
    final photo = NotePaperTemplate.image(id: 'photo', imageSource: '');
    await tester.pumpWidget(picker(templates: [photo], selectedId: 'photo'));
    expect(find.byType(NoteSlider), findsNothing);
  });

  testWidgets('each control can be switched off', (tester) async {
    await tester.pumpWidget(
      picker(selectedId: NotePaperCatalog.linedId, width: false),
    );
    expect(slider('line-spacing'), findsOneWidget);
    expect(slider('line-width'), findsNothing);
    await tester.pumpWidget(
      picker(selectedId: NotePaperCatalog.linedId, spacing: false),
    );
    expect(slider('line-spacing'), findsNothing);
    expect(slider('line-width'), findsOneWidget);
    await tester.pumpWidget(
      picker(
        selectedId: NotePaperCatalog.linedId,
        spacing: false,
        width: false,
      ),
    );
    expect(find.byType(NoteSlider), findsNothing);
  });

  testWidgets('the spacing slider updates the preview at once', (tester) async {
    await tester.pumpWidget(picker(selectedId: NotePaperCatalog.linedId));
    await tester.tapAt(tester.getCenter(slider('line-spacing')));
    await tester.pump();
    final expected = reported.last;
    expect(expected.id, NotePaperCatalog.linedId);
    expect(expected.lineSpacing, closeTo(63, 1));
    expect(previewOf(tester, NotePaperCatalog.linedId), expected);
    expect(find.text('${expected.lineSpacing.round()} pt'), findsOneWidget);
    expect(
      previewOf(tester, NotePaperCatalog.gridId),
      builtIns[2],
      reason: 'other previews are untouched',
    );
  });

  testWidgets('the width slider updates the preview at once', (tester) async {
    await tester.pumpWidget(picker(selectedId: NotePaperCatalog.dottedId));
    await tester.tapAt(tester.getCenter(slider('line-width')));
    await tester.pump();
    final expected = reported.last;
    expect(expected.lineWidth, closeTo(2.125, 0.06));
    expect(previewOf(tester, NotePaperCatalog.dottedId), expected);
  });

  testWidgets('dragging a slider keeps reporting', (tester) async {
    await tester.pumpWidget(picker(selectedId: NotePaperCatalog.linedId));
    await tester.dragFrom(
      tester.getCenter(slider('line-spacing')),
      const Offset(600, 0),
    );
    await tester.pump();
    expect(reported.last.lineSpacing, 120);
  });

  testWidgets('adjustments are remembered per paper', (tester) async {
    await tester.pumpWidget(picker(selectedId: NotePaperCatalog.linedId));
    await tester.tapAt(tester.getCenter(slider('line-spacing')));
    await tester.pump();
    final adjusted = reported.last;
    await tester.tap(tile(NotePaperCatalog.musicId));
    await tester.pump();
    await tester.tap(tile(NotePaperCatalog.linedId));
    await tester.pump();
    expect(reported.last, adjusted);
    // A rebuild with equal papers keeps them.
    await tester.pumpWidget(
      picker(
        templates: NotePaperCatalog.builtInTemplates(),
        selectedId: NotePaperCatalog.linedId,
      ),
    );
    expect(previewOf(tester, NotePaperCatalog.linedId), adjusted);
  });

  testWidgets('a changed paper from the host wins', (tester) async {
    await tester.pumpWidget(picker(selectedId: NotePaperCatalog.linedId));
    await tester.tapAt(tester.getCenter(slider('line-spacing')));
    await tester.pump();
    final landscape = [
      for (final paper in builtIns) paper.fitted(NotePageSize.a4.rotated),
    ];
    await tester.pumpWidget(
      picker(templates: landscape, selectedId: NotePaperCatalog.linedId),
    );
    expect(previewOf(tester, NotePaperCatalog.linedId), landscape[1]);
  });

  testWidgets('a new selectedId moves the selection', (tester) async {
    await tester.pumpWidget(picker(selectedId: NotePaperCatalog.musicId));
    expect(find.text('10 pt'), findsOneWidget);
    await tester.pumpWidget(picker(selectedId: NotePaperCatalog.dottedId));
    expect(find.text('24 pt'), findsOneWidget);
    expect(reported, isEmpty);
  });

  testWidgets('tiles are labelled, selectable buttons', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(picker(selectedId: NotePaperCatalog.gridId));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Grid')),
      isSemantics(
        label: 'Grid',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Lined')),
      isSemantics(label: 'Lined', isButton: true, isSelected: false),
    );
    tester.semantics.tap(find.semantics.byLabel('Lined'));
    await tester.pump();
    expect(reported.single.id, NotePaperCatalog.linedId);
    handle.dispose();
  });

  testWidgets('every text comes from the strings', (tester) async {
    await tester.pumpWidget(
      picker(
        selectedId: NotePaperCatalog.linedId,
        templates: [
          ...builtIns,
          NotePaperTemplate.lined(id: 'own', name: 'Journal'),
        ],
        strings: const NotePaperStrings(
          lined: 'Liniert',
          lineSpacing: 'Abstand',
          lineWidth: 'Stärke',
          pointUnit: 'Pkt',
        ),
      ),
    );
    expect(find.text('Liniert'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Abstand'), findsOneWidget);
    expect(find.text('Stärke'), findsOneWidget);
    expect(find.text('28 Pkt'), findsOneWidget);
  });

  testWidgets('works inside a scroll view', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        SingleChildScrollView(
          child: NotePaperPicker(
            templates: builtIns,
            selectedId: NotePaperCatalog.linedId,
            onSelected: reported.add,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(NoteSlider), findsNWidgets(2));
    await tester.tap(tile(NotePaperCatalog.gridId));
    expect(reported.single.id, NotePaperCatalog.gridId);
  });

  testWidgets('a narrow, short space still lays out', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        Center(
          child: SizedBox(
            width: 260,
            height: 300,
            child: NotePaperPicker(
              templates: builtIns,
              selectedId: NotePaperCatalog.linedId,
              onSelected: reported.add,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty list says so', (tester) async {
    await tester.pumpWidget(picker(templates: const []));
    expect(find.text('No templates'), findsOneWidget);
  });

  group('NotePaperStrings', () {
    const strings = NotePaperStrings();

    test('names every kind', () {
      for (final kind in NotePaperKind.values) {
        expect(strings.kindName(kind), NotePaperTemplate.defaultName(kind));
      }
    });

    test('formats lengths without trailing zeros', () {
      expect(strings.formatLength(28), '28 pt');
      expect(strings.formatLength(100), '100 pt');
      expect(strings.formatLength(0.6), '0.6 pt');
      expect(strings.formatLength(0.25), '0.25 pt');
      expect(strings.formatLength(10.5), '10.5 pt');
    });

    test('keeps custom names and translates default ones', () {
      const german = NotePaperStrings(grid: 'Kariert');
      expect(german.templateName(NotePaperTemplate.grid()), 'Kariert');
      expect(german.templateName(NotePaperTemplate.grid(name: 'Math')), 'Math');
      expect(
        german.templateName(NotePaperTemplate(id: 'n', name: '')),
        'Blank',
      );
    });
  });
}
