import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_controller.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_exception.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_panel_style.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_result.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_button.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_spinner.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';

/// The state-dependent part of the AI pen panel: hint, busy, answer or error.
/// Internal to `study/overlay`.
class NoteAiPenPanelBody extends StatelessWidget {
  /// Shows [status] with the matching [result] or [error].
  const NoteAiPenPanelBody({
    required this.status,
    required this.strings,
    required this.style,
    this.result,
    this.error,
    this.onCancel,
    this.onRetry,
    this.onCopy,
    super.key,
  });

  /// What to show.
  final NoteAiPenStatus status;

  /// All text.
  final NoteStudyOverlayStrings strings;

  /// Colours and metrics.
  final NoteAiPenPanelStyle style;

  /// The answer when done.
  final NoteAiPenResult? result;

  /// The failure when in error.
  final NoteAiPenException? error;

  /// Cancels the running request.
  final VoidCallback? onCancel;

  /// Runs the request again.
  final VoidCallback? onRetry;

  /// Copies the answer.
  final ValueChanged<String>? onCopy;

  TextStyle get _text =>
      TextStyle(color: style.textColor, fontSize: style.fontSize, height: 1.4);

  TextStyle get _muted => _text.copyWith(color: style.mutedTextColor);

  @override
  Widget build(BuildContext context) => switch (status) {
    NoteAiPenStatus.idle => _idle(),
    NoteAiPenStatus.running => _running(),
    NoteAiPenStatus.done => _done(result),
    NoteAiPenStatus.error => _failed(error),
  };

  Widget _idle() => _column([
    Text(strings.aiIdleHint, style: _muted),
    if (onRetry != null)
      _action('note-ai-pen-retry', strings.aiRetry, onRetry!),
  ]);

  Widget _running() => _column([
    Row(
      children: [
        NoteOverlaySpinner(color: style.accentColor),
        SizedBox(width: style.padding),
        Flexible(child: Text(strings.aiBusy, style: _muted)),
      ],
    ),
    if (onCancel != null)
      _action('note-ai-pen-cancel', strings.aiCancel, onCancel!),
  ]);

  Widget _done(NoteAiPenResult? answer) {
    if (answer == null) return _idle();
    final copy = onCopy;
    final steps = answer.steps ?? const <String>[];

    return _column([
      Text(answer.text, style: _text),
      if (steps.isNotEmpty) ...[
        Text(strings.aiSteps, style: _muted),
        for (var i = 0; i < steps.length; i++)
          Text('${i + 1}. ${steps[i]}', style: _text),
      ],
      if (copy != null)
        _action(
          'note-ai-pen-copy',
          strings.aiCopy,
          () => copy(answer.plainText),
        ),
    ]);
  }

  Widget _failed(NoteAiPenException? failure) => _column([
    Text(
      failure == null ? strings.aiErrorUnknown : strings.errorMessage(failure),
      style: _text.copyWith(color: style.errorColor),
    ),
    if (onRetry != null)
      _action('note-ai-pen-retry', strings.aiRetry, onRetry!),
  ]);

  Widget _column(List<Widget> children) => SingleChildScrollView(
    padding: EdgeInsets.all(style.padding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: style.padding / 2,
      children: children,
    ),
  );

  Widget _action(String key, String label, VoidCallback onPressed) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: NoteOverlayButton(
      key: ValueKey(key),
      label: label,
      onPressed: onPressed,
      background: style.accentColor.withValues(alpha: 0.1),
      padding: EdgeInsets.symmetric(horizontal: style.padding),
      child: Text(
        label,
        style: _text.copyWith(
          color: style.accentColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
