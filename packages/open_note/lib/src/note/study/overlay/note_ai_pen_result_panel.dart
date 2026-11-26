import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_controller.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_kind.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_panel_body.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_panel_header.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_panel_style.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';

/// The answer sheet of the AI pen: a tab per [NoteAiPenKind] above the busy
/// state, the answer with its steps and a copy button, or the error with a
/// retry button. It follows a [NoteAiPenController].
///
/// Tapping a tab calls [onKindSelected]. Without that callback the panel runs
/// the controller's latest request again with the tapped kind. A tab shows the
/// controller only while the latest request has its kind, otherwise the hint.
/// A request that starts running selects its own tab.
///
/// The panel is at most [NoteAiPenPanelStyle.maxHeight] tall and as wide as
/// its constraints.
class NoteAiPenResultPanel extends StatefulWidget {
  /// Shows [controller].
  const NoteAiPenResultPanel({
    required this.controller,
    this.initialKind = NoteAiPenKind.solve,
    this.onKindSelected,
    this.onCopy,
    this.onClose,
    this.strings = const NoteStudyOverlayStrings(),
    this.style = const NoteAiPenPanelStyle(),
    super.key,
  });

  /// The requests and answers.
  final NoteAiPenController controller;

  /// The tab selected while there is no request.
  final NoteAiPenKind initialKind;

  /// Takes over what tapping a tab does.
  final ValueChanged<NoteAiPenKind>? onKindSelected;

  /// Copies the answer (with its steps); without it there is no copy button.
  final ValueChanged<String>? onCopy;

  /// Closes the panel; without it there is no close button.
  final VoidCallback? onClose;

  /// All text.
  final NoteStudyOverlayStrings strings;

  /// Colours and metrics.
  final NoteAiPenPanelStyle style;

  @override
  State<NoteAiPenResultPanel> createState() => _NoteAiPenResultPanelState();
}

class _NoteAiPenResultPanelState extends State<NoteAiPenResultPanel> {
  late NoteAiPenKind _kind;

  @override
  void initState() {
    super.initState();
    _kind = widget.controller.request?.kind ?? widget.initialKind;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(NoteAiPenResultPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onControllerChanged);
    widget.controller.addListener(_onControllerChanged);
    _kind = widget.controller.request?.kind ?? _kind;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.strings.aiPanel,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: style.maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.backgroundColor,
            border: Border.all(color: style.borderColor),
            borderRadius: BorderRadius.all(Radius.circular(style.cornerRadius)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Flexible(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => NoteAiPenPanelHeader(
    selected: _kind,
    onSelect: _select,
    onClose: widget.onClose,
    strings: widget.strings,
    style: widget.style,
  );

  Widget _body() {
    final controller = widget.controller;
    final mine = controller.request?.kind == _kind;
    final status = mine ? controller.status : NoteAiPenStatus.idle;

    return NoteAiPenPanelBody(
      status: status,
      result: controller.result,
      error: controller.error,
      onCancel: controller.cancel,
      onRetry: mine ? () => unawaited(controller.retry()) : null,
      onCopy: widget.onCopy,
      strings: widget.strings,
      style: widget.style,
    );
  }

  void _select(NoteAiPenKind kind) {
    if (kind == _kind) return;
    setState(() => _kind = kind);
    final selected = widget.onKindSelected;
    if (selected != null) {
      selected(kind);

      return;
    }
    final request = widget.controller.request;
    if (request != null) {
      unawaited(widget.controller.run(request.copyWith(kind: kind)));
    }
  }

  void _onControllerChanged() {
    final request = widget.controller.request;
    setState(() {
      if (widget.controller.isRunning && request != null) {
        _kind = request.kind;
      }
    });
  }
}
