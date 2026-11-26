import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/editor/internal/note_editor_button.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_strings.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';
import 'package:open_note/src/note/editor/note_pdf_text_controller.dart';
import 'package:open_note/src/note/io/markup/note_text_markup_kind.dart';

/// The actions on selected PDF text.
class NotePdfTextBar extends StatefulWidget {
  const NotePdfTextBar({
    required this.controller,
    required this.strings,
    required this.style,
    super.key,
  });

  /// The markup colours.
  static const List<Color> colors = [
    Color(0xFFFFEB3B),
    Color(0xFF9CCC65),
    Color(0xFFF48FB1),
    Color(0xFF42A5F5),
    Color(0xFFE53935),
  ];

  /// The default colour of lines under or through text.
  static const Color lineColor = Color(0xFFE53935);

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;

  @override
  State<NotePdfTextBar> createState() => _NotePdfTextBarState();
}

class _NotePdfTextBarState extends State<NotePdfTextBar> {
  /// The chosen colour; without one each kind has its usual colour.
  Color? _color;

  /// The last mark did not go on the layer.
  bool _isLayerBlocked = false;

  NoteEditorController get _controller => widget.controller;

  NoteEditorStrings get _strings => widget.strings;

  NoteEditorStyle get _style => widget.style;

  @override
  Widget build(BuildContext context) {
    final text = _controller.pdfText;
    final message = switch (text.status) {
      NotePdfTextStatus.loading => _strings.readingPdfText,
      NotePdfTextStatus.failed => _strings.pdfTextFailed,
      NotePdfTextStatus.ready when text.selected.isEmpty =>
        _strings.selectTextHint,
      NotePdfTextStatus.ready => null,
      NotePdfTextStatus.idle || NotePdfTextStatus.empty => _strings.noPdfText,
    };

    return NoteEditorStrip(
      style: _style,
      children: [
        if (message != null)
          Text(message, style: _style.textStyle)
        else ...[
          _button(
            'highlight',
            _strings.highlightText,
            () => _mark(NoteTextMarkupKind.highlight),
          ),
          _button(
            'underline',
            _strings.underlineText,
            () => _mark(NoteTextMarkupKind.underline),
          ),
          _button(
            'strikeout',
            _strings.strikeOutText,
            () => _mark(NoteTextMarkupKind.strikeout),
          ),
          for (final (index, color) in NotePdfTextBar.colors.indexed)
            NoteEditorSwatch(
              key: ValueKey('note-pdf-color-$index'),
              color: color,
              label: _strings.colorName(color.toARGB32()),
              style: _style,
              selected: _color == color,
              onPressed: () =>
                  setState(() => _color = _color == color ? null : color),
            ),
          _button(
            'copy',
            _strings.copyText,
            () => Clipboard.setData(ClipboardData(text: text.selectedText)),
          ),
          _button('clear', _strings.clearSelection, text.clear),
        ],
        if (_isLayerBlocked)
          Text(_strings.layerCannotMark, style: _style.textStyle),
      ],
    );
  }

  Widget _button(String key, String label, VoidCallback onPressed) =>
      NoteEditorButton(
        key: ValueKey('note-pdf-$key'),
        label: label,
        style: _style,
        onPressed: onPressed,
      );

  void _mark(NoteTextMarkupKind kind) {
    final fallback = kind == NoteTextMarkupKind.highlight
        ? NotePdfTextBar.colors.first
        : NotePdfTextBar.lineColor;
    final marked = _controller.markPdfSelection(kind, _color ?? fallback);
    setState(() => _isLayerBlocked = !marked);
  }
}
