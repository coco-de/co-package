// Presentation Interop — open_epub 1.0
// Story: S7.4 (E7) — 선택 툴바 액션 1급 훅
//
// 선택 컨텍스트 메뉴에 하이라이트/사전/복사/TTS 같은 호스트 액션을 끼워넣기
// 위한 어댑터. 호스트는 SelectionArea(contextMenuBuilder:)에서 기본 항목과
// 합쳐 쓴다. kobic의 custom_text_selection_toolbar_wrapper에 대응.
//
// 좌표/선택 rect는 Flutter SelectionArea가 노출하지 않으므로(S7.1/S7.2 한계),
// 액션 콜백은 위치 정보 없이 호출된다 — 호스트는 selectionStream의
// EpubSelection(텍스트·offset)으로 컨텍스트를 얻는다.

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
