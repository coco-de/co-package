import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/image/image_drawable_extensions.dart';
import 'package:open_board/src/module/image/image_source_resolver.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/transform_handler.dart';
import 'package:open_board/src/module/widgets/scribble_widget_state.dart';

/// 삽입된 [ImageDrawable] 들을 캔버스에 렌더링하고, [interactive] 일 때
/// 탭 선택 → 이동/크기조절/회전/삭제를 제공하는 위젯 레이어.
///
/// 텍스트/올가미가 사용하는 CustomPaint + 포인터 파이프라인과 달리, 이미지는
/// 파일/네트워크 디코딩·캐싱이 필요하므로 위젯(Transform.rotate + Image) 기반으로
/// 렌더링한다. 변형 수학은 공통 [TransformHandler] 를 재사용한다.
///
/// [interactive] 가 `false` 이면(그리기 모드 등) 제스처 위젯을 구성하지 않고
/// 이미지만 정적으로 렌더링한다. 호스트는 그리기 모드에서 이 레이어를
/// `IgnorePointer` 로 감싸 스트로크가 통과하도록 한다.
class ImageDrawableLayer extends StatefulWidget {
  const ImageDrawableLayer({
    required this.notifier,
    required this.widgetState,
    required this.interactive,
    this.imageProviderResolver,
    super.key,
  });

  /// 현재 페이지의 스크리블 상태 소스.
  final ScribbleNotifier notifier;

  /// 선택 상태(`selectedImageId`)를 공유하는 위젯 상태.
  final ScribbleWidgetState widgetState;

  /// 선택/변형 제스처 활성화 여부(이미지 모드일 때 `true`).
  final bool interactive;

  /// [ImageDrawable.source] → [ImageProvider] 해석기. 미지정 시 플랫폼 기본값.
  final ImageProvider Function(String source)? imageProviderResolver;

  @override
  State<ImageDrawableLayer> createState() => _ImageDrawableLayerState();
}

class _ImageDrawableLayerState extends State<ImageDrawableLayer> {
  final TransformHandler _transform = TransformHandler();
  final GlobalKey _layerKey = GlobalKey();

  // 변형 시작 시점의 원본 스냅샷(누적 변형 방지).
  Offset? _dragCenter;
  Size? _dragOriginalSize;
  double _dragOriginalRotation = 0;

  static const double _handleVisualSize = 32;
  static const double _handleTouchSize = 48;
  static const double _cornerPadding = 6;

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ImageDrawableLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 이미지 모드를 벗어나면 선택/핸들을 정리한다.
    if (oldWidget.interactive && !widget.interactive) {
      widget.widgetState.resetImageState();
    }
  }

  ImageProvider _resolve(String source) =>
      (widget.imageProviderResolver ?? resolveImageSource)(source);

  void _select(String id) {
    if (widget.widgetState.selectedImageId == id) return;
    widget.widgetState.selectedImageId = id;
    _refresh();
  }

  void _deselect() {
    if (widget.widgetState.selectedImageId == null) return;
    widget.widgetState.selectedImageId = null;
    _refresh();
  }

  ImageDrawable? _selectedDrawable(List<ImageDrawable> drawables) {
    final id = widget.widgetState.selectedImageId;
    if (id == null) return null;
    for (final drawable in drawables) {
      if (drawable.id == id) return drawable;
    }
    return null;
  }

  Offset _rotateVector(Offset vector, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(
      vector.dx * cos - vector.dy * sin,
      vector.dx * sin + vector.dy * cos,
    );
  }

  Offset _globalToLayer(Offset global) {
    final box = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return global;
    return box.globalToLocal(global);
  }

  // ── 이동 ──

  void _onImageMoveUpdate(ImageDrawable image, DragUpdateDetails details) {
    // 제스처는 회전된 프레임 안에서 발생하므로 delta 를 레이어 프레임으로 되돌린다.
    final layerDelta = _rotateVector(details.delta, image.rotation);
    final current = _selectedDrawable(
      widget.notifier.getCurrentImageDrawables(),
    );
    if (current == null) return;
    widget.notifier.updateImageDrawable(
      image.id,
      current.copyWithPosition(current.position + layerDelta),
      addToUndoHistory: false,
    );
    _refresh();
  }

  void _onImageMoveEnd(ImageDrawable image) {
    final current = _selectedDrawable(
      widget.notifier.getCurrentImageDrawables(),
    );
    if (current == null) return;
    // 최종 위치를 히스토리에 1회 커밋.
    widget.notifier.updateImageDrawable(image.id, current);
    _refresh();
  }

  // ── 크기조절 + 회전 ──

  void _onTransformStart(ImageDrawable image, DragStartDetails details) {
    _dragCenter = image.center;
    _dragOriginalSize = image.size;
    _dragOriginalRotation = image.rotation;
    _transform.startResizeRotate(
      _globalToLayer(details.globalPosition),
      image.center,
      initialRotation: image.rotation,
    );
    widget.widgetState.isImageResizing = true;
    _refresh();
  }

  void _onTransformUpdate(ImageDrawable image, DragUpdateDetails details) {
    final center = _dragCenter;
    final originalSize = _dragOriginalSize;
    if (center == null || originalSize == null) return;

    final result = _transform.computeResizeRotate(
      _globalToLayer(details.globalPosition),
    );
    final newWidth = originalSize.width * result.scale;
    final newHeight = originalSize.height * result.scale;
    final newRotation = _dragOriginalRotation + result.deltaAngle;

    // 중심 고정: 새 크기에 맞춰 좌상단 재계산.
    final resized = image
        .copyWithSize(Size(newWidth, newHeight))
        .copyWithPosition(
          Offset(center.dx - newWidth / 2, center.dy - newHeight / 2),
        )
        .copyWithRotation(newRotation);

    widget.notifier.updateImageDrawable(
      image.id,
      resized,
      addToUndoHistory: false,
    );
    _refresh();
  }

  void _onTransformEnd(ImageDrawable image) {
    _transform.endResizeRotate();
    _dragCenter = null;
    _dragOriginalSize = null;
    widget.widgetState.isImageResizing = false;
    final current = _selectedDrawable(
      widget.notifier.getCurrentImageDrawables(),
    );
    if (current != null) {
      widget.notifier.updateImageDrawable(image.id, current);
    }
    _refresh();
  }

  void _onDelete(ImageDrawable image) {
    widget.notifier.removeImageDrawable(image.id);
    widget.widgetState.selectedImageId = null;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScribbleState>(
      valueListenable: widget.notifier,
      builder: (context, state, _) {
        final drawables = state.scribble.imageDrawables;
        if (drawables.isEmpty) return const SizedBox.shrink();

        final selected = widget.interactive
            ? _selectedDrawable(drawables)
            : null;

        return Stack(
          key: _layerKey,
          fit: StackFit.expand,
          children: [
            // 빈 영역 탭 → 선택 해제 (이미지 모드에서만).
            if (widget.interactive)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _deselect,
                ),
              ),

            // 이미지들.
            for (final image in drawables)
              if (!image.hidden)
                _buildImage(image, isSelected: selected?.id == image.id),

            // 선택된 이미지의 변형/삭제 핸들 (회전 모서리 위치).
            if (selected != null) ..._buildSelectionHandles(selected),
          ],
        );
      },
    );
  }

  Widget _buildImage(ImageDrawable image, {required bool isSelected}) {
    final child = Opacity(
      opacity: image.opacity.clamp(0.0, 1.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: isSelected
              ? Border.fromBorderSide(BorderSide(color: Colors.blue, width: 2))
              : null,
        ),
        child: Image(
          image: _resolve(image.source),
          fit: BoxFit.fill,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const ColoredBox(
            color: Color(0x22000000),
            child: Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.grey),
            ),
          ),
        ),
      ),
    );

    final rotated = Transform.rotate(
      angle: image.rotation,
      child: widget.interactive
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _select(image.id),
              onPanStart: isSelected ? (_) {} : null,
              onPanUpdate: isSelected
                  ? (details) => _onImageMoveUpdate(image, details)
                  : null,
              onPanEnd: isSelected ? (_) => _onImageMoveEnd(image) : null,
              child: child,
            )
          : child,
    );

    return Positioned(
      left: image.x,
      top: image.y,
      width: image.width,
      height: image.height,
      child: rotated,
    );
  }

  List<Widget> _buildSelectionHandles(ImageDrawable image) {
    final center = image.center;
    final halfWidth = image.width / 2;
    final halfHeight = image.height / 2;
    final rotation = image.rotation;

    // 회전 모서리 위치(패딩 포함): 우상단=삭제, 좌하단=변형.
    final deletePos =
        center +
        _rotateVector(
          Offset(halfWidth + _cornerPadding, -halfHeight - _cornerPadding),
          rotation,
        );
    final transformPos =
        center +
        _rotateVector(
          Offset(-halfWidth - _cornerPadding, halfHeight + _cornerPadding),
          rotation,
        );

    return [
      // 삭제 핸들 (우상단).
      Positioned(
        left: deletePos.dx - _handleTouchSize / 2,
        top: deletePos.dy - _handleTouchSize / 2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onDelete(image),
          child: _HandleButton(
            touchSize: _handleTouchSize,
            visualSize: _handleVisualSize,
            color: Colors.red,
            icon: Icons.close,
          ),
        ),
      ),

      // 크기조절/회전 핸들 (좌하단).
      Positioned(
        left: transformPos.dx - _handleTouchSize / 2,
        top: transformPos.dy - _handleTouchSize / 2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _onTransformStart(image, details),
          onPanUpdate: (details) => _onTransformUpdate(image, details),
          onPanEnd: (_) => _onTransformEnd(image),
          child: _HandleButton(
            touchSize: _handleTouchSize,
            visualSize: _handleVisualSize,
            color: Colors.blue,
            icon: Icons.open_in_full,
          ),
        ),
      ),
    ];
  }
}

/// 원형 핸들 버튼(투명 터치 영역 안에 시각 버튼).
class _HandleButton extends StatelessWidget {
  const _HandleButton({
    required this.touchSize,
    required this.visualSize,
    required this.color,
    required this.icon,
  });

  final double touchSize;
  final double visualSize;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: touchSize,
      child: Center(
        child: Container(
          width: visualSize,
          height: visualSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.white, width: 2),
            ),
          ),
          child: Icon(icon, size: visualSize * 0.55, color: Colors.white),
        ),
      ),
    );
  }
}
