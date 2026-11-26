import 'package:flutter/widgets.dart';

/// A single- or multi-line text input built on [EditableText], with a hint and
/// a plain border (the package does not depend on a design system).
///
/// Pass a [controller] to own the text, or [initialText] to let the field own
/// it. [onSubmitted] fires on the keyboard's done/enter action (single line) and
/// when focus is lost with [submitOnBlur].
class NoteTextField extends StatefulWidget {
  const NoteTextField({
    super.key,
    this.controller,
    this.initialText = '',
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.submitOnBlur = false,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.style = const TextStyle(fontSize: 14, color: Color(0xFF212121)),
    this.hintStyle = const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
    this.cursorColor = const Color(0xFF2962FF),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.decoration = const BoxDecoration(
      color: Color(0xFFFFFFFF),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFFBDBDBD))),
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
  });

  final TextEditingController? controller;

  /// Initial text when no [controller] is given.
  final String initialText;
  final FocusNode? focusNode;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  /// Also report the text through [onSubmitted] when the field loses focus.
  final bool submitOnBlur;

  /// 1 for a single line; `null` for unbounded multi-line.
  final int? maxLines;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final TextStyle style;
  final TextStyle hintStyle;
  final Color cursorColor;
  final EdgeInsetsGeometry padding;
  final Decoration? decoration;

  @override
  State<NoteTextField> createState() => _NoteTextFieldState();
}

class _NoteTextFieldState extends State<NoteTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialText);
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _unbind() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
  }

  @override
  void didUpdateWidget(NoteTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.focusNode != widget.focusNode) {
      _unbind();
      _bind();
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && widget.submitOnBlur) {
      widget.onSubmitted?.call(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editable = EditableText(
      controller: _controller,
      focusNode: _focusNode,
      style: widget.style,
      cursorColor: widget.cursorColor,
      backgroundCursorColor: const Color(0xFFBDBDBD),
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
    final showHint = _controller.text.isEmpty && widget.hintText != null;

    return DecoratedBox(
      decoration: widget.decoration ?? const BoxDecoration(),
      child: Padding(
        padding: widget.padding,
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            if (showHint)
              IgnorePointer(
                child: Text(
                  widget.hintText!,
                  style: widget.hintStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            editable,
          ],
        ),
      ),
    );
  }
}
