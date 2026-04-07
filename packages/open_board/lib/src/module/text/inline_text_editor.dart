  import 'dart:math' as math;

  import 'package:flutter/material.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/state/text_settings.dart';
  import 'package:open_board/src/module/text/text_drawable_extensions.dart';
  import 'package:open_board/src/module/text/text_drawable_factory.dart';

  /// 터치한 위치에 나타나는 인라인 텍스트 에디터
  final class InlineTextEditor extends StatefulWidget {
    const InlineTextEditor({
      super.key,
      required this.drawable,
      required this.position,
      required this.textSettings,
      required this.onComplete,
      required this.isNew,
      required this.scale,
      required this.selectedColor,
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
    late TextEditingController textEditingController;
    late FocusNode textFieldNode;
    double bottomViewInsets = 0;
    bool disposed = false;
    bool _hasUserInteracted = false; // 사용자가 실제로 입력했는지 추적
    bool _isCompleting = false; // 편집 완료 중인지 추적 (중복 호출 방지)

    @override
    void initState() {
      super.initState();

      // 포커스 노드 초기화
      textFieldNode = FocusNode();
      textFieldNode.addListener(focusListener);

      // 텍스트 컨트롤러 초기화
      textEditingController = TextEditingController();

      // 텍스트 변경 시 UI 업데이트를 위한 리스너 추가
      textEditingController.addListener(() {
        if (mounted && !disposed) {
          // 사용자가 텍스트를 입력했음을 표시
          if (textEditingController.text.isNotEmpty) {
            _hasUserInteracted = true;
          }
          setState(() {
            // 텍스트 변경 시 크기 재계산을 위해 rebuild
          });
        }
      });

      // 텍스트 설정
      textEditingController.text = widget.drawable.text;
      if (!widget.isNew) {
        _hasUserInteracted = true; // 기존 텍스트는 이미 상호작용이 있었다고 간주
      }

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
      final dateString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

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

      // 사용자가 상호작용했음을 표시
      _hasUserInteracted = true;

      // 포커스를 다시 텍스트 필드로 이동
      textFieldNode.requestFocus();
    }

    void _completeEditing() {
      if (disposed || _isCompleting) return;

      _isCompleting = true; // 중복 호출 방지

      try {
        final text = textEditingController.text.trim();

        // 새 텍스트인데 아직 사용자가 입력하지 않았다면 편집 상태 유지
        if (widget.isNew && !_hasUserInteracted) {
          return;
        }

        // 텍스트가 비어있다면 삭제 처리
        if (text.isEmpty) {
          widget.onComplete(null);
          _isCompleting = false; // 완료 상태 초기화
          return;
        }

        // 내용이 있는 경우 저장
        final textColor = widget.selectedColor;

        // 스케일을 고려한 실제 폰트 크기 계산
        final double actualFontSize;
        if (!widget.isNew) {
          // 기존 텍스트 편집인 경우
          final baseFontSize = widget.drawable.style.fontSize! / widget.scale;
          actualFontSize = baseFontSize;
        } else {
          // 새 텍스트 생성인 경우
          const baseFontSize = 16.0; // 기본 크기
          actualFontSize = baseFontSize;
        }

        // 텍스트 스타일 생성 (스케일 적용 안 함)
        final style = widget.textSettings.textStyle.copyWith(
          color: textColor,
          fontSize: actualFontSize,
          letterSpacing: 0,
        );

        // 텍스트 drawable 생성 또는 업데이트
        final drawable = !widget.isNew
            ? widget.drawable
                  .copyWithText(text)
                  .copyWithStyle(style)
                  .copyWithAlignment(widget.textSettings.textAlignment)
                  .copyWithHidden(false)
            : TextDrawableFactory.create(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: text,
                position: widget.position,
                style: style,
                alignment: widget.textSettings.textAlignment,
                hidden: false,
              );

        widget.onComplete(drawable);
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        widget.onComplete(null);
      } finally {
        _isCompleting = false; // 완료 상태 초기화
      }
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
      final value = MediaQuery.of(context).viewInsets.bottom;

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

      // 기본 폰트 크기 계산 (기존 텍스트의 경우 현재 스케일 고려)
      double baseFontSize;
      // 기존 텍스트인 경우: 현재 폰트 크기를 현재 스케일로 나누어 원본 크기 계산
      baseFontSize = !widget.isNew && widget.drawable.style.fontSize != null
          ? widget.drawable.style.fontSize! / widget.scale
          : math.max(
              20.0,
              widget.textSettings.textStyle.fontSize ?? 20.0,
            ); // 현재 스케일 적용
      final actualFontSize = baseFontSize * widget.scale;

      // TextDrawable과 동일한 스타일 생성
      final textStyle = widget.textSettings.textStyle.copyWith(
        fontSize: actualFontSize,
        color: textColor,
        letterSpacing: 0,
      );

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
        textDirection: TextDirection.ltr,
      );

      // 화면 너비에서 여백을 뺀 크기로 레이아웃
      textPainter.layout(maxWidth: screenSize.width - 60);

      // 에디터 크기 계산 (텍스트 크기 + 패딩 + 날짜 버튼 공간) - 텍스트 크기에 맞게 조정
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

      // 터치 포인트를 중심으로 에디터 배치 (alignment와 무관하게 항상 중심)
      double left = widget.position.dx - editorWidth / 2;
      double top = widget.position.dy - editorHeight / 2;

      // 화면 경계 체크 및 조정
      if (left + editorWidth > screenSize.width - 20) {
        left = screenSize.width - editorWidth - 20;
      }
      if (left < 20) {
        left = 20;
      }
      if (top + editorHeight > screenSize.height - 100) {
        top = screenSize.height - editorHeight - 100;
      }
      if (top < 50) {
        top = 50;
      }

      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // 배경 터치 시 완료 처리 (새 텍스트이고 아직 입력하지 않았다면 완료하지 않음)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (widget.isNew && !_hasUserInteracted) {
                    return;
                  }
                  _completeEditing();
                },
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
                  padding: EdgeInsets.zero,
                  width: editorWidth,
                  height: editorHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2.0),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      // 텍스트 필드
                      Expanded(
                        child: TextField(
                          controller: textEditingController,
                          focusNode: textFieldNode,
                          style: textStyle,
                          textAlign:
                              widget.textSettings.textAlignment.textAlign,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isDense: true,
                            hintStyle: textStyle.copyWith(
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                          maxLines: null,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          textInputAction:
                              TextInputAction.newline, // 🔥 엔터키를 줄바꿈으로 변경
                          textCapitalization: TextCapitalization.none,
                          expands: false,
                          // 🔥 onSubmitted 제거 - 엔터키로 편집 완료하지 않음
                        ),
                      ),

                      // 날짜 버튼
                      Container(
                        width: dateButtonWidth,
                        height: editorHeight,
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.blue, width: 1.0),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _insertTodayDate,
                            borderRadius: const .only(
                              topRight: Radius.circular(2),
                              bottomRight: Radius.circular(2),
                            ),
                            child: Container(
                              child: Icon(
                                Icons.calendar_today,
                                size: math.min(20.0, editorHeight * 0.6),
                                color: Colors.blue,
                              ),
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
        // 포커스를 잃으면 편집 완료
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !disposed) {
            _completeEditing();
          }
        });
      }
    }
  }
