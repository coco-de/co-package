import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/utilities/internal/note_utility_button.dart';
import 'package:open_note/src/note/study/utilities/internal/note_utility_icon.dart';
import 'package:open_note/src/note/study/utilities/note_duration_format.dart';
import 'package:open_note/src/note/study/utilities/note_recording.dart';
import 'package:open_note/src/note/study/utilities/note_recording_controller.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_strings.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_style.dart';

/// The recordings of a [NoteRecordingController] as rows with play/pause, the
/// playback speed (tap to cycle through the presets) and delete.
class NoteRecordingList extends StatelessWidget {
  /// Lists the recordings of [controller].
  const NoteRecordingList({
    required this.controller,
    super.key,
    this.pageNumber,
    this.onRemoved,
    this.shrinkWrap = false,
    this.strings = const NoteStudyUtilitiesStrings(),
    this.style = const NoteStudyUtilitiesStyle(),
  });

  /// The recordings and their playback.
  final NoteRecordingController controller;

  /// When set, only the recordings attached to this 1-based page are listed.
  final int? pageNumber;

  /// Called after a row's delete button removed a recording, so the host can
  /// delete its audio.
  final ValueChanged<NoteRecording>? onRemoved;

  /// Sizes the list to its rows (for use inside another scrollable).
  final bool shrinkWrap;

  /// Labels and messages.
  final NoteStudyUtilitiesStrings strings;

  /// Colors and sizes.
  final NoteStudyUtilitiesStyle style;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final page = pageNumber;
      final shown = page == null
          ? controller.recordings
          : controller.forPage(page);
      if (shown.isEmpty) return _EmptyRecordings(list: this);

      return ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: EdgeInsets.zero,
        itemCount: shown.length,
        itemBuilder: (context, index) => _RecordingRow(
          key: ValueKey(shown[index].id),
          list: this,
          recording: shown[index],
        ),
      );
    },
  );
}

class _EmptyRecordings extends StatelessWidget {
  const _EmptyRecordings({required this.list});

  final NoteRecordingList list;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(list.style.spacing * 2),
    child: Text(
      list.strings.noRecordings,
      textAlign: TextAlign.center,
      style: list.style.text(color: list.style.mutedForeground),
    ),
  );
}

class _RecordingRow extends StatelessWidget {
  const _RecordingRow({required this.list, required this.recording, super.key});

  final NoteRecordingList list;
  final NoteRecording recording;

  NoteRecordingController get _controller => list.controller;

  bool get _isCurrent => _controller.currentId == recording.id;

  bool get _isPlaying => _isCurrent && _controller.isPlaying;

  @override
  Widget build(BuildContext context) {
    final style = list.style;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: style.border)),
      ),
      child: Padding(
        padding: EdgeInsets.all(style.spacing),
        child: Row(
          children: [
            _playButton(),
            SizedBox(width: style.spacing),
            Expanded(child: _RecordingText(row: this)),
            SizedBox(width: style.spacing),
            _speedButton(),
            SizedBox(width: style.spacing / 2),
            _deleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _playButton() {
    final strings = list.strings;
    final label = _isPlaying
        ? strings.pauseRecordingLabel
        : strings.playRecordingLabel;

    return NoteUtilityButton(
      key: ValueKey('recording-play-${recording.id}'),
      semanticLabel: label(recording.title),
      style: list.style,
      icon: NoteUtilityIcon(
        glyph: _isPlaying ? NoteUtilityGlyph.pause : NoteUtilityGlyph.play,
        color: list.style.accent,
      ),
      onPressed: () => unawaited(_controller.toggle(recording.id)),
    );
  }

  Widget _speedButton() {
    final label = list.strings.speedLabel(recording.playbackSpeed);

    return NoteUtilityButton(
      key: ValueKey('recording-speed-${recording.id}'),
      text: label,
      semanticLabel: list.strings.playbackSpeedLabel(label),
      style: list.style,
      minSize: const Size(52, 36),
      onPressed: () => unawaited(_controller.cycleSpeed(recording.id)),
    );
  }

  Widget _deleteButton() => NoteUtilityButton(
    key: ValueKey('recording-delete-${recording.id}'),
    semanticLabel: list.strings.deleteRecordingLabel(recording.title),
    style: list.style,
    icon: NoteUtilityIcon(
      glyph: NoteUtilityGlyph.delete,
      color: list.style.danger,
    ),
    onPressed: () {
      final removed = _controller.find(recording.id);
      if (removed == null || !_controller.remove(removed.id)) return;
      list.onRemoved?.call(removed);
    },
  );
}

/// Title, times, page and error of one row, with progress while current.
class _RecordingText extends StatelessWidget {
  const _RecordingText({required this.row});

  final _RecordingRow row;

  String get _details {
    final strings = row.list.strings;
    final recording = row.recording;
    final total = NoteDurationFormat.clock(recording.duration);
    final time = row._isCurrent
        ? '${NoteDurationFormat.clock(row._controller.position)} / $total'
        : total;
    final page = recording.pageNumber;

    return page == null ? time : '$time · ${strings.pageLabel(page)}';
  }

  @override
  Widget build(BuildContext context) {
    final style = row.list.style;
    final failed = row._controller.failedId == row.recording.id;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.recording.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.text(),
        ),
        Text(
          failed ? row.list.strings.playbackError : _details,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.text(
            color: failed ? style.danger : style.mutedForeground,
          ),
        ),
        if (row._isCurrent && row.recording.duration > Duration.zero)
          _ProgressBar(row: row),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.row});

  final _RecordingRow row;

  @override
  Widget build(BuildContext context) {
    final style = row.list.style;
    final fraction =
        row._controller.position.inMicroseconds /
        row.recording.duration.inMicroseconds;

    return Padding(
      padding: EdgeInsets.only(top: style.spacing / 2),
      child: SizedBox(
        height: 3,
        child: ColoredBox(
          color: style.border,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0, 1).toDouble(),
            child: ColoredBox(color: style.accent),
          ),
        ),
      ),
    );
  }
}
