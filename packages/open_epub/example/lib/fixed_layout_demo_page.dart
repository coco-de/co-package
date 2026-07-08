// Fixed Layout(pre-paginated) A4 크기 데모 페이지.
//
// EPUB3 샘플 라이브러리(sample_book.dart)의 8종은 전부 reflowable 본문이라
// FixedLayoutEngine을 예제 앱에서 확인할 방법이 없었다. `demo_epub.dart`의
// buildFixedLayoutA4DemoEpub()(외부 asset 없이 순수 Dart로 생성, #235와 동일한
// 이유)을 열어 A4(794×1123px) 페이지가 실제로 그 비율/크기로 렌더되는지, 핀치
// 줌·페이지 넘김이 정상 동작하는지 확인한다.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_epub/open_epub.dart';

import 'demo_epub.dart'
    show buildFixedLayoutA4DemoEpub, kA4PageHeight, kA4PageWidth;

class FixedLayoutDemoPage extends StatefulWidget {
  const FixedLayoutDemoPage({super.key});

  @override
  State<FixedLayoutDemoPage> createState() => _FixedLayoutDemoPageState();
}

class _FixedLayoutDemoPageState extends State<FixedLayoutDemoPage> {
  late final Future<Uint8List> _bytesFuture;
  final EpubViewController _controller = EpubViewController();

  EpubBookSession? _session;
  int _spineIndex = 0;
  int _spineCount = 0;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _loadBytes();
  }

  Future<Uint8List> _loadBytes() async => buildFixedLayoutA4DemoEpub();

  void _onSessionReady(EpubBookSession session) {
    _session = session;
    if (mounted) setState(() {});
  }

  void _onPageChanged(int spineIndex, int spineCount) {
    setState(() {
      _spineIndex = spineIndex;
      _spineCount = spineCount;
    });
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
        title: const Text('Fixed Layout A4 데모'),
        centerTitle: true,
      ),
      body: FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildControlBar(theme),
              _buildStatusBar(theme),
              const Divider(height: 1),
              Expanded(
                child: EpubReader(
                  source: EpubSource.bytes(snapshot.data!),
                  controller: _controller,
                  onSessionReady: _onSessionReady,
                  onPageChanged: _onPageChanged,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBar(ThemeData theme) {
    final layout = _session?.book.layout.name ?? '-';
    final parts = <String>[
      'layout:$layout',
      'size:${kA4PageWidth.toInt()}×${kA4PageHeight.toInt()} (A4)',
      if (_spineCount > 0) '${_spineIndex + 1}/$_spineCount쪽',
    ];
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Text(
        parts.join('  ·  '),
        key: const ValueKey('fixed-layout-a4-status'),
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              key: const ValueKey('fixed-layout-a4-prev'),
              tooltip: '이전 페이지',
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _controller.previousPage(),
            ),
            IconButton(
              key: const ValueKey('fixed-layout-a4-next'),
              tooltip: '다음 페이지',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _controller.nextPage(),
            ),
          ],
        ),
      ),
    );
  }
}
