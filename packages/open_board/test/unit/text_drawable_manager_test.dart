import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';
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

    group('clearAll', () {
      test('모든 텍스트를 삭제한다', () {
        final texts = [
          createTextDrawable(id: 'text1'),
          createTextDrawable(id: 'text2'),
          createTextDrawable(id: 'text3'),
        ];
        final scribbleWithTexts = createScribble(textDrawables: texts);

        final result = manager.clearAll(scribbleWithTexts);

        expect(result.textDrawables, isEmpty);
      });

      test('strokes를 유지한다', () {
        final scribbleWithAll = createScribble(
          strokes: [createStroke()],
          textDrawables: [createTextDrawable(id: 'text1')],
        );

        final result = manager.clearAll(scribbleWithAll);

        expect(result.strokes.length, 1);
        expect(result.textDrawables, isEmpty);
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

    group('findById', () {
      test('ID가 일치하는 텍스트를 반환한다', () {
        final text = createTextDrawable(id: 'text1', text: 'Found');
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.findById(scribbleWithText, 'text1');

        expect(result, isNotNull);
        expect(result!.text, 'Found');
      });

      test('ID가 일치하지 않으면 null을 반환한다', () {
        final text = createTextDrawable(id: 'text1');
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.findById(scribbleWithText, 'nonexistent');

        expect(result, isNull);
      });
    });

    group('findAtPosition', () {
      test('위치 근처에 있는 텍스트를 반환한다', () {
        final text = createTextDrawable(id: 'text1', x: 100, y: 100);
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.findAtPosition(
          scribbleWithText,
          const Offset(105, 105),
          tolerance: 10.0,
        );

        expect(result, isNotNull);
        expect(result!.id, 'text1');
      });

      test('범위 밖의 위치이면 null을 반환한다', () {
        final text = createTextDrawable(id: 'text1', x: 100, y: 100);
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.findAtPosition(
          scribbleWithText,
          const Offset(200, 200),
          tolerance: 10.0,
        );

        expect(result, isNull);
      });

      test('여러 텍스트 중 가장 먼저 발견된 것을 반환한다', () {
        final text1 = createTextDrawable(id: 'text1', x: 100, y: 100);
        final text2 = createTextDrawable(id: 'text2', x: 102, y: 102);
        final scribbleWithTexts = createScribble(
          textDrawables: [text1, text2],
        );

        final result = manager.findAtPosition(
          scribbleWithTexts,
          const Offset(101, 101),
          tolerance: 10.0,
        );

        expect(result, isNotNull);
        expect(result!.id, 'text1');
      });
    });

    group('toggleVisibility', () {
      test('visible 텍스트를 hidden으로 토글한다', () {
        final text = createTextDrawable(id: 'text1', hidden: false);
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.toggleVisibility(scribbleWithText, 'text1');

        expect(result.textDrawables.first.hidden, isTrue);
      });

      test('hidden 텍스트를 visible로 토글한다', () {
        final text = createTextDrawable(id: 'text1', hidden: true);
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.toggleVisibility(scribbleWithText, 'text1');

        expect(result.textDrawables.first.hidden, isFalse);
      });

      test('존재하지 않는 ID이면 원본 Scribble을 반환한다', () {
        final text = createTextDrawable(id: 'text1');
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.toggleVisibility(
          scribbleWithText,
          'nonexistent',
        );

        expect(result.textDrawables.length, 1);
      });
    });

    group('move', () {
      test('텍스트 위치를 이동한다', () {
        final text = createTextDrawable(id: 'text1', x: 50, y: 50);
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.move(
          scribbleWithText,
          'text1',
          const Offset(200, 300),
        );

        expect(result.textDrawables.first.x, 200.0);
        expect(result.textDrawables.first.y, 300.0);
      });

      test('존재하지 않는 ID이면 원본 Scribble을 반환한다', () {
        final text = createTextDrawable(id: 'text1', x: 50, y: 50);
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.move(
          scribbleWithText,
          'nonexistent',
          const Offset(200, 300),
        );

        expect(result.textDrawables.first.x, 50.0);
        expect(result.textDrawables.first.y, 50.0);
      });
    });

    group('deleteSelected', () {
      test('선택된 ID 목록에 해당하는 텍스트들을 삭제한다', () {
        final texts = [
          createTextDrawable(id: 'text1'),
          createTextDrawable(id: 'text2'),
          createTextDrawable(id: 'text3'),
        ];
        final scribbleWithTexts = createScribble(textDrawables: texts);

        final result = manager.deleteSelected(
          scribbleWithTexts,
          ['text1', 'text3'],
        );

        expect(result.textDrawables.length, 1);
        expect(result.textDrawables.first.id, 'text2');
      });
    });

    group('updateStyle', () {
      test('텍스트 스타일을 변경한다', () {
        final text = createTextDrawable(
          id: 'text1',
          fontSize: 16,
          isBold: false,
        );
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.updateStyle(
          scribbleWithText,
          'text1',
          fontSize: 24,
          isBold: true,
        );

        final updated = result.textDrawables.first;
        expect(updated.fontSize, 24.0);
        expect(updated.isBold, isTrue);
      });

      test('지정하지 않은 스타일 속성은 유지한다', () {
        final text = createTextDrawable(
          id: 'text1',
          fontSize: 16,
          isBold: true,
          isItalic: true,
        );
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.updateStyle(
          scribbleWithText,
          'text1',
          fontSize: 24,
        );

        final updated = result.textDrawables.first;
        expect(updated.fontSize, 24.0);
        expect(updated.isBold, isTrue); // 유지됨
        expect(updated.isItalic, isTrue); // 유지됨
      });

      test('textAlignment을 변경한다', () {
        final text = createTextDrawable(id: 'text1', textAlign: 'left');
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.updateStyle(
          scribbleWithText,
          'text1',
          textAlignment: TextAlignment.right,
        );

        expect(result.textDrawables.first.textAlign, 'right');
      });

      test('존재하지 않는 ID이면 원본 Scribble을 반환한다', () {
        final text = createTextDrawable(id: 'text1', fontSize: 16);
        final scribbleWithText = createScribble(textDrawables: [text]);

        final result = manager.updateStyle(
          scribbleWithText,
          'nonexistent',
          fontSize: 24,
        );

        expect(result.textDrawables.first.fontSize, 16.0);
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
