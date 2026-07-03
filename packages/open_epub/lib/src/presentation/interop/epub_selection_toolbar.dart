// Presentation Interop — open_epub 1.0
// Story: S7.4 (E7) — 선택 툴바 액션 1급 훅
//
// 선택 컨텍스트 메뉴에 하이라이트/사전/복사/TTS 같은 호스트 액션을 끼워넣기
// 위한 어댑터. 호스트는 SelectionArea(contextMenuBuilder:)에서 기본 항목과
// 합쳐 쓴다. kobic의 custom_text_selection_toolbar_wrapper에 대응.
//
// 선택 앵커 좌표(S7.1/S7.2): contextMenuBuilder가 받는 SelectableRegionState의
// `contextMenuAnchors`(primary/secondary Offset)가 곧 선택 영역의 앵커
// 글로벌 좌표다 — 사전 풍선·커스텀 툴바 위치 잡기에 그대로 쓴다. 즉 "선택
// 앵커"는 Flutter가 이미 제공하므로 open_epub이 따로 노출할 것이 없다.
//
// 남은 한계: 임의의 저장된 offset(현재 선택이 아닌)에 대한 문자별 rect 매핑은
// flutter_html이 RichText 레이아웃 박스를 공개 API로 노출하지 않아 불가하다.
// pdfrx의 charRects 등가물이 필요하면 커스텀 RichText 렌더러를 도입해야
// 한다(별도 과제). 액션 콜백 자체는 위치 정보 없이 호출되며, 호스트는
// selectionStream의 EpubSelection(텍스트·offset)으로 컨텍스트를 얻는다.

import 'package:flutter/widgets.dart';

/// 선택 메뉴 액션 1건.
class EpubSelectionAction {
  const EpubSelectionAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// [actions]를 [ContextMenuButtonItem] 목록으로 변환한다.
///
/// 사용 예:
/// ```dart
/// SelectionArea(
///   contextMenuBuilder: (context, state) => AdaptiveTextSelectionToolbar.buttonItems(
///     anchors: state.contextMenuAnchors,
///     buttonItems: [
///       ...state.contextMenuButtonItems, // 기본 복사/전체선택
///       ...epubSelectionButtonItems([
///         EpubSelectionAction(label: '하이라이트', onPressed: ...),
///       ]),
///     ],
///   ),
///   child: reader,
/// )
/// ```
List<ContextMenuButtonItem> epubSelectionButtonItems(
  List<EpubSelectionAction> actions,
) =>
    [
      for (final action in actions)
        ContextMenuButtonItem(onPressed: action.onPressed, label: action.label),
    ];
