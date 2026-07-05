// Data Repository Impl — open_epub 1.0
// Story: S1.20 (#36), S1.21 (#37) — EPUB ZIP 해제 → 파서 연결 → EpubBook 조립
// Story: S9.6 (#70) — ZIP/XML 파싱 UI 스레드 블로킹 → isolate 오프로딩
//
// 책임: I/O(소스 읽기 + 보안 크기 검사) + ZIP 해제 + 파서(container/OPF/NCX/nav)
// 호출 + 도메인 EpubBook 조립까지. 호환성 보정(ApplyPatchesUseCase)은 상위
// UseCase가 수행한다(보정 전 raw EpubBook을 반환).

import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../api/epub_security_config.dart';
import '../../api/epub_source.dart';
import '../../domain/entity/epub_capabilities.dart';
import '../../domain/entity/epub_failure.dart';
import '../../domain/entity/epub_metadata.dart';
import '../../domain/entity/epub_navigation.dart';
import '../../domain/entity/epub_outline.dart';
import '../../domain/entity/epub_rendition.dart';
import '../../domain/entity/epub_spine_item.dart';
import '../../domain/repository/epub_repository.dart';
import '../compat/patch_catalog.dart'
    show AppliedPatch, PatchSeverity, PatchedEpubBook;
import '../parser/container_parser.dart';
import '../parser/nav_parser.dart';
import '../parser/ncx_parser.dart';
import '../parser/opf_parser.dart';
import '../security/encryption_parser.dart';
import 'archive_resource_reader.dart';

const String _containerPath = 'META-INF/container.xml';

/// isolate 오프로딩 기본 임계값 (1MiB). 이보다 작은 EPUB은 파싱 비용이 한
/// 프레임을 위협하지 않으므로 isolate spawn 오버헤드 없이 동기 파싱한다. (S9.6 #70)
const int _defaultIsolateThresholdBytes = 1024 * 1024;

class EpubRepositoryImpl implements EpubRepository {
  EpubRepositoryImpl({
    EpubSecurityConfig security = const EpubSecurityConfig(),
    ContainerParser containerParser = const ContainerParser(),
    OpfParser opfParser = const OpfParser(),
    NcxParser ncxParser = const NcxParser(),
    NavParser navParser = const NavParser(),
    int isolateThresholdBytes = _defaultIsolateThresholdBytes,
  })  : _security = security,
        _containerParser = containerParser,
        _opfParser = opfParser,
        _ncxParser = ncxParser,
        _navParser = navParser,
        _isolateThresholdBytes = isolateThresholdBytes;

  final EpubSecurityConfig _security;
  final ContainerParser _containerParser;
  final OpfParser _opfParser;
  final NcxParser _ncxParser;
  final NavParser _navParser;

  /// 이 크기(바이트) 이상의 EPUB만 파싱을 별도 isolate로 오프로딩한다. (S9.6 #70)
  final int _isolateThresholdBytes;

  @override
  Future<RawEpubLoad> load(EpubSource source) async {
    final bytes = await source.readBytes();

    if (bytes.length > _security.maxFileSizeBytes) {
      throw EpubFileTooLarge(
        actualBytes: bytes.length,
        limitBytes: _security.maxFileSizeBytes,
      );
    }

    // ZIP 디코드 + container/OPF/NCX/nav/encryption XML 파싱은 CPU 바운드지만
    // 전부 동기 코드라, 호출 isolate(통상 UI)를 대용량 EPUB에서 수백 ms~수 초
    // 블로킹해 프레임 드랍/ANR을 유발한다. 임계값 이상의 대용량 EPUB만 별도
    // isolate로 오프로딩한다(작은 책은 spawn 오버헤드가 오히려 손해). 파서는
    // 상태 없는 const 인스턴스라 isolate 경계를 넘길 수 있고, 반환 [_ParsedEpub]는
    // 전부 직렬화 가능한 도메인 객체다. (S9.6 #70)
    final containerParser = _containerParser;
    final opfParser = _opfParser;
    final ncxParser = _ncxParser;
    final navParser = _navParser;
    final _ParsedEpub parsed;
    try {
      parsed = bytes.length >= _isolateThresholdBytes
          ? await Isolate.run(
              () => _parseEpubDocuments(
                bytes,
                containerParser: containerParser,
                opfParser: opfParser,
                ncxParser: ncxParser,
                navParser: navParser,
              ),
            )
          : _parseEpubDocuments(
              bytes,
              containerParser: containerParser,
              opfParser: opfParser,
              ncxParser: ncxParser,
              navParser: navParser,
            );
    } on EpubCorrupted catch (e) {
      // isolate/동기 경로 공통 — source 식별자를 붙여 재던진다.
      throw EpubCorrupted('${e.message} (${source.debugIdentifier})');
    }

    // 리소스는 렌더 시점에 lazy 로드(+ LRU 캐시 상한)해야 하므로 Archive는 호출
    // isolate에서 재구성한다. decodeBytes는 중앙 디렉토리만 훑어 저렴하고, 실제
    // 압축 해제는 리소스 접근 시점까지 지연되므로 UI 블로킹 요인이 아니다.
    final archive = ZipDecoder().decodeBytes(bytes);

    return RawEpubLoad(
      book: PatchedEpubBook(
        metadata: parsed.metadata,
        spine: parsed.spine,
        outline: parsed.outline,
      ),
      patches: parsed.patches,
      resources: ArchiveResourceReader(
        archive,
        parsed.opfDir,
        obfuscatedResources: parsed.obfuscated,
        identifier: parsed.metadata.identifier,
      ),
      navigation: parsed.navigation,
      capabilities: parsed.capabilities,
      renditions: parsed.renditions,
    );
  }
}

/// [EpubRepositoryImpl.load]가 [Isolate.run]으로 실행하는 순수 CPU 파이프라인 —
/// ZIP 디코드 + container/OPF/NCX/nav/encryption 파싱. 인자·반환이 모두 직렬화
/// 가능해야 isolate 경계를 넘을 수 있다(Archive/리소스 reader는 lazy 읽기·메모리
/// 상한 유지를 위해 호출 isolate에서 재구성). (S9.6 #70)
_ParsedEpub _parseEpubDocuments(
  Uint8List bytes, {
  required ContainerParser containerParser,
  required OpfParser opfParser,
  required NcxParser ncxParser,
  required NavParser navParser,
}) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object catch (e) {
    throw EpubCorrupted('not a valid ZIP/EPUB container: $e');
  }

  final patches = <AppliedPatch>[];

  // raw-레벨 보정 1: mimetype 파일 검사 (ZIP 레벨 — EpubBook으론 감지 불가).
  final mimetype = _readArchiveString(archive, 'mimetype')?.trim();
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

  final containerXml = _readArchiveString(archive, _containerPath);
  if (containerXml == null) {
    throw EpubInvalidFile('missing $_containerPath');
  }
  final opfPath = containerParser.parse(containerXml);
  final renditions = containerParser.parseRootfiles(containerXml);

  final opfXml = _readArchiveString(archive, opfPath);
  if (opfXml == null) {
    throw EpubInvalidFile('missing OPF package at "$opfPath"');
  }
  // OPF XML은 한 번만 파싱한다 — parse/tocRefs/rawRenditionLayout/
  // parseCapabilities를 개별 호출하면 대형 manifest에서 파싱이 4중으로
  // 반복된다. (S9.5 #69)
  final bundle = opfParser.parseBundle(opfXml);
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
  final outline =
      _parseOutline(archive, opfDir, tocRefs, patches, navParser, ncxParser);
  final navigation = _parseNavigation(archive, opfDir, tocRefs, navParser);

  // encryption.xml — IDPF/Adobe 폰트 난독화는 투명 해제 맵으로, 콘텐츠(spine)에
  // 걸린 미지원 암호화(상업 DRM)는 EpubEncryptedUnsupported로. (S13.5, gap #8)
  final obfuscated = _parseEncryption(
    archive,
    opfDir,
    bundle.spine.map((s) => s.href),
  );

  return _ParsedEpub(
    metadata: bundle.metadata,
    spine: bundle.spine,
    outline: outline,
    navigation: navigation,
    capabilities: bundle.capabilities,
    patches: patches,
    renditions: renditions,
    obfuscated: obfuscated,
    opfDir: opfDir,
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
  final xml = _readArchiveString(archive, 'META-INF/encryption.xml');
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
  NavParser navParser,
) {
  final navHref = tocRefs.navHref;
  if (navHref == null) return EpubNavigation.empty;
  final xml = _readArchiveString(archive, resolveHref(opfDir, navHref));
  if (xml == null) return EpubNavigation.empty;
  return navParser.parseNavigation(xml);
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
  NavParser navParser,
  NcxParser ncxParser,
) {
  final navHref = tocRefs.navHref;
  if (navHref != null) {
    final xml = _readArchiveString(archive, resolveHref(opfDir, navHref));
    if (xml != null) {
      try {
        final result = navParser.parseDiagnosed(xml);
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
    final xml = _readArchiveString(archive, resolveHref(opfDir, ncxHref));
    if (xml != null) {
      try {
        return ncxParser.parse(xml);
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
        description: 'nav.xhtml에 epub:type="toc"가 없어 첫 <nav>를 목차로 복원',
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

String? _readArchiveString(Archive archive, String path) {
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

/// [_parseEpubDocuments]의 산출물 — isolate 경계를 넘는 직렬화 가능 도메인 묶음.
/// Archive/리소스 reader는 포함하지 않는다(호출 isolate에서 재구성). (S9.6 #70)
class _ParsedEpub {
  const _ParsedEpub({
    required this.metadata,
    required this.spine,
    required this.outline,
    required this.navigation,
    required this.capabilities,
    required this.patches,
    required this.renditions,
    required this.obfuscated,
    required this.opfDir,
  });

  final EpubMetadata metadata;
  final List<EpubSpineItem> spine;
  final EpubOutline outline;
  final EpubNavigation navigation;
  final BookCapabilities capabilities;
  final List<AppliedPatch> patches;
  final List<EpubRendition> renditions;
  final Map<String, String> obfuscated;
  final String opfDir;
}
