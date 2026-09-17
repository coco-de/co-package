import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/image/image_drawable_extensions.dart';
import 'package:open_board/src/module/image/image_drawable_factory.dart';
import 'package:open_board/src/module/scribble.notifier.dart';

void main() {
  group('ScribbleNotifier 이미지 드로어블 관리', () {
    late ScribbleNotifier notifier;

    ImageDrawable sample(String id) => ImageDrawableFactory.create(
      id: id,
      source: 'file:///tmp/$id.png',
      position: const Offset(10, 20),
      size: const Size(100, 80),
    );

    setUp(() {
      notifier = ScribbleNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('addImageDrawable 은 이미지를 추가한다', () {
      expect(notifier.getCurrentImageDrawables(), isEmpty);

      notifier.addImageDrawable(sample('a'));

      final images = notifier.getCurrentImageDrawables();
      expect(images.length, 1);
      expect(images.first.id, 'a');
    });

    test('updateImageDrawable 은 위치/크기/회전을 갱신한다', () {
      notifier.addImageDrawable(sample('a'));
      final original = notifier.getCurrentImageDrawables().first;

      notifier.updateImageDrawable(
        'a',
        original
            .copyWithPosition(const Offset(200, 300))
            .copyWithSize(const Size(150, 120))
            .copyWithRotation(0.5),
      );

      final updated = notifier.getCurrentImageDrawables().first;
      expect(updated.position, const Offset(200, 300));
      expect(updated.size, const Size(150, 120));
      expect(updated.rotation, 0.5);
    });

    test('addToUndoHistory:false 로도 현재 값에 반영된다', () {
      notifier.addImageDrawable(sample('a'));
      final original = notifier.getCurrentImageDrawables().first;

      notifier.updateImageDrawable(
        'a',
        original.copyWithPosition(const Offset(50, 60)),
        addToUndoHistory: false,
      );

      expect(
        notifier.getCurrentImageDrawables().first.position,
        const Offset(50, 60),
      );
    });

    test('removeImageDrawable 은 해당 이미지를 제거한다', () {
      notifier.addImageDrawable(sample('a'));
      notifier.addImageDrawable(sample('b'));

      notifier.removeImageDrawable('a');

      final images = notifier.getCurrentImageDrawables();
      expect(images.length, 1);
      expect(images.first.id, 'b');
    });

    test('addImageDrawable 은 onScribbleFinished 를 호출한다 (kobic#10836)', () {
      var callCount = 0;
      notifier.onScribbleFinished = () => callCount++;

      notifier.addImageDrawable(sample('a'));

      expect(callCount, 1);
    });

    test('updateImageDrawable(addToUndoHistory: false) 는 onScribbleFinished 를 '
        '호출하지 않는다 (드래그 중간 프레임, kobic#10836)', () {
      notifier.addImageDrawable(sample('a'));
      final original = notifier.getCurrentImageDrawables().first;

      var callCount = 0;
      notifier.onScribbleFinished = () => callCount++;

      notifier.updateImageDrawable(
        'a',
        original.copyWithPosition(const Offset(50, 60)),
        addToUndoHistory: false,
      );

      expect(callCount, 0);
    });

    test('이미지 조작이 스트로크/텍스트 컬렉션을 보존한다', () {
      notifier.addTextDrawable(
        TextDrawable(
          id: 't1',
          text: 'hello',
          x: 0,
          y: 0,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      notifier.addImageDrawable(sample('a'));

      expect(notifier.getCurrentTextDrawables().length, 1);
      expect(notifier.getCurrentImageDrawables().length, 1);
    });
  });
}
