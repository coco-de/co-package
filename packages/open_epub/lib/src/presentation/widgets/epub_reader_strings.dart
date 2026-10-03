import 'package:flutter/foundation.dart';

/// 리더가 직접 그리는 문구 묶음 — 책을 열 수 없을 때의 오류 화면, 위치 복원
/// 실패 배너, 빈 책 · 빈 페이지 · 본문 로드 실패 안내, 수식 대체 라벨.
///
/// 기본값은 open_epub 가 지금까지 보여 주던 글 그대로다 — 문구 묶음을 넣지
/// 않은 사용처는 화면이 달라지지 않는다. 앱이 번역을 넣으려면 바꿀 값만
/// 지정해 [EpubReader.strings] 로 넘기거나 [EpubReaderStringsScope] 로 감싼다.
///
/// ```dart
/// EpubReader(
///   source: source,
///   strings: const EpubReaderStrings(
///     openFailed: 'Could not open this book.',
///     corruptedFile: 'This EPUB is damaged or not valid.',
///   ),
/// )
/// ```
@immutable
class EpubReaderStrings {
  /// 바꿀 문구만 지정한다. 지정하지 않은 문구는 기본값(현재 글)을 쓴다.
  const EpubReaderStrings({
    this.fileTooLarge = '파일이 너무 커서 열 수 없습니다.',
    this.networkFailure = '네트워크 오류로 책을 가져오지 못했습니다.',
    this.corruptedFile = '손상되었거나 올바르지 않은 EPUB입니다.',
    this.openFailed = '책을 여는 중 오류가 발생했습니다.',
    this.positionRestoreFailed = '마지막 위치를 찾을 수 없어 처음부터 표시합니다',
    this.emptyBook = '이 책에는 표시할 내용이 없습니다.',
    this.emptyPage = '이 페이지에는 표시할 내용이 없습니다.',
    this.chapterLoadFailed = '본문을 불러올 수 없습니다.',
    this.pageLoadFailed = '페이지를 불러올 수 없습니다.',
    this.formula = '수식',
  });

  /// 오류 화면 — 파일이 크기 상한을 넘을 때.
  final String fileTooLarge;

  /// 오류 화면 — 네트워크 소스를 가져오지 못했을 때.
  final String networkFailure;

  /// 오류 화면 — 손상되었거나 EPUB 이 아닐 때.
  final String corruptedFile;

  /// 오류 화면 — 그 밖의 이유로 열지 못했을 때.
  final String openFailed;

  /// 저장된 위치를 찾지 못해 처음부터 보여 줄 때의 안내 배너.
  final String positionRestoreFailed;

  /// 표시할 spine 이 하나도 없는 책.
  final String emptyBook;

  /// 렌더할 콘텐츠가 없는 페이지(spine).
  final String emptyPage;

  /// 리플로우 본문(XHTML)을 불러오지 못했을 때. 아래 줄에 원인이 붙는다.
  final String chapterLoadFailed;

  /// 고정 레이아웃 페이지를 불러오지 못했을 때. 아래 줄에 원인이 붙는다.
  final String pageLoadFailed;

  /// alttext 가 없는 수식(MathML)의 대체 라벨.
  final String formula;

  List<String> get _values => [
        fileTooLarge,
        networkFailure,
        corruptedFile,
        openFailed,
        positionRestoreFailed,
        emptyBook,
        emptyPage,
        chapterLoadFailed,
        pageLoadFailed,
        formula,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpubReaderStrings && listEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values);
}
