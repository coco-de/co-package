import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';

/// Turns the source string of an image fill into an [ImageProvider]. The
/// default is the engine's `resolveImageSource` (files natively, URLs on the
/// web).
typedef NoteMaskImageResolver = ImageProvider Function(String source);

/// Loads the picture of an image fill and rebuilds [builder] with it. Internal
/// to `study/overlay`.
///
/// [builder] gets `null` while there is no [source], while the picture loads
/// and after a failure, so the cover stays painted with its plain colour.
class NoteMaskFillImage extends StatefulWidget {
  /// Loads [source] through [resolver].
  const NoteMaskFillImage({
    required this.source,
    required this.builder,
    this.resolver,
    super.key,
  });

  /// The image source, or `null` when the fill needs no picture.
  final String? source;

  /// How [source] becomes an image provider.
  final NoteMaskImageResolver? resolver;

  /// Builds the content with the decoded picture.
  final Widget Function(BuildContext context, ui.Image? image) builder;

  @override
  State<NoteMaskFillImage> createState() => _NoteMaskFillImageState();
}

class _NoteMaskFillImageState extends State<NoteMaskFillImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(NoteMaskFillImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.resolver != widget.resolver) {
      _resolve();
    }
  }

  @override
  void dispose() {
    _detach();
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _info?.image);

  void _resolve() {
    final source = widget.source;
    final stream = source == null ? null : _streamOf(source);
    // The same stream means the same picture: keep it.
    if (stream != null && stream.key == _stream?.key) return;
    _detach();
    _clear();
    if (stream == null) return;
    final listener = ImageStreamListener(_onImage, onError: _onError);
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  ImageStream? _streamOf(String source) {
    try {
      final provider = (widget.resolver ?? resolveImageSource)(source);

      return provider.resolve(createLocalImageConfiguration(context));
    } on Object {
      // A resolver that cannot handle the source leaves the plain colour.
      return null;
    }
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    if (!mounted) {
      info.dispose();

      return;
    }
    setState(() {
      _clear();
      _info = info;
    });
  }

  void _onError(Object error, StackTrace? stackTrace) {
    // The cover stays painted with its plain colour.
    if (mounted) setState(_clear);
  }

  void _detach() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  void _clear() {
    _info?.dispose();
    _info = null;
  }
}
