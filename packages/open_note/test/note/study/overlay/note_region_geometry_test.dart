import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

const _page = Size(400, 500);

void main() {
  test('a drag spans its two corners, clamped to the page', () {
    expect(
      NoteRegionGeometry.fromDrag(
        const Offset(100, 200),
        const Offset(40, 50),
        _page,
      ),
      const Rect.fromLTRB(40, 50, 100, 200),
    );
    expect(
      NoteRegionGeometry.fromDrag(
        const Offset(300, 400),
        const Offset(900, -50),
        _page,
      ),
      const Rect.fromLTRB(300, 0, 400, 400),
    );
  });

  test('fit shifts a rectangle in and shrinks only what cannot fit', () {
    expect(
      NoteRegionGeometry.fit(const Rect.fromLTWH(-10, 480, 50, 40), _page),
      const Rect.fromLTWH(0, 460, 50, 40),
    );
    expect(
      NoteRegionGeometry.fit(const Rect.fromLTWH(10, 10, 900, 40), _page),
      const Rect.fromLTWH(0, 10, 400, 40),
    );
  });

  test('move keeps the size and stops at the edges', () {
    const rect = Rect.fromLTWH(100, 100, 80, 60);

    expect(
      NoteRegionGeometry.move(rect, const Offset(500, -500), _page),
      const Rect.fromLTWH(320, 0, 80, 60),
    );
  });

  test('every handle moves only its own edges', () {
    const rect = Rect.fromLTRB(100, 100, 200, 200);
    const delta = Offset(10, 20);

    final results = {
      for (final handle in NoteRegionHandle.values)
        handle: NoteRegionGeometry.resize(rect, handle, delta, _page),
    };

    expect(results, {
      NoteRegionHandle.topLeft: const Rect.fromLTRB(110, 120, 200, 200),
      NoteRegionHandle.top: const Rect.fromLTRB(100, 120, 200, 200),
      NoteRegionHandle.topRight: const Rect.fromLTRB(100, 120, 210, 200),
      NoteRegionHandle.right: const Rect.fromLTRB(100, 100, 210, 200),
      NoteRegionHandle.bottomRight: const Rect.fromLTRB(100, 100, 210, 220),
      NoteRegionHandle.bottom: const Rect.fromLTRB(100, 100, 200, 220),
      NoteRegionHandle.bottomLeft: const Rect.fromLTRB(110, 100, 200, 220),
      NoteRegionHandle.left: const Rect.fromLTRB(110, 100, 200, 200),
    });
  });

  test('resizing stops at the page and at the minimum size', () {
    const rect = Rect.fromLTRB(100, 100, 200, 200);

    expect(
      NoteRegionGeometry.resize(
        rect,
        NoteRegionHandle.bottomRight,
        const Offset(-500, 900),
        _page,
        minSize: 30,
      ),
      const Rect.fromLTRB(100, 100, 130, 500),
    );
    expect(
      NoteRegionGeometry.resize(
        rect,
        NoteRegionHandle.topLeft,
        const Offset(500, -900),
        _page,
        minSize: 30,
      ),
      const Rect.fromLTRB(170, 0, 200, 200),
    );
  });

  test('resizing a rectangle already below the minimum does not throw', () {
    const sliver = Rect.fromLTRB(0, 0, 5, 5);

    for (final handle in NoteRegionHandle.values) {
      expect(
        () => NoteRegionGeometry.resize(
          sliver,
          handle,
          const Offset(-50, -50),
          _page,
          minSize: 30,
        ),
        returnsNormally,
      );
    }
  });

  test('handles sit on the corners and edge middles', () {
    const rect = Rect.fromLTRB(10, 20, 110, 220);

    expect(NoteRegionHandle.topLeft.positionOn(rect), const Offset(10, 20));
    expect(NoteRegionHandle.right.positionOn(rect), const Offset(110, 120));
    expect(NoteRegionHandle.bottom.positionOn(rect), const Offset(60, 220));
  });

  test('handleAt picks the nearest handle in reach', () {
    const rect = Rect.fromLTRB(10, 20, 110, 220);

    expect(
      NoteRegionGeometry.handleAt(rect, const Offset(108, 216), 20),
      NoteRegionHandle.bottomRight,
    );
    expect(
      NoteRegionGeometry.handleAt(rect, const Offset(60, 100), 20),
      isNull,
    );
  });

  test('atLeast drops taps and widens slivers', () {
    expect(
      NoteRegionGeometry.atLeast(const Rect.fromLTWH(5, 5, 10, 12), _page, 24),
      isNull,
    );
    expect(
      NoteRegionGeometry.atLeast(
        const Rect.fromLTWH(50, 50, 100, 10),
        _page,
        24,
      ),
      const Rect.fromLTRB(50, 43, 150, 67),
    );
    expect(
      NoteRegionGeometry.atLeast(const Rect.fromLTWH(0, 0, 100, 4), _page, 24),
      const Rect.fromLTRB(0, 0, 100, 24),
    );
  });

  test('a minimum larger than the page means the whole page', () {
    expect(
      NoteRegionGeometry.atLeast(
        const Rect.fromLTWH(0, 0, 30, 5),
        const Size(30, 40),
        100,
      ),
      const Rect.fromLTWH(0, 0, 30, 40),
    );
  });
}
