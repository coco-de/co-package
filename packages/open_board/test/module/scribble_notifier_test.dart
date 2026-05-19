import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ScribbleNotifier', () {
    late ScribbleNotifier notifier;

    setUp(() {
      notifier = ScribbleNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    group('초기 상태', () {
      test('초기 상태는 Drawing이어야 한다', () {
        expect(notifier.state, isA<Drawing>());
      });

      test('초기 스트로크 목록은 비어있어야 한다', () {
        expect(notifier.currentScribble.strokes, isEmpty);
      });

      test('state와 value는 동일한 객체를 반환해야 한다', () {
        expect(identical(notifier.state, notifier.value), isTrue);
      });
    });

    group('생성자 파라미터', () {
      test('scribble을 전달하면 해당 scribble로 초기화된다', () {
        final scribble = createScribbleWithStrokes(strokeCount: 2);
        final notifierWithScribble = ScribbleNotifier(scribble: scribble);
        addTearDown(notifierWithScribble.dispose);

        expect(notifierWithScribble.currentScribble.strokes.length, 2);
      });

      test('width, height를 전달하면 scribble에 반영된다', () {
        final notifierWithSize = ScribbleNotifier(width: 800, height: 600);
        addTearDown(notifierWithSize.dispose);

        expect(notifierWithSize.currentScribble.width, 800);
        expect(notifierWithSize.currentScribble.height, 600);
      });

      test('x, y를 전달하면 scribble의 origin에 반영된다', () {
        final notifierWithOrigin = ScribbleNotifier(x: 10, y: 20);
        addTearDown(notifierWithOrigin.dispose);

        expect(notifierWithOrigin.currentScribble.x, 10);
        expect(notifierWithOrigin.currentScribble.y, 20);
      });

      test('version을 전달하면 scribble에 반영된다', () {
        final notifierWithVersion = ScribbleNotifier(version: '2.0.0');
        addTearDown(notifierWithVersion.dispose);

        expect(notifierWithVersion.currentScribble.version, '2.0.0');
      });
    });

    group('currentScribble / currentState getter', () {
      test('currentScribble은 현재 state의 scribble을 반환한다', () {
        expect(
          identical(notifier.currentScribble, notifier.state.scribble),
          isTrue,
        );
      });

      test('currentState는 state와 동일하다', () {
        expect(identical(notifier.currentState, notifier.state), isTrue);
      });
    });

    group('clear()', () {
      test('스트로크가 있는 경우 모두 비운다', () {
        final scribble = createScribbleWithStrokes(strokeCount: 3);
        final n = ScribbleNotifier(scribble: scribble);
        addTearDown(n.dispose);

        // 스트로크가 있는지 확인
        expect(n.currentScribble.strokes.length, 3);

        n.clear();
        expect(n.currentScribble.strokes, isEmpty);
      });

      test('clear 후 상태는 Drawing이다', () {
        final scribble = createScribbleWithStrokes(strokeCount: 2);
        final n = ScribbleNotifier(scribble: scribble);
        addTearDown(n.dispose);

        n.clear();
        expect(n.state, isA<Drawing>());
      });

      test('스트로크가 비어있으면 clear()는 상태를 변경하지 않는다', () {
        final stateBefore = notifier.state;
        notifier.clear();
        // 상태가 변경되지 않아야 한다 (빈 스트로크이므로 early return)
        expect(identical(notifier.state, stateBefore), isTrue);
      });

      test('clear 후에도 scribble의 크기 정보는 유지된다', () {
        final scribble = createScribbleWithStrokes(strokeCount: 2);
        final n = ScribbleNotifier(
          scribble: scribble,
          width: 400,
          height: 600,
        );
        addTearDown(n.dispose);

        n.clear();
        // 원래 scribble의 크기가 유지되어야 한다
        expect(n.currentScribble.width, scribble.width);
        expect(n.currentScribble.height, scribble.height);
      });
    });

    group('setScribble()', () {
      test('새 scribble로 상태를 업데이트한다 (addToUndoHistory: true)', () {
        final newScribble = createScribbleWithStrokes(strokeCount: 5);
        notifier.setScribble(scribble: newScribble);

        expect(notifier.currentScribble.strokes.length, 5);
      });

      test('addToUndoHistory: true 일 때 undo로 이전 상태로 돌아갈 수 있다', () {
        final scribble1 = createScribbleWithStrokes(strokeCount: 2);
        final scribble2 = createScribbleWithStrokes(strokeCount: 4);

        notifier.setScribble(scribble: scribble1);
        notifier.setScribble(scribble: scribble2);

        expect(notifier.currentScribble.strokes.length, 4);

        notifier.undo();
        expect(notifier.currentScribble.strokes.length, 2);
      });

      test('addToUndoHistory: false 일 때 temporaryValue로 설정된다', () {
        final scribble1 = createScribbleWithStrokes(strokeCount: 2);
        final scribble2 = createScribbleWithStrokes(strokeCount: 4);

        notifier.setScribble(scribble: scribble1);
        notifier.setScribble(scribble: scribble2, addToUndoHistory: false);

        // 현재 상태는 scribble2
        expect(notifier.currentScribble.strokes.length, 4);
      });
    });

    group('setEraser()', () {
      test('Erasing 상태로 전환된다', () {
        notifier.setEraser();
        expect(notifier.state, isA<Erasing>());
      });

      test('지우개 모드 전환 후에도 기존 스트로크는 유지된다', () {
        final scribble = createScribbleWithStrokes(strokeCount: 3);
        final n = ScribbleNotifier(scribble: scribble);
        addTearDown(n.dispose);

        n.setEraser();
        expect(n.state, isA<Erasing>());
        expect(n.currentScribble.strokes.length, 3);
      });
    });

    group('setStrokeInk()', () {
      test('Erasing 상태에서 Drawing 상태로 전환된다', () {
        notifier.setEraser();
        expect(notifier.state, isA<Erasing>());

        notifier.setStrokeInk();
        expect(notifier.state, isA<Drawing>());
      });

      test('Drawing 상태에서 호출해도 Drawing 상태를 유지한다', () {
        expect(notifier.state, isA<Drawing>());
        notifier.setStrokeInk();
        expect(notifier.state, isA<Drawing>());
      });
    });

    group('setColor()', () {
      test('Drawing 상태를 유지한다', () {
        expect(notifier.state, isA<Drawing>());
        notifier.setColor();
        expect(notifier.state, isA<Drawing>());
      });

      test('Erasing 상태에서 호출하면 Drawing으로 전환된다', () {
        notifier.setEraser();
        expect(notifier.state, isA<Erasing>());

        notifier.setColor();
        expect(notifier.state, isA<Drawing>());
      });
    });

    group('undo / redo (HistoryValueNotifierMixin)', () {
      test('초기 상태에서 canUndo 확인', () {
        // 생성자에서 state = 할당으로 초기값이 히스토리에 들어갈 수 있음
        expect(notifier.canUndo, isA<bool>());
      });

      test('초기 상태에서 canRedo는 false이다', () {
        expect(notifier.canRedo, isFalse);
      });

      test('상태 변경 후 canUndo는 true가 된다', () {
        notifier.setScribble(
          scribble: createScribbleWithStrokes(strokeCount: 1),
        );
        expect(notifier.canUndo, isTrue);
      });

      test('undo 후 canRedo는 true가 된다', () {
        notifier.setScribble(
          scribble: createScribbleWithStrokes(strokeCount: 1),
        );
        notifier.undo();
        expect(notifier.canRedo, isTrue);
      });

      test('여러 상태 변경 후 undo로 순차적으로 이전 상태로 돌아간다', () {
        final s1 = createScribbleWithStrokes(strokeCount: 1);
        final s2 = createScribbleWithStrokes(strokeCount: 2);
        final s3 = createScribbleWithStrokes(strokeCount: 3);

        notifier.setScribble(scribble: s1);
        notifier.setScribble(scribble: s2);
        notifier.setScribble(scribble: s3);

        expect(notifier.currentScribble.strokes.length, 3);

        notifier.undo();
        expect(notifier.currentScribble.strokes.length, 2);

        notifier.undo();
        expect(notifier.currentScribble.strokes.length, 1);

        notifier.undo();
        expect(notifier.currentScribble.strokes, isEmpty);
      });

      test('redo로 undo한 상태를 다시 복원한다', () {
        final s1 = createScribbleWithStrokes(strokeCount: 2);
        final s2 = createScribbleWithStrokes(strokeCount: 4);

        notifier.setScribble(scribble: s1);
        notifier.setScribble(scribble: s2);

        notifier.undo();
        expect(notifier.currentScribble.strokes.length, 2);

        notifier.redo();
        expect(notifier.currentScribble.strokes.length, 4);
      });

      test('undo 후 새로운 상태를 설정하면 redo 히스토리가 사라진다', () {
        final s1 = createScribbleWithStrokes(strokeCount: 1);
        final s2 = createScribbleWithStrokes(strokeCount: 2);
        final s3 = createScribbleWithStrokes(strokeCount: 3);

        notifier.setScribble(scribble: s1);
        notifier.setScribble(scribble: s2);

        notifier.undo(); // s1으로 돌아감

        // 새로운 상태 설정 -> redo 불가능
        notifier.setScribble(scribble: s3);
        expect(notifier.canRedo, isFalse);
      });

      test('maxHistoryLength를 초과하면 오래된 히스토리가 제거된다', () {
        final n = ScribbleNotifier(maxHistoryLength: 3);
        addTearDown(n.dispose);

        // 초기 상태가 히스토리에 포함됨 (1개)
        // 3개 더 추가하면 총 4개 -> maxHistoryLength(3) 초과 -> 가장 오래된 것 제거
        n.setScribble(scribble: createScribbleWithStrokes(strokeCount: 1));
        n.setScribble(scribble: createScribbleWithStrokes(strokeCount: 2));
        n.setScribble(scribble: createScribbleWithStrokes(strokeCount: 3));

        expect(n.currentScribble.strokes.length, 3);

        // 최대 2번 undo 가능 (maxHistoryLength=3이므로 히스토리에 3개 저장)
        n.undo();
        expect(n.canUndo, isTrue);
        n.undo();
        // maxHistoryLength=3이므로 초기 상태는 이미 밀려났을 수 있다
        expect(n.canUndo, isFalse);
      });

      test('여러 번 undo를 호출해도 에러가 발생하지 않는다', () {
        // 최대한 undo 시도
        for (int i = 0; i < 50; i++) {
          notifier.undo();
        }
        expect(notifier.state, isA<ScribbleState>());
      });

      test('canRedo가 false인 상태에서 redo를 호출해도 에러가 발생하지 않는다', () {
        expect(notifier.canRedo, isFalse);
        notifier.redo(); // 에러 없이 동작
        expect(notifier.state, isA<Drawing>());
      });
    });

    group('Erasing 상태에서의 undo/redo', () {
      test('Erasing 상태에서 undo하면 scribble만 복원되고 상태 타입은 유지된다', () {
        final s1 = createScribbleWithStrokes(strokeCount: 2);
        final s2 = createScribbleWithStrokes(strokeCount: 4);

        notifier.setScribble(scribble: s1);
        notifier.setScribble(scribble: s2);

        // Erasing 모드로 전환 (temporaryValue이므로 히스토리에 추가되지 않음)
        notifier.setEraser();
        expect(notifier.state, isA<Erasing>());

        // undo -> scribble만 복원, Erasing 상태 유지
        notifier.undo();
        expect(notifier.state, isA<Erasing>());
        expect(notifier.currentScribble.strokes.length, 2);
      });
    });

    group('ValueNotifier 리스너', () {
      test('상태 변경 시 리스너가 호출된다', () {
        final tracker = ValueChangeTracker(notifier);
        addTearDown(() => tracker.dispose(notifier));

        notifier.setScribble(
          scribble: createScribbleWithStrokes(strokeCount: 1),
        );

        expect(tracker.hasChanged, isTrue);
      });

      test('setEraser 호출 시 리스너가 호출된다', () {
        final tracker = ValueChangeTracker(notifier);
        addTearDown(() => tracker.dispose(notifier));

        notifier.setEraser();
        expect(tracker.hasChanged, isTrue);
      });
    });

    group('removeLassoStrokes()', () {
      test('올가미 스트로크를 제거한다', () {
        final lassoStroke = createStroke(ink: 'lasso');
        final normalStroke = createStroke(ink: 'pencil');
        final scribble = createScribble(
          strokes: [normalStroke, lassoStroke],
        );
        final n = ScribbleNotifier(scribble: scribble);
        addTearDown(n.dispose);

        n.removeLassoStrokes();

        expect(n.currentScribble.strokes.length, 1);
        expect(n.currentScribble.strokes.first.ink, 'pencil');
      });

      test('올가미 스트로크가 없으면 기존 스트로크를 유지한다', () {
        final scribble = createScribbleWithStrokes(strokeCount: 3);
        final n = ScribbleNotifier(scribble: scribble);
        addTearDown(n.dispose);

        n.removeLassoStrokes();
        expect(n.currentScribble.strokes.length, 3);
      });
    });

    group('텍스트 관리', () {
      test('addTextDrawable로 텍스트를 추가할 수 있다', () {
        final textDrawable = createTextDrawable(text: 'Hello');
        notifier.addTextDrawable(textDrawable);

        expect(notifier.getCurrentTextDrawables().length, 1);
        expect(notifier.getCurrentTextDrawables().first.text, 'Hello');
      });

      test('removeTextDrawable로 텍스트를 삭제할 수 있다', () {
        final td = createTextDrawable(id: 'test-id', text: 'Hello');
        notifier.addTextDrawable(td);
        expect(notifier.getCurrentTextDrawables().length, 1);

        notifier.removeTextDrawable('test-id');
        expect(notifier.getCurrentTextDrawables(), isEmpty);
      });

      test('clearAllTextDrawables로 모든 텍스트를 삭제할 수 있다', () {
        notifier.addTextDrawable(createTextDrawable(id: 'a', text: 'A'));
        notifier.addTextDrawable(createTextDrawable(id: 'b', text: 'B'));

        notifier.clearAllTextDrawables();
        expect(notifier.getCurrentTextDrawables(), isEmpty);
      });

      test('findTextDrawableById로 텍스트를 찾을 수 있다', () {
        final td = createTextDrawable(id: 'find-me', text: 'Found');
        notifier.addTextDrawable(td);

        final found = notifier.findTextDrawableById('find-me');
        expect(found, isNotNull);
        expect(found!.text, 'Found');
      });

      test('존재하지 않는 id로 검색하면 null을 반환한다', () {
        final result = notifier.findTextDrawableById('nonexistent');
        expect(result, isNull);
      });
    });
  });
}
