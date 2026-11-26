import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/style/note_image_style.dart';
import 'package:open_note/src/note/style/note_image_style_painter.dart';

/// open_note: 이미지 스타일(자르기 · 모서리 · 테두리 · 불투명도)을 입혀 이미지를
/// 그린다. 부모 크기가 "잘라낸 부분이 놓일 자리"다.
///
/// 디코딩 전과 실패 시에는 [placeholder] 를 보인다.
class StyledImageView extends StatefulWidget {
  const StyledImageView({
    required this.image,
    required this.style,
    super.key,
    this.placeholder = const SizedBox.expand(),
  });

  final ImageProvider image;
  final NoteImageStyle style;
  final Widget placeholder;

  @override
  State<StyledImageView> createState() => _StyledImageViewState();
}

class _StyledImageViewState extends State<StyledImageView> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final ImageStreamListener _listener = ImageStreamListener(
    _onImage,
    onError: (error, stackTrace) => _replace(null),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(StyledImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _resolve();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  void _resolve() {
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  void _onImage(ImageInfo info, bool synchronousCall) => _replace(info);

  void _replace(ImageInfo? info) {
    if (!mounted) {
      info?.dispose();

      return;
    }
    final previous = _info;
    setState(() => _info = info);
    previous?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info == null) return widget.placeholder;

    return CustomPaint(
      size: Size.infinite,
      painter: _StyledImagePainter(info.image, widget.style),
    );
  }
}

class _StyledImagePainter extends CustomPainter {
  const _StyledImagePainter(this.image, this.style);

  final ui.Image image;
  final NoteImageStyle style;

  @override
  void paint(Canvas canvas, Size size) =>
      NoteImageStylePainter.paint(canvas, image, Offset.zero & size, style);

  @override
  bool shouldRepaint(_StyledImagePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.style != style;
}
