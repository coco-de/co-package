import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/library/note_cover.dart';
import 'package:open_note/src/note/library/note_cover_catalog.dart';
import 'package:open_note/src/note/library/note_cover_painter.dart';

/// Turns the source string of an image cover into an [ImageProvider], or
/// returns `null` when the host cannot show it (the cover then keeps its
/// placeholder).
typedef NoteCoverImageResolver = ImageProvider<Object>? Function(String source);

/// Draws a [NoteCover] at any size.
///
/// With tight constraints it fills them. With loose constraints it takes the
/// largest size that has the cover's proportions; along an unbounded axis it is
/// limited to the size of [NoteCover.pageSize].
///
/// Image covers resolve [NoteCover.imageSource] through
/// [imageProviderResolver]. A plain placeholder is shown until the picture is
/// ready, and stays when it cannot be loaded.
class NoteCoverView extends StatelessWidget {
  /// Creates a view of [cover].
  const NoteCoverView({
    required this.cover,
    super.key,
    this.imageProviderResolver = resolveImageSource,
    this.cornerRadius = 6,
    this.semanticLabel,
  });

  /// The cover to draw.
  final NoteCover cover;

  /// How image sources become pictures; defaults to the engine's resolver (a
  /// local file or a URL).
  final NoteCoverImageResolver imageProviderResolver;

  /// The corner radius in logical pixels.
  final double cornerRadius;

  /// The accessibility label; without it the cover is decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final page = cover.pageSize;
    final source = cover.kind == NoteCoverKind.image ? cover.imageSource : null;
    final provider = source == null || source.isEmpty
        ? null
        : imageProviderResolver(source);

    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: LimitedBox(
        maxWidth: page.width,
        maxHeight: page.height,
        child: AspectRatio(
          aspectRatio: cover.aspectRatio,
          child: _NoteCoverArtwork(
            cover: cover,
            provider: provider,
            cornerRadius: cornerRadius,
          ),
        ),
      ),
    );
  }
}

class _NoteCoverArtwork extends StatelessWidget {
  const _NoteCoverArtwork({
    required this.cover,
    required this.provider,
    required this.cornerRadius,
  });

  final NoteCover cover;
  final ImageProvider<Object>? provider;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final painted = CustomPaint(
      painter: NoteCoverPainter(
        NoteCoverCatalog.resolve(cover),
        cornerRadius: cornerRadius,
      ),
    );
    final image = provider;
    if (image == null) return painted;

    return Stack(
      fit: StackFit.expand,
      children: [
        painted,
        ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: Image(
            image: image,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
