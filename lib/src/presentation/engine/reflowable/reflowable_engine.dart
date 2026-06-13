// Presentation Engine — open_epub 1.0
// Story: S1.5 (#11) — Reflowable XHTML 렌더
// Story: S1.6 (#12) — 글자 크기·줄간격 + BookPosition(spineIndex) 보존
// BDD: F2.1 / F2.2 / F2.3 / F2.5
//
// 본 widget은 단일 spine 항목을 스크롤로 표시 (S1.5). S1.6에서
// fontSize / lineHeight property를 추가하여 글자 크기·줄간격 변경 시
// 본문이 재배치되며 현재 spineIndex가 보존됨을 보장한다.
//
// 페이지 모드(spine 단위 PageView)는 [ReflowablePageView]에서 처리.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../api/epub_book.dart';

/// spine href를 받아 해당 XHTML 콘텐츠 문자열을 비동기 로드.
typedef XhtmlLoader = Future<String> Function(String spineHref);

/// 이미지 src(XHTML 내 `<img src>`)를 받아 바이트를 비동기 로드.
/// null 반환 또는 throw 시 placeholder가 표시된다.
typedef ImageLoader = Future<Uint8List?> Function(String src);

/// 본문 내 링크(`<a href>`) 탭 콜백. href는 책 내부 상대 경로(예: "ch2.xhtml"),
/// 외부 URL, 또는 하이라이트 링크(openepub-hl:ID)일 수 있다. (S7.3/S7.5)
typedef EpubLinkTapCallback = void Function(String href);

/// Reflowable EPUB 책의 본문을 표시하는 최상위 엔진 widget.
///
/// 페이지 분할은 본 Story 범위가 아니므로 현재 spine 항목 전체를 스크롤로
/// 표시한다. S1.6 (#12)에서 `ReflowablePageView` + `PaginationStrategy`로
/// 페이지 모드를 도입한다.
class ReflowableEngine extends StatefulWidget {
  const ReflowableEngine({
    super.key,
    required this.book,
    required this.xhtmlLoader,
    this.imageLoader,
    this.initialSpineIndex = 0,
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.onLinkTap,
  });

  final EpubBook book;
  final XhtmlLoader xhtmlLoader;
  final ImageLoader? imageLoader;
  final int initialSpineIndex;

  /// 본문 글자 크기 (px). BDD F2.2 — 변경 시 본문 재배치 + spineIndex 보존.
  final double fontSize;

  /// 본문 줄간격 (배수). BDD F2.3 — 변경 시 본문 재배치.
  final double lineHeight;

  /// 본문 링크/하이라이트 탭 콜백. (S7.3/S7.5)
  final EpubLinkTapCallback? onLinkTap;

  @override
  State<ReflowableEngine> createState() => ReflowableEngineState();
}

@visibleForTesting
class ReflowableEngineState extends State<ReflowableEngine> {
  late int _spineIndex;
  late Future<String> _currentLoad;

  int get spineIndex => _spineIndex;
  int get spineCount => widget.book.spine.length;

  @override
  void initState() {
    super.initState();
    _spineIndex = widget.initialSpineIndex.clamp(
      0,
      widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
    );
    _currentLoad = _loadCurrent();
  }

  Future<String> _loadCurrent() {
    if (widget.book.spine.isEmpty) return Future.value('');
    return widget.xhtmlLoader(widget.book.spine[_spineIndex].href);
  }

  /// 다음 spine 항목으로 이동. 마지막이면 false.
  bool nextSpine() {
    if (_spineIndex >= spineCount - 1) return false;
    setState(() {
      _spineIndex++;
      _currentLoad = _loadCurrent();
    });
    return true;
  }

  /// 이전 spine 항목으로 이동. 처음이면 false.
  bool previousSpine() {
    if (_spineIndex <= 0) return false;
    setState(() {
      _spineIndex--;
      _currentLoad = _loadCurrent();
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book.spine.isEmpty) {
      return const _EmptyState();
    }

    return FutureBuilder<String>(
      future: _currentLoad,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(error: snapshot.error!);
        }
        final xhtml = snapshot.data ?? '';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: buildReflowableHtml(
            data: xhtml,
            fontSize: widget.fontSize,
            lineHeight: widget.lineHeight,
            imageLoader: widget.imageLoader,
            onLinkTap: widget.onLinkTap,
          ),
        );
      },
    );
  }
}

/// 사용자 글자 크기·줄간격이 적용된 [Html] widget을 빌드한다.
/// [ReflowablePageView]와 공유하는 internal helper.
Html buildReflowableHtml({
  required String data,
  required double fontSize,
  required double lineHeight,
  required ImageLoader? imageLoader,
  EpubLinkTapCallback? onLinkTap,
}) {
  return Html(
    data: data,
    onLinkTap: onLinkTap == null
        ? null
        : (url, _, __) {
            if (url != null && url.isNotEmpty) onLinkTap(url);
          },
    style: {
      'body': Style(
        fontSize: FontSize(fontSize),
        lineHeight: LineHeight(lineHeight),
      ),
    },
    extensions: [
      TagExtension(
        tagsToExtend: {'img'},
        builder: (ctx) {
          final src = ctx.attributes['src'];
          if (src == null || src.isEmpty) {
            return const _ImagePlaceholder(reason: 'missing src');
          }
          return _RemoteImage(src: src, loader: imageLoader);
        },
      ),
    ],
  );
}

@visibleForTesting
class RemoteImageState extends State<_RemoteImage> {
  late Future<Uint8List?> _load;

  @override
  void initState() {
    super.initState();
    _load = _resolve();
  }

  Future<Uint8List?> _resolve() async {
    final loader = widget.loader;
    if (loader == null) return null;
    try {
      return await loader(widget.src);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 32,
            width: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final bytes = snap.data;
        if (bytes == null) {
          return const _ImagePlaceholder(reason: 'image load failed');
        }
        return Image.memory(
          bytes,
          errorBuilder: (_, __, ___) =>
              const _ImagePlaceholder(reason: 'image decode failed'),
        );
      },
    );
  }
}

class _RemoteImage extends StatefulWidget {
  const _RemoteImage({required this.src, required this.loader});
  final String src;
  final ImageLoader? loader;

  @override
  State<_RemoteImage> createState() => RemoteImageState();
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'image placeholder ($reason)',
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('이 책에는 표시할 내용이 없습니다.'));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '본문을 불러올 수 없습니다.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
