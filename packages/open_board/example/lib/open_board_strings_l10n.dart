import 'package:open_board/open_board.dart';

import 'i18n/strings.g.dart';

/// 현재 언어의 번역으로 open_board 패키지 문구 묶음을 만든다 — 링크 메뉴 ·
/// 링크 대화상자 · 도구 이름 · undo/redo/clear 툴팁.
OpenBoardStrings openBoardStringsOf(Translations t) => OpenBoardStrings(
  addLink: t.link.add,
  editLink: t.link.edit,
  removeLink: t.link.remove,
  done: t.link.done,
  linkDialogTitle: t.link.dialogTitle,
  externalLink: t.link.external,
  internalPage: t.link.internal,
  pageNumber: t.link.pageNumber,
  url: t.link.url,
  cancel: t.link.cancel,
  confirm: t.link.confirm,
  undo: t.common.undo,
  redo: t.common.redo,
  clear: t.common.clear,
  toolPen: t.tools.pen,
  toolPencil: t.tools.pencil,
  toolMarker: t.tools.marker,
  toolHighlighter: t.tools.highlighter,
  toolFixedPen: t.tools.fixedPen,
  toolUniformPen: t.tools.uniformPen,
  toolEraser: t.tools.eraser,
  toolText: t.tools.text,
  toolShape: t.tools.shape,
  toolLasso: t.tools.lasso,
  toolImage: t.tools.image,
);
