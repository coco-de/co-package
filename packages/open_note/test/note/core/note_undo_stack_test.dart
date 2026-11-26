import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/note_undo_stack.dart';

void main() {
  late NoteUndoStack stack;
  late List<String> log;

  NoteUndoable command(String name) => NoteCallbackUndoable(
    label: name,
    onUndo: () => log.add('undo $name'),
    onRedo: () => log.add('redo $name'),
  );

  setUp(() {
    stack = NoteUndoStack();
    log = [];
  });

  test('undo and redo run commands newest first', () {
    stack
      ..push(command('a'))
      ..push(command('b'));

    expect(stack.undoLabel, 'b');
    expect(stack.undo(), isTrue);
    expect(stack.undo(), isTrue);
    expect(stack.undo(), isFalse);
    expect(stack.redo(), isTrue);

    expect(log, ['undo b', 'undo a', 'redo a']);
    expect(stack.canUndo, isTrue);
    expect(stack.canRedo, isTrue);
    expect(stack.redoLabel, 'b');
  });

  test('a new push clears the redo history', () {
    stack
      ..push(command('a'))
      ..undo()
      ..push(command('b'));

    expect(stack.canRedo, isFalse);
    expect(stack.undoLength, 1);
  });

  test('pushes made while undoing are ignored', () {
    final reentrant = NoteCallbackUndoable(
      label: 'r',
      onUndo: () => stack.push(command('loop')),
      onRedo: () {},
    );
    stack
      ..push(reentrant)
      ..undo();

    expect(stack.isApplying, isFalse);
    expect(stack.undoLength, 0);
    expect(stack.redoLength, 1);
  });

  test('maxLength drops the oldest commands', () {
    final small = NoteUndoStack(maxLength: 2)
      ..push(command('a'))
      ..push(command('b'))
      ..push(command('c'));

    expect(small.undoLength, 2);
    small
      ..undo()
      ..undo();
    expect(log, ['undo c', 'undo b']);
  });

  test('notifies listeners and clear forgets everything', () {
    var notified = 0;
    stack
      ..addListener(() => notified++)
      ..push(command('a'))
      ..undo()
      ..clear();

    expect(notified, 3);
    expect(stack.canUndo, isFalse);
    expect(stack.canRedo, isFalse);
  });

  test('a throwing command resets isApplying', () {
    stack.push(
      NoteCallbackUndoable(
        label: 'boom',
        onUndo: () => throw StateError('x'),
        onRedo: () {},
      ),
    );

    expect(() => stack.undo(), throwsStateError);
    expect(stack.isApplying, isFalse);
  });

  group('groups', () {
    late NoteUndoStack stack;
    late List<String> log;

    setUp(() {
      stack = NoteUndoStack();
      log = [];
    });

    tearDown(() => stack.dispose());

    NoteUndoable step(String name) => NoteCallbackUndoable(
      label: name,
      onUndo: () => log.add('undo $name'),
      onRedo: () => log.add('redo $name'),
    );

    test('a group undoes in reverse and redoes in order, as one step', () {
      stack.group('turn', () {
        stack.push(step('ink'));
        // 묶음 안의 묶음은 바깥에 합친다.
        stack.group('inner', () => stack.push(step('paper')));
      });

      expect(stack.undoLength, 1);
      expect(stack.undoLabel, 'turn');
      stack
        ..undo()
        ..redo();
      expect(log, ['undo paper', 'undo ink', 'redo ink', 'redo paper']);
    });

    test('amend joins the newest command and clears redo', () {
      stack
        ..push(step('stroke'))
        ..push(step('other'))
        ..undo()
        ..amend(() => stack.push(step('grow')));

      expect(stack.undoLength, 1);
      expect(stack.redoLength, 0);
      expect(stack.undoLabel, 'stroke');
      log.clear();
      stack.undo();
      expect(log, ['undo grow', 'undo stroke']);
    });

    test('an empty group records nothing; amend without history records', () {
      stack.group('nothing', () {});
      expect(stack.canUndo, isFalse);

      stack.amend(() => stack.push(step('grow')));
      expect(stack.undoLength, 1);
    });

    test('what was applied before a failure stays undoable', () {
      expect(
        () => stack.group('half', () {
          stack.push(step('ink'));
          throw StateError('stop');
        }),
        throwsStateError,
      );
      stack.push(step('next'));

      expect(stack.undoLength, 2);
    });
  });
}
