import 'package:flutter/material.dart';

import '../managers/scribble_cache_manager.dart';
import '../scribble_controller.dart';
import '../state/drawing_state.dart';

/// 범용 필기 도구 툴바
///
/// ScribbleCacheManager와 연동되어 모든 페이지에서 공유되는 도구 상태를 관리합니다.
final class ScribbleDrawingToolbar extends StatefulWidget {
  const ScribbleDrawingToolbar({
    required this.scribbleManager,
    required this.currentContentId,
    required this.currentPageIndex,
    this.backgroundColor,
    this.onToolChanged,
    this.onClose,
    this.showCloseButton = false,
    super.key,
  });

  final ScribbleCacheManager scribbleManager;
  final String currentContentId;
  final String currentPageIndex;
  final Color? backgroundColor;
  final Function(String tool)? onToolChanged;
  final VoidCallback? onClose;
  final bool showCloseButton;

  @override
  State<ScribbleDrawingToolbar> createState() => _ScribbleDrawingToolbarState();
}

final class _ScribbleDrawingToolbarState extends State<ScribbleDrawingToolbar> {
  // 현재 선택된 도구 상태 추적
  late String _currentTool;
  late Color _currentColor;
  late double _currentStrokeWidth;
  bool _showColorPicker = false;
  bool _showStrokeWidthPicker = false;

  @override
  void initState() {
    super.initState();
    _currentTool = widget.scribbleManager.currentTool;
    _currentColor = widget.scribbleManager.currentColor;
    _currentStrokeWidth = widget.scribbleManager.currentStrokeWidth;

    // 매니저 상태 변경 감지
    widget.scribbleManager.addListener(_onManagerChanged);
  }

  @override
  void dispose() {
    widget.scribbleManager.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (mounted) {
      setState(() {
        _currentTool = widget.scribbleManager.currentTool;
        _currentColor = widget.scribbleManager.currentColor;
        _currentStrokeWidth = widget.scribbleManager.currentStrokeWidth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 펜 도구들
            _buildToolGroup(context),

            _buildDivider(),

            // 색상 선택
            _buildColorSelector(context),

            _buildDivider(),

            // 브러시 크기 선택
            _buildStrokeWidthSelector(context),

            _buildDivider(),

            // 실행취소/다시실행
            _buildUndoRedoGroup(context),

            _buildDivider(),

            // 페이지 지우기
            _buildClearButton(context),

            // 닫기 버튼 (선택사항)
            if (widget.showCloseButton && widget.onClose != null) ...[
              _buildDivider(),
              _buildCloseButton(context),
            ],
          ],
        ),
      ),
    );
  }

  /// 도구 그룹
  Widget _buildToolGroup(BuildContext context) {
    final tools = [
      (ScribbleTool.pen, Icons.edit, '펜'),
      (ScribbleTool.pencil, Icons.create, '연필'),
      (ScribbleTool.marker, Icons.format_paint, '마커'),
      (ScribbleTool.eraser, Icons.cleaning_services, '지우개'),
    ];

    return Row(
      children: tools.map((tool) {
        final toolName = tool.$1;
        final icon = tool.$2;
        final tooltip = tool.$3;
        final isSelected = _currentTool == toolName;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _buildToolButton(
            context: context,
            icon: icon,
            tooltip: tooltip,
            isSelected: isSelected,
            onTap: () {
              widget.scribbleManager.setTool(toolName);
              widget.onToolChanged?.call(toolName);
            },
          ),
        );
      }).toList(),
    );
  }

  /// 색상 선택기
  Widget _buildColorSelector(BuildContext context) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.pink,
    ];

    return Row(
      children: [
        // 현재 색상 표시
        GestureDetector(
          onTap: () => setState(() => _showColorPicker = !_showColorPicker),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _currentColor,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.palette,
              size: 16,
              color: _currentColor == Colors.white
                  ? Colors.black
                  : Colors.white,
            ),
          ),
        ),

        // 색상 팔레트
        if (_showColorPicker) ...[
          const SizedBox(width: 8),
          ...colors.map((color) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () {
                  widget.scribbleManager.setColor(color);
                  setState(() => _showColorPicker = false);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: _currentColor == color
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: _currentColor == color ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  /// 브러시 크기 선택기
  Widget _buildStrokeWidthSelector(BuildContext context) {
    final strokeWidths = [1.0, 2.0, 4.0, 6.0, 8.0];

    return Row(
      children: [
        // 현재 크기 표시
        GestureDetector(
          onTap: () =>
              setState(() => _showStrokeWidthPicker = !_showStrokeWidthPicker),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Container(
                width: _currentStrokeWidth.clamp(2, 16),
                height: _currentStrokeWidth.clamp(2, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(
                    _currentStrokeWidth.clamp(2, 16) / 2,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 크기 선택 옵션
        if (_showStrokeWidthPicker) ...[
          const SizedBox(width: 8),
          ...strokeWidths.map((width) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  widget.scribbleManager.setStrokeWidth(width);
                  setState(() => _showStrokeWidthPicker = false);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _currentStrokeWidth == width
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: _currentStrokeWidth == width ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Container(
                      width: width.clamp(2, 16),
                      height: width.clamp(2, 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(
                          width.clamp(2, 16) / 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  /// Undo/Redo 버튼 그룹
  Widget _buildUndoRedoGroup(BuildContext context) {
    final globalState = DrawingState();

    return ValueListenableBuilder<bool>(
      valueListenable: globalState.canUndoNotifier,
      builder: (context, canUndo, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: globalState.canRedoNotifier,
          builder: (context, canRedo, _) {
            return Row(
              children: [
                _buildToolButton(
                  context: context,
                  icon: Icons.undo,
                  tooltip: '실행취소',
                  isEnabled: canUndo,
                  onTap: () {
                    globalState.undo();
                    // 상태 변경 후 UI 업데이트
                    widget.onToolChanged?.call('undo');
                  },
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  context: context,
                  icon: Icons.redo,
                  tooltip: '다시실행',
                  isEnabled: canRedo,
                  onTap: () {
                    globalState.redo();
                    // 상태 변경 후 UI 업데이트
                    widget.onToolChanged?.call('redo');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 페이지 지우기 버튼
  Widget _buildClearButton(BuildContext context) {
    return _buildToolButton(
      context: context,
      icon: Icons.clear_all,
      tooltip: '전체 지우기',
      isEnabled: !widget.scribbleManager.isPageEmpty(
        '${widget.currentContentId}/${widget.currentPageIndex}',
      ),
      onTap: () {
        // 확인 다이얼로그 표시
        showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('페이지 지우기'),
            content: const Text('현재 페이지의 모든 필기를 지우시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('지우기'),
              ),
            ],
          ),
        ).then((confirmed) {
          if (confirmed ?? false) {
            widget.scribbleManager.clearPage(
              '${widget.currentContentId}/${widget.currentPageIndex}',
            );
          }
        });
      },
    );
  }

  /// 닫기 버튼
  Widget _buildCloseButton(BuildContext context) {
    return _buildToolButton(
      context: context,
      icon: Icons.close,
      tooltip: '닫기',
      onTap: widget.onClose!,
    );
  }

  /// 도구 버튼 빌더
  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    bool isSelected = false,
    bool isEnabled = true,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled
                ? (isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }

  /// 구분선
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
