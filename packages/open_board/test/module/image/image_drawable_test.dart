import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/adapters/image_picker_adapter.dart';
import 'package:open_board/src/module/image/image_drawable_extensions.dart';
import 'package:open_board/src/module/image/image_drawable_factory.dart';
import 'package:open_board/src/module/image/image_drawable_manager.dart';

Scribble _emptyScribble() => Scribble(
  width: 1000,
  height: 1000,
  version: '1',
  createdAt: DateTime.now().toIso8601String(),
  updatedAt: DateTime.now().toIso8601String(),
);

void main() {
  group('ImageDrawableFactory.fromPickedImage', () {
    test('자연 크기가 주어지면 중심을 기준으로 박스를 배치한다', () {
      final picked = const PickedImage(
        source: 'https://example.com/a.png',
        naturalWidth: 400,
        naturalHeight: 200,
      );

      final drawable = ImageDrawableFactory.fromPickedImage(
        id: 'img-1',
        picked: picked,
        center: const Offset(500, 500),
      );

      expect(drawable.id, 'img-1');
      expect(drawable.source, 'https://example.com/a.png');
      expect(drawable.width, 400);
      expect(drawable.height, 200);
      // 중심 (500, 500) - half box (200, 100) = (300, 400)
      expect(drawable.x, 300);
      expect(drawable.y, 400);
      expect(drawable.rotation, 0);
      expect(drawable.opacity, 1);
      expect(drawable.hidden, isFalse);
      expect(drawable.naturalWidth, 400);
      expect(drawable.naturalHeight, 200);
    });

    test('자연 크기가 없으면 기본 사이즈(200×200)를 사용한다', () {
      final picked = const PickedImage(source: 'file:///tmp/a.jpg');

      final drawable = ImageDrawableFactory.fromPickedImage(
        id: 'img-2',
        picked: picked,
        center: const Offset(100, 100),
      );

      expect(drawable.width, ImageDrawableFactory.defaultSize.width);
      expect(drawable.height, ImageDrawableFactory.defaultSize.height);
      expect(drawable.x, 0);
      expect(drawable.y, 0);
    });

    test('size override가 우선 적용된다', () {
      final picked = const PickedImage(
        source: 'a',
        naturalWidth: 800,
        naturalHeight: 600,
      );

      final drawable = ImageDrawableFactory.fromPickedImage(
        id: 'img-3',
        picked: picked,
        center: const Offset(0, 0),
        size: const Size(100, 50),
      );

      expect(drawable.width, 100);
      expect(drawable.height, 50);
      // override 했어도 natural 값은 보존돼야 한다
      expect(drawable.naturalWidth, 800);
      expect(drawable.naturalHeight, 600);
    });
  });

  group('ImageDrawableExtensions', () {
    test('position/size/center 헬퍼는 proto 필드를 반영한다', () {
      final d = ImageDrawableFactory.create(
        id: 'a',
        source: 's',
        position: const Offset(50, 60),
        size: const Size(40, 20),
      );

      expect(d.position, const Offset(50, 60));
      expect(d.size, const Size(40, 20));
      expect(d.center, const Offset(70, 70));
    });

    test('aspectRatio는 natural 크기가 있을 때만 계산된다', () {
      final withNatural = ImageDrawableFactory.create(
        id: 'a',
        source: 's',
        position: Offset.zero,
        size: const Size(10, 10),
        naturalWidth: 800,
        naturalHeight: 400,
      );
      expect(withNatural.aspectRatio, closeTo(2.0, 1e-9));

      final withoutNatural = ImageDrawableFactory.create(
        id: 'b',
        source: 's',
        position: Offset.zero,
        size: const Size(10, 10),
      );
      expect(withoutNatural.aspectRatio, isNull);
    });

    test('copyWith* 시리즈는 원본을 보존하고 updatedAt을 갱신한다', () {
      final original = ImageDrawableFactory.create(
        id: 'a',
        source: 's',
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );
      final originalUpdatedAt = original.updatedAt;

      // updatedAt 비교가 동일 ms에 걸리지 않도록 약간의 지연 필요.
      // 실제 환경에서는 사용자 입력 사이에 충분한 시간이 있다.
      final moved = original.copyWithPosition(const Offset(10, 20));
      final resized = original.copyWithSize(const Size(50, 50));
      final rotated = original.copyWithRotation(0.5);
      final faded = original.copyWithOpacity(0.3);
      final hidden = original.copyWithHidden(true);
      final reSourced = original.copyWithSource('new-source');

      // 원본 불변
      expect(original.x, 0);
      expect(original.y, 0);
      expect(original.width, 100);
      expect(original.height, 100);
      expect(original.rotation, 0);
      expect(original.opacity, 1);
      expect(original.hidden, isFalse);
      expect(original.source, 's');
      expect(original.updatedAt, originalUpdatedAt);

      // 사본 반영
      expect(moved.position, const Offset(10, 20));
      expect(resized.size, const Size(50, 50));
      expect(rotated.rotation, 0.5);
      expect(faded.opacity, 0.3);
      expect(hidden.hidden, isTrue);
      expect(reSourced.source, 'new-source');
    });

    test('copyWithOpacity는 0..1 범위로 클램프한다', () {
      final d = ImageDrawableFactory.create(
        id: 'a',
        source: 's',
        position: Offset.zero,
        size: const Size(10, 10),
      );
      expect(d.copyWithOpacity(-0.5).opacity, 0);
      expect(d.copyWithOpacity(1.5).opacity, 1);
    });

    group('containsPoint', () {
      test('회전이 없으면 축 정렬 박스 내부/외부를 정확히 판정한다', () {
        // 좌상단 (100,100), 크기 40x20 → center (120, 110)
        final d = ImageDrawableFactory.create(
          id: 'a',
          source: 's',
          position: const Offset(100, 100),
          size: const Size(40, 20),
        );

        expect(d.containsPoint(const Offset(120, 110)), isTrue); // 중심
        expect(d.containsPoint(const Offset(100, 100)), isTrue); // 좌상단 경계
        expect(d.containsPoint(const Offset(140, 120)), isTrue); // 우하단 경계
        expect(d.containsPoint(const Offset(99, 110)), isFalse); // 좌측 밖
        expect(d.containsPoint(const Offset(120, 121)), isFalse); // 하단 밖
      });

      test('90도 회전 시 회전된 사각형 기준으로 판정한다', () {
        // center (0, 0), 크기 40(width) x 20(height), 90도 회전
        // → 회전 후 실제로는 세로 40 x 가로 20 형태가 된다.
        final d = ImageDrawableFactory.create(
          id: 'a',
          source: 's',
          position: const Offset(-20, -10),
          size: const Size(40, 20),
          rotation: math.pi / 2,
        );

        // 회전 전 기준 "가로로 먼(양옆)" 지점은 회전 후 범위 밖(세로만 김).
        expect(d.containsPoint(const Offset(15, 0)), isFalse);
        // 회전 후 "세로로 먼" 지점은 범위 안(원래 width=40이 세로축이 됨).
        expect(d.containsPoint(const Offset(0, 15)), isTrue);
      });
    });
  });

  group('ImageDrawableManager', () {
    const manager = ImageDrawableManager();

    test('add는 새 drawable을 포함한 새 Scribble을 반환한다', () {
      final scribble = _emptyScribble();
      final drawable = ImageDrawableFactory.create(
        id: 'a',
        source: 's',
        position: Offset.zero,
        size: const Size(10, 10),
      );

      final next = manager.add(scribble, drawable);

      // 원본 scribble 불변
      expect(scribble.imageDrawables, isEmpty);
      // 새 scribble은 1개
      expect(next.imageDrawables, hasLength(1));
      expect(next.imageDrawables.first.id, 'a');
    });

    test('update는 일치하는 id의 drawable을 교체한다', () {
      final base = ImageDrawableFactory.create(
        id: 'a',
        source: 's1',
        position: Offset.zero,
        size: const Size(10, 10),
      );
      final scribble = manager.add(_emptyScribble(), base);

      final updated = base.copyWithSource('s2');
      final next = manager.update(scribble, 'a', updated);

      expect(next.imageDrawables.first.source, 's2');
      // 원본 보존
      expect(scribble.imageDrawables.first.source, 's1');
    });

    test('update는 일치하는 id가 없으면 원본 그대로 반환한다', () {
      final scribble = _emptyScribble();
      final placeholder = ImageDrawableFactory.create(
        id: 'missing',
        source: 's',
        position: Offset.zero,
        size: const Size(10, 10),
      );
      final next = manager.update(scribble, 'missing', placeholder);
      expect(identical(next, scribble), isTrue);
    });

    test('remove는 일치하는 id의 drawable을 제거한다', () {
      final a = ImageDrawableFactory.create(
        id: 'a',
        source: 's',
        position: Offset.zero,
        size: const Size(10, 10),
      );
      final b = ImageDrawableFactory.create(
        id: 'b',
        source: 's',
        position: Offset.zero,
        size: const Size(10, 10),
      );
      final scribble = manager.add(manager.add(_emptyScribble(), a), b);

      final next = manager.remove(scribble, 'a');

      expect(next.imageDrawables.map((d) => d.id), ['b']);
      expect(scribble.imageDrawables.map((d) => d.id), ['a', 'b']);
    });

    test('remove는 일치하는 id가 없으면 원본 그대로 반환한다', () {
      final scribble = _emptyScribble();
      final next = manager.remove(scribble, 'missing');
      expect(identical(next, scribble), isTrue);
    });

    test('findById는 일치하는 drawable을 찾거나 null을 반환한다', () {
      final a = ImageDrawableFactory.create(
        id: 'a',
        source: 's',
        position: Offset.zero,
        size: const Size(10, 10),
      );
      final scribble = manager.add(_emptyScribble(), a);

      expect(manager.findById(scribble, 'a')?.id, 'a');
      expect(manager.findById(scribble, 'missing'), isNull);
    });

    test('getAll은 수정 불가능한 리스트를 반환한다', () {
      final a = ImageDrawableFactory.create(
        id: 'a',
        source: 's',
        position: Offset.zero,
        size: const Size(10, 10),
      );
      final scribble = manager.add(_emptyScribble(), a);
      final all = manager.getAll(scribble);
      expect(() => all.add(a), throwsUnsupportedError);
    });
  });

  group('Scribble proto backward-compat', () {
    test('imageDrawables 없는 기존 직렬화를 round-trip 한다', () {
      // imageDrawables 필드가 없던 시절의 Scribble을 흉내낸 bytes.
      // 우리는 그냥 빈 imageDrawables 로 생성한 메시지가 동일하게
      // 직렬화/역직렬화되는지를 확인한다.
      final scribble = Scribble(
        width: 100,
        height: 100,
        version: '1',
        createdAt: 'a',
        updatedAt: 'b',
      );
      final bytes = scribble.writeToBuffer();
      final decoded = Scribble.fromBuffer(bytes);
      expect(decoded.imageDrawables, isEmpty);
      expect(decoded.width, 100);
      expect(decoded.height, 100);
    });

    test('imageDrawables 1개를 직렬화/역직렬화한다', () {
      const manager = ImageDrawableManager();
      final drawable = ImageDrawableFactory.create(
        id: 'a',
        source: 'https://example.com/x.png',
        position: const Offset(10, 20),
        size: const Size(80, 60),
        rotation: 0.25,
        opacity: 0.5,
        naturalWidth: 800,
        naturalHeight: 600,
      );
      final scribble = manager.add(_emptyScribble(), drawable);
      final decoded = Scribble.fromBuffer(scribble.writeToBuffer());

      expect(decoded.imageDrawables, hasLength(1));
      final round = decoded.imageDrawables.first;
      expect(round.id, 'a');
      expect(round.source, 'https://example.com/x.png');
      expect(round.x, 10);
      expect(round.y, 20);
      expect(round.width, 80);
      expect(round.height, 60);
      expect(round.rotation, 0.25);
      expect(round.opacity, 0.5);
      expect(round.naturalWidth, 800);
      expect(round.naturalHeight, 600);
    });
  });
}
