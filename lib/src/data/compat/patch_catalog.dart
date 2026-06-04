// Data Compat — open_epub 1.0
// Story: S1.14 — PatchCatalog 인프라 + 진단 집계
// BDD: F9 (보정 카탈로그 + 진단)
// RFC-8 (tech-spec §9): 보정 카탈로그 + BookSessionDiagnostics
//
// 개별 patch의 적용 로직은 S1.15~S1.18에서 구현한다. 본 스토리는 보정 계약
// (EpubPatch.apply), 카탈로그 등록부, 순회 결과 집계(diagnostics), 그리고
// 부분 변형용 concrete EpubBook(PatchedEpubBook)을 제공한다.

import 'dart:convert';

import '../../api/epub_book.dart';
import '../../domain/entity/epub_metadata.dart';
import '../../domain/entity/epub_outline.dart';
import '../../domain/entity/epub_spine_item.dart';
import 'patches/broken_spine_href.dart';
import 'patches/cover_skip.dart';
import 'patches/empty_toc.dart';
import 'patches/mixed_href_encoding.dart';
import 'patches/sparse_ncx.dart';

// 개별 patch가 apply(EpubBook)을 구현할 수 있도록 EpubBook을 re-export.
export '../../api/epub_book.dart' show EpubBook, EpubLayout;

/// 보정의 영향도. RFC-8 §9.2 / BDD F9.
enum PatchSeverity { info, low, medium, high }

/// 단일 EPUB 호환성 보정 — 메타데이터 + 적용 로직.
///
/// OCP — 새 보정은 [PatchCatalog]에 추가만 하고 기존 코드는 수정하지 않는다.
abstract class EpubPatch {
  String get patchId;
  String get description;
  PatchSeverity get severity;

  /// [book]이 이 보정의 트리거 조건에 해당하면 변형 결과([PatchResult])를,
  /// 아니면 null을 반환한다. (감지 + 변형을 한 번에 수행)
  PatchResult? apply(EpubBook book);
}

/// 보정 적용 결과 — 변형된 book + 영향 설명(impact).
class PatchResult {
  const PatchResult({
    required this.book,
    this.impact = const <String, Object?>{},
  });

  final EpubBook book;
  final Map<String, Object?> impact;
}

/// 보정 가능한 모든 patch의 등록부. EpubBook(메타/spine/목차) 입력으로 감지·변형
/// 가능한 보정만 포함한다.
///
/// 카탈로그에 포함하지 않는 보정:
/// - `image-only-fxl`: DetectTextLayerUseCase(S1.13)가 텍스트 레이어 부재로 판정.
/// - `missing-mimetype` / `invalid-rendition-layout`: ZIP/OPF raw 컨텍스트가
///   필요하므로 EpubRepositoryImpl이 조립 시 진단을 직접 기록한다(S1.18 #34).
class PatchCatalog {
  const PatchCatalog();

  List<EpubPatch> get all => const [
        SparseNcxPatch(),
        CoverSkipPatch(),
        BrokenSpineHrefPatch(),
        MixedHrefEncodingPatch(),
        EmptyTocPatch(),
      ];
}

/// 적용된 보정 1건의 진단 기록. (BDD F9 — 진단 패널 카드)
class AppliedPatch {
  const AppliedPatch({
    required this.patchId,
    required this.description,
    required this.severity,
    this.impact = const <String, Object?>{},
  });

  final String patchId;
  final String description;
  final PatchSeverity severity;

  /// 사람이 읽는 영향 정보 (예: `{'removed': 2, 'href': '...'}`)
  final Map<String, Object?> impact;

  Map<String, Object?> toJson() => {
        'patchId': patchId,
        'description': description,
        'severity': severity.name,
        'impact': impact,
      };
}

/// 보정으로 해결되지 못한 이슈. (예: 보안 경고 — BDD epub_security)
class UnresolvedIssue {
  const UnresolvedIssue({required this.code, required this.message});

  final String code;
  final String message;

  Map<String, Object?> toJson() => {'code': code, 'message': message};
}

/// 책 1권의 보정/이슈 진단 결과. 운영자 진단 패널·JSON 내보내기의 소스.
abstract class BookSessionDiagnostics {
  List<AppliedPatch> get appliedPatches;
  List<UnresolvedIssue> get unresolvedIssues;

  /// 진단 결과 JSON (BDD F9 — 클립보드 복사).
  String toJson();
}

/// [BookSessionDiagnostics]의 불변 구현.
class BookSessionDiagnosticsData implements BookSessionDiagnostics {
  const BookSessionDiagnosticsData({
    this.appliedPatches = const [],
    this.unresolvedIssues = const [],
  });

  @override
  final List<AppliedPatch> appliedPatches;
  @override
  final List<UnresolvedIssue> unresolvedIssues;

  /// 보정·미해결 이슈가 전혀 없는 정상 EPUB.
  bool get isClean => appliedPatches.isEmpty && unresolvedIssues.isEmpty;

  @override
  String toJson() => jsonEncode({
        'appliedPatches': appliedPatches.map((p) => p.toJson()).toList(),
        'unresolvedIssues': unresolvedIssues.map((i) => i.toJson()).toList(),
      });
}

/// 보정 적용에 사용하는 concrete [EpubBook].
///
/// 부분 변형([copyWith])을 지원하여 각 patch가 spine/outline/metadata 중
/// 일부만 교체할 수 있게 한다. (S1.20 EpubRepositoryImpl에서도 재사용 가능)
class PatchedEpubBook implements EpubBook {
  const PatchedEpubBook({
    required this.metadata,
    required this.spine,
    required this.outline,
  });

  factory PatchedEpubBook.from(EpubBook book) => PatchedEpubBook(
        metadata: book.metadata,
        spine: book.spine,
        outline: book.outline,
      );

  @override
  final EpubMetadata metadata;
  @override
  final List<EpubSpineItem> spine;
  @override
  final EpubOutline outline;

  @override
  EpubLayout get layout => metadata.layout;

  PatchedEpubBook copyWith({
    EpubMetadata? metadata,
    List<EpubSpineItem>? spine,
    EpubOutline? outline,
  }) =>
      PatchedEpubBook(
        metadata: metadata ?? this.metadata,
        spine: spine ?? this.spine,
        outline: outline ?? this.outline,
      );
}
