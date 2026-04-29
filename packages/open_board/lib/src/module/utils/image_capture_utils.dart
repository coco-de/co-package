import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 위젯을 이미지로 캡처하는 유틸리티
abstract final class ImageCaptureUtils {
  /// 위젯을 [ui.Image]로 변환
  static Future<ui.Image> widgetToUiImage(
    Widget widget, {
    Duration delay = const Duration(seconds: 1),
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
  }) async {
    final ratio =
        pixelRatio ??
        (context != null
            ? MediaQuery.devicePixelRatioOf(context)
            : ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ??
                  1.0);
    final size = targetSize ?? const Size(256, 256);

    final repaintBoundary = RenderRepaintBoundary();
    final renderView = _createRenderView(size, ratio);

    final pipelineOwner = PipelineOwner()..rootNode = renderView;

    final buildOwner = BuildOwner(focusManager: FocusManager());

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(textDirection: TextDirection.ltr, child: widget),
    ).attachToRenderTree(buildOwner);

    renderView.child = repaintBoundary;

    buildOwner.buildScope(rootElement);
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    await Future<void>.delayed(delay);

    buildOwner.buildScope(rootElement);
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: ratio);

    buildOwner.finalizeTree();

    return image;
  }

  /// 위젯을 [ByteData] PNG로 캡처
  static Future<ByteData> captureFromWidget(
    Widget widget, {
    Duration delay = const Duration(seconds: 1),
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
  }) async {
    final image = await widgetToUiImage(
      widget,
      delay: delay,
      pixelRatio: pixelRatio,
      context: context,
      targetSize: targetSize,
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw StateError('Failed to capture widget as image');
    }

    return byteData;
  }

  static RenderView _createRenderView(Size size, double devicePixelRatio) {
    return RenderView(
      view: ui.PlatformDispatcher.instance.implicitView!,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: devicePixelRatio,
      ),
    );
  }
}
