import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/objects/objects.dart';

const int _side = 120;

/// Pixels of a transparent 120x120 canvas after [paint].
class _Pixels {
  _Pixels(this._data);

  final List<int> _data;

  static Future<_Pixels> of(void Function(Canvas canvas) paint) async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(_side, _side);
    final bytes = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    picture.dispose();
    image.dispose();

    return _Pixels(bytes!.buffer.asUint8List());
  }

  static Future<_Pixels> ofObject(
    NoteObject object, [
    NoteObjectPaintContext context = NoteObjectPaintContext.empty,
  ]) => of((canvas) => object.paintToCanvas(canvas, context));

  /// The colour at `(x, y)`.
  Color at(int x, int y) {
    final i = (y * _side + x) * 4;

    return Color.fromARGB(_data[i + 3], _data[i], _data[i + 1], _data[i + 2]);
  }

  int alphaAt(int x, int y) => _data[(y * _side + x) * 4 + 3];

  bool get isBlank {
    for (var i = 3; i < _data.length; i += 4) {
      if (_data[i] != 0) return false;
    }

    return true;
  }
}

const Color _red = Color(0xFFFF0000);
const Color _blue = Color(0xFF0000FF);

void main() {
  group('sticky', () {
    const note = NoteStickyObject(
      id: 's',
      bounds: Rect.fromLTWH(10, 10, 80, 60),
      text: 'XXX',
      paperColor: _red,
      textColor: _blue,
      fontSize: 20,
      shadow: false,
    );

    test('paints the paper inside its bounds only', () async {
      final pixels = await _Pixels.ofObject(note);

      expect(pixels.at(50, 60), _red);
      expect(pixels.alphaAt(5, 40), 0);
      expect(pixels.alphaAt(50, 72), 0);
    });

    test('paints the text from the top left inside the padding', () async {
      final pixels = await _Pixels.ofObject(note);

      // The test font draws each glyph as a solid box.
      expect(pixels.at(26, 31), _blue);
      expect(pixels.at(13, 31), _red);
    });

    test('casts a shadow below the paper when asked', () async {
      final pixels = await _Pixels.ofObject(note.copyWith(shadow: true));

      expect(pixels.alphaAt(50, 71), greaterThan(0));
    });

    test('draws only paper for a note too narrow for text', () async {
      final pixels = await _Pixels.ofObject(
        note.copyWith(bounds: const Rect.fromLTWH(10, 10, 12, 12)),
      );

      expect(pixels.at(15, 15), _red);
    });
  });

  group('arrow', () {
    // A horizontal arrow along y = 40 from x = 10 to x = 90.
    const arrow = NoteArrowObject(
      id: 'a',
      bounds: Rect.fromLTWH(10, 30, 80, 20),
      color: _red,
      width: 4,
    );

    test('paints the line between its ends', () async {
      final pixels = await _Pixels.ofObject(arrow);

      expect(pixels.at(40, 40), _red);
      expect(pixels.alphaAt(40, 33), 0);
      expect(pixels.alphaAt(100, 40), 0);
    });

    test('paints the head only when it has one', () async {
      // Beside the head, off the line.
      final withHead = await _Pixels.ofObject(arrow);
      final without = await _Pixels.ofObject(
        arrow.copyWith(headStyle: NoteArrowCap.none),
      );

      expect(withHead.alphaAt(76, 35), greaterThan(0));
      expect(without.alphaAt(76, 35), 0);
    });

    test('paints a tail cap at the start', () async {
      final pixels = await _Pixels.ofObject(
        arrow.copyWith(tailStyle: NoteArrowCap.triangle),
      );

      expect(pixels.alphaAt(24, 35), greaterThan(0));
    });

    test('an open head is hollow, a triangle is filled', () async {
      final open = await _Pixels.ofObject(
        arrow.copyWith(headStyle: NoteArrowCap.open),
      );
      final filled = await _Pixels.ofObject(arrow);

      // Inside the head, between the line and the chevron's edge.
      expect(filled.alphaAt(77, 36), greaterThan(0));
      expect(open.alphaAt(76, 37), 0);
      expect(open.alphaAt(75, 33), greaterThan(0));
    });

    test('a dashed line leaves gaps', () async {
      final dashed = await _Pixels.ofObject(
        arrow.copyWith(dashed: true, headStyle: NoteArrowCap.none),
      );

      expect(dashed.at(15, 40), _red);
      expect(dashed.alphaAt(26, 40), 0);
      expect(dashed.at(35, 40), _red);
    });

    test('an arrow of no length draws nothing', () async {
      final pixels = await _Pixels.ofObject(
        arrow.copyWith(start: Offset.zero, end: Offset.zero),
      );

      expect(pixels.isBlank, isTrue);
    });
  });

  group('link', () {
    const link = NoteLinkObject(
      id: 'l',
      bounds: Rect.fromLTWH(20, 20, 60, 30),
      color: _blue,
    );

    test('an outline frames the area', () async {
      final pixels = await _Pixels.ofObject(link);

      expect(pixels.alphaAt(20, 35), greaterThan(0));
      expect(pixels.alphaAt(50, 35), 0);
    });

    test('an underline draws along the bottom only', () async {
      final pixels = await _Pixels.ofObject(
        link.copyWith(appearance: NoteLinkAppearance.underline),
      );

      expect(pixels.alphaAt(50, 49), greaterThan(0));
      expect(pixels.alphaAt(20, 35), 0);
    });

    test('a hidden link draws nothing', () async {
      final pixels = await _Pixels.ofObject(
        link.copyWith(appearance: NoteLinkAppearance.hidden),
      );

      expect(pixels.isBlank, isTrue);
    });
  });

  group('sticker', () {
    const sticker = NoteStickerObject(
      id: 't',
      bounds: Rect.fromLTWH(10, 10, 80, 40),
      source: 'flag',
    );

    /// A 20x10 picture, red on the left half and blue on the right.
    Future<ui.Image> halves() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..drawRect(const Rect.fromLTWH(0, 0, 10, 10), Paint()..color = _red)
        ..drawRect(const Rect.fromLTWH(10, 0, 10, 10), Paint()..color = _blue);
      final picture = recorder.endRecording();
      final image = await picture.toImage(20, 10);
      picture.dispose();

      return image;
    }

    test('draws a light placeholder without the picture', () async {
      final pixels = await _Pixels.ofObject(sticker);

      expect(pixels.alphaAt(50, 30), inInclusiveRange(1, 80));
      expect(pixels.alphaAt(5, 30), 0);
    });

    test('draws the picture the context provides', () async {
      final image = await halves();
      addTearDown(image.dispose);
      final asked = <String>[];

      final pixels = await _Pixels.ofObject(
        sticker,
        NoteObjectPaintContext(
          imageLookup: (source) {
            asked.add(source);

            return image;
          },
        ),
      );

      expect(asked, ['flag']);
      expect(pixels.at(20, 30), _red);
      expect(pixels.at(80, 30), _blue);
    });

    test('mirrors the picture left to right', () async {
      final image = await halves();
      addTearDown(image.dispose);

      final pixels = await _Pixels.ofObject(
        sticker.copyWith(flipHorizontal: true),
        NoteObjectPaintContext(imageLookup: (_) => image),
      );

      expect(pixels.at(20, 30), _blue);
      expect(pixels.at(80, 30), _red);
    });

    test('keeps the aspect ratio', () async {
      final image = await halves();
      addTearDown(image.dispose);

      // A 2:1 picture in a square area leaves bands above and below.
      final pixels = await _Pixels.ofObject(
        sticker.copyWith(bounds: const Rect.fromLTWH(10, 10, 80, 80)),
        NoteObjectPaintContext(imageLookup: (_) => image),
      );

      expect(pixels.alphaAt(30, 20), 0);
      expect(pixels.at(30, 50), _red);
      expect(pixels.alphaAt(30, 80), 0);
    });

    test('an empty area draws nothing', () async {
      final pixels = await _Pixels.ofObject(
        sticker.copyWith(bounds: const Rect.fromLTWH(10, 10, 0, 40)),
      );

      expect(pixels.isBlank, isTrue);
    });
  });
}
