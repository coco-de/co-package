// open_epub 1.0 코어 데모 페이지.
//
// 이 파일에서만 `package:open_epub/open_epub.dart`를 import한다.
// 레거시 barrel(`open_epub.dart`)과 이름이 겹치는 타입(EpubSource 등)이 있어
// 한 파일에서 두 entry를 혼용할 수 없다 — main.dart는 이 페이지 위젯
// 클래스(V1DemoPage)만 import한다.
//
// 시연 내용:
//   - EpubSource.bytes() + EpubReader(onSessionReady:)로 책 열기
//   - session.book.metadata.title / layout / diagnostics.appliedPatches 표시
//   - lifecycleEvents / progressEvents / toolUseEvents 구독 → 하단 로그 패널
//   - BookPosition v1: 현재 position.toToken() 표시 버튼
//   - session.nextPage()/previousPage() + recordHighlight()/recordBookmark()

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_epub/open_epub.dart';

import 'demo_epub.dart' show buildDemoEpub;

class V1DemoPage extends StatefulWidget {
  const V1DemoPage({super.key});

  @override
  State<V1DemoPage> createState() => _V1DemoPageState();
}

class _V1DemoPageState extends State<V1DemoPage> {
  late final Future<Uint8List> _bytesFuture;

  /// EpubReader가 열어 준 세션. 소유권은 EpubReader에 있으므로 이 페이지에서
  /// dispose하지 않는다 (중복 dispose 금지) — stream 구독만 해제한다.
  EpubBookSession? _session;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _bytesFuture = _loadBytes();
  }

  Future<Uint8List> _loadBytes() async => buildDemoEpub();

  void _onSessionReady(EpubBookSession session) {
    _session = session;

    _subscriptions.add(
      session.lifecycleEvents.listen((event) {
        _addLog(switch (event) {
          EpubSessionStarted(:final epubVersion) =>
            'lifecycle: SessionStarted (EPUB $epubVersion)',
          EpubSessionEnded(:final sessionElapsed) =>
            'lifecycle: SessionEnded (${sessionElapsed.inSeconds}s)',
        });
      }),
    );
    _subscriptions.add(
      session.progressEvents.listen((event) {
        _addLog(
          'progress: ${(event.progress * 100).toStringAsFixed(1)}% '
          '(elapsed ${event.sessionElapsed.inSeconds}s)',
        );
      }),
    );
    _subscriptions.add(
      session.toolUseEvents.listen((event) {
        _addLog('toolUse: ${event.toAnalyticsMap()}');
      }),
    );

    // onSessionReady는 빌드 외부(async 콜백)에서 호출되므로 setState 안전.
    if (mounted) setState(() {});
  }

  void _addLog(String message) {
    // 세션 dispose 시점(SessionEnded)에는 이 State가 이미 dispose됐을 수 있다.
    if (!mounted) return;
    setState(() => _logs.insert(0, message));
  }

  void _showPositionToken() {
    final session = _session;
    if (session == null) return;
    final token = session.position.toToken();
    _addLog('position token: $token');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('BookPosition v1 토큰'),
        content: SelectableText(token),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    // 주의: _session.dispose()는 호출하지 않는다 — EpubReader가 세션을
    // 소유하고 자체 dispose에서 정리한다.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: session == null
            ? const Text('1.0 코어 데모')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.book.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'layout: ${session.book.layout.name} · '
                    '보정 ${session.diagnostics.appliedPatches.length}건',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: 'recordHighlight() — toolUse 이벤트',
            icon: const Icon(Icons.border_color_outlined),
            onPressed: session?.recordHighlight,
          ),
          IconButton(
            tooltip: 'recordBookmark() — toolUse 이벤트',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: session?.recordBookmark,
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('asset 로드 실패: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: EpubReader(
                  source: EpubSource.bytes(snapshot.data!),
                  // 데모에서 progress 이벤트를 빠르게 보기 위해 throttle 단축
                  // (기본 30초).
                  options: const EpubSessionOptions(
                    progressThrottle: Duration(seconds: 2),
                  ),
                  onSessionReady: _onSessionReady,
                ),
              ),
              _buildEventPanel(theme),
            ],
          );
        },
      ),
    );
  }

  // --- 하단 이벤트 로그 패널 ---

  Widget _buildEventPanel(ThemeData theme) {
    final session = _session;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text('이벤트 로그', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    IconButton(
                      tooltip: 'session.previousPage()',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: session?.previousPage,
                    ),
                    IconButton(
                      tooltip: 'session.nextPage()',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: session?.nextPage,
                    ),
                    TextButton.icon(
                      onPressed: session == null ? null : _showPositionToken,
                      icon: const Icon(Icons.pin_drop_outlined, size: 18),
                      label: const Text('위치 토큰'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _logs.isEmpty
                    ? Center(
                        child: Text(
                          '이벤트 대기 중...',
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) => Text(
                          _logs[index],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
