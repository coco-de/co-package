import 'package:flutter/widgets.dart';
import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/module/image/styled_image_view.dart';
import 'package:open_note/src/note/style/note_image_style.dart';
import 'package:open_note/src/module/scribble_painter.dart';
import 'package:open_note/src/module/state/scribble.state.dart';
import 'package:open_note/src/module/state/scribble_mode.state.dart';
import 'package:open_note/src/module/text/text_box_typography.dart';
import 'package:open_note/src/module/text/text_painter.dart';

/// A read-only rendering of one [Scribble] in page coordinates, drawn the way
/// the active layer draws it: strokes first, then texts, then images. Used for
/// the layers that are not being edited, and for previews.
class NoteScribbleView extends StatelessWidget {
  const NoteScribbleView({
    required this.scribble,
    required this.size,
    super.key,
    this.textBoxTypography = defaultTextBoxTypography,
    this.imageProviderResolver,
  });

  final Scribble scribble;

  /// The page size the ink coordinates refer to.
  final Size size;
  final TextBoxTypography textBoxTypography;

  /// Resolves an image source; defaults to the engine's resolver.
  final ImageProvider Function(String source)? imageProviderResolver;

  /// The painter decides repaints by state identity: reuse one state per ink
  /// instance so unchanged layers are not repainted.
  static final Expando<Drawing> _states = Expando<Drawing>();

  static final ScribbleModeState _modeState = ScribbleModeState(
    inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pen),
  );

  @override
  Widget build(BuildContext context) {
    final resolve = imageProviderResolver ?? resolveImageSource;

    return SizedBox.fromSize(
      size: size,
      child: RepaintBoundary(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ScribblePainter(
                  state: _states[scribble] ??= Drawing(scribble: scribble),
                  modeState: _modeState,
                  drawPointer: false,
                  drawEraser: false,
                  showLassoOverlay: false,
                ),
              ),
            ),
            if (scribble.textDrawables.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: TextDrawablePainter(
                    textDrawables: scribble.textDrawables,
                    selectedTextDrawable: null,
                    isTransforming: false,
                    editingTextId: null,
                    textBoxTypography: textBoxTypography,
                  ),
                ),
              ),
            for (final image in scribble.imageDrawables)
              if (!image.hidden)
                Positioned(
                  left: image.x,
                  top: image.y,
                  width: image.width,
                  height: image.height,
                  child: Transform.rotate(
                    angle: image.rotation,
                    child: Opacity(
                      opacity: image.opacity.clamp(0.0, 1.0),
                      child: image.imageStyle.isNotEmpty
                          ? StyledImageView(
                              image: resolve(image.source),
                              style: NoteImageStyle.decode(image.imageStyle),
                            )
                          : Image(
                              image: resolve(image.source),
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stack) =>
                                  const SizedBox.expand(),
                            ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
