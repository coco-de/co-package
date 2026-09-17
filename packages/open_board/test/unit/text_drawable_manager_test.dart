import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/text/text_drawable_manager.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('TextDrawableManager', () {
    late TextDrawableManager manager;
    late Scribble scribble;

    setUp(() {
      manager = const TextDrawableManager();
      scribble = createScribble();
    });

    group('add', () {
      test('텍스트를 추가한 새 Scribble을 반환한다', () {
        final textDrawable = createTextDrawable(id: 'text1', text: 'Hello');

        final result = manager.add(scribble, textDrawable);

        expect(result.textDrawables.length, 1);
        expect(result.textDrawables.first.id, 'text1');
        expect(result.textDrawables.first.text, 'Hello');
      });

      test('기존 텍스트를 유지하면서 추가한다', () {
        final existing = createTextDrawable(id: 'text1');
        final scribbleWithText = createScribble(textDrawables: [existing]);
        final newText = createTextDrawable(id: 'text2');

        final result = manager.add(scribbleWithText, newText);

        expect(result.textDrawables.length, 2);
        expect(result.textDrawables[0].id, 'text1');
        expect(result.textDrawables[1].id, 'text2');
      });

      test('strokes를 유지한다', () {
        final scribbleWithStrokes = createScribbleWithStrokes(strokeCount: 2);
        final textDrawable = createTextDrawable(id: 'text1');

        final result = manager.add(scribbleWithStrokes, textDrawable);

        expect(result.strokes.length, 2);
      });
    });

    group('update', () {
      test('ID가 일치하는 텍스트를 수정한다', () {
        final original = createTextDrawable(id: 'text1', text: 'Original');
        final scribbleWithText = createScribble(textDrawables: [original]);
        final updated = createTextDrawable(id: 'text1', text: 'Updated');

        final result = manager.update(scribbleWithText, 'text1', updated);

        expect(result.textDrawables.length, 1);
        expect(result.textDrawables.first.text, 'Updated');
      });

      test('ID가 일치하지 않는 텍스트는 유지한다', () {
        final text1 = createTextDrawable(id: 'text1', text: 'Text 1');
        final text2 = createTextDrawable(id: 'text2', text: 'Text 2');
        final scribbleWithTexts = createScribble(
          textDrawables: [text1, text2],
        );
        final updated = createTextDrawable(id: 'text1', text: 'Updated');

        final result = manager.update(scribbleWithTexts, 'text1', updated);

        expect(result.textDrawables.length, 2);
        expect(result.textDrawables[0].text, 'Updated');
        expect(result.textDrawables[1].text, 'Text 2');
      });
    });

    group('remove', () {
      test('ID가 일치하는 텍스트를 삭제한다', () {
        final text1 = createTextDrawable(id: 'text1');
        final text2 = createTextDrawable(id: 'text2');
        final scribbleWithTexts = createScribble(
          textDrawables: [text1, text2],
        );

        final result = manager.remove(scribbleWithTexts, 'text1');

        expect(result.textDrawables.length, 1);
        expect(result.textDrawables.first.id, 'text2');
      });

      test('존재하지 않는 ID로 삭제하면 모든 텍스트를 유지한다', () {
        final text = createTextDrawable(id: 'text1');
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.remove(scribbleWithText, 'nonexistent');

        expect(result.textDrawables.length, 1);
      });
    });

    group('getAll', () {
      test('모든 텍스트를 반환한다', () {
        final texts = [
          createTextDrawable(id: 'text1'),
          createTextDrawable(id: 'text2'),
        ];
        final scribbleWithTexts = createScribble(textDrawables: texts);

        final result = manager.getAll(scribbleWithTexts);

        expect(result.length, 2);
      });

      test('텍스트가 없으면 빈 리스트를 반환한다', () {
        final result = manager.getAll(scribble);

        expect(result, isEmpty);
      });
    });

    group('applyToScribble', () {
      test('텍스트 목록을 Scribble에 적용한 새 Scribble을 반환한다', () {
        final texts = [
          createTextDrawable(id: 'text1'),
          createTextDrawable(id: 'text2'),
        ];

        final result = manager.applyToScribble(scribble, texts);

        expect(result.textDrawables.length, 2);
        expect(result.x, scribble.x);
        expect(result.y, scribble.y);
        expect(result.width, scribble.width);
        expect(result.height, scribble.height);
        expect(result.strokes, scribble.strokes);
      });

      test('strokes를 유지한다', () {
        final scribbleWithStrokes = createScribbleWithStrokes(strokeCount: 3);
        final texts = [createTextDrawable(id: 'text1')];

        final result = manager.applyToScribble(scribbleWithStrokes, texts);

        expect(result.strokes.length, 3);
        expect(result.textDrawables.length, 1);
      });
    });
  });
}
