import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_board/open_board.dart';
import 'package:open_epub/open_epub.dart';

import 'widgets/drawing_toolbar.dart';

/// open_epub 리더 위에 페이지 연동 필기를 올리는 데모.
///
/// - 읽기 모드: 필기 레이어가 포인터를 통과시켜 EPUB 스와이프/탭 동작
/// - 필기 모드: ScribbleWidget이 제스처를 소비해 페이지 스와이프 차단
/// - 페이지 전환 시 ScribbleCacheManager로 페이지별 필기 저장/복원
class EpubAnnotationDemoPage extends StatefulWidget {
  const EpubAnnotationDemoPage({super.key});

  @override
  State<EpubAnnotationDemoPage> createState() => _EpubAnnotationDemoPageState();
}

class _EpubAnnotationDemoPageState extends State<EpubAnnotationDemoPage> {
  final _epubController = EpubReaderController();
  final _cacheManager = ScribbleCacheManager.instance;

  // 필기 레이어(InteractiveViewer)와 EPUB 레이어가 공유하는 변환 행렬.
  // 필기 모드에서 줌/팬 시 EPUB 본문이 함께 확대/이동된다.
  final _transformController = TransformationController();

  // 도구/색상/두께의 단일 소스. ScribbleWidget 이 이 싱글턴을 리스닝하며
  // 위젯 재생성(페이지 전환) 시에도 forceSyncAll 로 이 값을 notifier 에 적용하므로,
  // 툴바는 반드시 DrawingState 를 통해 도구를 변경해야 함
  final _drawingState = DrawingState();

  bool _isAnnotationMode = false;
  int _currentPage = 1; // onPageChanged 의 1-based 값
  int _totalPages = 0;

  static const _contentId = 'epub-demo';

  String _pageKey(int page) => '$_contentId/epub-page-$page';

  ScribbleController get _activeController =>
      _cacheManager.getController(_pageKey(_currentPage));

  @override
  void initState() {
    super.initState();
    // 웹 마우스 + 모바일 터치 모두 허용 (데모 접근성 우선)
    // mouseOnly 모드는 마우스/터치/스타일러스 드로잉을 모두 허용
    // (_canStartDrawing 이 DrawingState 싱글턴의 pointerMode 를 참조)
    _drawingState.pointerMode.value = DrawingPointerMode.mouseOnly;
    _drawingState.selectedTool.value = DrawingTool.pen;
    _drawingState.selectedColor.value = Colors.black;
    _drawingState.selectedThickness.value = 2.0;
    _drawingState.selectedTool.addListener(_refresh);
    _drawingState.selectedColor.addListener(_refresh);
    _drawingState.selectedThickness.addListener(_refresh);
    _cacheManager.setPointerMode('all');
    // onPageChanged 콜백은 페이지 전환 시에만 호출되므로,
    // 초기 로드 시 페이지 정보(setPageInfo)까지 받으려면 컨트롤러를 직접 리스닝
    _epubController.addListener(_onEpubControllerChanged);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _drawingState.selectedTool.removeListener(_refresh);
    _drawingState.selectedColor.removeListener(_refresh);
    _drawingState.selectedThickness.removeListener(_refresh);
    _epubController.removeListener(_onEpubControllerChanged);
    _epubController.dispose();
    _transformController.dispose();
    // 싱글턴이므로 dispose 하지 않고 현재 페이지 필기만 즉시 영속화
    _cacheManager.flushSave(_pageKey(_currentPage));
    super.dispose();
  }

  void _onEpubControllerChanged() {
    final total = _epubController.totalPages;
    if (total <= 0) return;
    final page = _epubController.currentPage + 1; // 0-based → 1-based
    if (page != _currentPage || total != _totalPages) {
      _onEpubPageChanged(page, total);
    }
  }

  Future<void> _onEpubPageChanged(int current, int total) async {
    final previousPage = _currentPage;
    final repaginated = _totalPages != 0 && _totalPages != total;

    // 이전 페이지 필기 즉시 영속화 (디바운스 flush)
    if (previousPage != current) {
      await _cacheManager.flushSave(_pageKey(previousPage));
    }

    if (!mounted) return;
    setState(() {
      _currentPage = current;
      _totalPages = total;
    });

    // 새 페이지 컨트롤러 확보 + 비어있으면 저장본 복원
    final controller = _cacheManager.getController(_pageKey(current));
    if (controller.currentScribble.strokes.isEmpty) {
      final saved = await _cacheManager.loadScribble(_pageKey(current));
      if (saved != null && saved.strokes.isNotEmpty) {
        controller.loadScribble(saved);
      }
    }

    // 총 페이지 수 변동 = repagination → 필기 위치 어긋남 경고
    if (repaginated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('본문이 재배치되어 기존 필기 위치가 어긋날 수 있습니다.'),
        ),
      );
    }
  }

  Future<void> _toggleMode() async {
    await _cacheManager.flushSave(_pageKey(_currentPage));
    if (!mounted) return;
    setState(() {
      _isAnnotationMode = !_isAnnotationMode;
      // 읽기 모드 복귀 시 줌/팬 초기화 (읽기 화면은 항상 1:1)
      if (!_isAnnotationMode) {
        _transformController.value = Matrix4.identity();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Annotation Demo'),
        actions: [
          if (_isAnnotationMode) ...[
            IconButton(
              onPressed: () => _activeController.undo(),
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
            ),
            IconButton(
              onPressed: () => _activeController.redo(),
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
            ),
            IconButton(
              onPressed: () => _activeController.clear(),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(cs),
          // 툴바를 항상 레이아웃에 유지해 EPUB 뷰포트 높이를 고정
          // (조건부 렌더링 시 모드 토글마다 repagination 이 발생해 필기가 어긋남)
          IgnorePointer(
            ignoring: !_isAnnotationMode,
            child: Opacity(
              opacity: _isAnnotationMode ? 1.0 : 0.35,
              child: _buildAnnotationToolbar(),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  children: [
                    // 1) EPUB 리더 (하단 레이어)
                    // showTopBar/settingsStorageKey 차단으로 폰트 변경에 의한
                    // repagination 경로를 막아 필기-본문 정합을 유지
                    // 필기 레이어의 줌/팬 변환을 동일하게 적용해 본문이 함께 확대됨
                    ValueListenableBuilder<Matrix4>(
                      valueListenable: _transformController,
                      builder: (context, matrix, child) => ClipRect(
                        child: Transform(
                          transform: matrix,
                          child: child,
                        ),
                      ),
                      child: EpubReaderWidget(
                        source:
                            const EpubSourceAsset('assets/books/alice.epub'),
                        controller: _epubController,
                        showTopBar: false,
                        showBottomBar: false,
                        settingsStorageKey: null,
                        localization: EpubReaderLocalization.english,
                        // 페이지 변경 감지는 _onEpubControllerChanged 리스너가 담당
                        // (onPageChanged 콜백은 초기 로드 시 호출되지 않음)
                        onError: (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('EPUB error: $error')),
                          );
                        },
                      ),
                    ),
                    // 2) 필기 오버레이 (상단 레이어)
                    Positioned.fill(
                      child: IgnorePointer(
                        // 읽기 모드: 포인터 통과 → EPUB 스와이프/탭 동작
                        ignoring: !_isAnnotationMode,
                        child: SimpleScribbleWidget(
                          // 페이지 전환 시 컨트롤러 재바인딩
                          key: ValueKey('epub-overlay-$_currentPage'),
                          controller: _activeController,
                          isScribbleEnabled: _isAnnotationMode,
                          // 줌/팬 허용 — 변환 행렬을 _transformController 로 공유해
                          // EPUB 본문과 필기가 함께 확대/이동됨
                          transformationController: _transformController,
                          panDirection: PanDirection.both,
                          maxScale: 4.0,
                          allowedPointersMode: ScribblePointerMode.all,
                          contentLogicalSize: size,
                          child: SizedBox.fromSize(size: size),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildPageNavigationBar(cs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleMode,
        icon: Icon(_isAnnotationMode ? Icons.menu_book : Icons.draw),
        label: Text(_isAnnotationMode ? '읽기 모드' : '필기 모드'),
      ),
    );
  }

  Widget _buildInfoBanner(ColorScheme cs) {
    final webNote = kIsWeb ? ' 웹에서는 세션 내에서만 필기가 유지됩니다.' : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: cs.surfaceContainerLow,
      child: Text(
        '필기는 페이지 번호 기준으로 저장됩니다. '
        '창 크기 변경 시 본문이 재배치되어 필기 위치가 어긋날 수 있습니다.$webNote\n'
        "Sample: Alice's Adventures in Wonderland (Project Gutenberg #11)",
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.4),
      ),
    );
  }

  Widget _buildAnnotationToolbar() {
    return DrawingToolbar(
      selectedTool: _drawingState.selectedTool.value,
      selectedColor: _drawingState.selectedColor.value,
      selectedWidth: _drawingState.selectedThickness.value,
      onToolSelected: (tool) => _drawingState.selectedTool.value = tool,
      onColorSelected: (color) => _drawingState.selectedColor.value = color,
      onWidthChanged: (width) => _drawingState.selectedThickness.value = width,
    );
  }

  Widget _buildPageNavigationBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: cs.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed:
                  _currentPage > 1 ? _epubController.previousPage : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              _totalPages > 0 ? '$_currentPage / $_totalPages' : '로딩 중...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            IconButton(
              onPressed: _currentPage < _totalPages
                  ? _epubController.nextPage
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
