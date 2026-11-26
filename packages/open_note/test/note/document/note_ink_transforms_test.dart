import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/text/text_painter.dart';
import 'package:open_note/src/note/document/note_ink_transforms.dart';
import 'package:open_note/src/note/document/note_page_numbering.dart';

Scribble _page() => Scribble(
  strokes: [
    Stroke(
      points: [Point(x: 10, y: 20, p: 0.5), Point(x: 30, y: 20, p: 0.5)],
      segments: [
        Segment(
          start: Point(x: 10, y: 20),
          end: Point(x: 30, y: 20),
          points: [Point(x: 20, y: 20)],
        ),
      ],
    ),
  ],
  imageDrawables: [ImageDrawable(id: 'i', x: 40, y: 50, width: 20, height: 10)],
  textDrawables: [
    TextDrawable(id: 't', text: 'abc', x: 60, y: 80, fontSize: 16),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const size = Size(100, 200);

  void expectPoint(Point point, double x, double y) {
    expect(point.x, closeTo(x, 1e-6));
    expect(point.y, closeTo(y, 1e-6));
  }

  group('translate', () {
    test('모든 필기 · 세그먼트 · 이미지 · 텍스트를 옮기고 원본은 둔다', () {
      final original = _page();

      final moved = NoteInkTransforms.translate(original, const Offset(5, 7));

      expectPoint(moved.strokes.single.points.first, 15, 27);
      expectPoint(moved.strokes.single.segments.single.end, 35, 27);
      expectPoint(moved.strokes.single.segments.single.points.single, 25, 27);
      expect(moved.imageDrawables.single.x, 45);
      expect(moved.textDrawables.single.y, 87);
      expectPoint(original.strokes.single.points.first, 10, 20);
    });

    test('이동이 없으면 같은 인스턴스', () {
      final original = _page();

      expect(
        NoteInkTransforms.translate(original, Offset.zero),
        same(original),
      );
    });
  });

  group('rotate', () {
    test('90° 시계 방향: (x, y) → (높이 − y, x)', () {
      final turned = NoteInkTransforms.rotate(_page(), 1, size);

      expectPoint(turned.strokes.single.points.first, 180, 10);
      expectPoint(turned.strokes.single.segments.single.end, 180, 30);
    });

    test('180° 와 270°(= −90°)', () {
      expectPoint(
        NoteInkTransforms.rotate(_page(), 2, size).strokes.single.points.first,
        90,
        180,
      );
      expectPoint(
        NoteInkTransforms.rotate(_page(), -1, size).strokes.single.points.first,
        20,
        90,
      );
    });

    test('이미지는 중심이 돌고 크기는 유지하며 회전각이 쌓인다', () {
      final image = NoteInkTransforms.rotate(
        _page(),
        1,
        size,
      ).imageDrawables.single;

      // 중심 (50, 55) → (200 − 55, 50) = (145, 50)
      expect(image.x + image.width / 2, closeTo(145, 1e-6));
      expect(image.y + image.height / 2, closeTo(50, 1e-6));
      expect(image.width, 20);
      expect(image.rotation, closeTo(math.pi / 2, 1e-9));
    });

    test('네 번 돌리면 좌표 · 텍스트 기준점이 원래대로', () {
      var scribble = _page();
      var pageSize = size;
      for (var i = 0; i < 4; i++) {
        scribble = NoteInkTransforms.rotate(scribble, 1, pageSize);
        pageSize = pageSize.flipped;
      }

      expectPoint(scribble.strokes.single.points.first, 10, 20);
      expect(scribble.imageDrawables.single.rotation, 0);
      expect(scribble.imageDrawables.single.x, closeTo(40, 1e-6));
      final text = scribble.textDrawables.single;
      expect(text.rotation, 0);
      expect(text.x, closeTo(60, 1e-6));
      expect(text.y, closeTo(80, 1e-6));
    });

    test('텍스트의 시각적 중심이 점과 함께 돈다', () {
      final before = TextDrawablePainter.getTextBounds(
        _page().textDrawables.single,
      ).center;

      final text = NoteInkTransforms.rotate(
        _page(),
        1,
        size,
      ).textDrawables.single;

      // 회전된 텍스트의 (x, y) 는 중심이다.
      expect(text.x, closeTo(200 - before.dy, 1e-6));
      expect(text.y, closeTo(before.dx, 1e-6));
      expect(text.rotation, closeTo(math.pi / 2, 1e-9));
    });

    test('0 회전은 같은 인스턴스', () {
      final original = _page();

      expect(NoteInkTransforms.rotate(original, 4, size), same(original));
    });
  });

  group('NotePageNumbering', () {
    const pages = ['cover', 'toc', 'p1', 'p2'];

    test('기본은 1 부터', () {
      const numbering = NotePageNumbering();

      expect(
        [for (var i = 0; i < 4; i++) numbering.labelOf(pages, i)],
        ['1', '2', '3', '4'],
      );
    });

    test('지정 페이지부터 번호를 시작하고 앞 장은 0-n', () {
      const numbering = NotePageNumbering(startsAtPageId: 'p1');

      expect(
        [for (var i = 0; i < 4; i++) numbering.labelOf(pages, i)],
        ['0-1', '0-2', '1', '2'],
      );
    });

    test('시작 번호와 접두어, 없는 시작 페이지는 무시', () {
      const numbering = NotePageNumbering(
        startsAtPageId: 'gone',
        firstNumber: 10,
        frontMatterPrefix: 'i',
      );

      expect(numbering.labelOf(pages, 1), '11');
    });

    test('JSON 왕복과 copyWith 로 시작 페이지 해제', () {
      const numbering = NotePageNumbering(
        startsAtPageId: 'p1',
        firstNumber: 3,
        frontMatterPrefix: 'a-',
      );

      expect(NotePageNumbering.fromJson(numbering.toJson()), numbering);
      expect(
        numbering.copyWith(startsAtPageId: () => null).startsAtPageId,
        isNull,
      );
      expect(NotePageNumbering.fromJson('x'), const NotePageNumbering());
    });
  });
}
