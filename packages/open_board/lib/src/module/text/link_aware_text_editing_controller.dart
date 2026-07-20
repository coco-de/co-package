import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/text/text_span_builder.dart';

/// 편집 중에도 링크 구간을 커밋 후 렌더링([buildLinkAwareTextSpan])과 동일한
/// 스타일(파랑 + 밑줄)로 표시하는 [TextEditingController]. (kobic #8481)
///
/// 링크 span 데이터는 인라인 에디터 State 가 소유·갱신하므로, 이 컨트롤러는
/// [linkSpansProvider] 로 매 빌드 시점의 최신 목록을 조회만 한다. span offset
/// 이 일시적으로 텍스트 길이와 어긋나는 프레임(입력 직후 재배치 전)에도
/// 안전하도록 [sanitizeLinkSpans] 로 정규화 후 사용한다.
final class LinkAwareTextEditingController extends TextEditingController {
  LinkAwareTextEditingController({required this.linkSpansProvider});

  /// 현재 링크 span 목록 조회 콜백 (에디터 State 소유).
  final List<TextLinkSpan> Function() linkSpansProvider;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final composing = withComposing && value.isComposingRangeValid
        ? value.composing
        : null;
    final spans = sanitizeLinkSpans(linkSpansProvider(), text.length);
    if (spans.isEmpty && composing == null) {
      return TextSpan(text: text, style: style);
    }

    final linkStyle = (style ?? const TextStyle()).copyWith(
      color: kTextLinkColor,
      decoration: .underline,
    );
    final composingStyle = (style ?? const TextStyle()).copyWith(
      decoration: .underline,
    );

    // 링크 경계 + IME 조합 경계를 모두 절단점으로 삼아 구간별 스타일을 입힌다.
    final boundaries = <int>{0, text.length};
    for (final span in spans) {
      boundaries
        ..add(span.start)
        ..add(span.end);
    }
    if (composing != null) {
      boundaries
        ..add(composing.start.clamp(0, text.length))
        ..add(composing.end.clamp(0, text.length));
    }
    final cuts = boundaries.toList()..sort();

    final children = <TextSpan>[];
    for (var index = 0; index < cuts.length - 1; index++) {
      final start = cuts[index];
      final end = cuts[index + 1];
      if (end <= start) continue;

      final inLink = spans.any(
        (span) => start >= span.start && end <= span.end,
      );
      final inComposing =
          composing != null && start >= composing.start && end <= composing.end;

      // 링크 스타일이 이미 밑줄을 포함하므로 링크 ∩ 조합 구간도 linkStyle 로 충분.
      final TextStyle? segmentStyle;
      if (inLink) {
        segmentStyle = linkStyle;
      } else if (inComposing) {
        segmentStyle = composingStyle;
      } else {
        segmentStyle = null;
      }

      children.add(
        TextSpan(text: text.substring(start, end), style: segmentStyle),
      );
    }

    return TextSpan(style: style, children: children);
  }
}
