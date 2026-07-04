// 샘플 EPUB 리더 데모 — marionette 통합테스트 대상.
//
// [SampleBook]을 열어 페이지 넘김/글자 크기/RTL 넘김 방향(E14 S14.1)/세로쓰기
// 조판(E15 S15.4)/Media Overlay 낭독(E15)을 검증한다. 모든 조작 컨트롤에
// marionette가 안정적으로 찾도록 ValueKey를 부착한다.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_epub/open_epub.dart';

import 'sample_book.dart';

class ReaderDemoPage extends StatefulWidget {
  const ReaderDemoPage({super.key, required this.book});

  final SampleBook book;

  @override
  State<ReaderDemoPage> createState() => _ReaderDemoPageState();
}

class _ReaderDemoPageState extends State<ReaderDemoPage> {
  late final Future<Uint8List> _bytesFuture;
  final EpubViewController _controller = EpubViewController();

  double _fontSize = 18;
  late bool _rtl = widget.book.autoRtl;
  late bool _vertical = widget.book.autoVertical;

  EpubBookSession? _session;
  BookCapabilities? _caps;

  // Media Overlay(낭독) — MO 샘플에서만 생성.
  MediaOverlayController? _moController;
  MediaOverlayState _moState = MediaOverlayState.idle;
  int _moPar = -1;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _loadBytes();
  }

  Future<Uint8List> _loadBytes() async {
    final data = await rootBundle.load(widget.book.asset);
    return data.buffer.asUint8List();
  }

  @override
  void dispose() {
    _moController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSessionReady(EpubBookSession session) {
    _session = session;
    _caps = session.capabilities;
    // 책이 선언한 진행 방향을 존중(사용자 토글 전 최초 1회).
    if (!widget.book.autoRtl && _caps!.isRightToLeft) _rtl = true;
    if (mounted) setState(() {});
  }

  // ── Media Overlay 낭독 ────────────────────────────────────────────────
  Future<void> _toggleNarration() async {
    final session = _session;
    if (session == null) return;

    // 재생 중이면 일시정지/재개.
    if (_moController != null) {
      if (_moState == MediaOverlayState.playing) {
        await _moController!.pause();
        return;
      }
      if (_moState == MediaOverlayState.paused) {
        await _moController!.resume();
        return;
      }
    }

    // 최초 시작 — MO가 걸린 첫 spine으로 이동 후 재생.
    final spine = session.book.spine;
    final idx = spine.indexWhere((s) => s.mediaOverlayHref != null);
    if (idx < 0) {
      _snack('이 책에는 Media Overlay가 없습니다');
      return;
    }
    final href = spine[idx].href;
    await _controller.goToSpine(idx);

    final overlay = await session.loadMediaOverlay(href);
    if (overlay.isEmpty) {
      _snack('Media Overlay(SMIL) 로드 실패');
      return;
    }

    final controller = _moController ??=
        MediaOverlayController(player: JustAudioMediaPlayer())
          ..addListener(_onMoChanged);
    if (mounted) setState(() {}); // EpubReader에 controller 주입 → 하이라이트 배선

    try {
      await controller.start(
        overlay,
        loadAudio: (src) async => session.resources.readBytes(src),
      );
    } catch (e) {
      // just_audio StreamAudioSource는 iOS 시뮬레이터에서 AVFoundation
      // (-11800)으로 실패한다(실기기/Android는 정상). SMIL 파싱·프래그먼트
      // 하이라이트 배선은 완료된 상태이므로 재생 실패만 안내한다.
      _snack('오디오 재생 실패(시뮬레이터 제약일 수 있음): $e');
    }
  }

  void _onMoChanged() {
    if (!mounted) return;
    setState(() {
      _moState = _moController!.state;
      _moPar = _moController!.activeParIndex.value;
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _session?.book.metadata.title ?? widget.book.title,
          key: const ValueKey('reader-title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              key: const ValueKey('reader-error'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('asset 로드 실패: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              key: ValueKey('reader-loading'),
              child: CircularProgressIndicator(),
            );
          }
          return Column(
            children: [
              _buildControlBar(theme),
              _buildStatusBar(theme),
              const Divider(height: 1),
              Expanded(
                child: EpubReader(
                  // key를 asset별로 고정 — 샘플 전환 시 리더 재생성.
                  key: ValueKey('epub-reader-${widget.book.id}'),
                  source: EpubSource.bytes(snapshot.data!),
                  controller: _controller,
                  paged: true,
                  fontSize: _fontSize,
                  readingDirection:
                      _rtl ? EpubPageProgression.rtl : EpubPageProgression.ltr,
                  verticalWriting: _vertical,
                  mediaOverlayController: _moController,
                  onSessionReady: _onSessionReady,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 현재 적용 상태를 marionette 스크린샷으로 검증 가능하게 노출.
  Widget _buildStatusBar(ThemeData theme) {
    final caps = _caps;
    final parts = <String>[
      'RTL:${_rtl ? "on" : "off"}',
      '세로:${_vertical ? "on" : "off"}',
      if (caps != null) 'PPD:${caps.pageProgressionDirection.name}',
      if (caps != null && caps.hasMediaOverlay) 'MO:${_moState.name}($_moPar)',
    ];
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Text(
        parts.join('  ·  '),
        key: const ValueKey('reader-status'),
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme) {
    final showMo = widget.book.hasMediaOverlay;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              key: const ValueKey('reader-prev'),
              tooltip: '이전 페이지',
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _controller.previousPage(),
            ),
            IconButton(
              key: const ValueKey('reader-next'),
              tooltip: '다음 페이지',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _controller.nextPage(),
            ),
            IconButton(
              key: const ValueKey('reader-font-dec'),
              tooltip: '글자 작게',
              icon: const Icon(Icons.text_decrease),
              onPressed: () =>
                  setState(() => _fontSize = (_fontSize - 2).clamp(12, 32)),
            ),
            IconButton(
              key: const ValueKey('reader-font-inc'),
              tooltip: '글자 크게',
              icon: const Icon(Icons.text_increase),
              onPressed: () =>
                  setState(() => _fontSize = (_fontSize + 2).clamp(12, 32)),
            ),
            IconButton(
              key: const ValueKey('reader-rtl-toggle'),
              tooltip: 'RTL 넘김 방향',
              isSelected: _rtl,
              icon: const Icon(Icons.format_textdirection_l_to_r),
              selectedIcon: const Icon(Icons.format_textdirection_r_to_l),
              onPressed: () => setState(() => _rtl = !_rtl),
            ),
            IconButton(
              key: const ValueKey('reader-vertical-toggle'),
              tooltip: '세로쓰기',
              isSelected: _vertical,
              icon: const Icon(Icons.view_column_outlined),
              selectedIcon: const Icon(Icons.view_column),
              onPressed: () => setState(() => _vertical = !_vertical),
            ),
            if (showMo)
              IconButton(
                key: const ValueKey('reader-mo-play'),
                tooltip: '낭독(Media Overlay)',
                isSelected: _moState == MediaOverlayState.playing,
                icon: const Icon(Icons.play_circle_outline),
                selectedIcon: const Icon(Icons.pause_circle_outline),
                onPressed: _toggleNarration,
              ),
          ],
        ),
      ),
    );
  }
}
