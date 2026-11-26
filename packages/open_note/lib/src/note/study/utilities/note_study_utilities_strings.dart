import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_exception.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_key.dart';
import 'package:open_note/src/note/study/utilities/note_duration_format.dart';

/// Every user-visible text of the study-utility widgets, with English
/// defaults. Pass a translated instance as `strings:`.
///
/// Functions receive the values to show, so word order stays up to the
/// translation.
@immutable
class NoteStudyUtilitiesStrings {
  /// English texts; replace any of them to translate.
  const NoteStudyUtilitiesStrings({
    this.timer = 'Timer',
    this.stopwatch = 'Stopwatch',
    this.start = 'Start',
    this.pause = 'Pause',
    this.resume = 'Resume',
    this.reset = 'Reset',
    this.lap = 'Lap',
    this.timerFinished = "Time's up",
    this.timeStepLabel = defaultTimeStepLabel,
    this.lapTitle = defaultLapTitle,
    this.calculatorDisplay = 'Calculator display',
    this.calculatorMemory = 'M',
    this.calculatorSyntaxError = 'Invalid expression',
    this.calculatorDivisionByZeroError = 'Cannot divide by zero',
    this.calculatorDomainError = 'Not a number',
    this.calculatorOverflowError = 'Number too large',
    this.calculatorKeyText = defaultCalculatorKeyText,
    this.calculatorKeyLabel = defaultCalculatorKeyLabel,
    this.scratchpad = 'Scratchpad',
    this.scratchpadSurface = 'Scratchpad drawing area',
    this.clear = 'Clear',
    this.close = 'Close',
    this.noRecordings = 'No recordings yet',
    this.playbackError = "Can't play this recording",
    this.playRecordingLabel = defaultPlayRecordingLabel,
    this.pauseRecordingLabel = defaultPauseRecordingLabel,
    this.deleteRecordingLabel = defaultDeleteRecordingLabel,
    this.playbackSpeedLabel = defaultPlaybackSpeedLabel,
    this.speedLabel = defaultSpeedLabel,
    this.pageLabel = defaultPageLabel,
  });

  /// Accessibility name of the timer.
  final String timer;

  /// Accessibility name of the stopwatch.
  final String stopwatch;

  /// Starts a timer or stopwatch.
  final String start;

  /// Pauses a timer or stopwatch.
  final String pause;

  /// Resumes a timer or stopwatch.
  final String resume;

  /// Resets a timer or stopwatch.
  final String reset;

  /// Records a lap.
  final String lap;

  /// Shown when a countdown reaches zero.
  final String timerFinished;

  /// Label of a timer button that changes the length by a signed step.
  final String Function(Duration step) timeStepLabel;

  /// Heading of the lap with this 1-based number.
  final String Function(int number) lapTitle;

  /// Screen-reader name of the calculator display.
  final String calculatorDisplay;

  /// Shown while the calculator memory holds a value.
  final String calculatorMemory;

  /// Message for [NoteCalculatorError.syntax].
  final String calculatorSyntaxError;

  /// Message for [NoteCalculatorError.divisionByZero].
  final String calculatorDivisionByZeroError;

  /// Message for [NoteCalculatorError.domain].
  final String calculatorDomainError;

  /// Message for [NoteCalculatorError.overflow].
  final String calculatorOverflowError;

  /// The symbol printed on a calculator key.
  final String Function(NoteCalculatorKey key) calculatorKeyText;

  /// The name a screen reader announces for a calculator key.
  final String Function(NoteCalculatorKey key) calculatorKeyLabel;

  /// Title of the scratchpad.
  final String scratchpad;

  /// Screen-reader name of the scratchpad's drawing area.
  final String scratchpadSurface;

  /// Erases the scratchpad.
  final String clear;

  /// Closes the scratchpad.
  final String close;

  /// Shown when a recording list is empty.
  final String noRecordings;

  /// Shown on a recording that failed to play.
  final String playbackError;

  /// Screen-reader name of the play button of the recording with this title.
  final String Function(String title) playRecordingLabel;

  /// Screen-reader name of the pause button of the recording with this title.
  final String Function(String title) pauseRecordingLabel;

  /// Screen-reader name of the delete button of the recording with this title.
  final String Function(String title) deleteRecordingLabel;

  /// Screen-reader name of the speed button; receives [speedLabel]'s text.
  final String Function(String speed) playbackSpeedLabel;

  /// Text of the speed button, such as `1.25×`.
  final String Function(double speed) speedLabel;

  /// Names the 1-based page a recording is attached to.
  final String Function(int pageNumber) pageLabel;

  /// The message for a calculator [error].
  String calculatorError(NoteCalculatorError error) => switch (error) {
    NoteCalculatorError.syntax => calculatorSyntaxError,
    NoteCalculatorError.divisionByZero => calculatorDivisionByZeroError,
    NoteCalculatorError.domain => calculatorDomainError,
    NoteCalculatorError.overflow => calculatorOverflowError,
  };

  /// Default [timeStepLabel]: `+01:00` or `−01:00`.
  static String defaultTimeStepLabel(Duration step) =>
      '${step.isNegative ? '−' : '+'}${NoteDurationFormat.clock(step.abs())}';

  /// Default [lapTitle]: `Lap 3`.
  static String defaultLapTitle(int number) => 'Lap $number';

  /// Default [speedLabel]: trailing zeros trimmed, as in `1×` or `0.75×`.
  static String defaultSpeedLabel(double speed) {
    final fixed = speed.toStringAsFixed(2);
    final trimmed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');

    return '$trimmed×';
  }

  /// Default [pageLabel]: `Page 3`.
  static String defaultPageLabel(int pageNumber) => 'Page $pageNumber';

  /// Default [playRecordingLabel].
  static String defaultPlayRecordingLabel(String title) => 'Play $title';

  /// Default [pauseRecordingLabel].
  static String defaultPauseRecordingLabel(String title) => 'Pause $title';

  /// Default [deleteRecordingLabel].
  static String defaultDeleteRecordingLabel(String title) => 'Delete $title';

  /// Default [playbackSpeedLabel].
  static String defaultPlaybackSpeedLabel(String speed) =>
      'Playback speed $speed';

  /// Default [calculatorKeyText].
  static String defaultCalculatorKeyText(NoteCalculatorKey key) =>
      switch (key) {
        NoteCalculatorKey.decimalPoint => '.',
        NoteCalculatorKey.add => '+',
        NoteCalculatorKey.subtract => '−',
        NoteCalculatorKey.multiply => '×',
        NoteCalculatorKey.divide => '÷',
        NoteCalculatorKey.power => '^',
        NoteCalculatorKey.percent => '%',
        NoteCalculatorKey.openParenthesis => '(',
        NoteCalculatorKey.closeParenthesis => ')',
        NoteCalculatorKey.sqrt => '√',
        NoteCalculatorKey.pi => 'π',
        NoteCalculatorKey.clear => 'C',
        NoteCalculatorKey.backspace => '⌫',
        NoteCalculatorKey.equals => '=',
        NoteCalculatorKey.memoryClear => 'MC',
        NoteCalculatorKey.memoryRecall => 'MR',
        NoteCalculatorKey.memoryAdd => 'M+',
        NoteCalculatorKey.memorySubtract => 'M−',
        _ => key.digit?.toString() ?? key.name,
      };

  /// Default [calculatorKeyLabel].
  static String defaultCalculatorKeyLabel(NoteCalculatorKey key) =>
      switch (key) {
        NoteCalculatorKey.decimalPoint => 'Decimal point',
        NoteCalculatorKey.add => 'Plus',
        NoteCalculatorKey.subtract => 'Minus',
        NoteCalculatorKey.multiply => 'Multiply',
        NoteCalculatorKey.divide => 'Divide',
        NoteCalculatorKey.power => 'Power',
        NoteCalculatorKey.percent => 'Percent',
        NoteCalculatorKey.openParenthesis => 'Open parenthesis',
        NoteCalculatorKey.closeParenthesis => 'Close parenthesis',
        NoteCalculatorKey.sqrt => 'Square root',
        NoteCalculatorKey.sin => 'Sine',
        NoteCalculatorKey.cos => 'Cosine',
        NoteCalculatorKey.tan => 'Tangent',
        NoteCalculatorKey.log => 'Logarithm base 10',
        NoteCalculatorKey.ln => 'Natural logarithm',
        NoteCalculatorKey.abs => 'Absolute value',
        NoteCalculatorKey.pi => 'Pi',
        NoteCalculatorKey.e => "Euler's number",
        NoteCalculatorKey.clear => 'Clear',
        NoteCalculatorKey.backspace => 'Backspace',
        NoteCalculatorKey.equals => 'Equals',
        NoteCalculatorKey.memoryClear => 'Clear memory',
        NoteCalculatorKey.memoryRecall => 'Recall memory',
        NoteCalculatorKey.memoryAdd => 'Add to memory',
        NoteCalculatorKey.memorySubtract => 'Subtract from memory',
        _ => key.digit?.toString() ?? key.name,
      };
}
