import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/document/note_page_background.dart';
import 'package:open_note/src/note/editor/note_export.dart';
import 'package:open_note/src/note/layer/note_scribble_view.dart';

/// A page drawn small and read-only, scaled to fit its constraints: paper,
/// visible layers and objects. Sticker pictures that are not decoded show as
/// placeholders.
class NotePageThumbnail extends StatelessWidget {
  const NotePageThumbnail({
    required this.page,
    super.key,
    this.sharedObjects = const [],
    this.imageProviderResolver = resolveImageSource,
    this.borderColor = const Color(0xFFD6D6DB),
  });

  final NotePage page;

  /// Objects shown on every page of the note.
  final List<NoteObject> sharedObjects;

  final NoteImageProviderResolver imageProviderResolver;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final size = page.size.toSize();

    return RepaintBoundary(
      child: FittedBox(
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(border: Border.all(color: borderColor)),
          child: SizedBox.fromSize(
            size: size,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFFFFFFFF)),
                  NotePageBackground(
                    page,
                    imageProviderResolver: imageProviderResolver,
                  ),
                  for (final content in page.layers)
                    if (content.layer.visible && !content.isEmpty)
                      Opacity(
                        opacity: content.layer.opacity,
                        child: NoteScribbleView(
                          scribble: content.scribble,
                          size: size,
                          imageProviderResolver: imageProviderResolver,
                        ),
                      ),
                  CustomPaint(
                    painter: _ObjectsPainter([
                      ...page.objects,
                      ...sharedObjects,
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ObjectsPainter extends CustomPainter {
  const _ObjectsPainter(this.objects);

  final List<NoteObject> objects;

  @override
  void paint(Canvas canvas, Size size) {
    for (final object in objects) {
      final bounds = object.bounds;
      canvas
        ..save()
        ..translate(bounds.center.dx, bounds.center.dy)
        ..rotate(object.rotation)
        ..translate(-bounds.center.dx, -bounds.center.dy);
      final faded = object.opacity < 1;
      if (faded) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromRGBO(0, 0, 0, object.opacity),
        );
      }
      object.paintToCanvas(canvas, NoteObjectPaintContext.empty);
      if (faded) canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ObjectsPainter oldDelegate) =>
      !_sameObjects(objects, oldDelegate.objects);

  static bool _sameObjects(List<NoteObject> a, List<NoteObject> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }

    return true;
  }
}
