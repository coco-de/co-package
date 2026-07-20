import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/link_aware_text_editing_controller.dart';
import 'package:open_board/src/module/text/link_span_offsets.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/text/text_span_builder.dart';

/// 터치한 위치에 나타나는 인라인 텍스트 에디터
final class InlineTextEditor extends StatefulWidget {
  const InlineTextEditor({
    required this.drawable,
    required this.position,
    required this.textSettings,
    required this.onComplete,
    required this.isNew,
    required this.scale,
    required this.selectedColor,
    super.key,
  });

  /// 편집할 텍스트 drawable
  final TextDrawable drawable;

  /// 에디터가 나타날 위치
  final Offset position;

  /// 텍스트 설정
  final TextSettings textSettings;

  /// 편집 완료 콜백
  final void Function(TextDrawable? drawable) onComplete;

  /// 새 텍스트인지 여부
  final bool isNew;

  /// 현재 스케일 (확대/축소)
  final double scale;

  /// 선택된 텍스트 컬러
  final Color selectedColor;

  @override
  State<InlineTextEditor> createState() => _InlineTextEditorState();
}

final class _InlineTextEditorState extends State<InlineTextEditor>
    with WidgetsBindingObserver {
  late LinkAwareTextEditingController textEditingController;
  late FocusNode textFieldNode;
  double bottomViewInsets = 0;
  bool disposed = false;
  bool _isCompleting = false; // 편집 완료 중인지 추적 (중복 호출 방지)

  /// 편집 중 유지되는 인라인 링크 span (커밋 시 drawable 에 기록).
  late List<TextLinkSpan> _linkSpans;

  /// offset shift 계산을 위한 직전 텍스트 스냅샷.
  late String _previousText;

  /// 링크 입력 다이얼로그 표시 중 포커스 손실에 의한 조기 완료를 막는 플래그.
  bool _suppressComplete = false;

  static TextLinkSpan _cloneSpan(TextLinkSpan span) => TextLinkSpan()
    ..start = span.start
    ..end = span.end
    ..url = span.url;

  @override
  void initState() {
    super.initState();

    // 포커스 노드 초기화
    textFieldNode = FocusNode();
    textFieldNode.addListener(focusListener);

    // 링크 span 초기화 (기존 텍스트 재편집 시 복원)
    // 컨트롤러의 linkSpansProvider 가 참조하므로 컨트롤러 생성보다 먼저 초기화.
    _linkSpans = widget.drawable.linkSpans.map(_cloneSpan).toList();

    // 텍스트 컨트롤러 초기화 — 편집 중에도 링크 구간을 파랑+밑줄로 표시
    // (커밋 후 렌더링과 동일한 시각 규약, kobic #8481)
    textEditingController = LinkAwareTextEditingController(
      linkSpansProvider: () => _linkSpans,
    );
    _previousText = widget.drawable.text;

    // 텍스트 설정 (리스너 부착 전에 설정해 초기 spurious 콜백 방지)
    textEditingController.text = widget.drawable.text;

    // 텍스트 변경 시 링크 span offset 재배치 + 크기 재계산
    textEditingController.addListener(_onControllerChanged);

    // 첫 프레임 렌더링 후 포커스 요청
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted && !disposed) {
        textFieldNode.requestFocus();
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  /// 현재 날짜를 yyyy-mm-dd 형식으로 텍스트 필드에 삽입
  void _insertTodayDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final dateString = '${now.year}-$month-$day';

    final currentText = textEditingController.text;
    final selection = textEditingController.selection;

    // 현재 커서 위치에 날짜 삽입
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      dateString,
    );

    textEditingController.text = newText;

    // 커서를 삽입된 날짜 뒤로 이동
    final newCursorPosition = selection.start + dateString.length;
    textEditingController.selection = TextSelection.collapsed(
      offset: newCursorPosition,
    );

    // 포커스를 다시 텍스트 필드로 이동
    textFieldNode.requestFocus();
  }

  /// 텍스트 변경 시 호출 — 링크 span offset 을 편집에 맞게 재배치한다.
  void _onControllerChanged() {
    if (!mounted || disposed) return;
    final newText = textEditingController.text;
    // 링크 span 재배치 + 텍스트 크기 재계산을 위해 rebuild
    setState(() {
      if (newText != _previousText) {
        final delta = computeTextEditDelta(_previousText, newText);
        _linkSpans = shiftLinkSpans(_linkSpans, delta);
        _previousText = newText;
      }
    });
  }

  /// 선택 영역과 겹치는 기존 링크의 URL (없으면 null).
  String? _selectionLinkUrl(TextSelection selection) {
    for (final span in _linkSpans) {
      if (selection.start < span.end && span.start < selection.end) {
        return span.url;
      }
    }
    return null;
  }

  /// 커서 위치 [offset] 이 놓인 링크 span (없으면 null).
  ///
  /// 굿노트처럼 링크 문자 사이뿐 아니라 양 끝 경계에 커서가 있어도 해당
  /// 링크를 편집 대상으로 삼는다 (경계가 인접 span 과 겹치면 앞선 span 우선).
  TextLinkSpan? _linkSpanAtCursor(int offset) {
    for (final span in _linkSpans) {
      if (offset >= span.start && offset <= span.end) {
        return span;
      }
    }
    return null;
  }

  /// 링크 추가/편집/삭제의 대상 범위를 해석한다. (kobic #8481)
  ///
  /// - 드래그 선택이 있으면 그 범위 그대로
  /// - 커서(collapsed)가 링크 위에 있으면 해당 링크 span 전체 범위
  /// - 그 외에는 null (링크 작업 불가)
  TextSelection? _linkTargetSelection(TextSelection selection) {
    if (!selection.isValid) return null;
    if (!selection.isCollapsed) return selection;
    final span = _linkSpanAtCursor(selection.baseOffset);
    if (span == null) return null;
    return TextSelection(baseOffset: span.start, extentOffset: span.end);
  }

  /// 선택 영역(또는 커서가 놓인 링크)에 링크를 추가하거나 기존 링크를 편집한다.
  Future<void> _onAddOrEditLink(TextSelection selection) async {
    final target = _linkTargetSelection(selection);
    if (target == null) return;
    final existingTarget = _selectionLinkUrl(target);
    final result = await _showLinkDialog(initialTarget: existingTarget);
    if (result == null || !mounted || disposed) return; // 취소/언마운트
    _applyLink(target, result);
  }

  /// 선택 영역(또는 커서가 놓인 링크)과 겹치는 링크들을 제거한다.
  void _removeLink(TextSelection selection) {
    final target = _linkTargetSelection(selection);
    if (target == null) return;
    setState(() {
      _linkSpans = _linkSpans
          .where(
            (span) => !(target.start < span.end && span.start < target.end),
          )
          .toList();
    });
    _restoreFocus(target);
  }

  /// 선택 영역 [selection] 에 [url] 링크를 적용한다 (겹치는 기존 링크 대체).
  void _applyLink(TextSelection selection, String url) {
    final start = math.min(selection.start, selection.end);
    final end = math.max(selection.start, selection.end);
    setState(() {
      final kept = _linkSpans
          .where((span) => !(start < span.end && span.start < end))
          .toList();
      kept.add(
        TextLinkSpan()
          ..start = start
          ..end = end
          ..url = url,
      );
      _linkSpans = kept;
    });
    _restoreFocus(selection);
  }

  /// 다이얼로그 종료 후 텍스트 필드 포커스/선택을 복원한다.
  void _restoreFocus(TextSelection selection) {
    if (!mounted || disposed) return;
    textFieldNode.requestFocus();
    final length = textEditingController.text.length;
    if (selection.start <= length && selection.end <= length) {
      textEditingController.selection = selection;
    }
  }

  /// 링크 입력 다이얼로그 — 외부 URL / 내부 페이지 선택 (#7222).
  ///
  /// 확인 시 정규화된 링크 타깃(외부: `https://...`, 내부: `page:N`)을, 취소/
  /// 빈값/비정수 페이지면 null 을 반환한다. [initialTarget] 이 `page:N` 이면
  /// 내부 모드로, 그 외엔 외부 모드로 시작한다.
  Future<String?> _showLinkDialog({String? initialTarget}) async {
    _suppressComplete = true;
    try {
      return await showDialog<String>(
        context: context,
        builder: (_) => _LinkInputDialog(initialTarget: initialTarget),
      );
    } finally {
      _suppressComplete = false;
    }
  }

  void _completeEditing() {
    if (disposed || _isCompleting || _suppressComplete) return;

    _isCompleting = true; // 중복 호출 방지

    try {
      final rawText = textEditingController.text;
      final text = rawText.trim();

      // 텍스트가 비어있다면 에디터 닫기 (취소 처리)
      if (text.isEmpty) {
        widget.onComplete(null);
        _isCompleting = false; // 완료 상태 초기화
        return;
      }

      // 스케일을 고려한 실제 폰트 크기 계산
      final double actualFontSize;
      if (!widget.isNew) {
        // 기존 텍스트 편집인 경우
        final baseFontSize = widget.drawable.style.fontSize! / widget.scale;
        actualFontSize = baseFontSize;
      } else {
        // 새 텍스트 생성인 경우: _addNewTextAt이 펜 굵기 기반으로 계산해
        // textSettings에 넣어둔 크기를 사용한다. (상수 16으로 고정하면
        // 입력 중 크게 보이던 텍스트가 커밋 순간 축소되고
        // '펜 굵기→텍스트 크기' 기능 전체가 사장된다)
        final baseFontSize =
            (widget.textSettings.textStyle.fontSize ?? 16.0) / widget.scale;
        actualFontSize = baseFontSize;
      }

      // 텍스트 스타일/정렬 생성 (스케일 적용 안 함)
      // 기존 텍스트 재편집 시에는 텍스트 고유 스타일(색/굵기/폰트/정렬)을
      // 보존한다 — 현재 펜 설정으로 덮어쓰면 글자 하나만 고쳐도 색·정렬이
      // 바뀌고, 정렬 변경은 position 해석이 달라져 위치까지 이동한다.
      final TextStyle style;
      final TextAlignment alignment;
      if (widget.isNew) {
        style = widget.textSettings.textStyle.copyWith(
          color: widget.selectedColor,
          fontSize: actualFontSize,
          letterSpacing: 0,
        );
        alignment = widget.textSettings.textAlignment;
      } else {
        style = widget.drawable.style.copyWith(
          fontSize: actualFontSize,
          letterSpacing: 0,
        );
        alignment = widget.drawable.alignment;
      }

      // 텍스트 drawable 업데이트
      // - 새 텍스트도 widget.drawable에 이미 올바른 캔버스 좌표(x, y)와
      //   새 ID가 세팅되어 있으므로 그대로 재활용한다.
      //   (widget.position은 화면 좌표라서 drawable position으로 쓰면 안 됨)
      // trim 으로 앞쪽이 잘린 만큼 링크 span offset 을 보정 후 정규화.
      final leadingTrimmed = rawText.length - rawText.trimLeft().length;
      final adjustedSpans = _linkSpans.map(
        (span) => TextLinkSpan()
          ..start = span.start - leadingTrimmed
          ..end = span.end - leadingTrimmed
          ..url = span.url,
      );
      final finalSpans = sanitizeLinkSpans(adjustedSpans, text.length);

      final drawable = widget.drawable
          .copyWithText(text)
          .copyWithStyle(style)
          .copyWithAlignment(alignment)
          .copyWithHidden(false)
          .copyWithLinkSpans(finalSpans);

      widget.onComplete(drawable);
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      widget.onComplete(null);
    } finally {
      _isCompleting = false; // 완료 상태 초기화
    }
  }

  /// 선택 영역이 있을 때 "링크 추가/편집/삭제" 항목을 추가한 선택 툴바.
  /// 지연 콜백 — 위젯이 아직 활성(mounted·미dispose)일 때만 편집 완료.
  void _completeEditingIfActive() {
    if (mounted && !disposed) {
      _completeEditing();
    }
  }

  /// 컨텍스트 메뉴 "링크 추가/편집" 탭 — 툴바를 닫고 링크 다이얼로그로 진입.
  void _onLinkMenuTap(TextSelection selection) {
    ContextMenuController.removeAny();
    unawaited(_onAddOrEditLink(selection));
  }

  /// 에디터 상시 노출 링크 버튼 탭 — 선택 영역(또는 커서가 놓인 링크)을
  /// 대상으로 링크 다이얼로그 진입. 대상이 없으면 무시 (버튼 비활성 표시).
  void _onLinkButtonTap() {
    unawaited(_onAddOrEditLink(textEditingController.selection));
  }

  /// 컨텍스트 메뉴 "링크 삭제" 탭 — 툴바를 닫고 선택 영역 링크 제거.
  void _onLinkRemoveTap(TextSelection selection) {
    ContextMenuController.removeAny();
    _removeLink(selection);
  }

  Widget _buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final buttonItems = editableTextState.contextMenuButtonItems;
    final selection = textEditingController.selection;
    // 드래그 선택뿐 아니라 커서가 링크 위에 있을 때(collapsed)도 링크
    // 편집/삭제를 노출한다 — 굿노트 동작 정합 (kobic #8481).
    final target = _linkTargetSelection(selection);
    if (target != null) {
      final hasLink = _selectionLinkUrl(target) != null;
      buttonItems.insert(
        0,
        ContextMenuButtonItem(
          label: hasLink ? '링크 편집' : '링크 추가',
          onPressed: () => _onLinkMenuTap(selection),
        ),
      );
      if (hasLink) {
        buttonItems.insert(
          1,
          ContextMenuButtonItem(
            label: '링크 삭제',
            onPressed: () => _onLinkRemoveTap(selection),
          ),
        );
      }
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  @override
  void dispose() {
    disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    textFieldNode.removeListener(focusListener);
    textFieldNode.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final value = MediaQuery.viewInsetsOf(context).bottom;

    if (value < bottomViewInsets && textFieldNode.hasFocus) {
      // 키보드가 닫히면 편집 완료
      _completeEditing();
    }

    bottomViewInsets = value;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    // TextDrawable과 동일한 스타일 적용
    final textColor = widget.selectedColor;

    // 반복 참조되는 drawable 스타일/폰트 크기를 변수로 hoist.
    final drawableStyle = widget.drawable.style;
    final existingFontSize = drawableStyle.fontSize;

    // 기본 폰트 크기 계산 (기존 텍스트의 경우 현재 스케일 고려)
    double baseFontSize;
    // 기존 텍스트인 경우: 현재 폰트 크기를 현재 스케일로 나누어 원본 크기 계산
    baseFontSize = !widget.isNew && existingFontSize != null
        ? existingFontSize / widget.scale
        : math.max(
            20,
            widget.textSettings.textStyle.fontSize ?? 20.0,
          ); // 현재 스케일 적용
    final actualFontSize = baseFontSize * widget.scale;

    // TextDrawable과 동일한 스타일 생성
    // 기존 텍스트 재편집 시에는 커밋(_completeEditing)과 동일하게 텍스트
    // 고유 스타일을 사용해 편집 중 표시 색상도 원본과 일치시킨다.
    final textStyle = widget.isNew
        ? widget.textSettings.textStyle.copyWith(
            fontSize: actualFontSize,
            color: textColor,
            letterSpacing: 0,
          )
        : drawableStyle.copyWith(fontSize: actualFontSize, letterSpacing: 0);

    // TextPainter로 텍스트 크기 측정 (TextDrawablePainter와 동일한 방식)
    final textSpan = TextSpan(
      text: textEditingController.text.isEmpty
          ? ''
          : textEditingController.text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: widget.textSettings.textAlignment.textAlign,
      textDirection: .ltr,
    );

    // 화면 너비에서 여백을 뺀 크기로 레이아웃
    textPainter.layout(maxWidth: screenSize.width - 60);

    // 에디터 크기 계산 (텍스트 크기 + 패딩 + 링크/날짜 버튼 공간)
    const minWidth = 40.0;
    const minHeight = 30.0;
    const dateButtonWidth = 32.0; // 날짜 버튼 너비
    const linkButtonWidth = 32.0; // 링크 버튼 너비 (kobic #8481)

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    double editorWidth = math.max(
      minWidth,
      textWidth * 1.05 + 8 + linkButtonWidth + dateButtonWidth + 8,
    ); // 링크/날짜 버튼 공간 추가
    double editorHeight = math.max(minHeight, textHeight * 1.05);

    // 화면 경계 제한
    editorWidth = math.min(editorWidth, screenSize.width - 40);
    editorHeight = math.min(editorHeight, screenSize.height * 0.4);

    // 소프트 키보드 높이 — MediaQuery 의존이라 키보드 높이가 변하면
    // (등장 애니메이션, 예측 입력 바 노출 등) 자동으로 rebuild 되어 따라간다.
    final keyboardInset = mediaQuery.viewInsets.bottom;

    // 키보드 위 도킹 시 에디터 하단과 키보드 상단 사이 여백 (#241)
    const keyboardGap = 8.0;
    const minTop = 50.0;

    if (keyboardInset > 0) {
      // 키보드가 떠 있으면 상단 경계~키보드 사이 공간에 맞게 높이 재제한
      final availableHeight =
          screenSize.height - keyboardInset - keyboardGap - minTop;
      editorHeight = math.max(
        minHeight,
        math.min(editorHeight, availableHeight),
      );
    }

    // 터치 포인트를 중심으로 에디터 배치 (alignment와 무관하게 항상 중심)
    var left = widget.position.dx - editorWidth / 2;
    var top = widget.position.dy - editorHeight / 2;

    // 화면 경계 체크 및 조정
    if (left + editorWidth > screenSize.width - 20) {
      left = screenSize.width - editorWidth - 20;
    }
    if (left < 20) {
      left = 20;
    }
    if (keyboardInset > 0) {
      // 키보드가 떠 있는 동안에는 터치 지점 대신 키보드 상단에 도킹해
      // 입력 중인 텍스트가 키보드에 가려지지 않게 한다 (#241).
      // 텍스트가 여러 줄로 늘어나면 하단(키보드 쪽)은 고정된 채 위로 자란다.
      top = screenSize.height - keyboardInset - keyboardGap - editorHeight;
      if (top < minTop) {
        // 키보드가 극단적으로 큰 경우 완전 회피보다 상단 경계 유지를 우선한다.
        top = minTop;
      }
    } else {
      if (top + editorHeight > screenSize.height - 100) {
        top = screenSize.height - editorHeight - 100;
      }
      if (top < 50) {
        top = 50;
      }
    }

    // 링크 버튼 활성 상태 — 드래그 선택이 있거나 커서가 링크 위에 있을 때.
    // 컨트롤러 리스너(_onControllerChanged)가 선택 변경마다 rebuild 하므로
    // 상태가 실시간으로 갱신된다.
    final hasLinkTarget =
        _linkTargetSelection(textEditingController.selection) != null;

    return Material(
      type: .transparency,
      child: Stack(
        children: [
          // 배경 터치 시 완료 처리
          // - 입력된 텍스트가 있으면 텍스트 추가 후 닫기
          // - 입력이 없으면 에디터 닫기 (취소)
          Positioned.fill(
            child: GestureDetector(
              onTap: _completeEditing,
              child: Container(color: Colors.transparent),
            ),
          ),

          // 텍스트 필드와 날짜 버튼을 포함하는 컨테이너
          Positioned(
            left: left,
            top: top,
            child: GestureDetector(
              onTap: () {}, // 텍스트 필드 영역 터치 시 이벤트 차단
              child: Container(
                key: const ValueKey('inline_text_editor_container'),
                padding: EdgeInsets.zero,
                width: editorWidth,
                height: editorHeight,
                decoration: BoxDecoration(
                  border: .all(color: Colors.blue, width: 2),
                  borderRadius: const .all(.circular(4)),
                ),
                child: Row(
                  children: [
                    // 텍스트 필드
                    Expanded(
                      child: TextField(
                        controller: textEditingController,
                        focusNode: textFieldNode,
                        contextMenuBuilder: _buildContextMenu,
                        style: textStyle,
                        textAlign: widget.textSettings.textAlignment.textAlign,
                        decoration: InputDecoration(
                          contentPadding: const .symmetric(horizontal: 4),
                          border: .none,
                          enabledBorder: .none,
                          focusedBorder: .none,
                          disabledBorder: .none,
                          errorBorder: .none,
                          focusedErrorBorder: .none,
                          isDense: true,
                          hintStyle: textStyle.copyWith(
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                        keyboardType: .multiline,
                        textInputAction: .newline, // 🔥 엔터키를 줄바꿈으로 변경
                        // 🔥 onSubmitted 제거 - 엔터키로 편집 완료하지 않음
                      ),
                    ),

                    // 링크 버튼 — 선택 영역/커서가 놓인 링크가 있을 때 활성
                    // (굿노트처럼 링크 적용·수정 진입점을 상시 노출, kobic #8481)
                    Container(
                      width: linkButtonWidth,
                      height: editorHeight,
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.blue)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const ValueKey('inline_text_editor_link_button'),
                          onTap: _onLinkButtonTap,
                          child: Icon(
                            Icons.link,
                            size: math.min(20, editorHeight * 0.6),
                            color: hasLinkTarget
                                ? Colors.blue
                                : Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),

                    // 날짜 버튼
                    Container(
                      width: dateButtonWidth,
                      height: editorHeight,
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.blue)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _insertTodayDate,
                          borderRadius: const .only(
                            topRight: .circular(2),
                            bottomRight: .circular(2),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: math.min(20, editorHeight * 0.6),
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void focusListener() {
    if (!mounted || disposed) return;
    if (!textFieldNode.hasFocus) {
      // 포커스를 잃으면 (지연 후) 편집 완료.
      Future<void>.delayed(
        const Duration(milliseconds: 100),
        _completeEditingIfActive,
      );
    }
  }
}

/// 링크 입력 다이얼로그 본체 — 외부 URL / 내부 페이지 선택 (#7222).
///
/// 입력 컨트롤러 수명을 다이얼로그가 스스로 관리한다. 호출 측이 showDialog
/// Future 해소 직후 dispose 하면 퇴장 애니메이션 중인 TextField 가 폐기된
/// 컨트롤러를 참조해 예외가 발생하므로(kobic #8481 실측), 라우트 언마운트
/// 시점(dispose)에 함께 정리되도록 StatefulWidget 으로 분리했다.
final class _LinkInputDialog extends StatefulWidget {
  const _LinkInputDialog({required this.initialTarget});

  /// 기존 링크 타깃 (`https://...` 또는 `page:N`, 새 링크면 null).
  final String? initialTarget;

  @override
  State<_LinkInputDialog> createState() => _LinkInputDialogState();
}

final class _LinkInputDialogState extends State<_LinkInputDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _pageController;
  bool _isInternal = false;

  @override
  void initState() {
    super.initState();
    final initialPage = parsePageLinkTarget(widget.initialTarget);
    _isInternal = initialPage != null;
    _urlController = TextEditingController(
      text: _isInternal ? '' : (widget.initialTarget ?? ''),
    );
    _pageController = TextEditingController(
      text: initialPage?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// 현재 모드 기준 정규화된 링크 타깃 (유효하지 않으면 null).
  String? _buildResult() => _isInternal
      ? formatPageLinkTarget(_pageController.text)
      : _normalizeUrl(_urlController.text);

  /// 입력 URL 정규화. 빈 값이면 null, scheme 없으면 https 를 붙인다.
  String? _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final hasScheme =
        trimmed.contains('://') ||
        trimmed.startsWith('mailto:') ||
        trimmed.startsWith('tel:');
    return hasScheme ? trimmed : 'https://$trimmed';
  }

  void _submit() => Navigator.of(context).pop(_buildResult());

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('링크 입력'),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('외부 URL')),
              ButtonSegment(value: true, label: Text('내부 페이지')),
            ],
            selected: {_isInternal},
            onSelectionChanged: (selection) =>
                setState(() => _isInternal = selection.contains(true)),
          ),
          const SizedBox(height: 12),
          if (_isInternal)
            TextField(
              controller: _pageController,
              autofocus: true,
              keyboardType: .number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '1',
                labelText: '페이지 번호',
              ),
              onSubmitted: (_) => _submit(),
            )
          else
            TextField(
              controller: _urlController,
              autofocus: true,
              keyboardType: .url,
              decoration: const InputDecoration(
                hintText: 'https://example.com',
                labelText: 'URL',
              ),
              onSubmitted: (_) => _submit(),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('취소')),
        TextButton(onPressed: _submit, child: const Text('확인')),
      ],
    );
  }
}
