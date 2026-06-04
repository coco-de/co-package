// Data Repository Impl — open_epub 1.0
// Story: S1.20 (#36), S1.21 (#37) — EPUB ZIP 해제 → 파서 연결 → EpubBook 조립
//
// 책임: I/O(소스 읽기 + 보안 크기 검사) + ZIP 해제 + 파서(container/OPF/NCX/nav)
// 호출 + 도메인 EpubBook 조립까지. 호환성 보정(ApplyPatchesUseCase)은 상위
// UseCase가 수행한다(보정 전 raw EpubBook을 반환).

import 'dart:convert';

import 'package:archive/archive.dart';

import '../../api/epub_book.dart';
import '../../api/epub_security_config.dart';
import '../../api/epub_source.dart';
import '../../domain/entity/epub_failure.dart';
import '../../domain/entity/epub_outline.dart';
import '../../domain/repository/epub_repository.dart';
import '../compat/patch_catalog.dart' show PatchedEpubBook;
import '../parser/container_parser.dart';
import '../parser/nav_parser.dart';
import '../parser/ncx_parser.dart';
import '../parser/opf_parser.dart';

class EpubRepositoryImpl implements EpubRepository {
  EpubRepositoryImpl({
    EpubSecurityConfig security = const EpubSecurityConfig(),
    ContainerParser containerParser = const ContainerParser(),
    OpfParser opfParser = const OpfParser(),
    NcxParser ncxParser = const NcxParser(),
    NavParser navParser = const NavParser(),
  })  : _security = security,
        _containerParser = containerParser,
        _opfParser = opfParser,
        _ncxParser = ncxParser,
        _navParser = navParser;

  final EpubSecurityConfig _security;
  final ContainerParser _containerParser;
  final OpfParser _opfParser;
  final NcxParser _ncxParser;
  final NavParser _navParser;

  static const String _containerPath = 'META-INF/container.xml';

  @override
  Future<EpubBook> load(EpubSource source) async {
    final bytes = await source.readBytes();

    if (bytes.length > _security.maxFileSizeBytes) {
      throw EpubFileTooLarge(
        actualBytes: bytes.length,
        limitBytes: _security.maxFileSizeBytes,
      );
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object catch (e) {
      throw EpubCorrupted(
        'not a valid ZIP/EPUB container (${source.debugIdentifier}): $e',
      );
    }

    final containerXml = _readString(archive, _containerPath);
    if (containerXml == null) {
      throw EpubInvalidFile('missing $_containerPath');
    }
    final opfPath = _containerParser.parse(containerXml);

    final opfXml = _readString(archive, opfPath);
    if (opfXml == null) {
      throw EpubInvalidFile('missing OPF package at "$opfPath"');
    }
    final parsed = _opfParser.parse(opfXml);
    final tocRefs = _opfParser.tocRefs(opfXml);

    final opfDir = _dirOf(opfPath);
    final outline = _parseOutline(archive, opfDir, tocRefs);

    return PatchedEpubBook(
      metadata: parsed.metadata,
      spine: parsed.spine,
      outline: outline,
    );
  }

  /// nav.xhtml(EPUB 3) 우선, 없으면 NCX(EPUB 2). 파일이 없거나 파싱 실패 시
  /// [EpubOutline.empty] (목차 부재는 sparse-ncx/empty-toc 보정이 진단).
  EpubOutline _parseOutline(
    Archive archive,
    String opfDir,
    ({String? ncxHref, String? navHref}) tocRefs,
  ) {
    final navHref = tocRefs.navHref;
    if (navHref != null) {
      final xml = _readString(archive, _resolve(opfDir, navHref));
      if (xml != null) {
        try {
          return _navParser.parse(xml);
        } on Object {
          // nav 파싱 실패 → NCX로 폴백 시도
        }
      }
    }

    final ncxHref = tocRefs.ncxHref;
    if (ncxHref != null) {
      final xml = _readString(archive, _resolve(opfDir, ncxHref));
      if (xml != null) {
        try {
          return _ncxParser.parse(xml);
        } on Object {
          // NCX 파싱 실패 → 빈 목차
        }
      }
    }

    return EpubOutline.empty;
  }

  String? _readString(Archive archive, String path) {
    final file = archive.findFile(path);
    if (file == null) return null;
    final content = file.content as List<int>;
    return utf8.decode(content, allowMalformed: true);
  }

  /// ZIP 내부 경로의 디렉토리 부분. `OEBPS/content.opf` → `OEBPS`.
  String _dirOf(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? '' : path.substring(0, i);
  }

  /// OPF 기준 상대 [href]를 [baseDir]과 결합하고 `.`/`..`를 정규화한다.
  String _resolve(String baseDir, String href) {
    final combined = baseDir.isEmpty ? href : '$baseDir/$href';
    final parts = <String>[];
    for (final seg in combined.split('/')) {
      if (seg.isEmpty || seg == '.') continue;
      if (seg == '..') {
        if (parts.isNotEmpty) parts.removeLast();
        continue;
      }
      parts.add(seg);
    }
    return parts.join('/');
  }
}
