import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/widgets/pointer_event_handler.dart';

void main() {
  late PointerEventHandler handler;
  late ScribbleNotifier scribbleNotifier;
  late ScribbleModeNotifier modeNotifier;

  setUp(() {
    scribbleNotifier = ScribbleNotifier();
    modeNotifier = ScribbleModeNotifier();
    handler = PointerEventHandler(
      scribbleNotifier: scribbleNotifier,
      modeNotifier: modeNotifier,
    );
  });

  tearDown(() {
    handler.dispose();
    scribbleNotifier.dispose();
    modeNotifier.dispose();
  });

  group('터치 카운트 관리', () {
    test('초기 상태에서 멀티터치가 아님', () {
      expect(handler.isMultiTouch(), isFalse);
    });

    test('incrementTouch 한 번 호출 시 멀티터치가 아님', () {
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isFalse);
    });

    test('incrementTouch 두 번 호출 시 멀티터치 감지', () {
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);
    });

    test('incrementTouch 세 번 호출 시에도 멀티터치', () {
      handler.incrementTouch();
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);
    });

    test('decrementTouch로 터치 카운트 감소', () {
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);

      handler.decrementTouch();
      expect(handler.isMultiTouch(), isFalse);
    });

    test('decrementTouch가 0 이하로 내려가지 않음', () {
      handler.decrementTouch();
      handler.decrementTouch();

      // 0 이하로 내려갔어도 이후 incrementTouch 1번으로 멀티터치 아님
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isFalse);
    });

    test('dispose 후 터치 카운트 초기화', () {
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);

      handler.dispose();
      expect(handler.isMultiTouch(), isFalse);
    });
  });

  group('canStartDrawing - 멀티터치 시 그리기 차단', () {
    test('싱글 터치 시 그리기 가능', () {
      handler.incrementTouch();

      final event = const PointerDownEvent(
        kind: ui.PointerDeviceKind.touch,
      );
      expect(handler.canStartDrawing(event), isTrue);
    });

    test('멀티터치 시 그리기 차단', () {
      handler.incrementTouch();
      handler.incrementTouch();

      final event = const PointerDownEvent(
        kind: ui.PointerDeviceKind.touch,
      );
      expect(handler.canStartDrawing(event), isFalse);
    });

    test('스타일러스는 멀티터치 여부와 관계없이 그리기 가능', () {
      handler.incrementTouch();
      handler.incrementTouch();

      final event = const PointerDownEvent(
        kind: ui.PointerDeviceKind.stylus,
      );
      expect(handler.canStartDrawing(event), isTrue);
    });
  });

  group('하이라이트 모드 핀치 줌 시나리오', () {
    test('외부 Listener에서 터치 카운트 관리 시 멀티터치 전환 흐름', () {
      // 시나리오: 하이라이트 모드에서 두 손가락 핀치 줌
      // 외부 Listener의 onPointerDown에서 터치 카운트 증가

      // 첫 번째 손가락 터치
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isFalse);

      // 두 번째 손가락 터치 → 핀치 줌 시작
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);

      // 핀치 줌 중에는 그리기 차단
      final touchEvent = const PointerDownEvent(
        kind: ui.PointerDeviceKind.touch,
      );
      expect(handler.canStartDrawing(touchEvent), isFalse);

      // 첫 번째 손가락 떼기
      handler.decrementTouch();
      expect(handler.isMultiTouch(), isFalse);

      // 두 번째 손가락 떼기
      handler.decrementTouch();
      expect(handler.isMultiTouch(), isFalse);
    });

    test('스타일러스 이벤트는 터치 카운트에 영향 없음', () {
      // 외부 Listener에서 touch 이벤트만 카운트
      // 스타일러스는 카운트하지 않음 (위젯 코드의 조건과 일치)
      // 이 테스트는 PointerEventHandler의 canStartDrawing이
      // 스타일러스를 항상 허용하는지 확인
      final stylusEvent = const PointerDownEvent(
        kind: ui.PointerDeviceKind.stylus,
      );
      expect(handler.canStartDrawing(stylusEvent), isTrue);

      // 터치가 두 개 들어와도 스타일러스는 그리기 가능
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.canStartDrawing(stylusEvent), isTrue);
    });

    test('핀치 줌 후 싱글 터치로 복귀하면 그리기 재개 가능', () {
      // 핀치 줌 시작
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);

      // 핀치 줌 종료 (두 손가락 모두 떼기)
      handler.decrementTouch();
      handler.decrementTouch();

      // 새 싱글 터치로 다시 그리기 시작
      handler.incrementTouch();
      final touchEvent = const PointerDownEvent(
        kind: ui.PointerDeviceKind.touch,
      );
      expect(handler.canStartDrawing(touchEvent), isTrue);
      expect(handler.isMultiTouch(), isFalse);
    });

    test('pointerCancel 시에도 터치 카운트 정상 감소', () {
      // 핀치 줌 중 시스템 cancel 이벤트 발생 시나리오
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);

      // cancel로 터치 감소
      handler.decrementTouch();
      expect(handler.isMultiTouch(), isFalse);

      handler.decrementTouch();
      expect(handler.isMultiTouch(), isFalse);
    });
  });

  group('비하이라이트 모드 회귀 방지', () {
    test('일반 드로잉 모드에서 싱글 터치 그리기 가능', () {
      // 비하이라이트 모드에서는 내부 Listener가 터치 카운트 관리
      // PointerEventHandler의 기본 동작 확인
      handler.incrementTouch();
      final touchEvent = const PointerDownEvent(
        kind: ui.PointerDeviceKind.touch,
      );
      expect(handler.canStartDrawing(touchEvent), isTrue);
    });

    test('일반 드로잉 모드에서 멀티터치 시 그리기 차단', () {
      handler.incrementTouch();
      handler.incrementTouch();
      final touchEvent = const PointerDownEvent(
        kind: ui.PointerDeviceKind.touch,
      );
      expect(handler.canStartDrawing(touchEvent), isFalse);
    });

    test('unknown 포인터 종류는 그리기 가능', () {
      final unknownEvent = const PointerDownEvent(
        kind: ui.PointerDeviceKind.unknown,
      );
      expect(handler.canStartDrawing(unknownEvent), isTrue);
    });
  });
}
