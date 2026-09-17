// Domain Entity — open_epub 1.0
// Story: S1.5-1 (E1.5) — EpubSelection (선택 영역 locator)
//
// 시각 선택(SelectionArea)을 spine 내부의 안정 위치로 표현한다. 오프셋은
// "body 텍스트 노드를 순서대로 이은 평문"(SpineTextExtractor.extractPlainText)
// 기준 char index다. 글자 크기·줄간격이 바뀌어도 이 오프셋은 불변이므로,
// 선택으로 만든 하이라이트가 repagination을 가로질러 보존된다.
//
// kobic PDF 마커의 textRanges(startIndex/endIndex)와 동일한 모델.

import '../../api/epub_position.dart';

/// spine 내 텍스트 선택 영역. [start] 포함, [end] 제외(half-open).
class EpubSelection {
  EpubSelection({
    required this.spineHref,
    required this.start,
    required this.end,
    required this.selectedText,
  })  : assert(start >= 0, 'start must be non-negative'),
        assert(end >= start, 'end must be >= start');

  final String spineHref;

  /// 평문 오프셋 공간에서의 시작 index(포함).
  final int start;

  /// 평문 오프셋 공간에서의 끝 index(제외).
  final int end;

  /// 선택된 텍스트 원문.
  final String selectedText;

  /// 선택 길이(문자 수).
  int get length => end - start;

  bool get isCollapsed => end == start;

  /// 선택 시작 지점을 [EpubReflowablePosition]으로 변환한다(점프/진도용).
  EpubReflowablePosition toStartPosition({double progress = 0.0}) =>
      EpubReflowablePosition(
        spineHref: spineHref,
        progress: progress,
        charOffset: start,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpubSelection &&
          runtimeType == other.runtimeType &&
          spineHref == other.spineHref &&
          start == other.start &&
          end == other.end &&
          selectedText == other.selectedText;

  @override
  int get hashCode => Object.hash(spineHref, start, end, selectedText);

  @override
  String toString() =>
      'EpubSelection(s=$spineHref, [$start,$end), "${_preview(selectedText)}")';

  static String _preview(String text) =>
      text.length <= 24 ? text : '${text.substring(0, 24)}…';
}
