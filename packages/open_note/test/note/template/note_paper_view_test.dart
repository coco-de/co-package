import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/template/template.dart';

import '../support/note_test_host.dart';
import 'support/pending_image_provider.dart';

void main() {
  const size = NotePageSize(200, 300);

  NotePaperTemplate picture({String? source = 'file:///paper.png'}) =>
      NotePaperTemplate(
        id: 'photo',
        kind: NotePaperKind.image,
        size: size,
        imageSource: source,
        imageFit: NotePaperImageFit.cover,
        imageOpacity: 0.75,
      );

  RawImage? rawImage(WidgetTester tester) {
    final found = find.byType(RawImage);

    return found.evaluate().isEmpty ? null : tester.widget<RawImage>(found);
  }

  Future<void> pumpView(
    WidgetTester tester,
    NotePaperTemplate paper, {
    NotePaperImageResolver? resolver,
  }) => tester.pumpWidget(
    noteTestHost(
      Center(
        child: resolver == null
            ? NotePaperView(template: paper)
            : NotePaperView(template: paper, imageProviderResolver: resolver),
      ),
    ),
  );

  testWidgets('is exactly as large as its template', (tester) async {
    await pumpView(tester, NotePaperTemplate.lined(size: size));
    expect(tester.getSize(find.byType(NotePaperView)), const Size(200, 300));
  });

  testWidgets('keeps its size when the surface is smaller', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: NotePaperView(template: NotePaperTemplate.grid()),
        ),
      ),
    );
    expect(tester.getSize(find.byType(NotePaperView)), const Size(595, 842));
  });

  testWidgets('paints the paper with a NotePaperPainter', (tester) async {
    final paper = NotePaperTemplate.lined(size: size);
    await pumpView(tester, paper);
    final custom = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(NotePaperView),
        matching: find.byType(CustomPaint),
      ),
    );
    expect((custom.painter! as NotePaperPainter).template, paper);
    expect(
      find.descendant(
        of: find.byType(NotePaperView),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(
      find.byType(NotePaperView),
      paints..rect(color: const Color(0xFFFFFFFF)),
    );
  });

  testWidgets('resolves pictures only for image papers', (tester) async {
    final asked = <String>[];
    ImageProvider resolver(String source) {
      asked.add(source);

      return PendingImageProvider();
    }

    await pumpView(
      tester,
      NotePaperTemplate.grid(size: size).copyWith(imageSource: 'ignored'),
      resolver: resolver,
    );
    await pumpView(tester, picture(source: null), resolver: resolver);
    await pumpView(tester, picture(source: ''), resolver: resolver);
    expect(asked, isEmpty);
    await pumpView(tester, picture(), resolver: resolver);
    expect(asked, ['file:///paper.png']);
  });

  testWidgets('shows plain paper until the picture is ready', (tester) async {
    final provider = PendingImageProvider();
    await pumpView(tester, picture(), resolver: (_) => provider);
    expect(rawImage(tester)?.image, isNull);
    expect(
      find.byType(NotePaperView),
      paints..rect(color: const Color(0xFFFFFFFF)),
    );

    await tester.runAsync(() async {
      final decoded = await createTestImage(width: 4, height: 6, cache: false);
      provider.completer.complete(ImageInfo(image: decoded));
    });
    await tester.pump();

    final shown = rawImage(tester)!;
    expect(shown.image, isNotNull);
    expect(shown.fit, BoxFit.cover);
    expect(shown.opacity!.value, 0.75);
    expect(tester.getSize(find.byType(Image)), const Size(200, 300));
  });

  testWidgets('a broken picture leaves plain paper', (tester) async {
    final provider = PendingImageProvider();
    await pumpView(tester, picture(), resolver: (_) => provider);
    provider.completer.completeError(StateError('missing file'));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(rawImage(tester), isNull);
    expect(tester.getSize(find.byType(NotePaperView)), const Size(200, 300));
  });

  testWidgets('does not need a Directionality or MediaQuery', (tester) async {
    await tester.pumpWidget(
      Center(child: NotePaperView(template: picture(source: null))),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(NotePaperView)), const Size(200, 300));
  });
}
