import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/objects/objects.dart';

import '../support/note_test_host.dart';
import 'support/objects_test_support.dart';

const NoteStickyObject sticky = NoteStickyObject(
  id: 's',
  bounds: Rect.fromLTWH(100, 100, 160, 120),
  text: 'hello',
);

String stickyText(LayerHarness harness) =>
    (harness.object('s') as NoteStickyObject).text;

/// A provider whose picture never arrives, or arrives at once as [image].
class FakeImage extends ImageProvider<FakeImage> {
  const FakeImage(this.source, [this.image]);

  final String source;
  final ui.Image? image;

  @override
  Future<FakeImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(FakeImage key, ImageDecoderCallback decode) {
    final picture = image;

    return OneFrameImageStreamCompleter(
      picture == null
          ? Completer<ImageInfo>().future
          : SynchronousFuture(ImageInfo(image: picture.clone())),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FakeImage && other.source == source;

  @override
  int get hashCode => source.hashCode;
}

void main() {
  group('sticky note editing', () {
    Future<LayerHarness> editSticky(
      WidgetTester tester, {
      List<NoteObject> more = const [],
    }) async {
      final harness = LayerHarness(tester, objects: [sticky, ...more]);
      await harness.pump();
      await harness.doubleTap(sticky.bounds.center);

      return harness;
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(EditableText), text);
      await tester.pump();
    }

    testWidgets('shows the text, then a focused field while editing', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [sticky]);
      await harness.pump(NoteObjectLayerMode.view);
      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);

      await harness.pump();
      await harness.doubleTap(sticky.bounds.center);

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.controller.text, 'hello');
      expect(field.focusNode.hasFocus, isTrue);
      expect(field.controller.selection.baseOffset, 5);
    });

    testWidgets('commits once, when editing ends, as one undo step', (
      tester,
    ) async {
      final harness = await editSticky(tester);

      await type(tester, 'hello w');
      await type(tester, 'hello world');
      // Nothing is committed while typing.
      expect(stickyText(harness), 'hello');
      expect(harness.history.undoLength, 0);
      await harness.tap(const Offset(350, 450));

      expect(stickyText(harness), 'hello world');
      expect(find.byType(EditableText), findsNothing);
      expect(harness.history.undoLength, 1);
      expect(harness.history.undoLabel, 'Edit');
      harness.history.undo();
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('keeps line breaks', (tester) async {
      final harness = await editSticky(tester);

      await type(tester, 'one\ntwo');
      harness.controller.endEditing();
      await tester.pump();

      expect(stickyText(harness), 'one\ntwo');
    });

    testWidgets('records nothing when nothing changed', (tester) async {
      final harness = await editSticky(tester);

      await harness.tap(const Offset(350, 450));
      await tester.pump();

      expect(harness.history.undoLength, 0);
    });

    testWidgets('losing focus commits while editing goes on', (tester) async {
      final harness = await editSticky(tester);
      await type(tester, 'blurred');

      tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode
          .unfocus();
      await tester.pump();

      expect(stickyText(harness), 'blurred');
      expect(harness.controller.editingId, 's');
      await type(tester, 'more');
      harness.controller.endEditing();
      await tester.pump();
      expect(stickyText(harness), 'more');
      expect(harness.history.undoLength, 2);
    });

    testWidgets('a tap anywhere on the paper focuses the field', (
      tester,
    ) async {
      final harness = await editSticky(tester);
      final focus = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;
      focus.unfocus();
      await tester.pump();

      // Well below the only line of text.
      await harness.tap(const Offset(180, 205));

      expect(focus.hasFocus, isTrue);
      expect(harness.controller.editingId, 's');
    });

    testWidgets('dragging another object keeps the typing a separate step', (
      tester,
    ) async {
      final other = box('b', bounds: const Rect.fromLTWH(20, 300, 80, 60));
      final harness = await editSticky(tester, more: [other]);
      await type(tester, 'typed');

      await harness.drag(other.bounds.center, const Offset(50, 0));
      await tester.pump();

      expect(stickyText(harness), 'typed');
      expect(harness.history.undoLength, 2);
      expect(harness.history.undoLabel, 'Move');
      harness.history.undo();
      expect(stickyText(harness), 'typed');
      expect(harness.object('b'), other);
      harness.history.undo();
      expect(stickyText(harness), 'hello');
    });

    testWidgets('duplicating copies the typed text', (tester) async {
      final harness = await editSticky(tester);
      await type(tester, 'copy me');

      final copies = harness.controller.duplicate(['s']);
      await tester.pump();

      expect(
        (harness.object(copies.single) as NoteStickyObject).text,
        'copy me',
      );
      expect(stickyText(harness), 'copy me');
    });

    testWidgets('moving it while editing keeps the typing', (tester) async {
      final harness = await editSticky(tester);
      await type(tester, 'typed');

      harness.controller.moveBy(['s'], const Offset(10, 10));
      await tester.pump();
      harness.controller.endEditing();
      await tester.pump();

      expect(stickyText(harness), 'typed');
      expect(harness.object('s').bounds.left, 110);
    });

    testWidgets('leaving edit mode commits', (tester) async {
      final harness = await editSticky(tester);
      await type(tester, 'typed');

      await harness.pump(NoteObjectLayerMode.passThrough);
      await tester.pump();

      expect(stickyText(harness), 'typed');
      expect(harness.controller.editingId, isNull);
      expect(harness.history.undoLength, 1);
    });

    testWidgets('removing the layer commits', (tester) async {
      final harness = await editSticky(tester);
      await type(tester, 'typed');

      await tester.pumpWidget(noteTestHost(const SizedBox()));
      await tester.pump();

      expect(stickyText(harness), 'typed');
      expect(harness.history.undoLength, 1);
    });

    testWidgets('switching controllers commits to the old one', (tester) async {
      final harness = await editSticky(tester);
      await type(tester, 'old page');
      final next = NoteObjectController(
        objects: [sticky.copyWith(text: 'new page')],
      );
      addTearDown(next.dispose);

      await tester.pumpWidget(
        noteTestHost(
          Center(
            child: NoteObjectLayer(
              controller: next,
              registry: harness.registry,
              size: testPageSize,
              mode: NoteObjectLayerMode.edit,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(stickyText(harness), 'old page');
      expect((next.find('s')! as NoteStickyObject).text, 'new page');
      expect(find.text('new page'), findsOneWidget);
    });

    testWidgets('flushing commits without ending', (tester) async {
      final harness = await editSticky(tester);
      await type(tester, 'saved');

      harness.controller.flushPendingEdits();
      await tester.pump();

      expect(stickyText(harness), 'saved');
      expect(harness.controller.editingId, 's');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'saved',
      );
    });

    testWidgets('an outside change wins over unsaved typing', (tester) async {
      final harness = LayerHarness(tester, objects: [sticky]);
      // Selected while changed, so undoing it keeps the note selected.
      harness.controller
        ..select('s')
        ..update(sticky.copyWith(text: 'second'));
      await harness.pump();
      await harness.doubleTap(sticky.bounds.center);
      await type(tester, 'unsaved');

      harness.history.undo();
      await tester.pump();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'hello',
      );
      harness.controller.endEditing();
      await tester.pump();
      expect(stickyText(harness), 'hello');
    });

    testWidgets('flushing and undoing in one go really undoes', (tester) async {
      final harness = await editSticky(tester);
      await type(tester, 'typed');

      // What a host's undo button does while the field is open.
      harness.controller.flushPendingEdits();
      harness.history.undo();
      await tester.pump();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'hello',
      );
      harness.controller.endEditing();
      await tester.pump();
      expect(stickyText(harness), 'hello');
      expect(harness.history.redoLength, 1);
    });

    testWidgets('an undo that ends editing keeps redo and drops typing', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [sticky]);
      // Nothing selected while changed, so undoing it deselects the note.
      harness.controller.update(sticky.copyWith(text: 'second'));
      await harness.pump();
      await harness.doubleTap(sticky.bounds.center);
      await type(tester, 'unsaved');

      harness.history.undo();
      await tester.pump();
      await tester.pump();

      expect(harness.controller.editingId, isNull);
      expect(stickyText(harness), 'hello');
      // Nothing new was recorded, so the change can still be redone.
      expect(harness.history.redoLength, 1);
    });

    testWidgets('an outside change just before ending is not undone', (
      tester,
    ) async {
      final harness = await editSticky(tester);
      await type(tester, 'unsaved');

      // No frame in between: the field has not seen the new text yet.
      harness.controller
        ..update(sticky.copyWith(text: 'remote'))
        ..endEditing();
      await tester.pump();

      expect(stickyText(harness), 'remote');
    });

    testWidgets('reloading drops the typing', (tester) async {
      final harness = await editSticky(tester);
      await type(tester, 'unsaved');

      harness.controller.replaceAll([sticky]);
      await tester.pump();
      await tester.pump();

      expect(stickyText(harness), 'hello');
      expect(harness.history.undoLength, 0);
    });

    testWidgets('an empty note shows a translatable hint', (tester) async {
      final registry = NoteObjectRegistry();
      registerNoteObjects(
        registry,
        strings: const NoteObjectsStrings(stickyHint: '메모를 입력하세요'),
      );
      final controller = NoteObjectController(
        objects: [sticky.copyWith(text: '')],
      )..beginEditing('s');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        noteTestHost(
          NoteObjectLayer(
            controller: controller,
            registry: registry,
            size: testPageSize,
            mode: NoteObjectLayerMode.edit,
          ),
        ),
      );

      expect(find.text('메모를 입력하세요'), findsOneWidget);
    });

    testWidgets('ignores the device text scale', (tester) async {
      Widget scaled(Widget child) => noteTestHost(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(3)),
            child: SizedBox(width: 160, height: 120, child: child),
          ),
        ),
      );
      await tester.pumpWidget(
        scaled(
          const NoteStickyView(object: sticky, scope: NoteObjectViewScope()),
        ),
      );
      expect(
        tester.widget<Text>(find.text('hello')).textScaler,
        TextScaler.noScaling,
      );

      await tester.pumpWidget(
        scaled(
          const NoteStickyView(
            object: sticky,
            scope: NoteObjectViewScope(editing: true),
          ),
        ),
      );
      expect(
        MediaQuery.textScalerOf(tester.element(find.byType(EditableText))),
        TextScaler.noScaling,
      );
    });

    testWidgets('works without a layer through onChanged', (tester) async {
      final changes = <NoteObject>[];
      Widget view({required bool editing}) => noteTestHost(
        SizedBox(
          width: 160,
          height: 120,
          child: NoteStickyView(
            object: sticky,
            scope: NoteObjectViewScope(
              editing: editing,
              onChanged: changes.add,
            ),
          ),
        ),
      );
      await tester.pumpWidget(view(editing: true));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'standalone');

      await tester.pumpWidget(view(editing: false));
      await tester.pump();

      expect(changes, [sticky.copyWith(text: 'standalone')]);
    });
  });

  group('arrow view', () {
    testWidgets('draws the arrow across its own size', (tester) async {
      await tester.pumpWidget(
        noteTestHost(
          const Center(
            child: SizedBox(
              width: 80,
              height: 20,
              child: NoteArrowView(
                object: NoteArrowObject(
                  id: 'a',
                  // The view draws in its own space, not at the bounds.
                  bounds: Rect.fromLTWH(300, 300, 80, 20),
                  color: Color(0xFFFF0000),
                  width: 4,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byType(NoteArrowView),
        paints
          ..line(
            p1: const Offset(0, 10),
            // The shaft stops short, under the 16-unit head.
            p2: const Offset(80 - 16 * 0.9, 10),
            color: const Color(0xFFFF0000),
          )
          ..path(color: const Color(0xFFFF0000)),
      );
    });
  });

  group('sticker view', () {
    const sticker = NoteStickerObject(
      id: 't',
      bounds: Rect.fromLTWH(0, 0, 100, 100),
      source: 'cat',
    );

    Widget host(Widget child) => noteTestHost(
      Center(child: SizedBox(width: 100, height: 100, child: child)),
    );

    testWidgets('resolves its source once, again when it changes', (
      tester,
    ) async {
      final resolved = <String>[];
      FakeImage resolve(String source) {
        resolved.add(source);

        return FakeImage(source);
      }

      Widget view(NoteStickerObject object) =>
          host(NoteStickerView(object: object, imageProviderResolver: resolve));
      await tester.pumpWidget(view(sticker));
      await tester.pumpWidget(view(sticker.copyWith(flipHorizontal: true)));
      expect(resolved, ['cat']);

      await tester.pumpWidget(view(sticker.copyWith(source: 'dog')));

      expect(resolved, ['cat', 'dog']);
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        const FakeImage('dog'),
      );
      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
    });

    testWidgets('uses the resolver given to registerNoteObjects', (
      tester,
    ) async {
      final registry = NoteObjectRegistry();
      registerNoteObjects(registry, imageProviderResolver: FakeImage.new);
      final controller = NoteObjectController(objects: [sticker]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        noteTestHost(
          NoteObjectLayer(
            controller: controller,
            registry: registry,
            size: testPageSize,
          ),
        ),
      );

      expect(
        tester.widget<Image>(find.byType(Image)).image,
        const FakeImage('cat'),
      );
    });

    testWidgets('shows a placeholder until a frame exists', (tester) async {
      await tester.pumpWidget(
        host(
          const NoteStickerView(
            object: sticker,
            imageProviderResolver: FakeImage.new,
          ),
        ),
      );
      expect(find.byType(RawImage), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);

      // The engine creates images outside the fake-async zone.
      final picture = (await tester.runAsync(
        () => createTestImage(width: 4, height: 4),
      ))!;
      addTearDown(picture.dispose);
      await tester.pumpWidget(
        host(
          NoteStickerView(
            object: sticker.copyWith(source: 'ready'),
            imageProviderResolver: (source) => FakeImage(source, picture),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(RawImage), findsOneWidget);
    });

    testWidgets('mirrors the picture', (tester) async {
      Matrix4 transformOf(WidgetTester tester) => tester
          .widget<Transform>(
            find.ancestor(
              of: find.byType(Image),
              matching: find.byType(Transform),
            ),
          )
          .transform;
      Widget view({required bool flipped}) => host(
        NoteStickerView(
          object: sticker.copyWith(flipHorizontal: flipped),
          imageProviderResolver: FakeImage.new,
        ),
      );

      await tester.pumpWidget(view(flipped: false));
      expect(transformOf(tester).storage.first, 1);
      await tester.pumpWidget(view(flipped: true));
      expect(transformOf(tester).storage.first, -1);
    });

    testWidgets('an empty source shows no image at all', (tester) async {
      await tester.pumpWidget(
        host(NoteStickerView(object: sticker.copyWith(source: ''))),
      );

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('defaults to the engine resolver', (tester) async {
      await tester.pumpWidget(
        host(NoteStickerView(object: sticker.copyWith(source: '/tmp/a.png'))),
      );

      final provider = tester.widget<Image>(find.byType(Image)).image;
      expect(provider, isA<FileImage>());
      expect((provider as FileImage).file.path, File('/tmp/a.png').path);
    });
  });

  group('registry', () {
    testWidgets('typing into such an object is not lost', (tester) async {
      final controller = NoteObjectController(
        objects: [NoteObjectRegistry().decode(sticky.toJson())!],
      )..beginEditing('s');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        noteTestHost(
          NoteObjectLayer(
            controller: controller,
            registry: testRegistry(),
            size: testPageSize,
            mode: NoteObjectLayerMode.edit,
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'typed');

      controller.endEditing();
      await tester.pump();

      // Committing replaces the raw object with a real sticky note.
      expect(controller.find('s'), sticky.copyWith(text: 'typed'));
    });

    testWidgets('builds an object decoded before its kind was known', (
      tester,
    ) async {
      final early = NoteObjectRegistry().decode(sticky.toJson())!;
      expect(early, isA<NoteUnknownObject>());
      final controller = NoteObjectController(objects: [early]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        noteTestHost(
          NoteObjectLayer(
            controller: controller,
            registry: testRegistry(),
            size: testPageSize,
          ),
        ),
      );

      expect(find.byType(NoteStickyView), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
    });
  });
}
