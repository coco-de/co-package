import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/tools.dart';

List<String> _ids(NoteToolbarLayout layout) => [
  for (final item in layout.items) item.id,
];

NoteToolbarLayout _abc() => NoteToolbarLayout(
  items: const [
    NoteToolbarItem(id: 'a'),
    NoteToolbarItem(id: 'b', visible: false),
    NoteToolbarItem(id: 'c'),
  ],
);

void main() {
  group('NoteToolbarItem', () {
    test('round trips through JSON', () {
      const item = NoteToolbarItem(id: 'pen', visible: false);

      expect(NoteToolbarItem.fromJson(item.toJson()), item);
      expect(item.copyWith(visible: true).visible, isTrue);
      expect(item.copyWith().hashCode, item.hashCode);
      expect(item.toString(), contains('pen'));
    });

    test('never throws on malformed JSON', () {
      expect(NoteToolbarItem.fromJson(null).id, isEmpty);
      expect(
        NoteToolbarItem.fromJson({'id': 'x', 'visible': 3}).visible,
        isTrue,
      );
    });
  });

  group('NoteToolbarLayout', () {
    test('standard layout lists every standard item, docked on top', () {
      final layout = NoteToolbarLayout();

      expect(_ids(layout), [
        'pen',
        'pencil',
        'marker',
        'eraser',
        'lasso',
        'shape',
        'text',
        'image',
        'undo',
        'redo',
        'layers',
        'presets',
      ]);
      expect(_ids(layout), NoteToolbarItemIds.standard);
      expect(layout.visibleItems.length, 12);
      expect(layout.placement, NoteToolbarPlacement.docked);
      expect(layout.dockEdge, NoteToolbarDockEdge.top);
      expect(layout.floatingOffset, NoteToolbarLayout.defaultFloatingOffset);
    });

    test('drops empty and repeated ids', () {
      final layout = NoteToolbarLayout(
        items: const [
          NoteToolbarItem(id: 'a'),
          NoteToolbarItem(id: ''),
          NoteToolbarItem(id: 'a', visible: false),
        ],
      );

      expect(_ids(layout), ['a']);
      expect(layout.isVisible('a'), isTrue);
    });

    test('has unmodifiable items', () {
      expect(
        () => _abc().items.add(const NoteToolbarItem(id: 'x')),
        throwsUnsupportedError,
      );
    });

    test('moveItem puts the item at its final index', () {
      expect(_ids(_abc().moveItem(0, 2)), ['b', 'c', 'a']);
      expect(_ids(_abc().moveItem(2, 0)), ['c', 'a', 'b']);
      expect(_ids(_abc().moveItem(0, 99)), ['b', 'c', 'a']);
      expect(_ids(_abc().moveItem(2, -4)), ['c', 'a', 'b']);
    });

    test('moveItem keeps the layout for no-ops', () {
      final layout = _abc();

      expect(layout.moveItem(1, 1), same(layout));
      expect(layout.moveItem(-1, 0), same(layout));
      expect(layout.moveItem(3, 0), same(layout));
    });

    test('setVisible shows and hides known items only', () {
      final layout = _abc();

      expect(layout.setVisible('a', false).isVisible('a'), isFalse);
      expect(layout.setVisible('b', true).visibleItems.length, 3);
      expect(layout.setVisible('a', true), same(layout));
      expect(layout.setVisible('zzz', false), same(layout));
      expect(layout.isVisible('zzz'), isFalse);
      expect(layout.item('zzz'), isNull);
      expect(layout.item('b')?.visible, isFalse);
      expect(layout.visibleItems.map((item) => item.id), ['a', 'c']);
    });

    test('reset returns the factory layout', () {
      final changed = _abc().copyWith(
        placement: NoteToolbarPlacement.floating,
        dockEdge: NoteToolbarDockEdge.left,
      );

      expect(changed.reset(), NoteToolbarLayout());
    });

    test('ensureItems appends what is missing', () {
      final old = NoteToolbarLayout(
        items: const [
          NoteToolbarItem(id: 'eraser', visible: false),
          NoteToolbarItem(id: 'pen'),
        ],
      );
      final next = old.ensureItems();

      expect(_ids(next).take(2), ['eraser', 'pen']);
      expect(next.isVisible('eraser'), isFalse);
      expect(next.isVisible('presets'), isTrue);
      expect(next.items.length, 12);
      expect(next.ensureItems(), same(next));
      expect(_ids(_abc().ensureItems(['x', 'x', '', 'a'])), [
        'a',
        'b',
        'c',
        'x',
      ]);
    });

    test('repairs the floating offset', () {
      expect(
        NoteToolbarLayout(floatingOffset: const Offset(-5, 12)).floatingOffset,
        const Offset(0, 12),
      );
      expect(
        NoteToolbarLayout(
          floatingOffset: const Offset(double.nan, 1),
        ).floatingOffset,
        NoteToolbarLayout.defaultFloatingOffset,
      );
    });

    test('round trips through JSON', () {
      final layout = _abc().copyWith(
        placement: NoteToolbarPlacement.floating,
        dockEdge: NoteToolbarDockEdge.bottom,
        floatingOffset: const Offset(40, 56),
      );
      final json = NoteJson.decodeMap(NoteJson.encode(layout.toJson()));

      final decoded = NoteToolbarLayout.fromJson(json);

      expect(decoded, layout);
      expect(decoded.hashCode, layout.hashCode);
      expect(layout.toJson()['dockEdge'], 'bottom');
      expect(layout.toJson()['placement'], 'floating');
      expect(
        NoteToolbarLayout.fromJson(NoteToolbarLayout().toJson()),
        NoteToolbarLayout(),
      );
      expect(layout.toString(), contains('floating'));
    });

    test('never throws on malformed JSON', () {
      for (final json in <Object?>[null, 1, 'x', <Object?>[], {}]) {
        expect(NoteToolbarLayout.fromJson(json), NoteToolbarLayout());
      }
      final layout = NoteToolbarLayout.fromJson({
        'items': [
          1,
          {'visible': false},
          {'id': 'pen', 'visible': 'no'},
        ],
        'placement': 'orbiting',
        'dockEdge': 7,
        'floatingOffset': {'x': 'a'},
      });

      expect(_ids(layout), ['pen']);
      expect(layout.isVisible('pen'), isTrue);
      expect(layout.placement, NoteToolbarPlacement.docked);
      expect(layout.dockEdge, NoteToolbarDockEdge.top);
      expect(layout.floatingOffset, NoteToolbarLayout.defaultFloatingOffset);
    });

    test('keeps an explicitly empty item list', () {
      expect(NoteToolbarLayout.fromJson({'items': []}).items, isEmpty);
    });

    test('differs when order, visibility or placement differ', () {
      expect(_abc(), _abc());
      expect(_abc().moveItem(0, 1), isNot(_abc()));
      expect(_abc().setVisible('a', false), isNot(_abc()));
      expect(
        _abc().copyWith(placement: NoteToolbarPlacement.floating),
        isNot(_abc()),
      );
    });
  });
}
