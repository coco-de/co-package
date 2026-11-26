import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_page_size.dart';
import 'package:open_note/src/note/layer/note_layer_strings.dart';
import 'package:open_note/src/note/nav/note_nav_strings.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_strings.dart';
import 'package:open_note/src/note/style/note_shape_kind.dart';
import 'package:open_note/src/note/table/note_table_strings.dart';
import 'package:open_note/src/note/template/note_paper_strings.dart';
import 'package:open_note/src/note/tools/note_tools_strings.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';

/// Every label of `NoteEditorView`, in English by default, and the labels of
/// the module widgets it shows — translate them all in one place.
@immutable
class NoteEditorStrings {
  const NoteEditorStrings({
    this.tools = const NoteToolsStrings(),
    this.layers = const NoteLayerStrings(),
    this.nav = const NoteNavStrings(),
    this.objects = const NoteObjectsStrings(),
    this.table = const NoteTableStrings(),
    this.paper = const NotePaperStrings(),
    this.studyOverlay = const NoteStudyOverlayStrings(),
    this.studyUtilities = const NoteStudyUtilitiesStrings(),
    this.view = const NoteViewStrings(),
    this.back = 'Back',
    this.previousPage = 'Previous page',
    this.nextPage = 'Next page',
    this.pageCounter = defaultPageCounter,
    this.addPage = 'Add page',
    this.pageMenu = 'Page',
    this.viewMenu = 'View',
    this.studyMenu = 'Study',
    this.export = 'Export PDF',
    this.close = 'Close',
    this.saving = 'Saving…',
    this.saved = 'Saved',
    this.saveFailed = 'Save failed — retry',
    this.unsaved = 'Save',
    this.drawMode = 'Draw',
    this.objectMode = 'Select',
    this.readMode = 'Read',
    this.maskMode = 'Cover',
    this.regionMode = 'Capture',
    this.pdfTextMode = 'PDF text',
    this.highlightText = 'Highlight',
    this.underlineText = 'Underline',
    this.strikeOutText = 'Strike out',
    this.copyText = 'Copy text',
    this.clearSelection = 'Clear',
    this.selectTextHint = 'Drag across the text to select it',
    this.readingPdfText = 'Reading text…',
    this.noPdfText = 'No selectable text on this page',
    this.pdfTextFailed = 'The text could not be read',
    this.layerCannotMark = 'Show and unlock the layer to mark text',
    this.layersPanel = 'Layers',
    this.pagesPanel = 'Pages',
    this.bookmarksPanel = 'Bookmarks',
    this.outlinePanel = 'Outline',
    this.bookmark = 'Bookmark',
    this.removeBookmark = 'Remove bookmark',
    this.addToOutline = 'Add page to outline',
    this.outlineTitle = defaultOutlineTitle,
    this.pen = 'Pen',
    this.pencil = 'Pencil',
    this.marker = 'Marker',
    this.eraser = 'Eraser',
    this.lasso = 'Lasso',
    this.shape = 'Shape',
    this.text = 'Text',
    this.image = 'Image',
    this.undo = 'Undo',
    this.redo = 'Redo',
    this.presets = 'Favourites',
    this.moreColors = 'More colours',
    this.colorName = defaultColorName,
    this.width = 'Width',
    this.solidLine = 'Solid',
    this.dashedLine = 'Dashed',
    this.dottedLine = 'Dotted',
    this.wavyLine = 'Wavy',
    this.zigzagLine = 'Zigzag',
    this.doubleLine = 'Double',
    this.dashLength = 'Dash',
    this.dashGap = 'Gap',
    this.waveHeight = 'Wave height',
    this.waveLength = 'Wave length',
    this.doubleSpacing = 'Spacing',
    this.textBox = 'Text box',
    this.fontSize = 'Size',
    this.penSettings = 'Pen settings',
    this.saveFavorite = 'Save favourite',
    this.fingerDrawing = 'Finger drawing',
    this.holdToSnap = 'Hold to make shapes',
    this.strokeEraser = 'Whole stroke',
    this.pixelEraser = 'Partial',
    this.eraserSettings = 'Eraser settings',
    this.rectangleLasso = 'Box lasso',
    this.freeformLasso = 'Free lasso',
    this.recolor = 'Recolour',
    this.thinner = 'Thinner',
    this.thicker = 'Thicker',
    this.outlineEffect = 'Outline text',
    this.moveToLayer = defaultMoveToLayer,
    this.deselect = 'Deselect',
    this.autoShape = 'Auto',
    this.shapeName = defaultShapeName,
    this.fill = 'Fill',
    this.roundedCorners = 'Rounded',
    this.addImages = 'Add pictures',
    this.imageFrame = 'Frame',
    this.imageOpacity = 'Opacity',
    this.cropImage = 'Crop',
    this.freeCrop = 'Free crop',
    this.rectangleCrop = 'Box crop',
    this.applyCrop = 'Apply',
    this.wholeImage = 'Whole picture',
    this.cancel = 'Cancel',
    this.addBefore = 'Add before',
    this.addAfter = 'Add after',
    this.addAtEnd = 'Add at end',
    this.addLandscape = 'Add landscape page',
    this.duplicatePage = 'Duplicate page',
    this.deletePage = 'Delete page',
    this.rotatePage = 'Rotate',
    this.extendRight = 'Extend right margin',
    this.extendBottom = 'Extend bottom margin',
    this.removeMargins = 'Remove margins',
    this.changePaper = 'Paper',
    this.paperForAllPages = 'Apply to every page',
    this.movePageEarlier = 'Move earlier',
    this.movePageLater = 'Move later',
    this.onlyPagesWithInk = 'Pages with ink only',
    this.restoreDeleted = defaultRestoreDeleted,
    this.normalColors = 'Normal colours',
    this.nightMode = 'Night',
    this.eyeProtect = 'Eye comfort',
    this.ruler = 'Ruler',
    this.magnifier = 'Magnifier',
    this.zoomLock = 'Lock zoom',
    this.fitPage = 'Fit page',
    this.fullScreen = 'Full screen',
    this.exitFullScreen = 'Exit full screen',
    this.stickyNote = 'Sticky note',
    this.arrow = 'Arrow',
    this.curve = 'Curve',
    this.straighten = 'Straighten',
    this.bendLine = 'Bend line',
    this.tableObject = 'Table',
    this.linkArea = 'Link',
    this.tape = 'Tape',
    this.sticker = 'Sticker',
    this.noStickers = 'No stickers yet',
    this.duplicate = 'Duplicate',
    this.delete = 'Delete',
    this.bringToFront = 'To front',
    this.sendToBack = 'To back',
    this.lock = 'Lock',
    this.unlock = 'Unlock',
    this.linkHint = 'https://…, page:3 or note:id',
    this.linkToPage = 'Link to a page',
    this.pageOption = defaultPageOption,
    this.dashed = 'Dashed arrow',
    this.maskBox = 'Box',
    this.maskPenShape = 'Pen',
    this.maskEveryPage = 'On every page',
    this.revealAll = 'Reveal all',
    this.coverAll = 'Cover all',
    this.removeCovers = 'Remove covers',
    this.regionHint = 'Drag over the part to capture',
    this.makeSticker = 'Make sticker',
    this.saveExcerpt = 'Save excerpt',
    this.askAi = 'Ask AI',
    this.captureCollection = 'Captures',
    this.excerptLabel = 'Excerpt',
    this.excerptsPanel = 'Excerpts',
    this.pageTags = 'Page tags',
    this.toolbarSettings = 'Toolbar',
    this.toolbarTop = 'Top',
    this.toolbarBottom = 'Bottom',
    this.toolbarLeft = 'Left',
    this.toolbarRight = 'Right',
    this.toolbarFloating = 'Floating',
    this.showItem = 'Show',
    this.hideItem = 'Hide',
    this.moveUp = 'Move up',
    this.moveDown = 'Move down',
    this.cornerRadius = 'Corner radius',
    this.opacity = 'Opacity',
    this.fillOpacity = 'Fill opacity',
    this.textBorder = 'Border box',
    this.textDashedBorder = 'Dashed box',
    this.importPages = 'Import pages…',
    this.goToWriting = 'Go to writing',
    this.saveZoom = 'Save this zoom',
    this.swipeHorizontal = 'Swipe sideways to turn pages',
    this.swipeVertical = 'Swipe up and down to turn pages',
    this.record = 'Record',
    this.stopRecording = 'Stop recording',
    this.attachments = 'Attachments',
    this.attachFile = 'Attach a file',
    this.noAttachments = 'No attachments yet',
    this.openAttachment = 'Open',
    this.removeAttachment = 'Remove',
    this.pageSizeName = defaultPageSizeName,
    this.newPageOfSize = defaultNewPageOfSize,
    this.zoomLevel = defaultZoomLevel,
    this.endlessPage = 'Endless page (grows as you write)',
    this.calculator = 'Calculator',
    this.timer = 'Timer',
    this.stopwatch = 'Stopwatch',
    this.scratchpad = 'Scratchpad',
    this.recordings = 'Recordings',
  });

  final NoteToolsStrings tools;
  final NoteLayerStrings layers;
  final NoteNavStrings nav;
  final NoteObjectsStrings objects;
  final NoteTableStrings table;
  final NotePaperStrings paper;
  final NoteStudyOverlayStrings studyOverlay;
  final NoteStudyUtilitiesStrings studyUtilities;
  final NoteViewStrings view;

  final String back;
  final String previousPage;
  final String nextPage;

  /// The page indicator; [label] is the printed page number.
  final String Function(String label, int index, int count) pageCounter;

  final String addPage;
  final String pageMenu;
  final String viewMenu;
  final String studyMenu;
  final String export;
  final String close;
  final String saving;
  final String saved;
  final String saveFailed;
  final String unsaved;
  final String drawMode;
  final String objectMode;
  final String readMode;
  final String maskMode;
  final String regionMode;

  /// The PDF text mode and its actions.
  final String pdfTextMode;
  final String highlightText;
  final String underlineText;
  final String strikeOutText;
  final String copyText;
  final String clearSelection;
  final String selectTextHint;
  final String readingPdfText;
  final String noPdfText;
  final String pdfTextFailed;
  final String layerCannotMark;
  final String layersPanel;
  final String pagesPanel;
  final String bookmarksPanel;
  final String outlinePanel;
  final String bookmark;
  final String removeBookmark;
  final String addToOutline;
  final String Function(String pageLabel) outlineTitle;
  final String pen;
  final String pencil;
  final String marker;
  final String eraser;
  final String lasso;
  final String shape;
  final String text;
  final String image;
  final String undo;
  final String redo;
  final String presets;
  final String moreColors;

  /// The spoken name of a colour swatch (`#rrggbb` by default).
  final String Function(int argb) colorName;

  final String width;
  final String solidLine;
  final String dashedLine;
  final String dottedLine;
  final String wavyLine;
  final String zigzagLine;
  final String doubleLine;
  final String dashLength;
  final String dashGap;
  final String waveHeight;
  final String waveLength;
  final String doubleSpacing;
  final String textBox;
  final String fontSize;
  final String penSettings;
  final String saveFavorite;
  final String fingerDrawing;
  final String holdToSnap;
  final String strokeEraser;
  final String pixelEraser;
  final String eraserSettings;
  final String rectangleLasso;
  final String freeformLasso;
  final String recolor;
  final String thinner;
  final String thicker;
  final String outlineEffect;
  final String Function(String layerName) moveToLayer;
  final String deselect;
  final String autoShape;
  final String Function(NoteShapeKind kind) shapeName;
  final String fill;
  final String roundedCorners;
  final String addImages;
  final String imageFrame;
  final String imageOpacity;
  final String cropImage;
  final String freeCrop;
  final String rectangleCrop;
  final String applyCrop;
  final String wholeImage;
  final String cancel;
  final String addBefore;
  final String addAfter;
  final String addAtEnd;
  final String addLandscape;
  final String duplicatePage;
  final String deletePage;
  final String rotatePage;
  final String extendRight;
  final String extendBottom;
  final String removeMargins;
  final String changePaper;
  final String paperForAllPages;
  final String movePageEarlier;
  final String movePageLater;
  final String onlyPagesWithInk;
  final String Function(int count) restoreDeleted;
  final String normalColors;
  final String nightMode;
  final String eyeProtect;
  final String ruler;
  final String magnifier;
  final String zoomLock;
  final String fitPage;
  final String fullScreen;
  final String exitFullScreen;
  final String stickyNote;
  final String arrow;
  final String curve;
  final String straighten;

  /// The name of the grip that bends a line.
  final String bendLine;
  final String tableObject;
  final String linkArea;
  final String tape;
  final String sticker;
  final String noStickers;
  final String duplicate;
  final String delete;
  final String bringToFront;
  final String sendToBack;
  final String lock;
  final String unlock;
  final String linkHint;
  final String linkToPage;
  final String Function(String pageLabel) pageOption;
  final String dashed;
  final String maskBox;
  final String maskPenShape;
  final String maskEveryPage;
  final String revealAll;
  final String coverAll;
  final String removeCovers;
  final String regionHint;
  final String makeSticker;
  final String saveExcerpt;
  final String askAi;

  /// The sticker collection captured regions go to.
  final String captureCollection;

  final String excerptLabel;
  final String excerptsPanel;
  final String pageTags;
  final String toolbarSettings;
  final String toolbarTop;
  final String toolbarBottom;
  final String toolbarLeft;
  final String toolbarRight;
  final String toolbarFloating;
  final String showItem;
  final String hideItem;
  final String moveUp;
  final String moveDown;
  final String cornerRadius;
  final String opacity;
  final String fillOpacity;
  final String textBorder;
  final String textDashedBorder;
  final String importPages;
  final String goToWriting;
  final String saveZoom;
  final String swipeHorizontal;
  final String swipeVertical;
  final String record;
  final String stopRecording;
  final String attachments;
  final String attachFile;
  final String noAttachments;
  final String openAttachment;
  final String removeAttachment;
  final String Function(NotePageSize size) pageSizeName;
  final String Function(String sizeName) newPageOfSize;
  final String Function(int percent) zoomLevel;
  final String endlessPage;
  final String calculator;
  final String timer;
  final String stopwatch;
  final String scratchpad;
  final String recordings;

  static String defaultPageCounter(String label, int index, int count) =>
      label == '${index + 1}'
      ? '${index + 1} / $count'
      : '$label (${index + 1} / $count)';

  static String defaultOutlineTitle(String pageLabel) => 'Page $pageLabel';

  static String defaultColorName(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String defaultMoveToLayer(String layerName) => 'Move to $layerName';

  static String defaultShapeName(NoteShapeKind kind) {
    final name = kind.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => ' ${match[0]!.toLowerCase()}',
    );

    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  static String defaultRestoreDeleted(int count) => 'Restore deleted ($count)';

  static String defaultPageOption(String pageLabel) => 'Page $pageLabel';

  static String defaultPageSizeName(NotePageSize size) => switch (size) {
    NotePageSize.a4 => 'A4',
    NotePageSize.a5 => 'A5',
    NotePageSize.letter => 'Letter',
    NotePageSize.square => 'Square',
    _ => '${size.width.round()}×${size.height.round()}',
  };

  static String defaultNewPageOfSize(String sizeName) => 'Add $sizeName page';

  static String defaultZoomLevel(int percent) => '$percent%';
}
