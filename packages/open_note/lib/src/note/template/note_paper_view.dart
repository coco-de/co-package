import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/template/note_paper_kind.dart';
import 'package:open_note/src/note/template/note_paper_painter.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// Turns an `imageSource` string into an [ImageProvider]. Return providers that
/// compare equal for equal sources, or the picture reloads on every rebuild.
typedef NotePaperImageResolver = ImageProvider Function(String source);

/// A paper as a widget, **exactly `template.size` large**, in page coordinates:
/// use it as the background of a page and let the host scale it.
///
/// An `image` paper resolves `imageSource` with [imageProviderResolver] and
/// shows plain paper until the picture is ready (and if it fails to load).
class NotePaperView extends StatelessWidget {
  const NotePaperView({
    required this.template,
    super.key,
    this.imageProviderResolver = resolveImageSource,
    this.sheetSize,
    this.paperRect,
  }) : assert(
         (sheetSize == null) == (paperRect == null),
         'a continued sheet needs both its size and the paper place',
       );

  /// With [paperRect]: shows a sheet of this size continuing the paper (see
  /// `NotePaperPainter.paperRect`). Only for papers that repeat.
  final Size? sheetSize;

  /// Where the paper lies on the sheet.
  final Rect? paperRect;

  /// The paper to show.
  final NotePaperTemplate template;

  /// Resolves the picture of an `image` paper. Defaults to the engine's
  /// platform resolver (local file path or URL).
  final NotePaperImageResolver imageProviderResolver;

  @override
  Widget build(BuildContext context) {
    final source = template.kind == NotePaperKind.image
        ? template.imageSource
        : null;

    return SizedBox(
      width: sheetSize?.width ?? template.size.width,
      height: sheetSize?.height ?? template.size.height,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: NotePaperPainter(template, paperRect: paperRect),
          isComplex: true,
          child: source == null || source.isEmpty
              ? null
              : _NotePaperPicture(
                  template: template,
                  image: imageProviderResolver(source),
                ),
        ),
      ),
    );
  }
}

class _NotePaperPicture extends StatelessWidget {
  const _NotePaperPicture({required this.template, required this.image});

  final NotePaperTemplate template;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) => Image(
    image: image,
    fit: template.imageFit.boxFit,
    opacity: AlwaysStoppedAnimation<double>(template.imageOpacity),
    filterQuality: FilterQuality.medium,
    gaplessPlayback: true,
    excludeFromSemantics: true,
    errorBuilder: _showPlainPaper,
  );

  static Widget _showPlainPaper(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => const SizedBox.shrink();
}
