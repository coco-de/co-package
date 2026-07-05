// Data Repository Impl — open_epub 1.0
// Story: S1.20 (#36), S1.21 (#37) — EPUB ZIP 해제 → 파서 연결 → EpubBook 조립
//
// 책임: I/O(소스 읽기 + 보안 크기 검사) + ZIP 해제 + 파서(container/OPF/NCX/nav)
// 호출 + 도메인 EpubBook 조립까지. 호환성 보정(ApplyPatchesUseCase)은 상위
// UseCase가 수행한다(보정 전 raw EpubBook을 반환).

import 'dart:convert';

import 'package:archive/archive.dart';

import '../../api/epub_security_config.dart';
import '../../api/epub_source.dart';
import '../../domain/entity/epub_failure.dart';
import '../../domain/entity/epub_navigation.dart';
import '../../domain/entity/epub_outline.dart';
import '../../domain/repository/epub_repository.dart';
import '../compat/patch_catalog.dart'
    show AppliedPatch, PatchSeverity, PatchedEpubBook;
import '../parser/container_parser.dart';
import '../parser/nav_parser.dart';
import '../parser/ncx_parser.dart';
import '../parser/opf_parser.dart';
import '../security/encryption_parser.dart';
import 'archive_resource_reader.dart';

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
  Future<RawEpubLoad> load(EpubSource source) async {
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

    final patches = <AppliedPatch>[];

    // raw-레벨 보정 1: mimetype 파일 검사 (ZIP 레벨 — EpubBook으론 감지 불가).
    final mimetype = _readString(archive, 'mimetype')?.trim();
    if (mimetype != 'application/epub+zip') {
      patches.add(
        AppliedPatch(
          patchId: 'missing-mimetype',
          description: 'mimetype 파일 누락/불일치 — EPUB로 가정하여 진행',
          severity: PatchSeverity.low,
          impact: {'found': mimetype ?? '(none)'},
        ),
      );
    }

    final containerXml = _readString(archive, _containerPath);
    if (containerXml == null) {
      throw EpubInvalidFile('missing $_containerPath');
    }
    final opfPath = _containerParser.parse(containerXml);
    final renditions = _containerParser.parseRootfiles(containerXml);

    final opfXml = _readString(archive, opfPath);
    if (opfXml == null) {
      throw EpubInvalidFile('missing OPF package at "$opfPath"');
    }
    // OPF XML은 한 번만 파싱한다 — parse/tocRefs/rawRenditionLayout/
    // parseCapabilities를 개별 호출하면 대형 manifest에서 파싱이 4중으로
    // 반복된다. (S9.5 #69)
    final bundle = _opfParser.parseBundle(opfXml);
    final tocRefs = bundle.tocRefs;

    // raw-레벨 보정 2: 비표준 rendition:layout (OPF raw — 파싱 후 소실됨).
    final rawLayout = bundle.rawRenditionLayout;
    if (rawLayout != null &&
        rawLayout != 'pre-paginated' &&
        rawLayout != 'reflowable') {
      patches.add(
        AppliedPatch(
          patchId: 'invalid-rendition-layout',
          description:
              '비표준 rendition:layout "$rawLayout" → reflowable fallback',
          severity: PatchSeverity.medium,
          impact: {'raw': rawLayout},
        ),
      );
    }

    final opfDir = _dirOf(opfPath);
    final outline = _parseOutline(archive, opfDir, tocRefs, patches);
    final navigation = _parseNavigation(archive, opfDir, tocRefs);
    final capabilities = bundle.capabilities;

    // encryption.xml — IDPF/Adobe 폰트 난독화는 투명 해제 맵으로, 콘텐츠(spine)에
    // 걸린 미지원 암호화(상업 DRM)는 EpubEncryptedUnsupported로. (S13.5, gap #8)
    final obfuscated = _parseEncryption(
      archive,
      opfDir,
      bundle.spine.map((s) => s.href),
    );

    return RawEpubLoad(
      book: PatchedEpubBook(
        metadata: bundle.metadata,
        spine: bundle.spine,
        outline: outline,
      ),
      patches: patches,
      resources: ArchiveResourceReader(
        archive,
        opfDir,
        obfuscatedResources: obfuscated,
        identifier: bundle.metadata.identifier,
      ),
      navigation: navigation,
      capabilities: capabilities,
      renditions: renditions,
    );
  }

  /// META-INF/encryption.xml을 파싱한다. 폰트 난독화 항목은 ZIP 루트 경로 →
  /// 알고리즘 맵으로 반환(투명 해제용). spine 콘텐츠 문서가 미지원 암호화로
  /// 보호되면 [EpubEncryptedUnsupported]를 던진다. (S13.5, gap #8)
  Map<String, String> _parseEncryption(
    Archive archive,
    String opfDir,
    Iterable<String> spineHrefs,
  ) {
    final xml = _readString(archive, 'META-INF/encryption.xml');
    if (xml == null) return const {};
    final entries = const EncryptionParser().parse(xml);
    if (entries.isEmpty) return const {};

    final spinePaths = {
      for (final href in spineHrefs) resolveHref(opfDir, href),
    };
    final obfuscated = <String, String>{};
    for (final e in entries) {
      if (e.isFontObfuscation) {
        obfuscated[e.uri] = e.algorithm;
      } else if (spinePaths.contains(e.uri)) {
        // 본문 문서가 미지원 암호화로 보호됨 → 렌더 불가.
        throw EpubEncryptedUnsupported(algorithm: e.algorithm, uri: e.uri);
      }
    }
    return obfuscated;
  }

  /// nav.xhtml(EPUB 3)에서 landmarks / page-list 보조 내비게이션을 추출한다.
  /// nav가 없거나(EPUB 2) 파싱 실패 시 [EpubNavigation.empty]. (S13.1, gap #2)
  EpubNavigation _parseNavigation(
    Archive archive,
    String opfDir,
    ({String? ncxHref, String? navHref}) tocRefs,
  ) {
    final navHref = tocRefs.navHref;
    if (navHref == null) return EpubNavigation.empty;
    final xml = _readString(archive, resolveHref(opfDir, navHref));
    if (xml == null) return EpubNavigation.empty;
    return _navParser.parseNavigation(xml);
  }

  /// nav.xhtml(EPUB 3) 우선, 없으면 NCX(EPUB 2). 파일이 없거나 파싱 실패 시
  /// [EpubOutline.empty] (목차 부재는 sparse-ncx/empty-toc 보정이 진단).
  ///
  /// nav 구조 결함(비표준 epub:type, 불완전 항목, span 헤더)을 복원하면 각각
  /// [patches]에 AppliedPatch로 기록한다. (S13.7, gap #10a)
  EpubOutline _parseOutline(
    Archive archive,
    String opfDir,
    ({String? ncxHref, String? navHref}) tocRefs,
    List<AppliedPatch> patches,
  ) {
    final navHref = tocRefs.navHref;
    if (navHref != null) {
      final xml = _readString(archive, resolveHref(opfDir, navHref));
      if (xml != null) {
        try {
          final result = _navParser.parseDiagnosed(xml);
          for (final defect in result.defects) {
            patches.add(_navDefectPatch(defect));
          }
          return result.outline;
        } on Object {
          // nav 파싱 실패 → NCX로 폴백 시도
        }
      }
    }

    final ncxHref = tocRefs.ncxHref;
    if (ncxHref != null) {
      final xml = _readString(archive, resolveHref(opfDir, ncxHref));
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

  /// nav 결함 코드 → AppliedPatch. (S13.7, gap #10a)
  AppliedPatch _navDefectPatch(String defect) {
    switch (defect) {
      case NavParseResult.nonstandardTocType:
        return const AppliedPatch(
          patchId: NavParseResult.nonstandardTocType,
          description:
              'nav.xhtml에 epub:type="toc"가 없어 첫 <nav>를 목차로 복원',
          severity: PatchSeverity.low,
        );
      case NavParseResult.incompleteEntries:
        return const AppliedPatch(
          patchId: NavParseResult.incompleteEntries,
          description: 'nav 목차의 불완전한 항목(빈 href/title)을 건너뜀',
          severity: PatchSeverity.low,
        );
      case NavParseResult.spanHeading:
        return const AppliedPatch(
          patchId: NavParseResult.spanHeading,
          description: '링크 없는 <span> 헤더 + 하위 목차를 섹션 그룹으로 복원',
          severity: PatchSeverity.low,
        );
      default:
        return AppliedPatch(
          patchId: defect,
          description: 'nav 구조 결함 복원',
          severity: PatchSeverity.low,
        );
    }
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
}
