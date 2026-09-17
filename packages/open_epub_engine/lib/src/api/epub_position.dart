// Public API — open_epub 1.0
// Story: S1.10 (#16) — BookPosition v1 codec
// Story: S1.11 (#17) — Reflowable locator
// Story: S1.12 (#18) — Fixed locator
//
// ADR-001: 자체 canonical 포맷 (CFI 미채택). JSON ≤ 512 bytes,
// encode→decode round-trip 무손실.
//
// Token 스키마 v1:
//   { "v":1, "t":"r", "s":"ch01.xhtml", "p":0.45, "c":512, "x":7, "a":-1.35 }
//                "f"                              "i":3
//   v: schema version (현재 1)
//   t: "r" Reflowable | "f" FixedLayout
//   s: spineHref
//   p: progress 0.0~1.0
//   c: charOffset (Reflowable, 필수)
//   x: pageIndex hint (Reflowable, optional) — paged/윈도잉 모드의 화면 단위 윈도우 인덱스
//   a: scrollAlignment hint (Reflowable, optional) — 스크롤 모드의 챕터 내부 위치.
//      scrollable_positioned_list의 ItemPosition.itemLeadingEdge와 동일 좌표계
//      (뷰포트 높이 단위, 0=챕터 상단이 뷰포트 상단, 음수=그만큼 스크롤해 들어간 상태).
//      additive 필드 — 없는 기존 v1 토큰도 그대로 디코드된다(하위 호환).
//   i: pageIndex (Fixed, 필수)

import 'dart:convert';

/// BookPosition v1 — Reflowable 또는 Fixed Layout 위치 표현. sealed class.
sealed class EpubPosition {
  const EpubPosition({required this.spineHref, required this.progress})
      : assert(progress >= 0.0 && progress <= 1.0, 'progress must be 0.0..1.0');

  final String spineHref;
  final double progress;

  /// 현재 schema 버전.
  static const int schemaVersion = 1;

  /// 토큰의 최대 크기 (UTF-8 bytes). ADR-001.
  static const int maxTokenBytes = 512;

  Map<String, dynamic> toJson();

  /// JSON 토큰으로 직렬화. 결과가 [maxTokenBytes]를 초과하면 [EpubPositionTooLargeException].
  String toToken() {
    final token = jsonEncode(toJson());
    if (utf8.encode(token).length > maxTokenBytes) {
      throw EpubPositionTooLargeException(
          actualBytes: utf8.encode(token).length);
    }
    return token;
  }

  /// 토큰 문자열에서 [EpubPosition]을 복원한다.
  ///
  /// 잘못된 JSON, 미지원 버전, schema 불일치 시 [EpubPositionDecodeException].
  static EpubPosition fromToken(String token) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(token);
    } on FormatException catch (e) {
      throw EpubPositionDecodeException('invalid JSON: $e');
    }
    if (decoded is! Map<String, dynamic>) {
      throw EpubPositionDecodeException('token root must be a JSON object');
    }

    final v = decoded['v'];
    if (v != schemaVersion) {
      throw EpubPositionDecodeException(
        'unsupported schema version $v (expected $schemaVersion)',
      );
    }

    final t = decoded['t'];
    final s = decoded['s'];
    final p = decoded['p'];
    if (s is! String || s.isEmpty) {
      throw EpubPositionDecodeException('missing or invalid "s" (spineHref)');
    }
    if (p is! num || p < 0.0 || p > 1.0) {
      throw EpubPositionDecodeException(
          '"p" (progress) must be a number in [0,1]');
    }

    switch (t) {
      case 'r':
        final c = decoded['c'];
        if (c is! int || c < 0) {
          throw EpubPositionDecodeException(
              '"c" (charOffset) must be non-negative int');
        }
        final x = decoded['x'];
        if (x != null && (x is! int || x < 0)) {
          throw EpubPositionDecodeException(
              '"x" (pageIndex) must be non-negative int when present');
        }
        final a = decoded['a'];
        if (a != null && (a is! num || !a.isFinite)) {
          throw EpubPositionDecodeException(
              '"a" (scrollAlignment) must be a finite number when present');
        }
        return EpubReflowablePosition(
          spineHref: s,
          progress: p.toDouble(),
          charOffset: c,
          pageIndex: x as int?,
          scrollAlignment: (a as num?)?.toDouble(),
        );

      case 'f':
        final i = decoded['i'];
        if (i is! int || i < 0) {
          throw EpubPositionDecodeException(
              '"i" (pageIndex) must be non-negative int');
        }
        return EpubFixedPosition(
          spineHref: s,
          progress: p.toDouble(),
          pageIndex: i,
        );

      default:
        throw EpubPositionDecodeException('unsupported "t" value: $t');
    }
  }
}

/// Reflowable EPUB 위치: spineHref + charOffset + (optional pageIndex/scrollAlignment).
///
/// 글자 크기·줄간격이 바뀌어도 charOffset은 보존된다 (S1.11 책임).
/// pageIndex는 viewport 변경 시 무효화 가능한 hint(paged/윈도잉 모드 전용).
/// scrollAlignment는 스크롤 모드의 챕터 내부 위치 hint — 저장 시점과 동일한
/// 뷰포트 크기·폰트 크기를 전제로 한 근사 복원이며, 크게 달라지면 부정확할 수
/// 있다(둘 다 viewport 변경 시 무효화 가능한 hint라는 점은 동일).
class EpubReflowablePosition extends EpubPosition {
  const EpubReflowablePosition({
    required super.spineHref,
    required super.progress,
    required this.charOffset,
    this.pageIndex,
    this.scrollAlignment,
  })  : assert(charOffset >= 0, 'charOffset must be non-negative'),
        assert(pageIndex == null || pageIndex >= 0,
            'pageIndex must be non-negative'),
        assert(
          scrollAlignment == null ||
              (scrollAlignment > double.negativeInfinity &&
                  scrollAlignment < double.infinity),
          'scrollAlignment must be finite',
        );

  final int charOffset;
  final int? pageIndex;

  /// 스크롤 모드 챕터 내부 위치 — [scrollable_positioned_list]
  /// `ItemPosition.itemLeadingEdge`와 동일 좌표계(뷰포트 높이 단위).
  final double? scrollAlignment;

  @override
  Map<String, dynamic> toJson() => {
        'v': EpubPosition.schemaVersion,
        't': 'r',
        's': spineHref,
        'p': progress,
        'c': charOffset,
        if (pageIndex != null) 'x': pageIndex,
        if (scrollAlignment != null) 'a': scrollAlignment,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpubReflowablePosition &&
          runtimeType == other.runtimeType &&
          spineHref == other.spineHref &&
          progress == other.progress &&
          charOffset == other.charOffset &&
          pageIndex == other.pageIndex &&
          scrollAlignment == other.scrollAlignment;

  @override
  int get hashCode =>
      Object.hash(spineHref, progress, charOffset, pageIndex, scrollAlignment);

  @override
  String toString() =>
      'EpubReflowablePosition(s=$spineHref, p=$progress, c=$charOffset, '
      'x=$pageIndex, a=$scrollAlignment)';
}

/// Fixed Layout EPUB 위치: spineHref + pageIndex. (S1.12 책임)
class EpubFixedPosition extends EpubPosition {
  const EpubFixedPosition({
    required super.spineHref,
    required super.progress,
    required this.pageIndex,
  }) : assert(pageIndex >= 0, 'pageIndex must be non-negative');

  final int pageIndex;

  @override
  Map<String, dynamic> toJson() => {
        'v': EpubPosition.schemaVersion,
        't': 'f',
        's': spineHref,
        'p': progress,
        'i': pageIndex,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpubFixedPosition &&
          runtimeType == other.runtimeType &&
          spineHref == other.spineHref &&
          progress == other.progress &&
          pageIndex == other.pageIndex;

  @override
  int get hashCode => Object.hash(spineHref, progress, pageIndex);

  @override
  String toString() =>
      'EpubFixedPosition(s=$spineHref, p=$progress, i=$pageIndex)';
}

class EpubPositionTooLargeException implements Exception {
  EpubPositionTooLargeException({required this.actualBytes});
  final int actualBytes;
  @override
  String toString() =>
      'EpubPositionTooLargeException: token is $actualBytes bytes '
      '(max ${EpubPosition.maxTokenBytes})';
}

class EpubPositionDecodeException implements Exception {
  EpubPositionDecodeException(this.reason);
  final String reason;
  @override
  String toString() => 'EpubPositionDecodeException: $reason';
}
