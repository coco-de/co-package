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

/// 링크 타깃 입력 UI 를 호스트 앱이 제공하기 위한 콜백.
///
/// 확인 시 정규화된 링크 타깃(외부: `https://...`, 내부: `page:N`)을, 취소하면
/// null 을 반환한다. [initialTarget] 은 기존 링크를 편집할 때의 현재 타깃이며
/// 새 링크면 null 이다.
///
/// open_board 는 특정 디자인 시스템에 의존하지 않으므로 다이얼로그의 생김새를
/// 규정하지 않는다. 미주입 시에는 패키지 내장 Material 다이얼로그로 폴백해
/// 단독 사용에서도 링크 입력이 동작한다.
typedef LinkTargetResolver =
    Future<String?> Function(BuildContext context, {String? initialTarget});

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
    this.linkTargetResolver,
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

  /// 링크 타깃 입력 UI 제공자 (미주입 시 내장 Material 다이얼로그로 폴백).
  final LinkTargetResolver? linkTargetResolver;

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

  /// 링크를 추가하거나 기존 링크를 편집한다.
  ///
  /// - 드래그 선택 있음 → 그 텍스트에 링크 적용
  /// - 커서가 기존 링크 위 → 그 링크 편집
  /// - 그 외(선택 없음) → 링크 타깃을 커서 위치에 **삽입**하고 그 범위에 링크를
  ///   적용한다. 선택을 먼저 만들지 않으면 링크를 걸 방법이 아예 없던 사각을
  ///   없앤다 (kobic #9838 — 굿노트·노션 동작 정합).
  Future<void> _onAddOrEditLink(TextSelection selection) async {
    final target = _linkTargetSelection(selection);
    final existingTarget = target == null ? null : _selectionLinkUrl(target);
    final result = await _showLinkDialog(initialTarget: existingTarget);
    if (result == null || !mounted || disposed) return; // 취소/언마운트

    if (target != null) {
      _applyLink(target, result);
      return;
    }
    _insertLinkAtCursor(selection, result);
  }

  /// 커서 위치에 링크 타깃 [url] 을 텍스트로 삽입하고 그 범위에 링크를 건다.
  ///
  /// 삽입 문자열은 타깃 그대로다 — 로케일에 의존하는 라벨을 패키지가 정하지
  /// 않기 위함이며, 사용자는 이어서 원하는 문구로 고칠 수 있다(편집 시 링크
  /// span 은 [shiftLinkSpans] 가 따라 이동시킨다).
  void _insertLinkAtCursor(TextSelection selection, String url) {
    final text = textEditingController.text;
    final start = selection.isValid
        ? math.min(selection.start, text.length)
        : text.length;
    final end = selection.isValid
        ? math.min(selection.end, text.length)
        : text.length;

    textEditingController.text = text.replaceRange(start, end, url);
    _applyLink(
      TextSelection(baseOffset: start, extentOffset: start + url.length),
      url,
    );
    if (!mounted || disposed) return;
    // 삽입 텍스트를 선택 상태로 두면 이어지는 입력이 링크 span 째 날려버리므로,
    // 날짜 삽입과 동일하게 커서를 삽입분 뒤로 보낸다.
    textEditingController.selection = TextSelection.collapsed(
      offset: start + url.length,
    );
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
  ///
  /// 호스트 앱이 [InlineTextEditor.linkTargetResolver] 를 주입했으면 그쪽에
  /// 위임해 앱의 디자인 시스템으로 렌더링하고, 없으면 내장 Material
  /// 다이얼로그로 폴백한다.
  Future<String?> _showLinkDialog({String? initialTarget}) async {
    // 다이얼로그가 포커스를 가져가는 동안 focusListener 가 편집을 조기 완료하지
    // 않도록 억제한다 — 주입 경로에서도 동일하게 필요하다.
    _suppressComplete = true;
    try {
      final resolver = widget.linkTargetResolver;
      if (resolver != null) {
        return await resolver(context, initialTarget: initialTarget);
      }
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
    final hasLink = target != null && _selectionLinkUrl(target) != null;
    // 대상이 없어도(선택 없음) "링크 추가"를 노출한다 — 그 경우 링크 타깃이
    // 커서 위치에 삽입된다. 이 진입점이 없으면 선택을 만들지 못한 사용자에게
    // 링크 기능이 도달 불가가 된다 (kobic #9838).
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

    // 에디터 크기 계산 (텍스트 크기 + 패딩 + 날짜 버튼 공간)
    const minWidth = 40.0;
    const minHeight = 30.0;
    const dateButtonWidth = 32.0; // 날짜 버튼 너비

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    double editorWidth = math.max(
      minWidth,
      textWidth * 1.05 + 8 + dateButtonWidth + 8,
    ); // 날짜 버튼 공간 추가
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
      // 터치 지점 그대로 뒀을 때 에디터 하단이 키보드 상단을 넘어 가려지는
      // 경우에만 키보드 위로 도킹한다 — 이미 안전한 위치라면 터치 지점을
      // 그대로 유지한다 (#241 의도 보존 + #251, kobic#9001: 도킹이 무조건
      // 발동해 "선택한 위치가 아닌 키보드 위로 이동"하는 문제 수정).
      final keyboardSafeBottom =
          screenSize.height - keyboardInset - keyboardGap;
      if (top + editorHeight > keyboardSafeBottom) {
        // 텍스트가 여러 줄로 늘어나면 하단(키보드 쪽)은 고정된 채 위로 자란다.
        top = keyboardSafeBottom - editorHeight;
        if (top < minTop) {
          // 키보드가 극단적으로 큰 경우 완전 회피보다 상단 경계 유지를 우선한다.
          top = minTop;
        }
      }
    }
    if (top + editorHeight > screenSize.height - 100) {
      top = screenSize.height - editorHeight - 100;
    }
    if (top < 50) {
      top = 50;
    }

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
  ///
  /// 정규화 규약은 [normalizeExternalLinkTarget] / [formatPageLinkTarget] 이
  /// 소유한다 — 호스트 앱이 주입하는 입력 UI 도 같은 함수를 쓰므로 두 경로가
  /// 동일한 타깃을 만든다 (kobic #9838).
  String? _buildResult() => _isInternal
      ? formatPageLinkTarget(_pageController.text)
      : normalizeExternalLinkTarget(_urlController.text);

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
