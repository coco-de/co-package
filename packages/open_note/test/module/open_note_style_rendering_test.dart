import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/painter/shape_paint_delegate.dart';
import 'package:open_note/src/module/painter/stroke_paint_delegate.dart';
import 'package:open_note/src/module/painter/stroke_styles.dart';
import 'package:open_note/src/module/scribble.notifier.dart';
import 'package:open_note/src/module/state/scribble_mode.state.dart';
import 'package:open_note/src/module/text/text_painter.dart';
import 'package:open_note/src/note/core/note_page_size.dart';
import 'package:open_note/src/note/io/pdf/note_styled_vectorizer.dart';
import 'package:open_note/src/note/io/pdf/note_vector_segment.dart';
import 'package:open_note/src/note/io/render/note_page_render_input.dart';
import 'package:open_note/src/note/io/render/note_page_render_layer.dart';
import 'package:open_note/src/note/io/render/note_page_renderer.dart';
import 'package:open_note/src/note/style/note_image_style.dart';
import 'package:open_note/src/note/style/note_image_crop.dart';
import 'package:open_note/src/note/style/note_line_style_kind.dart';
import 'package:open_note/src/note/style/note_shape_kind.dart';
import 'package:open_note/src/note/style/note_shape_style.dart';
import 'package:open_note/src/note/style/note_text_box_style.dart';

/// open_note: 선 · 도형 · 텍스트 상자 · 이미지 스타일이 화면(엔진 페인터) ·
/// 지우개 · PDF 벡터 내보내기에 반영되는지 **픽셀과 기하**로 확인한다.
const _width = 200;
const _height = 100;
const _black = 0xFF000000;

Future<Uint8List> _render(void Function(ui.Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(_width, _height);
  final data = await image.toByteData();
  image.dispose();

  return data!.buffer.asUint8List();
}

Color _pixel(Uint8List pixels, int x, int y) {
  final i = (y * _width + x) * 4;

  return Color.fromARGB(pixels[i + 3], pixels[i], pixels[i + 1], pixels[i + 2]);
}

bool _inked(Uint8List pixels, int x, int y) => _pixel(pixels, x, y).a > 0.5;

/// y 행에서 x ∈ [from, to] 중 칠해진 비율.
double _coverage(Uint8List pixels, int y, int from, int to) {
  var count = 0;
  for (var x = from; x <= to; x++) {
    if (_inked(pixels, x, y)) count++;
  }

  return count / (to - from + 1);
}

Stroke _horizontal(String ink, {String lineStyle = '', double size = 4}) =>
    Stroke(
      ink: ink,
      color: _black,
      lineStyle: lineStyle,
      options: StrokeOptions(size: size, isComplete: true),
      points: [
        for (var x = 10; x <= 190; x += 10)
          Point(x: x.toDouble(), y: 50, p: 0.5),
      ],
    );

Stroke _shape(String type, {String shapeStyle = '', String lineStyle = ''}) =>
    Stroke(
      id: type,
      ink: InkModes.shape,
      color: _black,
      shapeType: type,
      shapeStyle: shapeStyle,
      lineStyle: lineStyle,
      options: StrokeOptions(size: 3),
      points: [Point(x: 40, y: 10), Point(x: 160, y: 90)],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('선 스타일', () {
    for (final ink in [InkModes.pen, InkModes.pencil, InkModes.fixedPen]) {
      test('$ink: 점선은 간격을 두고, 실선은 빈틈없이 그린다', () async {
        final solid = await _render(
          (canvas) => const StrokePaintDelegate(
            strokes: [],
          ).drawStroke(canvas, _horizontal(ink)),
        );
        final dashed = await _render(
          (canvas) => const StrokePaintDelegate(
            strokes: [],
          ).drawStroke(canvas, _horizontal(ink, lineStyle: 'dashed:2:2')),
        );

        expect(_coverage(solid, 50, 20, 180), greaterThan(0.97));
        expect(_coverage(dashed, 50, 20, 180), inInclusiveRange(0.3, 0.7));
      });
    }

    test('마커의 점선은 두 배 두께와 투명한 색을 유지한다', () async {
      // 엔진은 지정된 파스텔 5색에만 마커 투명도를 준다 — 파스텔 노랑.
      final stroke = _horizontal(InkModes.marker, lineStyle: 'dashed:3:2')
        ..color = 0xFFFAF4C0;
      final pixels = await _render(
        (canvas) =>
            const StrokePaintDelegate(strokes: []).drawStroke(canvas, stroke),
      );
      // 마커 알파는 약 0.5 라 마커 검사만 낮은 기준을 쓴다.
      List<Color> painted(int y) => [
        for (var x = 20; x <= 180; x++)
          if (_pixel(pixels, x, y).a > 0.3) _pixel(pixels, x, y),
      ];

      expect(painted(50), isNotEmpty);
      expect(painted(50).first.a, closeTo(0.5, 0.05));
      expect(painted(50).length / 161, inInclusiveRange(0.3, 0.8));
      // 두께 8(= 4 × 2): 중심에서 3 px 떨어진 곳도 칠해진 구간이 있다.
      expect(painted(47).length / 161, greaterThan(0.3));
    });

    test('이중선은 가운데가 비고 위아래 두 줄이다', () async {
      final pixels = await _render(
        (canvas) => const StrokePaintDelegate(strokes: []).drawStroke(
          canvas,
          _horizontal(InkModes.pencil, lineStyle: 'double', size: 3),
        ),
      );

      expect(_coverage(pixels, 50, 30, 170), lessThan(0.1));
      final rows = [
        for (var y = 40; y <= 60; y++)
          if (_coverage(pixels, y, 30, 170) > 0.9) y,
      ];
      expect(rows.where((y) => y < 50), isNotEmpty);
      expect(rows.where((y) => y > 50), isNotEmpty);
    });
  });

  group('도형', () {
    test('엔진이 몰랐던 2점 도형(별)을 그린다', () async {
      final pixels = await _render(
        (canvas) => ShapePaintDelegate(
          strokes: [_shape('star')],
        ).paint(canvas, const Size(200, 100)),
      );

      var painted = 0;
      for (var y = 0; y < _height; y++) {
        for (var x = 0; x < _width; x++) {
          if (_inked(pixels, x, y)) painted++;
        }
      }
      expect(painted, greaterThan(300));
    });

    test('모든 노트 도형 종류가 2점 드래그로 그려진다', () async {
      for (final kind in NoteShapeKind.values) {
        final pixels = await _render(
          (canvas) => ShapePaintDelegate(
            strokes: [_shape(kind.name)],
          ).paint(canvas, const Size(200, 100)),
        );
        final any = Iterable<int>.generate(
          _width * _height,
        ).any((i) => pixels[i * 4 + 3] > 128);
        expect(any, isTrue, reason: kind.name);
      }
    });

    test('스타일 없는 사각형 · 타원은 종전처럼 외곽선만 그린다', () async {
      final pixels = await _render(
        (canvas) => ShapePaintDelegate(
          strokes: [_shape('rectangle')],
        ).paint(canvas, const Size(200, 100)),
      );

      expect(_inked(pixels, 100, 10), isTrue);
      expect(_inked(pixels, 100, 50), isFalse);
    });

    test('채움 스타일은 안을 칠한다', () async {
      final style = NoteShapeStyle(
        fillColor: Color(0xFFFF0000),
        fillOpacity: 1,
      ).encode();

      final pixels = await _render(
        (canvas) => ShapePaintDelegate(
          strokes: [_shape('rectangle', shapeStyle: style)],
        ).paint(canvas, const Size(200, 100)),
      );

      expect(_pixel(pixels, 100, 50), const Color(0xFFFF0000));
    });
  });

  group('지우개는 2점 도형을 윤곽으로 판정한다', () {
    bool erases(Stroke shape, Offset from, Offset to) {
      final notifier = ScribbleNotifier(scribble: Scribble(strokes: [shape]));
      final mode = ScribbleModeState(
        inkGroupInfo: InkGroupInfo(selectedInk: InkModes.erase)
          ..setStrokeBox({InkModes.erase: 2}),
      );
      notifier
        ..setEraser()
        ..onPointerDown(
          PointerDownEvent(position: from, kind: PointerDeviceKind.stylus),
          mode,
        )
        ..onPointerUpdate(
          PointerMoveEvent(position: to, kind: PointerDeviceKind.stylus),
          mode,
        )
        ..onPointerUp(
          PointerUpEvent(position: to, kind: PointerDeviceKind.stylus),
          mode,
        );

      return notifier.currentScribble.strokes.isEmpty;
    }

    test('사각형 윗변을 지나면 지우고, 안쪽 빈 곳만 지나면 남긴다', () {
      // 대각선 (40,10)-(160,90) 은 지나지 않는 윗변.
      expect(
        erases(
          _shape('rectangle'),
          const Offset(140, 0),
          const Offset(140, 20),
        ),
        isTrue,
      );
      // 대각선을 가로지르지만 어떤 변도 닿지 않는다.
      expect(
        erases(
          _shape('rectangle'),
          const Offset(90, 50),
          const Offset(110, 55),
        ),
        isFalse,
      );
    });

    test('타원의 왼쪽 끝을 지우면 지운다', () {
      expect(
        erases(_shape('ellipse'), const Offset(30, 50), const Offset(50, 50)),
        isTrue,
      );
    });
  });

  group('PDF 벡터 내보내기', () {
    int subpaths(Stroke stroke) {
      final shapes = NoteStyledVectorizer.vectorize(stroke)!;

      return shapes
          .expand((shape) => shape.path.segments)
          .whereType<NoteVectorMove>()
          .length;
    }

    test('스타일 없는 획은 일반 벡터화에 맡긴다', () {
      expect(NoteStyledVectorizer.vectorize(_horizontal('pen')), isNull);
      expect(NoteStyledVectorizer.vectorize(_shape('rectangle')), isNull);
    });

    test('점선 획은 여러 조각의 벡터 선이 된다', () {
      expect(
        subpaths(_horizontal('pen', lineStyle: 'dashed:2:2')),
        greaterThan(5),
      );
    });

    test('입체 도형은 숨은 모서리를 점선 조각으로 내보낸다', () {
      expect(subpaths(_shape('cube')), greaterThan(8));
    });

    test('채운 도형은 채움 도형을 먼저 낸다', () {
      final shapes = NoteStyledVectorizer.vectorize(
        _shape(
          'star',
          shapeStyle: NoteShapeStyle(fillColor: Color(0xFF00FF00)).encode(),
        ),
      )!;

      expect(shapes.first.filled, isTrue);
      expect(shapes.last.filled, isFalse);
    });
  });

  test('2점 도형 판별: 이름 변형과 여러 점 도형', () {
    expect(StrokeStyles.kindOfShapeType('circle'), NoteShapeKind.ellipse);
    expect(StrokeStyles.kindOfShapeType('square'), NoteShapeKind.rectangle);
    expect(StrokeStyles.kindOfShapeType('pending'), isNull);
    expect(
      StrokeStyles.twoPointShapeOf(
        _shape('star')..points.add(Point(x: 1, y: 1)),
      ),
      isNull,
    );
    expect(
      StrokeStyles.lineStyleOf(_horizontal('pen', lineStyle: 'solid')),
      isNull,
    );
    expect(
      StrokeStyles.lineStyleOf(_horizontal('pen', lineStyle: 'wavy:1:6'))!.kind,
      NoteLineStyleKind.wavy,
    );
  });

  group('텍스트 상자 스타일', () {
    TextDrawable text({String boxStyle = ''}) => TextDrawable(
      id: 't',
      text: 'ABC',
      x: 40,
      y: 50,
      fontSize: 20,
      color: _black,
      textAlign: 'left',
      boxStyle: boxStyle,
    );

    Future<Uint8List> paint(TextDrawable drawable) => _render(
      (canvas) => TextDrawablePainter(
        textDrawables: [drawable],
        selectedTextDrawable: null,
        isTransforming: false,
        editingTextId: null,
      ).paint(canvas, const Size(200, 100)),
    );

    test('배경과 여백을 글자 둘레에 칠한다', () async {
      final style = NoteTextBoxStyle(
        backgroundColor: Color(0xFF00FF00),
        padding: EdgeInsets.all(8),
      ).encode();
      final bounds = TextDrawablePainter.getTextBounds(text());
      final probeX = (bounds.left - 4).round();
      final probeY = bounds.center.dy.round();

      expect(_inked(await paint(text()), probeX, probeY), isFalse);
      expect(
        _pixel(await paint(text(boxStyle: style)), probeX, probeY),
        const Color(0xFF00FF00),
      );
    });

    test('줄 높이는 글자 상자 높이를 키운다', () {
      final normal = TextDrawablePainter.getTextBounds(text()).height;
      final tall = TextDrawablePainter.getTextBounds(
        text(boxStyle: NoteTextBoxStyle(lineHeight: 2).encode()),
      ).height;

      expect(tall, greaterThan(normal * 1.5));
    });
  });

  test('이미지 자르기 스타일은 내보내기에서도 남긴 부분만 그린다', () async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..drawRect(
        const Rect.fromLTWH(0, 0, 10, 10),
        Paint()..color = const Color(0xFFFF0000),
      )
      ..drawRect(
        const Rect.fromLTWH(10, 0, 10, 10),
        Paint()..color = const Color(0xFF0000FF),
      );
    final source = await recorder.endRecording().toImage(20, 10);
    addTearDown(source.dispose);
    final style = NoteImageStyle(
      crop: NoteImageCrop.rect(0.5, 0, 1, 1),
    ).encode();

    final image = await NotePageRenderer.renderToImage(
      NotePageRenderInput(
        size: const NotePageSize(100, 100),
        layers: [
          NotePageRenderLayer(
            scribble: Scribble(
              imageDrawables: [
                ImageDrawable(
                  id: 'i',
                  source: 'two-colors',
                  x: 10,
                  y: 10,
                  width: 80,
                  height: 80,
                  opacity: 1,
                  imageStyle: style,
                ),
              ],
            ),
          ),
        ],
        images: {'two-colors': source},
      ),
    );
    final data = (await image.toByteData())!.buffer.asUint8List();
    image.dispose();
    Color at(int x, int y) {
      final i = (y * 100 + x) * 4;

      return Color.fromARGB(data[i + 3], data[i], data[i + 1], data[i + 2]);
    }

    expect(at(20, 50), const Color(0xFF0000FF));
    expect(at(80, 50), const Color(0xFF0000FF));
  });
}
