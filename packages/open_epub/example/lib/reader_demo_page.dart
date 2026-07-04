// 실제 책(EPUB) 리더 데모 — marionette 통합테스트 대상.
//
// assets/nohoechan.epub(EPUB 2 reflowable)를 열고, 페이지 넘김/글자 크기/
// RTL 넘김 방향(E14 S14.1)/세로쓰기 조판(E15 S15.4)을 토글할 수 있다. 모든
// 조작 컨트롤에 marionette가 안정적으로 찾을 수 있도록 ValueKey를 부착한다.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_epub/open_epub.dart';

class ReaderDemoPage extends StatefulWidget {
  const ReaderDemoPage({super.key});

  @override
  State<ReaderDemoPage> createState() => _ReaderDemoPageState();
}

class _ReaderDemoPageState extends State<ReaderDemoPage> {
  late final Future<Uint8List> _bytesFuture;
  final EpubViewController _controller = EpubViewController();

  double _fontSize = 18;
  bool _rtl = false;
  bool _vertical = false;
  EpubBookSession? _session;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _loadBytes();
  }

  Future<Uint8List> _loadBytes() async {
    final data = await rootBundle.load('assets/nohoechan.epub');
    return data.buffer.asUint8List();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _session?.book.metadata.title ?? '실제 책 데모',
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
              const Divider(height: 1),
              Expanded(
                child: EpubReader(
                  // key 고정 — fontSize/RTL/세로쓰기 토글은 EpubReader가 live로
                  // 반영하므로 세션 재생성(위치 리셋) 없이 갱신된다.
                  key: const ValueKey('epub-reader'),
                  source: EpubSource.bytes(snapshot.data!),
                  controller: _controller,
                  fontSize: _fontSize,
                  readingDirection:
                      _rtl ? EpubPageProgression.rtl : EpubPageProgression.ltr,
                  verticalWriting: _vertical,
                  onSessionReady: (session) {
                    _session = session;
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
            // RTL 넘김 방향 토글 (E14 S14.1)
            IconButton(
              key: const ValueKey('reader-rtl-toggle'),
              tooltip: 'RTL 넘김 방향',
              isSelected: _rtl,
              icon: const Icon(Icons.format_textdirection_l_to_r),
              selectedIcon: const Icon(Icons.format_textdirection_r_to_l),
              onPressed: () => setState(() => _rtl = !_rtl),
            ),
            // 세로쓰기 조판 토글 (E15 S15.4)
            IconButton(
              key: const ValueKey('reader-vertical-toggle'),
              tooltip: '세로쓰기',
              isSelected: _vertical,
              icon: const Icon(Icons.view_column_outlined),
              selectedIcon: const Icon(Icons.view_column),
              onPressed: () => setState(() => _vertical = !_vertical),
            ),
          ],
        ),
      ),
    );
  }
}
