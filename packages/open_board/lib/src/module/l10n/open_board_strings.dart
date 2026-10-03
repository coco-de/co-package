import 'package:flutter/foundation.dart';
import 'package:open_board/src/module/state/drawing_state.dart';

/// 🌐 open_board 가 직접 그리는 문구 묶음.
///
/// 인라인 텍스트 에디터(링크 메뉴 · 완료 버튼) · 링크 입력 대화상자 ·
/// [ScribbleFloatingToolbar] 의 도구 이름과 툴팁이 여기서 나온다. 기본값은
/// open_board 가 지금까지 보여 주던 글 그대로다 — 문구 묶음을 넣지 않은
/// 사용처는 화면이 달라지지 않는다.
///
/// 앱이 번역을 넣으려면 바꿀 값만 지정해 [OpenBoardStringsScope] 로 감싼다.
/// 에디터와 대화상자는 Overlay · 새 라우트에 뜨므로 `MaterialApp.builder` 처럼
/// Navigator 위에 두는 것이 가장 단순하다(필기 위젯 위 어디에 두어도 에디터에는
/// 전달된다).
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => OpenBoardStringsScope(
///     strings: const OpenBoardStrings(addLink: 'Add link', cancel: 'Cancel'),
///     child: child!,
///   ),
/// )
/// ```
@immutable
class OpenBoardStrings {
  /// 바꿀 문구만 지정한다. 지정하지 않은 문구는 기본값(현재 글)을 쓴다.
  const OpenBoardStrings({
    this.addLink = '링크 추가',
    this.editLink = '링크 편집',
    this.removeLink = '링크 삭제',
    this.done = '완료',
    this.linkDialogTitle = '링크 입력',
    this.externalLink = '외부 URL',
    this.internalPage = '내부 페이지',
    this.pageNumber = '페이지 번호',
    this.url = 'URL',
    this.cancel = '취소',
    this.confirm = '확인',
    this.undo = 'Undo',
    this.redo = 'Redo',
    this.clear = 'Clear',
    this.toolPen = 'Pen',
    this.toolPencil = 'Pencil',
    this.toolMarker = 'Marker',
    this.toolHighlighter = 'Highlighter',
    this.toolFixedPen = 'Fixed',
    this.toolUniformPen = 'Uniform',
    this.toolEraser = 'Eraser',
    this.toolText = 'Text',
    this.toolShape = 'Shape',
    this.toolLasso = 'Lasso',
    this.toolImage = 'Image',
  });

  /// 텍스트 편집 컨텍스트 메뉴 — 링크가 없을 때. 기본값 `링크 추가`.
  final String addLink;

  /// 텍스트 편집 컨텍스트 메뉴 — 링크가 있을 때. 기본값 `링크 편집`.
  final String editLink;

  /// 텍스트 편집 컨텍스트 메뉴 — 링크 제거. 기본값 `링크 삭제`.
  final String removeLink;

  /// 인라인 텍스트 에디터의 편집 완료 버튼. 기본값 `완료`.
  final String done;

  /// 링크 입력 대화상자 제목. 기본값 `링크 입력`.
  final String linkDialogTitle;

  /// 링크 입력 대화상자 — 외부 URL 탭. 기본값 `외부 URL`.
  final String externalLink;

  /// 링크 입력 대화상자 — 내부 페이지 탭. 기본값 `내부 페이지`.
  final String internalPage;

  /// 링크 입력 대화상자 — 페이지 번호 입력란 라벨. 기본값 `페이지 번호`.
  final String pageNumber;

  /// 링크 입력 대화상자 — URL 입력란 라벨. 기본값 `URL`.
  final String url;

  /// 링크 입력 대화상자 — 취소 버튼. 기본값 `취소`.
  final String cancel;

  /// 링크 입력 대화상자 — 확인 버튼. 기본값 `확인`.
  final String confirm;

  /// 플로팅 도구 패널 — 실행 취소 툴팁. 기본값 `Undo`.
  final String undo;

  /// 플로팅 도구 패널 — 다시 실행 툴팁. 기본값 `Redo`.
  final String redo;

  /// 플로팅 도구 패널 — 지우기 툴팁. 기본값 `Clear`.
  final String clear;

  /// [DrawingTool.pen] 이름. 기본값 `Pen`.
  final String toolPen;

  /// [DrawingTool.pencil] 이름. 기본값 `Pencil`.
  final String toolPencil;

  /// [DrawingTool.marker] 이름. 기본값 `Marker`.
  final String toolMarker;

  /// [DrawingTool.highlighter] 이름. 기본값 `Highlighter`.
  final String toolHighlighter;

  /// [DrawingTool.fixedPen] 이름. 기본값 `Fixed`.
  final String toolFixedPen;

  /// [DrawingTool.uniformPen] 이름. 기본값 `Uniform`.
  final String toolUniformPen;

  /// [DrawingTool.erase] 이름. 기본값 `Eraser`.
  final String toolEraser;

  /// [DrawingTool.text] 이름. 기본값 `Text`.
  final String toolText;

  /// [DrawingTool.shape] 이름. 기본값 `Shape`.
  final String toolShape;

  /// [DrawingTool.lasso] 이름. 기본값 `Lasso`.
  final String toolLasso;

  /// [DrawingTool.image] 이름. 기본값 `Image`.
  final String toolImage;

  /// [tool] 의 표시 이름.
  String toolLabel(DrawingTool tool) => switch (tool) {
    DrawingTool.pen => toolPen,
    DrawingTool.pencil => toolPencil,
    DrawingTool.marker => toolMarker,
    DrawingTool.highlighter => toolHighlighter,
    DrawingTool.fixedPen => toolFixedPen,
    DrawingTool.uniformPen => toolUniformPen,
    DrawingTool.erase => toolEraser,
    DrawingTool.text => toolText,
    DrawingTool.shape => toolShape,
    DrawingTool.lasso => toolLasso,
    DrawingTool.image => toolImage,
  };

  List<String> get _values => [
    addLink,
    editLink,
    removeLink,
    done,
    linkDialogTitle,
    externalLink,
    internalPage,
    pageNumber,
    url,
    cancel,
    confirm,
    undo,
    redo,
    clear,
    toolPen,
    toolPencil,
    toolMarker,
    toolHighlighter,
    toolFixedPen,
    toolUniformPen,
    toolEraser,
    toolText,
    toolShape,
    toolLasso,
    toolImage,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenBoardStrings && listEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values);
}
