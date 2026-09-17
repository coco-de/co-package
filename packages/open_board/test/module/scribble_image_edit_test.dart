import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/open_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

ImageDrawable image(String id) => ImageDrawable(
  id: id,
  source: 'file:///$id.png',
  x: 10,
  y: 20,
  width: 100,
  height: 80,
);

void expectEdit(
  ScribbleImageEdit? edit,
  ScribbleImageEditKind kind,
  List<String> before,
  List<String> after,
) {
  expect(edit, isNotNull);
  expect(edit!.kind, kind);
  expect(edit.before.map((item) => item.id), before);
  expect(edit.after.map((item) => item.id), after);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScribbleImageEditTest notifier;
  late List<ScribbleImageEdit?> notifications;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notifier = ScribbleImageEditTest();
    notifications = [];
    notifier.addListener(() => notifications.add(notifier.activeImageEdit));
  });

  tearDown(() {
    notifier.dispose();
  });

  test('should_notify_add_remove_and_clear_when_committed', () {
    notifier.addImageDrawable(image('a'));
    notifier.addImageDrawable(image('b'));
    notifier.removeImageDrawable('a');
    notifier.clear();

    expect(notifications, hasLength(4));
    expectEdit(notifications[0], .edit, [], ['a']);
    expectEdit(notifications[1], .edit, ['a'], ['a', 'b']);
    expectEdit(notifications[2], .edit, ['a', 'b'], ['b']);
    expectEdit(notifications[3], .edit, ['b'], []);
    expect(notifier.activeImageEdit, isNull);
    expect(notifier.currentScribble.imageDrawables, isEmpty);
  });

  test('should_notify_replacement_when_setScribble_commits_membership', () {
    notifier.setScribble(scribble: Scribble(imageDrawables: [image('a')]));
    notifier.setScribble(scribble: Scribble(imageDrawables: [image('b')]));

    expect(notifications, hasLength(2));
    expectEdit(notifications[0], .edit, [], ['a']);
    expectEdit(notifications[1], .edit, ['a'], ['b']);
  });

  test('should_compare_id_counts_when_duplicate_ids_are_present', () {
    final a = image('a');
    final b = image('b');
    notifier.setScribble(scribble: Scribble(imageDrawables: [a, a, b]));
    notifier.setScribble(scribble: Scribble(imageDrawables: [a, b, b]));

    expectEdit(notifications.last, .edit, ['a', 'a', 'b'], ['a', 'b', 'b']);
  });

  test('should_notify_id_replacement_when_drawable_update_commits', () {
    notifier.addImageDrawable(image('a'));
    notifications.clear();
    notifier.updateImageDrawable('a', image('b'));

    expectEdit(notifications.single, .edit, ['a'], ['b']);
  });

  test('should_ignore_non_membership_changes_when_committed_or_replayed', () {
    notifier.setScribble(
      scribble: Scribble(imageDrawables: [image('a'), image('b')]),
    );
    notifications.clear();
    notifier.updateImageDrawable(
      'a',
      image('a')
        ..x = 200
        ..width = 150
        ..rotation = 0.5
        ..hidden = true
        ..opacity = 0.4
        ..source = 'https://example.org/new.png',
    );
    notifier.setScribble(
      scribble: Scribble(
        imageDrawables: notifier.currentScribble.imageDrawables.reversed,
      ),
    );
    notifier.addTextDrawable(TextDrawable(id: 'text', text: 'content'));
    notifier.undo();
    notifier.undo();
    notifier.undo();
    notifier.redo();

    expect(notifications, hasLength(7));
    expect(notifications, everyElement(isNull));
  });

  for (final operation in ['add', 'remove', 'clear']) {
    test('should_notify_actual_deltas_when_undoing_and_redoing_$operation', () {
      notifier.setScribble(
        scribble: Scribble(imageDrawables: [image('a')]),
        addToUndoHistory: false,
      );
      notifier.resetHistoryToBaseline();
      switch (operation) {
        case 'add':
          notifier.addImageDrawable(image('b'));
        case 'remove':
          notifier.removeImageDrawable('a');
        case 'clear':
          notifier.clear();
      }
      final editedIds = operation == 'add' ? ['a', 'b'] : <String>[];
      notifications.clear();

      notifier.undo();
      expectEdit(notifications.single, .undo, editedIds, ['a']);
      expect(notifier.currentState.scribble.imageDrawables.single.id, 'a');
      expect(notifier.activeImageEdit, isNull);

      notifications.clear();
      notifier.redo();
      expectEdit(notifications.single, .redo, ['a'], editedIds);
      expect(
        notifier.currentScribble.imageDrawables.map((item) => item.id),
        editedIds,
      );
      expect(notifier.activeImageEdit, isNull);
    });
  }

  test('should_use_applied_state_when_load_diverges_from_undo_history', () {
    notifier.addImageDrawable(image('a'));
    notifier.addImageDrawable(image('b'));
    notifier.setScribble(
      scribble: Scribble(imageDrawables: [image('loaded')]),
      addToUndoHistory: false,
    );
    notifications.clear();

    notifier.undo();
    expectEdit(notifications.single, .undo, ['loaded'], ['a']);
    notifier.setScribble(
      scribble: Scribble(imageDrawables: [image('external')]),
      addToUndoHistory: false,
    );
    notifications.clear();
    notifier.redo();
    expectEdit(notifications.single, .redo, ['external'], ['a', 'b']);
  });

  test(
    'should_keep_history_callback_deferred_and_token_free_when_applied',
    () async {
      notifier.addImageDrawable(image('a'));
      final callbackEdits = <ScribbleImageEdit?>[];
      notifier.onHistoryApplied = () =>
          callbackEdits.add(notifier.activeImageEdit);
      notifications.clear();

      notifier.undo();
      notifier.redo();
      expect(notifications, hasLength(2));
      expectEdit(notifications[0], .undo, ['a'], []);
      expectEdit(notifications[1], .redo, [], ['a']);
      expect(callbackEdits, isEmpty);
      await Future<void>.value();
      expect(callbackEdits, [null, null]);
    },
  );

  test('should_expose_no_token_when_finished_callback_runs', () {
    final finishedEdits = <ScribbleImageEdit?>[];
    notifier.onScribbleFinished = () =>
        finishedEdits.add(notifier.activeImageEdit);
    notifier.addImageDrawable(image('a'));
    notifier.setScribble(scribble: Scribble());

    expect(finishedEdits, [null, null]);
    expect(notifications.whereType<ScribbleImageEdit>(), hasLength(2));
  });

  test('should_preserve_no_ops_and_baseline_when_no_membership_is_applied', () {
    notifier.undo();
    notifier.redo();
    notifier.clear();
    expect(notifications, isEmpty);
    notifier.removeImageDrawable('missing');
    notifier.updateImageDrawable('missing', image('unused'));
    notifier.setScribble(scribble: notifier.currentScribble);
    notifier.setScribble(
      scribble: Scribble(imageDrawables: [image('loaded')]),
      addToUndoHistory: false,
    );
    notifier.resetHistoryToBaseline();
    expect(notifier.canUndo, isFalse);
    notifier.undo();
    notifier.redo();
    notifier.clearQueue();
    notifier.clearRedoQueue();

    expect(notifications, isNotEmpty);
    expect(notifications, everyElement(isNull));
    expect(notifier.activeImageEdit, isNull);
  });

  test('should_not_infer_history_application_when_operations_are_blocked', () {
    notifier.addImageDrawable(image('a'));
    notifications.clear();
    notifier.operationsAllowed = false;
    expect(notifier.canUndo, isTrue);
    notifier.undo();
    expect(notifications, isEmpty);
    expect(notifier.activeImageEdit, isNull);
    notifier.operationsAllowed = true;
    notifier.undo();
    notifications.clear();
    notifier.operationsAllowed = false;
    expect(notifier.canRedo, isTrue);
    notifier.redo();
    expect(notifications, isEmpty);
    expect(notifier.activeImageEdit, isNull);
  });

  test('should_expose_no_token_when_only_text_and_strokes_are_cleared', () {
    notifier.setScribble(
      scribble: Scribble(
        textDrawables: [TextDrawable(id: 'text')],
        strokes: [Stroke(ink: 'pen')],
      ),
    );
    notifier.clear();
    notifier.undo();
    notifier.redo();
    expect(notifications, hasLength(4));
    expect(notifications, everyElement(isNull));
  });

  test(
    'should_expose_no_token_when_cursor_tool_or_temporary_value_changes',
    () {
      notifier.addImageDrawable(image('a'));
      notifications.clear();
      notifier.updateImageDrawable(
        'a',
        image('temporary'),
        addToUndoHistory: false,
      );
      notifier.setTemporary(
        Drawing(scribble: Scribble(), pointerPosition: Point(x: 1)),
      );
      notifier.clearCursor();
      notifier.setEraser();
      notifier.setStrokeInk();
      notifier.setColor();
      notifier.state = Drawing(
        scribble: Scribble(imageDrawables: [image('raw')]),
      );

      expect(notifications, hasLength(7));
      expect(notifications, everyElement(isNull));
    },
  );

  test(
    'should_retain_frozen_snapshots_when_inputs_change_after_callback',
    () async {
      final original = image('a');
      notifier.addImageDrawable(original);
      notifier.removeImageDrawable('a');
      final added = notifications[0]!;
      final removed = notifications[1]!;
      original.source = 'mutated';
      original.x = 999;
      await Future<void>.value();

      expect(notifier.activeImageEdit, isNull);
      for (final snapshot in [added.after.single, removed.before.single]) {
        expect(snapshot, isNot(same(original)));
        expect(snapshot.source, 'file:///a.png');
        expect(snapshot.x, 10);
        expect(snapshot.isFrozen, isTrue);
        expect(() => snapshot.source = 'bad', throwsUnsupportedError);
        expect(() => snapshot.clearId(), throwsUnsupportedError);
      }
      for (final snapshot in [
        added.before,
        added.after,
        removed.before,
        removed.after,
      ]) {
        expect(() => snapshot.add(image('bad')), throwsUnsupportedError);
        if (snapshot.isNotEmpty) {
          expect(() => snapshot[0] = image('bad'), throwsUnsupportedError);
        }
      }
      expect(original.isFrozen, isFalse);
    },
  );

  test('should_copy_lists_and_images_when_edit_is_constructed_directly', () {
    final before = [image('a')];
    final after = [image('b')];
    final edit = ScribbleImageEdit(before: before, after: after, kind: .edit);
    before.single.id = 'changed';
    after.single.id = 'changed';
    before.clear();
    after.clear();

    expectEdit(edit, .edit, ['a'], ['b']);
    expect(edit.before.single.isFrozen, isTrue);
    expect(edit.after.single.isFrozen, isTrue);
  });

  for (final outerKind in ScribbleImageEditKind.values) {
    test('should_mask_nested_non_edits_when_notifying_${outerKind.name}', () {
      final a = image('a');
      if (outerKind != .edit) notifier.addImageDrawable(a);
      if (outerKind == .redo) notifier.undo();
      notifications.clear();
      var nested = false;
      notifier.addListener(() {
        final outer = notifier.activeImageEdit;
        if (nested || outer == null) return;
        nested = true;
        notifier.setScribble(
          scribble: Scribble(imageDrawables: [image('load')]),
          addToUndoHistory: false,
        );
        notifier.resetHistoryToBaseline();
        notifier.setTemporary(Drawing(scribble: Scribble()));
        notifier.setEraser();
        notifier.addTextDrawable(TextDrawable(id: 'text'));
        expect(notifier.activeImageEdit, same(outer));
      });

      switch (outerKind) {
        case .edit:
          notifier.addImageDrawable(a);
        case .undo:
          notifier.undo();
        case .redo:
          notifier.redo();
      }

      expect(nested, isTrue);
      expect(notifications, hasLength(6));
      expect(notifications.first!.kind, outerKind);
      expect(notifications.skip(1), everyElement(isNull));
      expect(notifier.activeImageEdit, isNull);
      notifier.notifyListeners();
      expect(notifications.last, isNull);
    });
  }

  test('should_restore_outer_token_when_listener_commits_a_nested_edit', () {
    var nested = false;
    notifier.addListener(() {
      if (nested) return;
      nested = true;
      final outer = notifier.activeImageEdit;
      notifier.setScribble(scribble: Scribble(imageDrawables: [image('b')]));
      expect(notifier.activeImageEdit, same(outer));
    });
    notifier.addImageDrawable(image('a'));

    expect(notifications, hasLength(2));
    expectEdit(notifications[0], .edit, [], ['a']);
    expectEdit(notifications[1], .edit, ['a'], ['b']);
    expect(notifier.activeImageEdit, isNull);
  });

  test('should_restore_history_kind_when_listener_redoes_during_undo', () {
    notifier.addImageDrawable(image('a'));
    notifications.clear();
    var nested = false;
    notifier.addListener(() {
      if (nested) return;
      nested = true;
      final outer = notifier.activeImageEdit;
      notifier.redo();
      expect(notifier.activeImageEdit, same(outer));
    });
    notifier.undo();

    expect(notifications, hasLength(2));
    expectEdit(notifications[0], .undo, ['a'], []);
    expectEdit(notifications[1], .redo, [], ['a']);
    expect(notifier.activeImageEdit, isNull);
    notifier.removeImageDrawable('a');
    expectEdit(notifications.last, .edit, ['a'], []);
  });

  test('should_clear_pending_token_when_history_transform_throws', () {
    notifier.addImageDrawable(image('a'));
    notifications.clear();
    notifier.throwAfterTransform = true;
    expect(notifier.undo, throwsStateError);
    expect(notifier.activeImageEdit, isNull);
    expect(notifications, isEmpty);
    notifier.setColor();
    expect(notifications.single, isNull);
    notifier.throwAfterTransform = false;
    notifier.removeImageDrawable('a');
    expectEdit(notifications.last, .edit, ['a'], []);
  });

  testWidgets('should_clear_active_token_when_state_listener_throws', (
    tester,
  ) async {
    void failingListener() => throw StateError('listener failed');
    notifier.addListener(failingListener);
    notifier.addImageDrawable(image('a'));

    expect(tester.takeException(), isStateError);
    expectEdit(notifications.single, .edit, [], ['a']);
    expect(notifier.activeImageEdit, isNull);
    notifier.removeListener(failingListener);
    notifier.setColor();
    expect(notifications.last, isNull);
  });

  for (final delegation in ['controller', 'drawingState']) {
    test('should_preserve_tokens_when_delegating_through_$delegation', () {
      final controller = ScribbleController();
      addTearDown(controller.dispose);
      final delegated = controller.scribbleNotifier;
      final observed = <ScribbleImageEdit?>[];
      controller.onScribbleChanged = (_) =>
          observed.add(delegated.activeImageEdit);
      controller.loadScribble(Scribble(imageDrawables: [image('loaded')]));
      expect(observed, [null, null]);
      observed.clear();
      delegated.addImageDrawable(image('a'));
      final drawingState = DrawingState();
      drawingState.setLastActiveScribbleNotifier(delegated);

      if (delegation == 'controller') {
        controller.undo();
        controller.redo();
        controller.clear();
      } else {
        drawingState.undo();
        drawingState.redo();
        drawingState.clearActive();
      }

      expect(observed, hasLength(4));
      expectEdit(observed[0], .edit, ['loaded'], ['loaded', 'a']);
      expectEdit(observed[1], .undo, ['loaded', 'a'], ['loaded']);
      expectEdit(observed[2], .redo, ['loaded'], ['loaded', 'a']);
      expectEdit(observed[3], .edit, ['loaded', 'a'], []);
      expect(delegated.activeImageEdit, isNull);
    });
  }
}

/// Exposes temporary frames and history failure/permission seams for tests.
class ScribbleImageEditTest extends ScribbleNotifier {
  bool operationsAllowed = true;
  bool throwAfterTransform = false;

  @override
  bool get allowOperations => operationsAllowed;

  void setTemporary(ScribbleState next) => temporaryValue = next;

  @override
  ScribbleState transformHistoryValue(
    ScribbleState history,
    ScribbleState current,
  ) {
    final transformed = super.transformHistoryValue(history, current);
    if (throwAfterTransform) throw StateError('history transform failed');
    return transformed;
  }
}
