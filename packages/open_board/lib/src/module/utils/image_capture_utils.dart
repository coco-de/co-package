import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 이미지 캡처 관련 유틸리티 클래스
class ImageCaptureUtils {
  /// 위젯을 이미지로 렌더링
  static Future<ByteData> renderWidgetToImage(
    Widget widget, {
    double pixelRatio = 1.0,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
    GlobalKey? globalKey,
  }) async {
    if (globalKey?.currentContext != null) {
      final RenderRepaintBoundary? renderObject =
          globalKey!.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (renderObject != null) {
        final img = await renderObject.toImage(pixelRatio: pixelRatio);
        return (await img.toByteData(format: format))!;
      }
    }

    // Fallback: 위젯을 직접 캡처
    return await captureFromWidget(
      widget,
      pixelRatio: pixelRatio,
      format: format,
    );
  }

  /// 위젯을 직접 캡처하여 이미지로 변환
  static Future<ByteData> captureFromWidget(
    Widget widget, {
    Duration delay = const Duration(seconds: 1),
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    final image = await widgetToUiImage(
      widget,
      delay: delay,
      pixelRatio: pixelRatio,
      context: context,
      targetSize: targetSize,
    );

    final byteData = await image.toByteData(format: format);
    image.dispose();

    return byteData ?? ByteData(0);
  }

  /// 위젯을 UI 이미지로 변환
  static Future<ui.Image> widgetToUiImage(
    Widget widget, {
    Duration delay = const Duration(seconds: 1),
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
  }) async {
    int retryCounter = 3;
    bool isDirty = false;

    Widget child = widget;

    if (context != null) {
      child = InheritedTheme.captureAll(
        context,
        MediaQuery(
          data: MediaQuery.of(context),
          child: Material(color: Colors.transparent, child: child),
        ),
      );
    }

    final repaintBoundary = RenderRepaintBoundary();
    final physicalSize =
        ui.PlatformDispatcher.instance.views.first.physicalSize;
    final devicePixelRatio =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    final logicalSize = targetSize ?? physicalSize / devicePixelRatio;
    final imageSize = targetSize ?? physicalSize;

    assert(
      logicalSize.aspectRatio.toStringAsPrecision(5) ==
          imageSize.aspectRatio.toStringAsPrecision(5),
    );

    final renderView = RenderView(
      view: View.of(context!),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        physicalConstraints: BoxConstraints(
          minWidth: logicalSize.width,
          minHeight: logicalSize.height,
          maxWidth: logicalSize.width,
          maxHeight: logicalSize.height,
        ),
        devicePixelRatio: pixelRatio ?? 1.0,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(
      focusManager: FocusManager(),
      onBuildScheduled: () {
        isDirty = true;
      },
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    ).attachToRenderTree(buildOwner);

    // 렌더링 수행
    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    ui.Image? image;

    do {
      isDirty = false;

      image = await repaintBoundary.toImage(
        pixelRatio: pixelRatio ?? (imageSize.width / logicalSize.width),
      );

      await Future<void>.delayed(delay);

      if (isDirty) {
        buildOwner.buildScope(rootElement);
        buildOwner.finalizeTree();
        pipelineOwner.flushLayout();
        pipelineOwner.flushCompositingBits();
        pipelineOwner.flushPaint();
      }
      retryCounter--;
    } while (isDirty && retryCounter >= 0);

    return image;
  }
}
