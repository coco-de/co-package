import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/objects/internal/note_sticker_painting.dart';
import 'package:open_note/src/note/objects/note_sticker_object.dart';

/// Turns a sticker's source string into an image provider.
typedef NoteStickerImageResolver = ImageProvider Function(String source);

/// Draws a [NoteStickerObject] filling its constraints. The picture keeps its
/// aspect ratio; while it loads, fails to load or the source is empty, a light
/// placeholder shows (the placeholder is gone as soon as a first frame exists).
///
/// A sticker has nothing to tap, so it lets every pointer through (in edit
/// mode the layer handles selection and dragging).
class NoteStickerView extends StatefulWidget {
  const NoteStickerView({
    required this.object,
    super.key,
    this.imageProviderResolver,
  });

  /// The sticker to draw.
  final NoteStickerObject object;

  /// Resolves [NoteStickerObject.source]; defaults to the engine's
  /// `resolveImageSource` (a file path, or an `http`/`blob` URL). The provider
  /// is resolved again only when the source or the resolver changes.
  final NoteStickerImageResolver? imageProviderResolver;

  @override
  State<NoteStickerView> createState() => _NoteStickerViewState();
}

class _NoteStickerViewState extends State<NoteStickerView> {
  ImageProvider? _provider;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _resolve() {
    final source = widget.object.source;
    final resolve = widget.imageProviderResolver ?? resolveImageSource;
    _provider = source.isEmpty ? null : resolve(source);
  }

  @override
  void didUpdateWidget(NoteStickerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.object.source != widget.object.source ||
        oldWidget.imageProviderResolver != widget.imageProviderResolver) {
      _resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;

    return IgnorePointer(
      child: provider == null
          ? const _StickerPlaceholder()
          : Transform.flip(
              flipX: widget.object.flipHorizontal,
              child: Image(
                image: provider,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                excludeFromSemantics: true,
                filterQuality: FilterQuality.medium,
                frameBuilder: (context, child, frame, synchronouslyLoaded) =>
                    frame == null && !synchronouslyLoaded
                    ? const _StickerPlaceholder()
                    : child,
                errorBuilder: (context, error, stackTrace) =>
                    const _StickerPlaceholder(),
              ),
            ),
    );
  }
}

class _StickerPlaceholder extends StatelessWidget {
  const _StickerPlaceholder();

  @override
  Widget build(BuildContext context) => const CustomPaint(
    painter: _StickerPlaceholderPainter(),
    child: SizedBox.expand(),
  );
}

class _StickerPlaceholderPainter extends CustomPainter {
  const _StickerPlaceholderPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      NoteStickerPainting.paintPlaceholder(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_StickerPlaceholderPainter oldDelegate) => false;
}
