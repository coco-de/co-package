import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/module/text/text_box_typography.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/note_document.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/document/note_page_background.dart';
import 'package:open_note/src/note/io/import/note_imported_page.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_exporter.dart';
import 'package:open_note/src/note/io/render/note_page_render_input.dart';
import 'package:open_note/src/note/io/render/note_page_render_layer.dart';
import 'package:open_note/src/note/objects/note_sticker_object.dart';
import 'package:open_note/src/note/study/overlay/note_mask_object.dart';
import 'package:open_note/src/note/study/overlay/note_tape_object.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// Turns an image source into a provider (the engine's resolver by default).
typedef NoteImageProviderResolver = ImageProvider Function(String source);

/// Every picture [page] (with the every-page [shared] objects) needs decoded
/// to be drawn without widgets.
Set<String> notePageImageSources(
  NotePage page, {
  Iterable<NoteObject> shared = const [],
}) => {
  for (final content in page.layers)
    if (content.layer.visible)
      for (final image in content.scribble.imageDrawables)
        if (!image.hidden && image.source.isNotEmpty) image.source,
  ?page.template.imageSource,
  ?page.marginTemplate?.imageSource,
  for (final object in [...page.objects, ...shared])
    ?switch (object) {
      NoteStickerObject(:final source) when source.isNotEmpty => source,
      NoteMaskObject(:final imageSource) => imageSource,
      NoteTapeObject(:final imageSource) => imageSource,
      _ => null,
    },
};

/// What `NotePageRenderer`, `NoteRegionCapture` and `NotePdfExporter` need to
/// draw [page]: its paper, layers and objects (with the every-page [shared]
/// ones on top). [images] holds the decoded [notePageImageSources].
NotePageRenderInput notePageRenderInput(
  NotePage page, {
  Iterable<NoteObject> shared = const [],
  Map<String, ui.Image> images = const {},
  TextBoxTypography textBoxTypography = defaultTextBoxTypography,
}) => NotePageRenderInput(
  size: page.size,
  paintBackground: (canvas, size) =>
      NotePageBackground.paint(canvas, page, images: images),
  layers: [
    for (final content in page.layers)
      NotePageRenderLayer(
        scribble: content.scribble,
        opacity: content.layer.opacity,
        visible: content.layer.visible,
      ),
  ],
  objects: [...page.objects, ...shared],
  images: images,
  textBoxTypography: textBoxTypography,
);

/// Decodes pictures. A source that fails is left out (it draws as a
/// placeholder). The caller disposes the images.
Future<Map<String, ui.Image>> loadNoteImages(
  Iterable<String> sources, {
  NoteImageProviderResolver resolver = resolveImageSource,
}) async {
  final images = <String, ui.Image>{};
  await Future.wait([
    for (final source in sources.toSet())
      _decode(source, resolver).then((image) {
        if (image != null) images[source] = image;
      }),
  ]);

  return images;
}

/// A vector PDF of [pageIds] (every page by default) of [document].
Future<Uint8List> exportNotePdf(
  NoteDocument document, {
  Iterable<String>? pageIds,
  NoteImageProviderResolver imageProviderResolver = resolveImageSource,
  bool includeBackground = true,
  TextBoxTypography textBoxTypography = defaultTextBoxTypography,
  void Function(int done, int total)? onPageExported,
}) async {
  final pages = [
    for (final id in pageIds ?? document.pageIds) ?document.page(id),
  ];
  final shared = document.documentObjects;
  final images = await loadNoteImages({
    for (final page in pages) ...notePageImageSources(page, shared: shared),
  }, resolver: imageProviderResolver);
  try {
    return await NotePdfExporter.export(
      [
        for (final page in pages)
          notePageRenderInput(
            page,
            shared: shared,
            images: images,
            textBoxTypography: textBoxTypography,
          ),
      ],
      includeBackground: includeBackground,
      title: document.title.isEmpty ? null : document.title,
      onPageExported: onPageExported,
    );
  } finally {
    for (final image in images.values) {
      image.dispose();
    }
  }
}

/// Note pages for pages an importer produced: each takes the imported picture
/// as its paper. [storeImage] keeps a picture and returns its source (pages
/// that already have a source use it). Add them with
/// `NoteDocument.appendPages` or `NoteEditorController.insertPages`.
Future<List<NotePage>> notePagesFromImport(
  List<NoteImportedPage> imported, {
  required Future<String> Function(Uint8List png, int index) storeImage,
  NoteIdFactory idFactory = generateNoteId,
  NoteClock clock = systemNoteClock,
}) async {
  final pages = <NotePage>[];
  for (final (index, page) in imported.indexed) {
    final png = page.backgroundPng;
    final source =
        page.backgroundSource ??
        (png == null ? null : await storeImage(png, index));
    final made = NotePage.blank(
      template: source == null
          ? NotePaperTemplate.blank(size: page.size)
          : NotePaperTemplate.image(
              id: 'imported:${idFactory()}',
              imageSource: source,
              size: page.size,
            ),
      idFactory: idFactory,
      clock: clock,
    );
    pages.add(
      source == null
          ? made
          : made.copyWith(pdf: page.pdf?.copyWith(picture: source)),
    );
  }

  return pages;
}

Future<ui.Image?> _decode(String source, NoteImageProviderResolver resolver) {
  final completer = Completer<ui.Image?>();
  final ImageStream stream;
  try {
    stream = resolver(source).resolve(ImageConfiguration.empty);
  } on Object catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );

    return Future.value();
  }
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) completer.complete(info.image.clone());
      info.dispose();
      stream.removeListener(listener);
    },
    onError: (error, stack) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);

  return completer.future;
}
