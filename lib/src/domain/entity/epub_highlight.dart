// Domain Entity — open_epub 1.0
// Story: S1.5-4 (E1.5) — in-core 하이라이트 모델
//
// 코어가 직접 보유·렌더하는 하이라이트. example 데모의 host-소유
// DemoHighlight(평문 첫 일치 앵커)를 대체한다. 오프셋은 EpubSelection과 같은
// "body 텍스트 노드 평문" 공간이라 글자 크기 변경에도 안정적이다.
//
// 영속(Serverpod/Drift/shared_preferences)은 소비자 책임이므로 toJson/fromJson
// 만 제공하고 저장소는 코어에 두지 않는다(E3 범위).

import 'epub_selection.dart';

/// 하이라이트 1건 — 위치(spineHref + start/end) + 색 + 메모.
class EpubHighlight {
  const EpubHighlight({
    required this.id,
    required this.spineHref,
    required this.start,
    required this.end,
    required this.selectedText,
    required this.colorArgb,
    this.note = '',
  })  : assert(start >= 0, 'start must be non-negative'),
        assert(end >= start, 'end must be >= start');

  /// [EpubSelection]으로부터 하이라이트를 만든다.
  factory EpubHighlight.fromSelection(
    EpubSelection selection, {
    required String id,
    required int colorArgb,
    String note = '',
  }) =>
      EpubHighlight(
        id: id,
        spineHref: selection.spineHref,
        start: selection.start,
        end: selection.end,
        selectedText: selection.selectedText,
        colorArgb: colorArgb,
        note: note,
      );

  factory EpubHighlight.fromJson(Map<String, dynamic> json) => EpubHighlight(
        id: json['id'] as String,
        spineHref: json['spineHref'] as String,
        start: (json['start'] as num).toInt(),
        end: (json['end'] as num).toInt(),
        selectedText: json['selectedText'] as String,
        colorArgb: (json['colorArgb'] as num).toInt(),
        note: (json['note'] as String?) ?? '',
      );

  final String id;
  final String spineHref;
  final int start;
  final int end;
  final String selectedText;

  /// 배경색 ARGB 32-bit(예: 0xFFFFF59D). 렌더 시 RGB만 사용.
  final int colorArgb;
  final String note;

  EpubHighlight copyWith({int? colorArgb, String? note}) => EpubHighlight(
        id: id,
        spineHref: spineHref,
        start: start,
        end: end,
        selectedText: selectedText,
        colorArgb: colorArgb ?? this.colorArgb,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'spineHref': spineHref,
        'start': start,
        'end': end,
        'selectedText': selectedText,
        'colorArgb': colorArgb,
        'note': note,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpubHighlight &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          spineHref == other.spineHref &&
          start == other.start &&
          end == other.end &&
          selectedText == other.selectedText &&
          colorArgb == other.colorArgb &&
          note == other.note;

  @override
  int get hashCode =>
      Object.hash(id, spineHref, start, end, selectedText, colorArgb, note);

  @override
  String toString() =>
      'EpubHighlight($id, s=$spineHref, [$start,$end), color=${colorArgb.toRadixString(16)})';
}
