import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/utilities/internal/note_utility_button.dart';
import 'package:open_note/src/note/study/utilities/note_duration_format.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_strings.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_style.dart';
import 'package:open_note/src/note/study/utilities/note_timer_controller.dart';

/// Shows a [NoteTimerController]: the remaining time (`mm:ss`, `h:mm:ss` from an
/// hour up, rounded up to whole seconds) with start/pause/resume and reset.
/// While idle, two buttons change the length by [step].
class NoteTimerView extends StatelessWidget {
  /// A view of [controller].
  const NoteTimerView({
    required this.controller,
    super.key,
    this.strings = const NoteStudyUtilitiesStrings(),
    this.style = const NoteStudyUtilitiesStyle(),
    this.step = const Duration(minutes: 1),
  });

  /// The countdown shown.
  final NoteTimerController controller;

  /// Labels and messages.
  final NoteStudyUtilitiesStrings strings;

  /// Colors and sizes.
  final NoteStudyUtilitiesStyle style;

  /// How much the length buttons change it; `null` hides them.
  final Duration? step;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final finished = controller.status == NoteTimerStatus.finished;
      final editable = controller.status == NoteTimerStatus.idle;
      final amount = step;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TimerDigits(view: this, finished: finished),
          if (finished)
            Text(strings.timerFinished, style: style.text(color: style.accent)),
          SizedBox(height: style.spacing),
          _TimerButtons(view: this),
          if (editable && amount != null) ...[
            SizedBox(height: style.spacing),
            _TimerSteps(view: this, step: amount),
          ],
        ],
      );
    },
  );
}

class _TimerDigits extends StatelessWidget {
  const _TimerDigits({required this.view, required this.finished});

  final NoteTimerView view;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final text = NoteDurationFormat.clock(
      view.controller.remaining,
      roundUp: true,
    );

    return Semantics(
      label: view.strings.timer,
      value: text,
      excludeSemantics: true,
      child: Text(
        text,
        style: view.style.digits(color: finished ? view.style.accent : null),
      ),
    );
  }
}

class _TimerButtons extends StatelessWidget {
  const _TimerButtons({required this.view});

  final NoteTimerView view;

  @override
  Widget build(BuildContext context) {
    final controller = view.controller;
    final strings = view.strings;
    final (label, action) = switch (controller.status) {
      NoteTimerStatus.idle ||
      NoteTimerStatus.finished => (strings.start, controller.start),
      NoteTimerStatus.running => (strings.pause, controller.pause),
      NoteTimerStatus.paused => (strings.resume, controller.resume),
    };
    final startable = controller.duration > Duration.zero;
    final canReset = controller.status != NoteTimerStatus.idle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NoteUtilityButton(
          key: const ValueKey('timer-primary'),
          text: label,
          semanticLabel: label,
          style: view.style,
          kind: NoteUtilityButtonKind.primary,
          onPressed: startable ? action : null,
        ),
        SizedBox(width: view.style.spacing),
        NoteUtilityButton(
          key: const ValueKey('timer-reset'),
          text: strings.reset,
          semanticLabel: strings.reset,
          style: view.style,
          onPressed: canReset ? controller.reset : null,
        ),
      ],
    );
  }
}

class _TimerSteps extends StatelessWidget {
  const _TimerSteps({required this.view, required this.step});

  final NoteTimerView view;
  final Duration step;

  @override
  Widget build(BuildContext context) {
    final controller = view.controller;
    final decrease = view.strings.timeStepLabel(-step);
    final increase = view.strings.timeStepLabel(step);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NoteUtilityButton(
          key: const ValueKey('timer-decrease'),
          text: decrease,
          semanticLabel: decrease,
          style: view.style,
          onPressed: controller.duration > Duration.zero
              ? () => controller.setDuration(controller.duration - step)
              : null,
        ),
        SizedBox(width: view.style.spacing),
        NoteUtilityButton(
          key: const ValueKey('timer-increase'),
          text: increase,
          semanticLabel: increase,
          style: view.style,
          onPressed: controller.duration < NoteTimerController.maxDuration
              ? () => controller.setDuration(controller.duration + step)
              : null,
        ),
      ],
    );
  }
}
