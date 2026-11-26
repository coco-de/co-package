import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';
import 'note_view_test_support.dart';

class _Probe extends NoteViewNotifier {
  void poke() => notifyChanged();
}

String _germanRuler(String length, NoteRulerUnit unit, int degrees) =>
    'Lineal $length ${unit.code} ($degrees)';

String _germanPage(int number) => 'Seite $number';

void main() {
  group('NoteViewStyle', () {
    test('compares by value and copies', () {
      const style = NoteViewStyle();

      expect(style, const NoteViewStyle());
      expect(style.copyWith(), style);
      expect(style.copyWith().hashCode, style.hashCode);
      final red = style.copyWith(accentColor: const Color(0xFFFF0000));
      expect(red, isNot(style));
      expect(red.accentColor, const Color(0xFFFF0000));
      expect(red.rulerColor, style.rulerColor);
    });

    test('copies every colour', () {
      const marker = Color(0xFF010203);
      const style = NoteViewStyle();
      final changed = <NoteViewStyle>[
        style.copyWith(accentColor: marker),
        style.copyWith(surfaceColor: marker),
        style.copyWith(barColor: marker),
        style.copyWith(borderColor: marker),
        style.copyWith(textColor: marker),
        style.copyWith(mutedTextColor: marker),
        style.copyWith(dividerColor: marker),
        style.copyWith(dropZoneColor: marker),
        style.copyWith(dropZoneActiveColor: marker),
        style.copyWith(rulerColor: marker),
        style.copyWith(rulerMarkColor: marker),
        style.copyWith(magnifierBorderColor: marker),
      ];

      expect(changed.toSet(), hasLength(changed.length));
      expect(changed, everyElement(isNot(style)));
    });
  });

  group('NoteViewStrings', () {
    const strings = NoteViewStrings(
      closeTab: 'Tab schließen',
      untitled: 'Ohne Titel',
      rulerLabel: _germanRuler,
      pageLabel: _germanPage,
    );

    test('has English defaults', () {
      const english = NoteViewStrings();

      expect(english.pageLabel(3), 'Page 3');
      expect(english.zoomLabel(2.5), '2.5×');
      expect(english.rulerLabel('2.5', NoteRulerUnit.cm, 45), '2.5 cm · 45°');
    });

    testWidgets('translates the widgets', (tester) async {
      final semantics = tester.ensureSemantics();
      final tabs = NoteTabsController(tabs: const [NoteTab(noteId: 'a')]);
      await tester.pumpWidget(
        noteTestHost(
          Column(
            children: [
              NoteTabBar(controller: tabs, strings: strings),
              Expanded(
                child: NoteRuler(
                  controller: NoteRulerController(length: 72, visible: true),
                  strings: strings,
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Ohne Titel'), findsOneWidget);
      expect(find.text('Lineal 2.5 cm (0)'), findsOneWidget);
      expect(find.semantics.byLabel('Tab schließen: Ohne Titel'), findsOne);
      semantics.dispose();
    });

    testWidgets('labels thumbnails', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        noteTestHost(
          NoteThumbnailGrid(
            controller: NoteThumbnailGridController(),
            pageCount: 1,
            strings: strings,
            itemBuilder: (context, index) => const SizedBox(),
          ),
        ),
      );

      expect(find.semantics.byLabel('Seite 1'), findsOne);
      semantics.dispose();
    });
  });

  test('NoteViewNotifier goes quiet after dispose', () {
    final probe = _Probe();
    final counter = NotifyCounter(probe);

    probe.poke();
    probe.dispose();
    probe.poke();
    probe.dispose();

    expect(probe.isDisposed, isTrue);
    expect(counter.count, 1);
  });
}
