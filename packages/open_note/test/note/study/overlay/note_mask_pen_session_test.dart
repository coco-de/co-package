import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

int _issued = 0;

NoteMaskPenSession _session({
  NoteMaskShape shape = NoteMaskShape.rect,
  double minSize = 8,
}) {
  _issued = 0;

  return NoteMaskPenSession(
    shape: shape,
    minSize: minSize,
    thickness: 16,
    fill: const NoteMaskFill.solid(Color(0xFF010203)),
    fillOpacity: 0.75,
    scope: NoteMaskScope.document,
    idFactory: () => 'id-${++_issued}',
  );
}

void main() {
  test('a rectangle is the bounding box of the pen points', () {
    final session = _session()
      ..add(const Offset(30, 40))
      ..add(const Offset(80, 20))
      ..add(const Offset(60, 90));

    final mask = session.finish()!;

    expect(mask.id, 'id-1');
    expect(mask.shape, NoteMaskShape.rect);
    expect(mask.bounds, const Rect.fromLTRB(30, 20, 80, 90));
    expect(mask.fill.color, const Color(0xFF010203));
    expect(mask.fillOpacity, 0.75);
    expect(mask.scope, NoteMaskScope.document);
    expect(mask.revealed, isFalse);
  });

  test('a stroke follows the pen at its thickness', () {
    final session = _session(shape: NoteMaskShape.stroke)
      ..add(const Offset(10, 10))
      ..add(const Offset(60, 12))
      ..add(const Offset(110, 10));

    final mask = session.finish()!;

    expect(mask.shape, NoteMaskShape.stroke);
    expect(mask.thickness, 16);
    expect(mask.bounds, const Rect.fromLTRB(2, 2, 118, 20));
    expect(mask.pagePoints, hasLength(3));
    expect(
      (mask.pagePoints[1] - const Offset(60, 12)).distance,
      lessThan(1e-6),
    );
  });

  test('an accidental tap makes nothing and takes no id', () {
    final session = _session()
      ..add(const Offset(10, 10))
      ..add(const Offset(13, 14));

    expect(session.finish(), isNull);
    expect(_issued, 0);
    expect(session.isEmpty, isTrue);
  });

  test('the same limit applies to strokes', () {
    final session = _session(shape: NoteMaskShape.stroke)
      ..add(const Offset(10, 10))
      ..add(const Offset(17, 17));

    expect(session.finish(), isNull);
  });

  test('a flat drag is widened to the minimum around its centre', () {
    final session = _session()
      ..add(const Offset(10, 50))
      ..add(const Offset(90, 50));

    final mask = session.finish()!;

    expect(mask.bounds, const Rect.fromLTRB(10, 46, 90, 54));
  });

  test('the minimum size is configurable', () {
    final large = _session(minSize: 40)
      ..add(Offset.zero)
      ..add(const Offset(30, 30));
    final none = _session(minSize: 0)
      ..add(Offset.zero)
      ..add(const Offset(2, 3));

    expect(large.finish(), isNull);
    expect(none.finish()!.bounds, const Rect.fromLTRB(0, 0, 2, 3));
  });

  test('without a minimum a lone point still makes no empty mask', () {
    final session = _session(minSize: 0)..add(const Offset(5, 5));

    expect(session.finish(), isNull);
  });

  test('jitter and non-finite points are ignored', () {
    final session = _session()
      ..add(const Offset(10, 10))
      ..add(const Offset(10.2, 10.1))
      ..add(const Offset(double.nan, 3))
      ..add(const Offset(20, double.infinity))
      ..add(const Offset(40, 40));

    expect(session.points, const [Offset(10, 10), Offset(40, 40)]);
    expect(() => session.points.add(Offset.zero), throwsUnsupportedError);
  });

  test('preview shows the mask so far without ending the drag', () {
    final session = _session()..add(const Offset(10, 10));

    expect(session.preview(), isNull);
    session.add(const Offset(50, 60));

    final preview = session.preview()!;
    expect(preview.id, NoteMaskPenSession.previewId);
    expect(preview.bounds, const Rect.fromLTRB(10, 10, 50, 60));
    expect(session.points, hasLength(2));
    expect(_issued, 0);
    expect(session.finish()!.id, 'id-1');
  });

  test('finish and cancel start over', () {
    final session = _session()
      ..add(Offset.zero)
      ..add(const Offset(50, 50));
    session.finish();
    expect(session.isEmpty, isTrue);

    session
      ..add(Offset.zero)
      ..add(const Offset(50, 50))
      ..cancel();

    expect(session.isEmpty, isTrue);
    expect(session.finish(), isNull);
  });
}
