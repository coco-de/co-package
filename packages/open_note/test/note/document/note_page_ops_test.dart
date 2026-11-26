import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/document.dart';
import 'package:open_note/src/note/objects/objects.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

import 'support/document_fixtures.dart';

void main() {
  NotePage page() => withStroke(
    NotePage.blank(
      template: NotePaperTemplate.lined(),
      size: const NotePageSize(200, 300),
      idFactory: counterIds(),
      clock: fixedClock,
    ),
    const Offset(10, 20),
    const Offset(30, 40),
  ).copyWith(objects: [linkTo('page:2')]);

  Offset firstPoint(NotePage page) {
    final point = page.layers.last.scribble.strokes.single.points.first;

    return Offset(point.x, point.y);
  }

  group('rotate', () {
    test('turns the page, ink, paper and objects clockwise', () {
      final turned = NotePageOps.rotate(page(), 1);

      expect(turned.size, const NotePageSize(300, 200));
      expect(turned.paperTurns, 1);
      expect(turned.paperSize, const NotePageSize(200, 300));
      // (x, y) → (height − y, x)
      expect(firstPoint(turned), const Offset(280, 10));
      final bounds = turned.objects.single.bounds;
      expect(bounds.center, const Offset(280, 35));
      expect(turned.objects.single.rotation, closeTo(1.5708, 0.001));
    });

    test('four quarter turns restore the page', () {
      final original = page();
      var turned = original;
      for (var i = 0; i < 4; i++) {
        turned = NotePageOps.rotate(turned, 1);
      }

      expect(turned.size, original.size);
      expect(turned.paperTurns, 0);
      expect(firstPoint(turned).dx, closeTo(10, 0.001));
      expect(firstPoint(turned).dy, closeTo(20, 0.001));
      expect(turned.objects.single.bounds, original.objects.single.bounds);
      expect(turned.objects.single.rotation, closeTo(0, 0.001));
    });

    test('zero turns return the same page', () {
      final original = page();

      expect(NotePageOps.rotate(original, 4), same(original));
    });

    test('margins turn with the page', () {
      final extended = NotePageOps.setMargins(
        page(),
        const EdgeInsets.only(left: 10, top: 20),
      );

      expect(
        NotePageOps.rotate(extended, 1).margins,
        const EdgeInsets.only(top: 10, right: 20),
      );
    });
  });

  group('margins', () {
    test('extending grows the page and moves ink and objects with it', () {
      final extended = NotePageOps.setMargins(
        page(),
        const EdgeInsets.only(left: 100, top: 5),
      );

      expect(extended.size, const NotePageSize(300, 305));
      expect(extended.paperSize, const NotePageSize(200, 300));
      expect(extended.contentRect, const Rect.fromLTWH(100, 5, 200, 300));
      expect(firstPoint(extended), const Offset(110, 25));
      expect(extended.objects.single.bounds.topLeft, const Offset(110, 15));
    });

    test('shrinking back restores positions; margins never go negative', () {
      final extended = NotePageOps.extendMargin(
        page(),
        NoteMarginSide.right,
        80,
      );
      expect(extended.size, const NotePageSize(280, 300));
      expect(firstPoint(extended), const Offset(10, 20));

      final shrunk = NotePageOps.extendMargin(
        extended,
        NoteMarginSide.right,
        -500,
      );
      expect(shrunk.margins, EdgeInsets.zero);
      expect(shrunk.size, const NotePageSize(200, 300));
    });
  });

  group('duplicate', () {
    test('gives every part a new id and keeps the content', () {
      final original = page();
      final copy = NotePageOps.duplicate(
        original,
        registry: documentRegistry(),
        idFactory: counterIds('c'),
        strokeIdFactory: () => 'new-stroke',
        clock: fixedClock,
      );

      expect(copy.id, isNot(original.id));
      expect(
        copy.layers.single.layer.id,
        isNot(original.layers.single.layer.id),
      );
      expect(copy.activeLayerId, copy.layers.single.layer.id);
      expect(copy.layers.single.scribble.strokes.single.id, 'new-stroke');
      expect(copy.objects.single, isA<NoteLinkObject>());
      expect(copy.objects.single.id, isNot('link'));
      expect(firstPoint(copy), firstPoint(original));
      expect(original.layers.single.scribble.strokes.single.id, 'ink');
    });

    test('keeps the concrete type with a registry that lacks the kind', () {
      final copy = NotePageOps.duplicate(
        page(),
        registry: NoteObjectRegistry(),
        clock: fixedClock,
      );

      expect(copy.objects.single, isA<NoteLinkObject>());
    });

    test('a link to the page itself follows the copy', () {
      final original = page();
      final linked = original.copyWith(
        objects: [linkTo('pageid:${original.id}')],
        layers: [
          original.layers.single.copyWith(
            scribble: Scribble(
              textDrawables: [
                TextDrawable(
                  id: 't',
                  text: 'here',
                  linkSpans: [
                    TextLinkSpan(
                      start: 0,
                      end: 4,
                      url: 'pageid:${original.id}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

      final copy = NotePageOps.duplicate(
        linked,
        registry: documentRegistry(),
        clock: fixedClock,
      );

      expect(
        (copy.objects.single as NoteLinkObject).target,
        'pageid:${copy.id}',
      );
      expect(
        copy.layers.single.scribble.textDrawables.single.linkSpans.single.url,
        'pageid:${copy.id}',
      );
      expect(
        linked.layers.single.scribble.textDrawables.single.linkSpans.single.url,
        'pageid:${original.id}',
      );
    });
  });

  test('page JSON round-trips (ink is stored separately)', () {
    final original = NotePageOps.setMargins(
      NotePageOps.rotate(page(), 1),
      const EdgeInsets.only(bottom: 30),
    ).copyWith(marginTemplate: () => NotePaperTemplate.grid());

    final decoded = NotePage.fromJson(
      NoteJson.decodeMap(NoteJson.encode(original.toJson())),
      registry: documentRegistry(),
      ink: {
        for (final content in original.layers)
          content.layer.id: content.scribble,
      },
    )!;

    expect(decoded.toJson(), original.toJson());
    expect(decoded.hasInk, isTrue);
  });

  test('a page without layers gets one; one without an id is rejected', () {
    final registry = documentRegistry();

    final page = NotePage.fromJson({'id': 'x'}, registry: registry)!;

    expect(page.layers, hasLength(1));
    expect(NotePage.fromJson({'layers': []}, registry: registry), isNull);
  });
}
