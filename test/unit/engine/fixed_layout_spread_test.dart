// Story: S1.9 (#15) — buildSpreadRows / slotFromSpineProperties tests
// BDD: F3.5 (page-spread-left/right 슬롯 존중)

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_spread.dart';

void main() {
  group('slotFromSpineProperties', () {
    test('page-spread-left → SpreadSlot.left', () {
      expect(slotFromSpineProperties(['page-spread-left']), SpreadSlot.left);
    });

    test('page-spread-right → SpreadSlot.right', () {
      expect(slotFromSpineProperties(['page-spread-right']), SpreadSlot.right);
    });

    test('rendition:page-spread-center → SpreadSlot.center (left/right보다 우선)', () {
      expect(
        slotFromSpineProperties([
          'page-spread-left',
          'rendition:page-spread-center',
        ]),
        SpreadSlot.center,
      );
    });

    test('미명시 → null', () {
      expect(slotFromSpineProperties(const []), isNull);
      expect(slotFromSpineProperties(['nav', 'svg']), isNull);
    });
  });

  group('buildSpreadRows', () {
    test('미명시 spine 4개 → 2 rows (좌→우 흐름)', () {
      final spine = _items([
        ('a', const []),
        ('b', const []),
        ('c', const []),
        ('d', const []),
      ]);
      final rows = buildSpreadRows(spine);
      expect(rows, hasLength(2));
      expect(rows[0].left?.idref, 'a');
      expect(rows[0].right?.idref, 'b');
      expect(rows[1].left?.idref, 'c');
      expect(rows[1].right?.idref, 'd');
    });

    test('마지막 항목 단독 → row left만 채움', () {
      final spine = _items([
        ('a', const []),
        ('b', const []),
        ('c', const []),
      ]);
      final rows = buildSpreadRows(spine);
      expect(rows, hasLength(2));
      expect(rows[0].left?.idref, 'a');
      expect(rows[0].right?.idref, 'b');
      expect(rows[1].left?.idref, 'c');
      expect(rows[1].right, isNull);
    });

    test('page-spread-right 강제 → 단독 row의 right slot', () {
      final spine = _items([
        ('a', ['page-spread-right']),
        ('b', const []),
        ('c', const []),
      ]);
      final rows = buildSpreadRows(spine);
      expect(rows[0].left, isNull);
      expect(rows[0].right?.idref, 'a');
      expect(rows[1].left?.idref, 'b');
      expect(rows[1].right?.idref, 'c');
    });

    test('page-spread-left 강제가 next에 오면 cur는 단독 row left', () {
      final spine = _items([
        ('a', const []),
        ('b', ['page-spread-left']),
        ('c', const []),
      ]);
      final rows = buildSpreadRows(spine);
      // a는 단독 row left (next b가 left 강제이므로)
      expect(rows[0].left?.idref, 'a');
      expect(rows[0].right, isNull);
      // b 시작 새 row, c가 right
      expect(rows[1].left?.idref, 'b');
      expect(rows[1].right?.idref, 'c');
    });

    test('center 페이지는 단독 row', () {
      final spine = _items([
        ('a', const []),
        ('cover', ['rendition:page-spread-center']),
        ('b', const []),
        ('c', const []),
      ]);
      final rows = buildSpreadRows(spine);
      expect(rows, hasLength(3));
      expect(rows[0].left?.idref, 'a');
      expect(rows[0].right, isNull); // next가 center → cur는 단독
      expect(rows[1].isCenter, isTrue);
      expect(rows[1].center?.idref, 'cover');
      expect(rows[2].left?.idref, 'b');
      expect(rows[2].right?.idref, 'c');
    });

    test('left 강제 + right 강제 페어', () {
      final spine = _items([
        ('a', ['page-spread-left']),
        ('b', ['page-spread-right']),
        ('c', ['page-spread-left']),
        ('d', ['page-spread-right']),
      ]);
      final rows = buildSpreadRows(spine);
      expect(rows, hasLength(2));
      expect(rows[0].left?.idref, 'a');
      expect(rows[0].right?.idref, 'b');
      expect(rows[1].left?.idref, 'c');
      expect(rows[1].right?.idref, 'd');
    });

    test('빈 spine → 빈 rows', () {
      expect(buildSpreadRows(const []), isEmpty);
    });
  });
}

List<EpubSpineItem> _items(List<(String, List<String>)> data) => [
      for (final (id, props) in data)
        EpubSpineItem(
          idref: id,
          href: '$id.xhtml',
          mediaType: 'application/xhtml+xml',
          properties: props,
        ),
    ];
