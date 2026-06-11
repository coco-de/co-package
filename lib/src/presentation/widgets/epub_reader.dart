// Presentation Top-level Widget — open_epub 1.0
// Story: S1.21 (#37) — EpubBookSession.open() 기반 최상위 reader
// BDD: F1 (책 열고 첫 페이지 표시), F1.2 (진도 인디케이터), F1.3 (복원 실패 안내)
//
// 최상위 entry widget. 내부적으로 EpubBookSession을 관리하고 ReflowableEngine
// 또는 FixedLayoutEngine으로 분기. 선택적 사용 — kobic은 자체 BLoC을 통해
// EpubBookSession을 직접 다룬다.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../api/epub_book.dart';
import '../../api/epub_book_session.dart';
import '../../api/epub_position.dart';
import '../../api/epub_source.dart';
import '../../domain/entity/epub_failure.dart';
import '../../domain/entity/epub_spine_item.dart';
import '../engine/fixed_layout/fixed_layout_engine.dart';
import '../engine/reflowable/reflowable_engine.dart';

/// 세션 open 완료 시점에 호출 — 호출자가 analytics 스트림 구독·위치 저장 등
/// 세션 수준 기능에 접근할 수 있게 한다.
typedef EpubSessionReadyCallback = void Function(EpubBookSession session);

/// open_epub 1.0 최상위 reader widget.
///
/// [source]로 세션을 열어 책의 layout에 따라 [ReflowableEngine] 또는
/// [FixedLayoutEngine]으로 본문을 표시한다. 위치 복원 실패 시 안내 배너
/// (BDD F1.3), 하단에 진도 인디케이터(BDD F1.2)를 표시한다.
class EpubReader extends StatefulWidget {
  const EpubReader({
    super.key,
    required this.source,
    this.initialPosition,
    this.options = const EpubSessionOptions(),
    this.onSessionReady,
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.showProgressIndicator = true,
  });

  final EpubSource source;

  /// 저장된 위치(BookPosition v1). 복원 실패 시 첫 페이지 fallback + 배너.
  final EpubPosition? initialPosition;

  final EpubSessionOptions options;
  final EpubSessionReadyCallback? onSessionReady;

  /// Reflowable 본문 글자 크기 (px).
  final double fontSize;

  /// Reflowable 본문 줄간격 (배수).
  final double lineHeight;

  /// 하단 진도 인디케이터("45%") 표시 여부.
  final bool showProgressIndicator;

  @override
  State<EpubReader> createState() => _EpubReaderState();
}

class _EpubReaderState extends State<EpubReader> {
  late Future<EpubBookSession> _open;
  EpubBookSession? _session;

  @override
  void initState() {
    super.initState();
    _open = _openSession();
  }

  Future<EpubBookSession> _openSession() async {
    final session = await EpubBookSession.open(
      widget.source,
      initialPosition: widget.initialPosition,
      options: widget.options,
    );
    _session = session;
    widget.onSessionReady?.call(session);
    return session;
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EpubBookSession>(
      future: _open,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _OpenErrorView(error: snapshot.error!);
        }
        return _SessionView(
          session: snapshot.data!,
          fontSize: widget.fontSize,
          lineHeight: widget.lineHeight,
          showProgressIndicator: widget.showProgressIndicator,
        );
      },
    );
  }
}

class _SessionView extends StatelessWidget {
  const _SessionView({
    required this.session,
    required this.fontSize,
    required this.lineHeight,
    required this.showProgressIndicator,
  });

  final EpubBookSession session;
  final double fontSize;
  final double lineHeight;
  final bool showProgressIndicator;

  int get _initialSpineIndex {
    final spine = session.book.spine;
    final i = spine.indexWhere((s) => s.href == session.position.spineHref);
    return i < 0 ? 0 : i;
  }

  String? get _restoreFailedMessage {
    for (final issue in session.diagnostics.unresolvedIssues) {
      if (issue.code == 'position-restore-failed') return issue.message;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final book = session.book;
    final engine = book.layout == EpubLayout.fixedLayout
        ? FixedLayoutEngine(
            book: book,
            initialSpineIndex: _initialSpineIndex,
            pageBuilder: _buildFixedPage,
          )
        : ReflowableEngine(
            book: book,
            initialSpineIndex: _initialSpineIndex,
            xhtmlLoader: _loadXhtml,
            imageLoader: _loadImage,
            fontSize: fontSize,
            lineHeight: lineHeight,
          );

    final restoreMessage = _restoreFailedMessage;
    return Column(
      children: [
        if (restoreMessage != null)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(restoreMessage)),
                ],
              ),
            ),
          ),
        Expanded(child: engine),
        if (showProgressIndicator)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '${(session.progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Future<String> _loadXhtml(String spineHref) async =>
      session.readSpineXhtml(spineHref) ?? '';

  Future<Uint8List?> _loadImage(String src) async =>
      session.resources.readBytes(src);

  Future<FixedLayoutPageData> _buildFixedPage(EpubSpineItem item) async {
    final xhtml = session.readSpineXhtml(item.href) ?? '';
    return FixedLayoutPageData(
      logicalSize: _viewportSize(xhtml),
      content: buildReflowableHtml(
        data: xhtml,
        fontSize: fontSize,
        lineHeight: lineHeight,
        imageLoader: _loadImage,
      ),
    );
  }

  /// `<meta name="viewport" content="width=600, height=800"/>`에서 논리
  /// 크기를 파싱한다. 없거나 비정상이면 기본 600×800.
  static Size _viewportSize(String xhtml) {
    final width = _viewportDimension(xhtml, 'width');
    final height = _viewportDimension(xhtml, 'height');
    if (width == null || height == null || width <= 0 || height <= 0) {
      return const Size(600, 800);
    }
    return Size(width, height);
  }

  static double? _viewportDimension(String xhtml, String name) {
    final match =
        RegExp('$name\\s*=\\s*(\\d+(?:\\.\\d+)?)').firstMatch(xhtml);
    return match == null ? null : double.tryParse(match.group(1)!);
  }
}

class _OpenErrorView extends StatelessWidget {
  const _OpenErrorView({required this.error});

  final Object error;

  String get _message => switch (error) {
        EpubFileTooLarge() => '파일이 너무 커서 열 수 없습니다.',
        EpubNetworkFailure() => '네트워크 오류로 책을 가져오지 못했습니다.',
        EpubCorrupted() || EpubInvalidFile() => '손상되었거나 올바르지 않은 EPUB입니다.',
        _ => '책을 여는 중 오류가 발생했습니다.',
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('$_message\n$error', textAlign: TextAlign.center),
      ),
    );
  }
}
