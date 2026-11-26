import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/utilities/internal/note_utility_button.dart';
import 'package:open_note/src/note/study/utilities/note_duration_format.dart';
import 'package:open_note/src/note/study/utilities/note_stopwatch_controller.dart';
import 'package:open_note/src/note/study/utilities/note_stopwatch_lap.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_strings.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_style.dart';

/// Shows a [NoteStopwatchController]: the elapsed time (`mm:ss`, `h:mm:ss` from
/// an hour up) with start/pause/resume, lap and reset, and the laps newest first.
class NoteStopwatchView extends StatelessWidget {
  /// A view of [controller].
  const NoteStopwatchView({
    required this.controller,
    super.key,
    this.strings = const NoteStudyUtilitiesStrings(),
    this.style = const NoteStudyUtilitiesStyle(),
    this.maxLapsHeight = 160,
  });

  /// The stopwatch shown.
  final NoteStopwatchController controller;

  /// Labels and messages.
  final NoteStudyUtilitiesStrings strings;

  /// Colors and sizes.
  final NoteStudyUtilitiesStyle style;

  /// The lap list scrolls beyond this height; `0` hides it.
  final double maxLapsHeight;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final text = NoteDurationFormat.clock(controller.elapsed);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: strings.stopwatch,
            value: text,
            excludeSemantics: true,
            child: Text(text, style: style.digits()),
          ),
          SizedBox(height: style.spacing),
          _StopwatchButtons(view: this),
          if (maxLapsHeight > 0 && controller.laps.isNotEmpty) ...[
            SizedBox(height: style.spacing),
            _LapList(view: this),
          ],
        ],
      );
    },
  );
}

class _StopwatchButtons extends StatelessWidget {
  const _StopwatchButtons({required this.view});

  final NoteStopwatchView view;

  @override
  Widget build(BuildContext context) {
    final controller = view.controller;
    final strings = view.strings;
    final (label, action) = switch (controller.status) {
      NoteStopwatchStatus.idle => (strings.start, controller.start),
      NoteStopwatchStatus.running => (strings.pause, controller.pause),
      NoteStopwatchStatus.paused => (strings.resume, controller.start),
    };
    final lapEnabled =
        controller.isRunning && controller.laps.length < controller.maxLaps;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NoteUtilityButton(
          key: const ValueKey('stopwatch-primary'),
          text: label,
          semanticLabel: label,
          style: view.style,
          kind: NoteUtilityButtonKind.primary,
          onPressed: action,
        ),
        SizedBox(width: view.style.spacing),
        NoteUtilityButton(
          key: const ValueKey('stopwatch-lap'),
          text: strings.lap,
          semanticLabel: strings.lap,
          style: view.style,
          onPressed: lapEnabled ? controller.lap : null,
        ),
        SizedBox(width: view.style.spacing),
        NoteUtilityButton(
          key: const ValueKey('stopwatch-reset'),
          text: strings.reset,
          semanticLabel: strings.reset,
          style: view.style,
          onPressed: controller.status == NoteStopwatchStatus.idle
              ? null
              : controller.reset,
        ),
      ],
    );
  }
}

class _LapList extends StatelessWidget {
  const _LapList({required this.view});

  final NoteStopwatchView view;

  @override
  Widget build(BuildContext context) {
    final laps = view.controller.laps;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: view.maxLapsHeight),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: laps.length,
        itemBuilder: (context, index) =>
            _LapRow(view: view, lap: laps[laps.length - 1 - index]),
      ),
    );
  }
}

class _LapRow extends StatelessWidget {
  const _LapRow({required this.view, required this.lap});

  final NoteStopwatchView view;
  final NoteStopwatchLap lap;

  @override
  Widget build(BuildContext context) {
    final style = view.style;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: style.spacing,
        vertical: style.spacing / 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(view.strings.lapTitle(lap.number), style: style.text()),
          ),
          Text(NoteDurationFormat.clock(lap.split), style: style.text()),
          SizedBox(width: style.spacing * 2),
          Text(
            NoteDurationFormat.clock(lap.total),
            style: style.text(color: style.mutedForeground),
          ),
        ],
      ),
    );
  }
}
