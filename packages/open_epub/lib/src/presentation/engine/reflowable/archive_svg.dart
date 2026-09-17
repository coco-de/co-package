// Presentation Engine — open_epub 1.0
// Issue: #278 — EPUB3 SVG-래핑 FXL의 archive <image href>를 data URI로 치환한다.
//
// fwfh_svg는 SvgStringLoader(outerHtml)로 넘기므로, data:가 아닌 href는 버려져
// 빈 SVG와 같아지고 never-empty 안내도 뜨지 않는다(<svg>가 있으면 비어있지 않다고 판정).

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html/dom.dart' as dom;

final _svgImageTag = RegExp(
  r'<image\b[^>]*>',
  caseSensitive: false,
);

final _svgHrefAttr = RegExp(
  r'''(?:xlink:)?href\s*=\s*(["'])([^"']+)\1''',
  caseSensitive: false,
);

final _svgDrawnTag = RegExp(
  r'<(path|rect|circle|ellipse|polygon|polyline|line|text|use|g)\b',
  caseSensitive: false,
);

/// [svg] 요소가 아카이브 상대 경로 `<image>`를 가지면 가로채고, 아니면 null
/// (fwfh_svg가 처리).
Widget? archiveSvgWidget(
  dom.Element svg, {
  required Future<Uint8List?> Function(String src)? loadImage,
}) {
  final hrefs = _archiveImageHrefs(svg.outerHtml);
  if (hrefs.isEmpty) return null;
  return _ArchiveSvg(
    markup: svg.outerHtml,
    hrefs: hrefs,
    loadImage: loadImage,
  );
}

List<String> _archiveImageHrefs(String markup) {
  final hrefs = <String>[];
  for (final tag in _svgImageTag.allMatches(markup)) {
    final href = _svgHrefAttr.firstMatch(tag.group(0)!)?.group(2);
    if (href == null || href.isEmpty) continue;
    if (_isExternalOrData(href)) continue;
    hrefs.add(href);
  }
  return hrefs;
}

bool _isExternalOrData(String href) {
  final lower = href.toLowerCase();
  return lower.startsWith('data:') ||
      lower.startsWith('http:') ||
      lower.startsWith('https:') ||
      lower.startsWith('file:') ||
      lower.startsWith('asset:');
}

class _ArchiveSvg extends StatefulWidget {
  const _ArchiveSvg({
    required this.markup,
    required this.hrefs,
    required this.loadImage,
  });

  final String markup;
  final List<String> hrefs;
  final Future<Uint8List?> Function(String src)? loadImage;

  @override
  State<_ArchiveSvg> createState() => _ArchiveSvgState();
}

class _ArchiveSvgState extends State<_ArchiveSvg> {
  late Future<_RewrittenSvg> _rewrite;

  @override
  void initState() {
    super.initState();
    _rewrite = _resolve();
  }

  Future<_RewrittenSvg> _resolve() async {
    var markup = widget.markup;
    var loaded = 0;
    Uint8List? firstBytes;
    final loader = widget.loadImage;
    for (final href in widget.hrefs) {
      if (loader == null) continue;
      Uint8List? bytes;
      try {
        bytes = await loader(href);
      } catch (_) {
        bytes = null;
      }
      if (bytes == null || bytes.isEmpty) continue;
      firstBytes ??= bytes;
      final dataUri = _dataUri(href, bytes);
      markup = markup.replaceAll(href, dataUri);
      loaded++;
    }
    return _RewrittenSvg(
      markup: markup,
      loaded: loaded,
      bytes: firstBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RewrittenSvg>(
      future: _rewrite,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 32,
            width: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final rewritten = snap.data;
        final hasDrawing = _svgDrawnTag.hasMatch(widget.markup);
        if (rewritten == null || rewritten.loaded == 0) {
          if (hasDrawing) {
            return SvgPicture.string(widget.markup, fit: BoxFit.fill);
          }
          return const _SvgImagePlaceholder();
        }
        // EPUB3 FXL 표준 패턴은 svg가 이미지 한 장을 감싼 것. nested <image>
        // data URI는 vector_graphics가 종종 못 디코드하므로 비트맵으로 그린다.
        final bytes = rewritten.bytes;
        if (bytes != null && bytes.isNotEmpty && !hasDrawing) {
          return Image.memory(
            bytes,
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => const _SvgImagePlaceholder(),
          );
        }
        return SvgPicture.string(rewritten.markup, fit: BoxFit.fill);
      },
    );
  }
}

class _RewrittenSvg {
  const _RewrittenSvg({
    required this.markup,
    required this.loaded,
    this.bytes,
  });
  final String markup;
  final int loaded;
  final Uint8List? bytes;
}

String _dataUri(String href, Uint8List bytes) {
  final mime = _mimeFor(href);
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

String _mimeFor(String href) {
  final path = href.split('?').first.split('#').first.toLowerCase();
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
  if (path.endsWith('.gif')) return 'image/gif';
  if (path.endsWith('.webp')) return 'image/webp';
  if (path.endsWith('.svg')) return 'image/svg+xml';
  return 'image/png';
}

class _SvgImagePlaceholder extends StatelessWidget {
  const _SvgImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'image placeholder (svg image load failed)',
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
