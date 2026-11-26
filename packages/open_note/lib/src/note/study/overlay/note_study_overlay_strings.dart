import 'package:open_note/src/note/study/overlay/note_ai_pen_exception.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_kind.dart';

/// Every user-visible text and accessibility label of the study overlay
/// widgets, with English defaults. Pass a translated instance as `strings:`.
///
/// Extend it to change how [errorMessage] reads, for example to show the
/// message an AI service sent.
class NoteStudyOverlayStrings {
  /// Creates the strings; every value defaults to English.
  const NoteStudyOverlayStrings({
    this.revealMask = 'Show what the mask hides',
    this.hideMask = 'Cover again',
    this.revealTape = 'Peel off the tape',
    this.hideTape = 'Stick the tape back',
    this.regionSelector = 'Select a region of the page',
    this.confirmRegion = 'Use this selection',
    this.cancelRegion = 'Cancel selection',
    this.solveTab = 'Solve',
    this.explainTab = 'Explain',
    this.translateTab = 'Translate',
    this.aiPanel = 'AI pen',
    this.aiIdleHint = 'Select a region to start.',
    this.aiBusy = 'Working…',
    this.aiCancel = 'Cancel',
    this.aiRetry = 'Try again',
    this.aiCopy = 'Copy',
    this.aiClose = 'Close',
    this.aiSteps = 'Steps',
    this.aiErrorNotConfigured = 'No AI service is set up.',
    this.aiErrorInvalidRequest = 'This selection cannot be processed.',
    this.aiErrorNetwork = 'The AI service could not be reached.',
    this.aiErrorUnknown = 'Something went wrong.',
    this.closeWindow = 'Close window',
    this.minimizeWindow = 'Minimize window',
    this.restoreWindow = 'Restore window',
    this.pinWindow = 'Keep window on top',
    this.unpinWindow = 'Stop keeping window on top',
    this.moveWindow = 'Move window',
    this.resizeWindow = 'Resize window',
  });

  /// Action of a hidden mask.
  final String revealMask;

  /// Action of a revealed mask.
  final String hideMask;

  /// Action of a tape that is stuck on.
  final String revealTape;

  /// Action of a peeled tape.
  final String hideTape;

  /// Label of the region selector.
  final String regionSelector;

  /// Button that accepts the selected region.
  final String confirmRegion;

  /// Button that abandons the selection.
  final String cancelRegion;

  /// AI pen tab that solves the selected problem.
  final String solveTab;

  /// AI pen tab that explains the selection.
  final String explainTab;

  /// AI pen tab that translates the selection.
  final String translateTab;

  /// Label of the AI pen result panel.
  final String aiPanel;

  /// Shown before anything ran.
  final String aiIdleHint;

  /// Shown while the service works.
  final String aiBusy;

  /// Button that cancels a running request.
  final String aiCancel;

  /// Button that runs the last request again.
  final String aiRetry;

  /// Button that copies the answer.
  final String aiCopy;

  /// Button that closes the panel.
  final String aiClose;

  /// Heading above the solution steps.
  final String aiSteps;

  /// Error text for [NoteAiPenErrorCode.notConfigured].
  final String aiErrorNotConfigured;

  /// Error text for [NoteAiPenErrorCode.invalidRequest].
  final String aiErrorInvalidRequest;

  /// Error text for [NoteAiPenErrorCode.network].
  final String aiErrorNetwork;

  /// Error text for [NoteAiPenErrorCode.unknown].
  final String aiErrorUnknown;

  /// Button that closes a floating window.
  final String closeWindow;

  /// Button that collapses a floating window to its title bar.
  final String minimizeWindow;

  /// Button that expands a minimized floating window.
  final String restoreWindow;

  /// Button that pins a floating window on top.
  final String pinWindow;

  /// Button that unpins a floating window.
  final String unpinWindow;

  /// Label of a window's draggable title bar.
  final String moveWindow;

  /// Label of a window's resize corner.
  final String resizeWindow;

  /// The tab title of [kind].
  String kindLabel(NoteAiPenKind kind) => switch (kind) {
    NoteAiPenKind.solve => solveTab,
    NoteAiPenKind.explain => explainTab,
    NoteAiPenKind.translate => translateTab,
  };

  /// The text shown for a failed request. The default depends only on
  /// [NoteAiPenException.code]; the exception's own message is for logs.
  String errorMessage(NoteAiPenException error) => switch (error.code) {
    NoteAiPenErrorCode.notConfigured => aiErrorNotConfigured,
    NoteAiPenErrorCode.invalidRequest => aiErrorInvalidRequest,
    NoteAiPenErrorCode.network => aiErrorNetwork,
    NoteAiPenErrorCode.unknown => aiErrorUnknown,
  };
}
