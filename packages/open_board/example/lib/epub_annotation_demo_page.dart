// ignore_for_file: member-ordering
// member-ordering 면제(이 파일 한정): DCM은 State에서 initState를 private
// 메서드보다 앞에, build를 뒤에 두길 동시에 요구해 본 데모의 가독성 배치와
// 상충한다. 기능/품질 규칙(widget 추출, async, empty-block 등)은 모두 준수.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_board/open_board.dart';
import 'package:open_epub/open_epub_v1.dart';

import 'widgets/drawing_toolbar.dart';

/// open_epub 1.0 리더 위에 페이지 연동 필기를 올리는 데모.
///
/// - 읽기 모드: 필기 레이어가 포인터를 통과시켜 EPUB 스와이프/탭 동작
/// - 필기 모드: ScribbleWidget이 제스처를 소비해 페이지 스와이프 차단
/// - 챕터 전환 시 ScribbleCacheManager로 spineHref별 필기 저장/복원
///
/// 1.0 마이그레이션 포인트:
/// - 위젯: EpubReaderWidget(0.1.x) → EpubReader(1.0, open_epub_v1.dart)
/// - 컨트롤러: EpubReaderController(0.1.x) → EpubViewController(1.0)
/// - 필기 키: 페이지 번호 → spineHref(EpubPosition) 앵커. 글자 크기 고정 +
///   spineHref 기준이라 재배치(repagination)에도 필기가 어긋나지 않는다(S8.4).
class EpubAnnotationDemoPage extends StatefulWidget {
  const EpubAnnotationDemoPage({super.key});

  @override
  State<EpubAnnotationDemoPage> createState() => _EpubAnnotationDemoPageState();
}

class _EpubAnnotationDemoPageState extends State<EpubAnnotationDemoPage> {
  static const _contentId = 'epub-demo';

  // 페이지 내비게이션 + 현재 인덱스/총 개수 관찰 (1.0 EpubViewController).
  final _epubController = EpubViewController();
  final _cacheManager = ScribbleCacheManager.instance;

  // 필기 레이어와 EPUB 레이어가 공유하는 변환 행렬(줌/팬 동기).
  final _transformController = TransformationController();

  // 도구/색상/두께의 단일 소스.
  final _drawingState = DrawingState();

  bool _isAnnotationMode = false;

  // 현재 표시 중인 spine — 필기 저장/복원 키(페이지 번호 대신 안정 앵커).
  String? _currentSpineHref;

  // asset에서 로드한 EPUB 바이트(1.0 EpubSource.bytes). null이면 로딩 중.
  Uint8List? _bytes;

  ScribbleController get _activeController =>
      _cacheManager.getController(_pageKey(_currentSpineHref ?? '__init__'));

  String _pageKey(String spineHref) => '$_contentId/$spineHref';

  @override
  void initState() {
    super.initState();
    // 웹 마우스 + 모바일 터치 모두 허용 (데모 접근성 우선)
    _drawingState.pointerMode.value = DrawingPointerMode.mouseOnly;
    _drawingState.selectedTool.value = DrawingTool.pen;
    _drawingState.selectedColor.value = Colors.black;
    _drawingState.selectedThickness.value = 2.0;
    _cacheManager.setPointerMode('all');
    unawaited(_loadBook());
  }

  @override
  void dispose() {
    _epubController.dispose();
    _transformController.dispose();
    // 싱글턴이므로 dispose 하지 않고 현재 페이지 필기만 즉시 영속화.
    final href = _currentSpineHref;
    if (href != null) unawaited(_cacheManager.flushSave(_pageKey(href)));
    super.dispose();
  }

  Future<void> _loadBook() async {
    final data = await rootBundle.load('assets/books/alice.epub');
    if (!mounted) return;
    setState(() => _bytes = data.buffer.asUint8List());
  }

  /// EpubReader가 챕터(spine) 전환을 보고하면 이전 필기를 저장하고 새 필기를
  /// 복원한다. EpubReader는 초기 위치도 1회 보고하므로 첫 챕터도 처리된다.
  Future<void> _onPositionChanged(EpubPosition position) async {
    final href = position.spineHref;
    if (href == _currentSpineHref) return;
    final previous = _currentSpineHref;
    if (previous != null) {
      await _cacheManager.flushSave(_pageKey(previous));
    }
    if (!mounted) return;
    setState(() => _currentSpineHref = href);

    final key = _pageKey(href);
    final controller = _cacheManager.getController(key);
    if (controller.currentScribble.strokes.isEmpty) {
      final saved = await _cacheManager.loadScribble(key);
      if (saved != null && saved.strokes.isNotEmpty) {
        controller.loadScribble(saved);
      }
    }
  }

  Future<void> _toggleMode() async {
    final href = _currentSpineHref;
    if (href != null) await _cacheManager.flushSave(_pageKey(href));
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
    final bytes = _bytes;

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
      body: bytes == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _InfoBanner(colorScheme: cs),
                // 툴바를 항상 레이아웃에 유지해 EPUB 뷰포트 높이를 고정.
                IgnorePointer(
                  ignoring: !_isAnnotationMode,
                  child: Opacity(
                    opacity: _isAnnotationMode ? 1.0 : 0.35,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _drawingState.selectedTool,
                        _drawingState.selectedColor,
                        _drawingState.selectedThickness,
                      ]),
                      builder: (context, _) => DrawingToolbar(
                        selectedTool: _drawingState.selectedTool.value,
                        selectedColor: _drawingState.selectedColor.value,
                        selectedWidth: _drawingState.selectedThickness.value,
                        onToolSelected: (tool) =>
                            _drawingState.selectedTool.value = tool,
                        onColorSelected: (color) =>
                            _drawingState.selectedColor.value = color,
                        onWidthChanged: (width) =>
                            _drawingState.selectedThickness.value = width,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Stack(
                        children: [
                          // 1) EPUB 리더 (하단 레이어). 필기 레이어의 줌/팬
                          // 변환을 동일하게 적용해 본문이 함께 확대된다.
                          ValueListenableBuilder<Matrix4>(
                            valueListenable: _transformController,
                            builder: (context, matrix, child) => ClipRect(
                              child: Transform(transform: matrix, child: child),
                            ),
                            child: EpubReader(
                              source: EpubSource.bytes(bytes),
                              controller: _epubController,
                              showProgressIndicator: false,
                              onPositionChanged: (position) =>
                                  unawaited(_onPositionChanged(position)),
                            ),
                          ),
                          // 2) 필기 오버레이 (상단 레이어)
                          Positioned.fill(
                            child: IgnorePointer(
                              // 읽기 모드: 포인터 통과 → EPUB 스와이프/탭 동작
                              ignoring: !_isAnnotationMode,
                              child: SimpleScribbleWidget(
                                // 챕터 전환 시 컨트롤러 재바인딩
                                key: ValueKey(
                                  'epub-overlay-${_currentSpineHref ?? ''}',
                                ),
                                controller: _activeController,
                                isScribbleEnabled: _isAnnotationMode,
                                // 변환 행렬 공유 — 본문과 필기가 함께 확대/이동
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
                _PageNavBar(controller: _epubController, colorScheme: cs),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_toggleMode()),
        icon: Icon(_isAnnotationMode ? Icons.menu_book : Icons.draw),
        label: Text(_isAnnotationMode ? '읽기 모드' : '필기 모드'),
      ),
    );
  }
}

/// 데모 안내 배너.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final webNote = kIsWeb ? ' 웹에서는 세션 내에서만 필기가 유지됩니다.' : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: colorScheme.surfaceContainerLow,
      child: Text(
        '필기는 챕터(spineHref) 기준으로 저장됩니다 — open_epub 1.0 EpubReader + '
        'EpubViewController 연동.$webNote\n'
        "Sample: Alice's Adventures in Wonderland (Project Gutenberg #11)",
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}

/// 챕터 이전/다음 + 진행 표시 바. EpubViewController 상태를 구독한다.
class _PageNavBar extends StatelessWidget {
  const _PageNavBar({required this.controller, required this.colorScheme});

  final EpubViewController controller;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final count = controller.spineCount;
            final index = controller.currentSpineIndex;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: controller.hasPrevious
                      ? () => unawaited(controller.previousPage())
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  count > 0 ? '${index + 1} / $count' : '로딩 중...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                IconButton(
                  onPressed: controller.hasNext
                      ? () => unawaited(controller.nextPage())
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
