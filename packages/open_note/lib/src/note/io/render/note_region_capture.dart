import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:open_note/src/note/io/render/note_page_render_input.dart';
import 'package:open_note/src/note/io/render/note_page_renderer.dart';

/// Cuts a region out of a page as a PNG — how a "screenshot to sticker" with a
/// transparent background is made.
abstract final class NoteRegionCapture {
  /// A PNG of [region] (page units) rendered at [pixelRatio] pixels per unit.
  ///
  /// With [transparentBackground] (the default) the PNG holds only the ink,
  /// images and objects of the region on transparency — no paper. Pass false to
  /// include the paper, like a screenshot. Parts of [region] outside the page
  /// stay transparent.
  ///
  /// Throws [ArgumentError] for an empty or non-finite [region] or a
  /// non-positive [pixelRatio].
  static Future<Uint8List> capture(
    NotePageRenderInput input,
    ui.Rect region, {
    bool transparentBackground = true,
    double pixelRatio = 2,
  }) => NotePageRenderer.renderToPng(
    input,
    region: region,
    pixelRatio: pixelRatio,
    includeBackground: !transparentBackground,
  );
}
