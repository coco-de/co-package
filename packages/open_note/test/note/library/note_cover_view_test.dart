import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/library.dart';

import '../support/note_test_host.dart';

const double _a4Ratio = 595 / 842;

/// An image that always fails to load.
class _BrokenImage extends ImageProvider<_BrokenImage> {
  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _BrokenImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(StateError('cannot load')),
  );
}

NoteCoverPainter _painterOf(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(NoteCoverView),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((paint) => paint.painter)
    .whereType<NoteCoverPainter>()
    .single;

Widget _inBox(Widget child, {double width = 200, double height = 400}) =>
    noteTestHost(
      Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: height),
          child: child,
        ),
      ),
    );

void main() {
  group('NoteCoverView size', () {
    testWidgets('fills tight constraints', (tester) async {
      await tester.pumpWidget(
        noteTestHost(
          const Center(
            child: SizedBox(
              width: 120,
              height: 200,
              child: NoteCoverView(cover: NoteCover.standard),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(NoteCoverView)), const Size(120, 200));
    });

    testWidgets('keeps the page proportions in loose constraints', (
      tester,
    ) async {
      await tester.pumpWidget(
        _inBox(const NoteCoverView(cover: NoteCover.standard)),
      );

      final size = tester.getSize(find.byType(NoteCoverView));
      expect(size.width, closeTo(200, 0.01));
      expect(size.width / size.height, closeTo(_a4Ratio, 0.001));
    });

    testWidgets('is wide for a landscape cover', (tester) async {
      await tester.pumpWidget(
        _inBox(
          const NoteCoverView(
            cover: NoteCover.builtIn(
              'ocean',
              orientation: NotePageOrientation.landscape,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(NoteCoverView));
      expect(size.width, greaterThan(size.height));
    });

    testWidgets('takes its ratio from the width in a column', (tester) async {
      await tester.pumpWidget(
        noteTestHost(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [NoteCoverView(cover: NoteCover.standard)],
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(NoteCoverView));
      expect(size.width, closeTo(100, 0.01));
      expect(size.height, closeTo(100 / _a4Ratio, 0.01));
    });

    testWidgets('falls back to the page size with no limits', (tester) async {
      await tester.pumpWidget(
        noteTestHost(
          const Center(
            child: UnconstrainedBox(
              child: NoteCoverView(
                cover: NoteCover.builtIn('mint', size: NotePageSize(90, 120)),
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(NoteCoverView)), const Size(90, 120));
    });
  });

  group('NoteCoverView artwork', () {
    testWidgets('paints the built-in design', (tester) async {
      await tester.pumpWidget(
        _inBox(const NoteCoverView(cover: NoteCover.builtIn('plum'))),
      );

      expect(_painterOf(tester).design, NoteCoverCatalog.designOf('plum'));
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('paints a solid colour cover', (tester) async {
      const fill = Color(0xFF228844);
      await tester.pumpWidget(
        _inBox(const NoteCoverView(cover: NoteCover.solid(fill))),
      );

      expect(_painterOf(tester).design, NoteCoverDesign.solid(fill));
    });

    testWidgets('draws unknown built-ins like the default', (tester) async {
      await tester.pumpWidget(
        _inBox(const NoteCoverView(cover: NoteCover.builtIn('aurora'))),
      );

      expect(
        _painterOf(tester).design,
        NoteCoverCatalog.designOf(NoteCoverCatalog.defaultId),
      );
    });

    testWidgets('asks the resolver for an image cover', (tester) async {
      final asked = <String>[];
      await tester.pumpWidget(
        _inBox(
          NoteCoverView(
            cover: const NoteCover.picture('store://cover-1'),
            imageProviderResolver: (source) {
              asked.add(source);

              return _BrokenImage();
            },
          ),
        ),
      );

      expect(asked, contains('store://cover-1'));
      expect(find.byType(Image), findsOneWidget);
      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
      expect(
        _painterOf(tester).design,
        NoteCoverCatalog.imagePlaceholder,
        reason: 'plain placeholder under the picture',
      );
    });

    testWidgets('keeps the placeholder when the picture fails', (tester) async {
      await tester.pumpWidget(
        _inBox(
          NoteCoverView(
            cover: const NoteCover.picture('broken.png'),
            imageProviderResolver: (_) => _BrokenImage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_painterOf(tester).design, NoteCoverCatalog.imagePlaceholder);
    });

    testWidgets('shows only the placeholder without a provider', (
      tester,
    ) async {
      await tester.pumpWidget(
        _inBox(
          NoteCoverView(
            cover: const NoteCover.picture('unknown'),
            imageProviderResolver: (_) => null,
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(_painterOf(tester).design, NoteCoverCatalog.imagePlaceholder);
    });

    test('uses the engine resolver by default', () {
      const view = NoteCoverView(cover: NoteCover.standard);

      expect(view.imageProviderResolver, same(resolveImageSource));
    });

    testWidgets('has a semantic label when given one', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _inBox(
          const NoteCoverView(
            cover: NoteCover.standard,
            semanticLabel: 'Blue cover',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Blue cover'), findsOneWidget);
      handle.dispose();
    });
  });

  group('NoteCoverPainter', () {
    test('paints every design at any size', () {
      final designs = [
        for (final id in NoteCoverCatalog.builtIn)
          NoteCoverCatalog.designOf(id),
        NoteCoverCatalog.imagePlaceholder,
        for (final pattern in NoteCoverPattern.values)
          NoteCoverDesign(
            background: const Color(0xFF000000),
            accent: const Color(0xFFFFFFFF),
            pattern: pattern,
          ),
      ];
      const sizes = [
        Size.zero,
        Size(1, 1),
        Size(40, 52),
        Size(600, 800),
        Size(800, 40),
        Size(10, 500),
        Size(0.001, 20000),
      ];

      for (final design in designs) {
        for (final size in sizes) {
          final recorder = ui.PictureRecorder();

          NoteCoverPainter(design).paint(Canvas(recorder), size);

          recorder.endRecording().dispose();
        }
      }
    });

    test('paints visible pixels in the background colour', () async {
      const design = NoteCoverDesign(
        background: Color(0xFFFF0000),
        accent: Color(0xFF00FF00),
      );
      final recorder = ui.PictureRecorder();
      const NoteCoverPainter(
        design,
        cornerRadius: 0,
      ).paint(Canvas(recorder), const Size(100, 100));
      final image = await recorder.endRecording().toImage(100, 100);
      final bytes = (await image.toByteData())!;
      const center = (50 * 100 + 60) * 4;

      expect(bytes.getUint8(center), 255);
      expect(bytes.getUint8(center + 1), 0);
      expect(bytes.getUint8(center + 3), 255);
      image.dispose();
    });

    test('repaints only when something changes', () {
      final design = NoteCoverCatalog.designOf('ocean');
      final painter = NoteCoverPainter(design);

      expect(painter.shouldRepaint(NoteCoverPainter(design)), isFalse);
      expect(
        painter.shouldRepaint(NoteCoverPainter(design, cornerRadius: 2)),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          NoteCoverPainter(NoteCoverCatalog.designOf('forest')),
        ),
        isTrue,
      );
    });
  });
}
