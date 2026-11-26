import 'dart:math' as math;

import 'package:fake_async/fake_async.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/scribble.notifier.dart';
import 'package:open_note/src/module/scribble_mode.notifier.dart';
import 'package:open_note/src/module/state/scribble.state.dart';
import 'package:open_note/src/module/state/scribble_input_options.dart';
import 'package:open_note/src/module/state/scribble_mode.state.dart';

/// open_note 엔진 확장 검증: 펜 설정 · 선 스타일 · 부분 지우개 · 필압 지우개 ·
/// 사각 올가미 · 정지 도형 보정 · 손글씨 재스타일.
ScribbleModeState _mode(
  String ink, {
  ScribbleInputOptions options = ScribbleInputOptions.standard,
  double width = 2,
  double eraserWidth = 4,
}) {
  final info = InkGroupInfo(selectedInk: ink)
    ..setStrokeBox({ink: width, InkModes.erase: eraserWidth});

  return ScribbleModeState(inkGroupInfo: info, inputOptions: options);
}

const _stylus = PointerDeviceKind.stylus;

PointerDownEvent _down(
  Offset at, {
  double pressure = 0.3,
  double pressureMin = 0,
  double pressureMax = 1,
}) => PointerDownEvent(
  pointer: 1,
  position: at,
  kind: _stylus,
  pressure: pressure,
  pressureMin: pressureMin,
  pressureMax: pressureMax,
);

PointerMoveEvent _move(Offset at, {double pressure = 0.3}) => PointerMoveEvent(
  pointer: 1,
  position: at,
  kind: _stylus,
  pressure: pressure,
  pressureMin: 0,
  pressureMax: 1,
);

PointerUpEvent _up(Offset at, {double pressure = 0}) => PointerUpEvent(
  pointer: 1,
  position: at,
  kind: _stylus,
  pressure: pressure,
  pressureMin: 0,
  pressureMax: 1,
);

/// 한 획을 그린다: 첫 점에서 눌러 나머지 점을 지나 마지막 점에서 뗀다.
void _draw(ScribbleNotifier notifier, ScribbleModeState mode, List<Offset> at) {
  notifier.onPointerDown(_down(at.first), mode);
  for (final point in at.skip(1).take(at.length - 2)) {
    notifier.onPointerUpdate(_move(point), mode);
  }
  notifier.onPointerUp(_up(at.last), mode);
}

Stroke _line(
  Offset from,
  Offset to, {
  String id = 'a',
  String shapeType = '',
}) => Stroke(
  id: id,
  ink: InkModes.pencil,
  color: 0xFF000000,
  width: 2,
  shapeType: shapeType,
  options: StrokeOptions(size: 2),
  points: [
    Point(x: from.dx, y: from.dy, p: 0.5),
    Point(x: to.dx, y: to.dy, p: 0.5),
  ],
);

ScribbleNotifier _notifierWith(List<Stroke> strokes) {
  var counter = 0;

  return ScribbleNotifier(
    scribble: Scribble(strokes: strokes),
    strokeIdFactory: () => 'new-${counter++}',
  );
}

void main() {
  group('입력 옵션 기본값', () {
    test('지정하지 않으면 스트로크 옵션이 open_board 와 같고 새 필드는 비운다', () {
      final notifier = ScribbleNotifier();
      final mode = _mode(InkModes.pen);

      _draw(notifier, mode, const [Offset(0, 0), Offset(20, 0), Offset(40, 0)]);

      final stroke = notifier.currentScribble.strokes.single;
      expect(stroke.options.streamline, 0.5);
      expect(stroke.options.smoothing, 0.5);
      expect(stroke.options.thinning, 0.9);
      expect(stroke.hasLineStyle(), isFalse);
      expect(stroke.hasShapeStyle(), isFalse);
    });

    test('모드 설정자는 입력 옵션을 보존한다', () {
      const options = ScribbleInputOptions(
        eraserMode: ScribbleEraserMode.pixel,
        lineStyle: 'wavy:1:6',
      );
      final mode = ScribbleModeNotifier()..setInputOptions(options);

      mode
        ..setPen()
        ..setColor(const Color(0xFF123456))
        ..setStrokeWidth(3)
        ..setScaleFactor(2)
        ..setShapeType('ellipse')
        ..setAllowedPointersMode(ScribblePointerMode.penOnly)
        ..setEraser();

      expect(mode.state.inputOptions, options);
      expect(mode.state.inkGroupInfo.selectedInk, InkModes.erase);
    });

    test('같은 옵션을 다시 설정하면 알리지 않는다', () {
      final mode = ScribbleModeNotifier();
      var notified = 0;
      mode.addListener(() => notified++);

      mode.setInputOptions(const ScribbleInputOptions());
      mode.setInputOptions(const ScribbleInputOptions(rectangleLasso: true));
      mode.setInputOptions(const ScribbleInputOptions(rectangleLasso: true));

      expect(notified, 1);
    });
  });

  group('펜 설정 · 선 스타일', () {
    test('획 안정화 · 스무딩 · 두께 폭을 새 스트로크에 싣는다', () {
      final notifier = ScribbleNotifier();
      final mode = _mode(
        InkModes.pen,
        options: const ScribbleInputOptions(
          pen: ScribblePenParams(
            streamline: 0.8,
            smoothing: 0.2,
            thinningScale: 0.5,
          ),
        ),
      );

      _draw(notifier, mode, const [Offset(0, 0), Offset(20, 0), Offset(40, 0)]);

      final options = notifier.currentScribble.strokes.single.options;
      expect(options.streamline, 0.8);
      expect(options.smoothing, 0.2);
      expect(options.thinning, closeTo(0.45, 1e-9));
    });

    test('thinning 배율이 커도 0.99 를 넘지 않는다', () {
      final notifier = ScribbleNotifier();
      final mode = _mode(
        InkModes.pen,
        options: const ScribbleInputOptions(
          pen: ScribblePenParams(thinningScale: 1.5),
        ),
      );

      _draw(notifier, mode, const [Offset(0, 0), Offset(20, 0), Offset(40, 0)]);

      expect(notifier.currentScribble.strokes.single.options.thinning, 0.99);
    });

    test('필압 감마는 하드웨어 필압에 곡선 뒤에 적용한다', () {
      double firstPressure(double gamma) {
        final notifier = ScribbleNotifier();
        final mode = _mode(
          InkModes.pen,
          options: ScribbleInputOptions(
            pen: ScribblePenParams(pressureGamma: gamma),
          ),
        );
        notifier.onPointerDown(_down(Offset.zero, pressure: 0.5), mode);

        return (notifier.state as Drawing).activeLine!.points.first.p;
      }

      // 곡선 1-(1-0.5)^2 = 0.75
      expect(firstPressure(1), closeTo(0.75, 1e-9));
      expect(firstPressure(2), closeTo(0.5625, 1e-9));
      expect(firstPressure(0.5), closeTo(math.sqrt(0.75), 1e-9));
    });

    test('필압 없는 입력의 중립값(0.5)에는 감마를 적용하지 않는다', () {
      final notifier = ScribbleNotifier();
      final mode = _mode(
        InkModes.pen,
        options: const ScribbleInputOptions(
          pen: ScribblePenParams(pressureGamma: 2),
        ),
      );

      notifier.onPointerDown(
        _down(Offset.zero, pressure: 1, pressureMin: 1),
        mode,
      );

      expect((notifier.state as Drawing).activeLine!.points.first.p, 0.5);
    });

    test('선 스타일은 필기 잉크에, 도형 스타일은 도형에만 싣는다', () {
      const options = ScribbleInputOptions(
        lineStyle: 'dashed:1.4:1.6',
        shapeStyle: '{"fill":1}',
      );
      Stroke drawn(String ink) {
        final notifier = ScribbleNotifier();
        notifier.onPointerDown(
          _down(Offset.zero),
          _mode(ink, options: options),
        );

        return (notifier.state as Drawing).activeLine!;
      }

      for (final ink in [
        InkModes.pen,
        InkModes.pencil,
        InkModes.marker,
        InkModes.fixedPen,
        InkModes.uniformPen,
      ]) {
        expect(drawn(ink).lineStyle, 'dashed:1.4:1.6', reason: ink);
        expect(drawn(ink).hasShapeStyle(), isFalse, reason: ink);
      }
      expect(drawn(InkModes.shape).lineStyle, 'dashed:1.4:1.6');
      expect(drawn(InkModes.shape).shapeStyle, '{"fill":1}');
      expect(drawn(InkModes.lasso).hasLineStyle(), isFalse);
    });
  });

  group('부분(픽셀) 지우개', () {
    const pixel = ScribbleInputOptions(eraserMode: ScribbleEraserMode.pixel);

    void eraseAcross(ScribbleNotifier notifier, ScribbleModeState mode) {
      notifier
        ..setEraser()
        ..onPointerDown(_down(const Offset(150, -30)), mode)
        ..onPointerUpdate(_move(const Offset(150, 30)), mode)
        ..onPointerUp(_up(const Offset(150, 30)), mode);
    }

    test('성긴 직선의 가운데만 지워 두 조각으로 남기고 undo 한 번에 복구한다', () {
      final original = _line(const Offset(0, 0), const Offset(300, 0));
      final notifier = _notifierWith([original]);
      final mode = _mode(InkModes.erase, options: pixel);

      eraseAcross(notifier, mode);

      final pieces = notifier.currentScribble.strokes;
      expect(pieces, hasLength(2));
      expect(pieces.map((s) => s.id).toSet(), {'new-0', 'new-1'});
      expect(pieces.first.points.first.x, 0);
      expect(pieces.first.points.last.x, lessThan(150));
      expect(pieces.last.points.first.x, greaterThan(150));
      expect(pieces.last.points.last.x, 300);
      expect(pieces.every((s) => s.color == original.color), isTrue);
      // 지운 구간은 지우개 반경 근처로 좁다.
      expect(
        pieces.last.points.first.x - pieces.first.points.last.x,
        lessThan(20),
      );

      expect(notifier.canUndo, isTrue);
      notifier.undo();

      expect(notifier.currentScribble.strokes.single.id, 'a');
      expect(notifier.canUndo, isFalse);
    });

    test('개수가 그대로여도 내용이 바뀌면 커밋한다', () {
      // 끝을 잘라내면 조각이 하나만 남는다 — 스트로크 수는 1 로 같다.
      final notifier = _notifierWith([
        _line(const Offset(0, 0), const Offset(150, 0)),
      ]);

      eraseAcross(notifier, _mode(InkModes.erase, options: pixel));

      expect(notifier.currentScribble.strokes, hasLength(1));
      expect(
        notifier.currentScribble.strokes.single.points.last.x,
        lessThan(150),
      );
      expect(notifier.canUndo, isTrue);
    });

    test('닿지 않은 스트로크는 같은 인스턴스로 남고 빈 지우기는 기록하지 않는다', () {
      final far = _line(const Offset(0, 200), const Offset(100, 200));
      final notifier = _notifierWith([far]);

      eraseAcross(notifier, _mode(InkModes.erase, options: pixel));

      expect(notifier.currentScribble.strokes.single, same(far));
      expect(notifier.canUndo, isFalse);
    });

    test('도형은 점으로 나눌 수 없어 통째로 지운다', () {
      final notifier = _notifierWith([
        _line(const Offset(0, 0), const Offset(300, 0), shapeType: 'line'),
      ]);

      eraseAcross(notifier, _mode(InkModes.erase, options: pixel));

      expect(notifier.currentScribble.strokes, isEmpty);
    });

    test('기본(스트로크) 지우개는 종전처럼 통째로 지운다', () {
      final notifier = _notifierWith([
        _line(const Offset(0, 0), const Offset(300, 0)),
      ]);

      eraseAcross(notifier, _mode(InkModes.erase));

      expect(notifier.currentScribble.strokes, isEmpty);
    });
  });

  group('필압 지우개', () {
    const options = ScribbleInputOptions(
      pressureEraser: true,
      pressureEraserThreshold: 0.8,
    );

    test('필기 중 세게 누르면 그 제스처가 지우개가 되고 떼면 필기로 돌아온다', () {
      final existing = _line(const Offset(0, 50), const Offset(200, 50));
      final notifier = _notifierWith([existing]);
      final mode = _mode(InkModes.pen, options: options);

      notifier
        ..onPointerDown(_down(const Offset(100, 0)), mode)
        ..onPointerUpdate(_move(const Offset(100, 10)), mode)
        ..onPointerUpdate(_move(const Offset(100, 20), pressure: 0.95), mode)
        ..onPointerUpdate(_move(const Offset(100, 80), pressure: 0.95), mode);
      expect(notifier.state, isA<Erasing>());
      notifier.onPointerUp(_up(const Offset(100, 80)), mode);

      expect(notifier.state, isA<Drawing>());
      expect((notifier.state as Drawing).activeLine, isNull);
      expect(notifier.currentScribble.strokes, isEmpty);
      notifier.undo();
      expect(notifier.currentScribble.strokes.single.id, 'a');
      expect(notifier.state, isA<Drawing>());
    });

    test('아무것도 지우지 않은 필압 지우기는 히스토리를 남기지 않는다', () {
      final notifier = _notifierWith([]);
      final mode = _mode(InkModes.pen, options: options);

      notifier
        ..onPointerDown(_down(const Offset(0, 0)), mode)
        ..onPointerUpdate(_move(const Offset(5, 0), pressure: 0.95), mode)
        ..onPointerUp(_up(const Offset(5, 0)), mode);

      expect(notifier.state, isA<Drawing>());
      expect(notifier.currentScribble.strokes, isEmpty);
      expect(notifier.canUndo, isFalse);
    });

    test('꺼져 있으면(기본) 세게 눌러도 그대로 그린다', () {
      final notifier = ScribbleNotifier();
      final mode = _mode(InkModes.pen);

      notifier
        ..onPointerDown(_down(const Offset(0, 0)), mode)
        ..onPointerUpdate(_move(const Offset(20, 0), pressure: 1), mode)
        ..onPointerUp(_up(const Offset(40, 0)), mode);

      expect(notifier.currentScribble.strokes, hasLength(1));
    });

    test('포인터가 화면을 벗어나도 필기 상태로 돌아온다', () {
      final notifier = _notifierWith([
        _line(const Offset(0, 50), const Offset(200, 50)),
      ]);
      final mode = _mode(InkModes.pen, options: options);

      notifier
        ..onPointerDown(_down(const Offset(100, 0)), mode)
        ..onPointerUpdate(_move(const Offset(100, 40), pressure: 0.9), mode)
        ..onPointerUpdate(_move(const Offset(100, 90), pressure: 0.9), mode)
        ..onPointerExit(
          const PointerExitEvent(pointer: 1, kind: _stylus),
          mode,
        );

      expect(notifier.state, isA<Drawing>());
      expect(notifier.currentScribble.strokes, isEmpty);
    });
  });

  group('사각 올가미', () {
    test('드래그한 대각선을 닫힌 사각형으로 만들어 안의 스트로크를 고른다', () {
      final inside = _line(const Offset(20, 20), const Offset(60, 60));
      final notifier = _notifierWith([inside]);
      final mode = _mode(
        InkModes.lasso,
        options: const ScribbleInputOptions(rectangleLasso: true),
      );

      notifier
        ..onPointerDown(_down(const Offset(0, 0)), mode)
        ..onPointerUpdate(_move(const Offset(50, 10)), mode)
        ..onPointerUpdate(_move(const Offset(90, 90)), mode)
        ..onPointerUp(_up(const Offset(100, 100)), mode);

      final lasso = notifier.currentScribble.strokes.singleWhere(
        (s) => s.ink == InkModes.lasso,
      );
      expect(lasso.points.map((p) => Offset(p.x, p.y)), const [
        Offset(0, 0),
        Offset(100, 0),
        Offset(100, 100),
        Offset(0, 100),
        Offset(0, 0),
      ]);
    });

    test('안에 아무것도 없으면 올가미를 지운다', () {
      final notifier = _notifierWith([
        _line(const Offset(300, 300), const Offset(340, 340)),
      ]);
      final mode = _mode(
        InkModes.lasso,
        options: const ScribbleInputOptions(rectangleLasso: true),
      );

      notifier
        ..onPointerDown(_down(const Offset(0, 0)), mode)
        ..onPointerUpdate(_move(const Offset(40, 40)), mode)
        ..onPointerUp(_up(const Offset(50, 50)), mode);

      expect(
        notifier.currentScribble.strokes.where((s) => s.ink == InkModes.lasso),
        isEmpty,
      );
    });
  });

  group('정지 도형 보정', () {
    List<Offset> circle(Offset center, double radius) => [
      for (var i = 0; i <= 40; i++)
        center +
            Offset(
              math.cos(i / 40 * 2 * math.pi) * radius,
              math.sin(i / 40 * 2 * math.pi) * radius,
            ),
    ];

    void drawAndHold(
      ScribbleNotifier notifier,
      ScribbleModeState mode,
      FakeAsync async,
    ) {
      final points = circle(const Offset(200, 200), 80);
      notifier.onPointerDown(_down(points.first), mode);
      for (final point in points.skip(1)) {
        notifier.onPointerUpdate(_move(point), mode);
      }
      async.elapse(ScribbleNotifier.kPenStraightenDelay);
      async.flushMicrotasks();
    }

    test('손그림 원을 멈추고 있으면 도형이 되고 이후 이동은 무시한다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _mode(
          InkModes.pen,
          options: const ScribbleInputOptions(holdToSnapShapes: true),
        );
        drawAndHold(notifier, mode, async);

        final snapped = (notifier.state as Drawing).activeLine!;
        expect(snapped.shapeType, anyOf('circle', 'ellipse'));
        expect(snapped.ink, InkModes.shape);

        final before = snapped.points.length;
        final moved = notifier.onPointerUpdate(
          _move(const Offset(500, 500)),
          mode,
        );
        expect(moved, isFalse);
        expect((notifier.state as Drawing).activeLine!.points.length, before);

        notifier.onPointerUp(_up(const Offset(500, 500)), mode);
        final committed = notifier.currentScribble.strokes.single;
        expect(committed.shapeType, anyOf('circle', 'ellipse'));
        expect(committed.points.length, before);
      });
    });

    test('꺼져 있으면(기본) 종전처럼 직선으로 편다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        drawAndHold(notifier, _mode(InkModes.pen), async);

        final line = (notifier.state as Drawing).activeLine!;
        expect(line.points, hasLength(2));
        expect(line.shapeType, isEmpty);
      });
    });
  });

  group('획 위치 보정 (자 맞춤)', () {
    ScribbleNotifier constrained() => _notifierWith([])
      ..strokeConstraintFor = (start) => start.dy > 90 && start.dy < 110
          ? (point) => Offset(point.dx, 100)
          : null;

    test('보정 대상에서 시작한 획의 모든 점이 선 위에 놓인다', () {
      final notifier = constrained();

      _draw(notifier, _mode(InkModes.pen), const [
        Offset(10, 105),
        Offset(40, 130),
        Offset(80, 70),
        Offset(120, 95),
      ]);

      final points = notifier.currentScribble.strokes.single.points;
      expect(points, hasLength(greaterThan(2)));
      expect(points.map((point) => point.y), everyElement(100));
      expect(points.last.x, 120);
    });

    test('멀리서 시작한 획 · 다음 획 · 지우개는 보정하지 않는다', () {
      final notifier = constrained();
      _draw(notifier, _mode(InkModes.pen), const [
        Offset(10, 105),
        Offset(60, 104),
        Offset(90, 103),
      ]);
      _draw(notifier, _mode(InkModes.pen), const [
        Offset(10, 200),
        Offset(40, 230),
        Offset(80, 170),
      ]);

      final free = notifier.currentScribble.strokes.last.points;
      expect(free.first.y, 200);
      expect(free.last.y, 170);

      notifier.setEraser();
      // 지우개는 보정하지 않으므로 아래 획(y 170~230)을 지운다.
      _draw(notifier, _mode(InkModes.erase), const [
        Offset(40, 105),
        Offset(40, 215),
        Offset(40, 260),
      ]);
      expect(notifier.currentScribble.strokes, hasLength(1));
      expect(
        notifier.currentScribble.strokes.single.points.map((p) => p.y),
        everyElement(100),
      );
    });
  });

  group('손글씨 재스타일 · 외곽선', () {
    test('색 · 두께 · 선 스타일을 바꾸고 새 id 를 주며 undo 한 번에 복구', () {
      final a = _line(const Offset(0, 0), const Offset(10, 0));
      final b = _line(const Offset(0, 10), const Offset(10, 10), id: 'b');
      final notifier = _notifierWith([a, b]);

      notifier.restyleStrokes(
        [1, 1, 7, -1],
        color: 0xFFFF0000,
        width: 6,
        lineStyle: 'dotted:0.1:1.6',
      );

      final strokes = notifier.currentScribble.strokes;
      expect(strokes.first, same(a));
      expect(strokes.last.id, 'new-0');
      expect(strokes.last.color, 0xFFFF0000);
      expect(strokes.last.width, 6);
      expect(strokes.last.options.size, 6);
      expect(strokes.last.lineStyle, 'dotted:0.1:1.6');
      expect(b.color, 0xFF000000, reason: '원본은 변형하지 않는다');

      notifier.undo();
      expect(notifier.currentScribble.strokes.last.id, 'b');
      expect(notifier.canUndo, isFalse);
    });

    test('함께 고른 글상자는 색만 바뀌고 같은 undo 단계에 묶인다', () {
      final stroke = _line(const Offset(0, 0), const Offset(10, 0));
      final notifier = ScribbleNotifier(
        scribble: Scribble(
          strokes: [stroke],
          textDrawables: [TextDrawable(id: 't', text: '메모', color: 0xFF000000)],
        ),
      );
      addTearDown(notifier.dispose);

      notifier.restyleStrokes([0], color: 0xFF0000FF, textIndexes: [0, 9]);

      final text = notifier.currentScribble.textDrawables.single;
      expect(text.color, 0xFF0000FF);
      expect(notifier.currentScribble.strokes.single.color, 0xFF0000FF);

      notifier.undo();
      expect(notifier.currentScribble.textDrawables.single.color, 0xFF000000);
      expect(notifier.canUndo, isFalse);
    });

    test("lineStyle '' 은 실선으로 되돌린다", () {
      final dashed = _line(const Offset(0, 0), const Offset(10, 0))
        ..lineStyle = 'dashed';
      final notifier = _notifierWith([dashed]);

      notifier.restyleStrokes([0], lineStyle: '');

      expect(notifier.currentScribble.strokes.single.hasLineStyle(), isFalse);
    });

    test('바꿀 것이 없거나 올가미 선뿐이면 아무것도 하지 않는다', () {
      // 생성자는 올가미 선을 지우므로, 생성한 뒤에 (히스토리 없이) 넣는다.
      final lasso = _line(const Offset(0, 0), const Offset(10, 0))
        ..ink = InkModes.lasso;
      final notifier = _notifierWith([])
        ..setScribble(
          scribble: Scribble(strokes: [lasso]),
          addToUndoHistory: false,
        );

      notifier
        ..restyleStrokes([0], color: 0xFFFF0000)
        ..restyleStrokes([0])
        ..restyleStrokes([5], color: 0xFFFF0000)
        ..outlineStrokes([0], color: 0xFFFF0000);

      expect(notifier.canUndo, isFalse);
      expect(notifier.currentScribble.strokes.single, same(lasso));
    });

    test('외곽선은 선택 전체의 아래에 끼워 넣는다', () {
      final a = _line(const Offset(0, 0), const Offset(10, 0));
      final b = _line(const Offset(5, 0), const Offset(15, 0), id: 'b');
      final c = _line(const Offset(0, 90), const Offset(10, 90), id: 'c');
      final notifier = _notifierWith([c, a, b]);

      notifier.outlineStrokes([2, 1], color: 0xFFFFFF00, extraWidth: 4);

      final strokes = notifier.currentScribble.strokes;
      expect(strokes.map((s) => s.id), ['c', 'new-0', 'new-1', 'a', 'b']);
      expect(strokes[1].color, 0xFFFFFF00);
      expect(strokes[1].options.size, 6);
      expect(strokes[3].color, 0xFF000000);
    });
  });
}
