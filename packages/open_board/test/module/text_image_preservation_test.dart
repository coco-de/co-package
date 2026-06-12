// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/extensions/scribble_extension.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/adapters/image_picker_adapter.dart';
import 'package:open_board/src/module/image/image_drawable_factory.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/text/text_drawable_manager.dart';

import '../helpers/test_helpers.dart';

/// 텍스트/이미지 데이터 보존 회귀 테스트.
///
/// 필기 기능 전면 재검토에서 확정된 결함들의 회귀 방지:
/// - Scribble을 필드 나열로 재구성하는 사이트들이 imageDrawables를 누락해
///   텍스트/스트로크 조작 한 번에 페이지의 모든 이미지가 소실되는 문제
/// - ImageDrawableFactory가 자연 해상도를 검증 없이 사용하는 문제
void main() {
  ImageDrawable sampleImage() => ImageDrawableFactory.create(
    id: 'img1',
    source: 'file:///tmp/a.png',
    position: const Offset(10, 10),
    size: const Size(100, 80),
  );

  Scribble scribbleWithImage() =>
      createScribble(
          strokes: [
            createStroke(points: [createPoint(x: 5, y: 5)]),
          ],
          textDrawables: [createTextDrawable(id: 't1')],
        )
        ..imageDrawables.add(sampleImage());

  group('copyWithContents — 미지정 필드 보존', () {
    test('strokes만 교체해도 텍스트/이미지/메타가 보존된다', () {
      final original = scribbleWithImage();
      final copied = original.copyWithContents(strokes: []);

      expect(copied.strokes, isEmpty);
      expect(copied.textDrawables.length, 1);
      expect(copied.imageDrawables.length, 1);
      expect(copied.createdAt, original.createdAt);
      expect(copied.width, original.width);
    });

    test('textDrawables만 교체해도 이미지가 보존된다', () {
      final original = scribbleWithImage();
      final copied = original.copyWithContents(textDrawables: []);

      expect(copied.textDrawables, isEmpty);
      expect(copied.imageDrawables.length, 1);
      expect(copied.strokes.length, 1);
    });
  });

  group('imageDrawables 보존 — 콘텐츠 조작 경로 전수', () {
    test('텍스트 add/update/remove 후 이미지가 보존된다', () {
      const manager = TextDrawableManager();
      var scribble = scribbleWithImage();

      scribble = manager.add(scribble, createTextDrawable(id: 't2'));
      expect(scribble.imageDrawables.length, 1, reason: 'add 후 이미지 소실');

      scribble = manager.update(
        scribble,
        't2',
        createTextDrawable(id: 't2', x: 99),
      );
      expect(scribble.imageDrawables.length, 1, reason: 'update 후 이미지 소실');

      scribble = manager.remove(scribble, 't2');
      expect(scribble.imageDrawables.length, 1, reason: 'remove 후 이미지 소실');
    });

    test('스트로크 완료(finishStroke) 후 이미지가 보존된다', () {
      final notifier = ScribbleNotifier(scribble: scribbleWithImage());
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setPen();

      notifier.onPointerDown(
        const PointerDownEvent(
          kind: PointerDeviceKind.stylus,
          pointer: 1,
          position: Offset(50, 50),
        ),
        mode.state,
      );
      notifier.onPointerUpdate(
        const PointerMoveEvent(
          kind: PointerDeviceKind.stylus,
          pointer: 1,
          position: Offset(70, 70),
        ),
        mode.state,
      );
      notifier.onPointerUp(
        const PointerUpEvent(
          kind: PointerDeviceKind.stylus,
          pointer: 1,
          position: Offset(70, 70),
        ),
        mode.state,
      );

      expect(notifier.currentScribble.strokes.length, 2);
      expect(
        notifier.currentScribble.imageDrawables.length,
        1,
        reason: '필기 한 획에 이미지가 소실되면 안 된다',
      );
    });

    test('지우개로 스트로크 삭제 후 이미지가 보존된다', () {
      final notifier = ScribbleNotifier(scribble: scribbleWithImage());
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setEraser();
      mode.setStrokeWidth(4.0);
      notifier.setEraser();

      notifier.onPointerDown(
        const PointerDownEvent(
          kind: PointerDeviceKind.stylus,
          pointer: 1,
          position: Offset(5, 0),
        ),
        mode.state,
      );
      notifier.onPointerUpdate(
        const PointerMoveEvent(
          kind: PointerDeviceKind.stylus,
          pointer: 1,
          position: Offset(5, 10),
        ),
        mode.state,
      );
      notifier.onPointerUp(
        const PointerUpEvent(
          kind: PointerDeviceKind.stylus,
          pointer: 1,
          position: Offset(5, 10),
        ),
        mode.state,
      );

      expect(notifier.currentScribble.strokes, isEmpty);
      expect(notifier.currentScribble.imageDrawables.length, 1);
    });
  });

  group('ImageDrawableFactory — 지오메트리 검증', () {
    test('대형 사진은 maxSize 이내로 비율 유지 축소된다', () {
      final drawable = ImageDrawableFactory.fromPickedImage(
        id: 'img',
        picked: const PickedImage(
          source: 'file:///photo.jpg',
          naturalWidth: 4032,
          naturalHeight: 3024,
        ),
        center: const Offset(200, 300),
      );

      expect(drawable.width, lessThanOrEqualTo(400));
      expect(drawable.height, lessThanOrEqualTo(400));
      expect(
        drawable.width / drawable.height,
        closeTo(4032 / 3024, 0.01),
        reason: '비율이 유지되어야 한다',
      );
      expect(drawable.x, greaterThan(-200), reason: '좌표가 캔버스 밖 큰 음수가 되면 안 된다');
    });

    test('자연 크기가 maxSize 이내면 그대로 사용한다', () {
      final drawable = ImageDrawableFactory.fromPickedImage(
        id: 'img',
        picked: const PickedImage(
          source: 'file:///small.png',
          naturalWidth: 120,
          naturalHeight: 90,
        ),
        center: const Offset(100, 100),
      );

      expect(drawable.width, 120);
      expect(drawable.height, 90);
    });

    test('create는 음수/NaN 크기와 범위 밖 opacity를 정규화한다', () {
      final drawable = ImageDrawableFactory.create(
        id: 'img',
        source: 's',
        position: const Offset(10, 10),
        size: const Size(-5, double.nan),
        opacity: 3.0,
      );

      expect(drawable.width, greaterThan(0));
      expect(drawable.height, greaterThan(0));
      expect(drawable.opacity, inInclusiveRange(0.0, 1.0));
    });
  });
}
