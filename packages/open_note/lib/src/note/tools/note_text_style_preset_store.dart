import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/note_preset_store.dart';
import 'package:open_note/src/note/tools/note_text_style_align.dart';
import 'package:open_note/src/note/tools/note_text_style_preset.dart';
import 'package:open_note/src/note/tools/note_tools_strings.dart';

/// The user's text styles, in order, with the selected one.
///
/// See [NotePresetStore] for the shared rules. Persisted under [key].
class NoteTextStylePresetStore extends NotePresetStore<NoteTextStylePreset> {
  /// [NoteStore] key of the persisted styles.
  static const String key = 'tools/text_styles.json';

  /// Id of the default title style.
  static const String titleId = 'default.text.title';

  /// Id of the default heading style.
  static const String headingId = 'default.text.heading';

  /// Id of the default body style.
  static const String bodyId = 'default.text.body';

  /// Id of the default caption style.
  static const String captionId = 'default.text.caption';

  /// Creates a store; see [NotePresetStore.new].
  NoteTextStylePresetStore({
    super.presets,
    super.activeId,
    super.maxPresets,
    super.idFactory,
  });

  /// A store holding [defaultPresets] with the body style selected.
  factory NoteTextStylePresetStore.defaults({
    NoteToolsStrings strings = const NoteToolsStrings(),
    int maxPresets = NotePresetStore.defaultMaxPresets,
    NoteIdFactory? idFactory,
  }) => NoteTextStylePresetStore(
    presets: defaultPresets(strings),
    activeId: bodyId,
    maxPresets: maxPresets,
    idFactory: idFactory,
  );

  @override
  String get storageKey => key;

  /// Title (24, bold), heading (18, bold), body (14) and caption (11, grey)
  /// styles, named from [strings].
  static List<NoteTextStylePreset> defaultPresets([
    NoteToolsStrings strings = const NoteToolsStrings(),
  ]) => [
    NoteTextStylePreset(
      id: titleId,
      name: strings.titleStyle,
      fontSize: 24,
      bold: true,
    ),
    NoteTextStylePreset(
      id: headingId,
      name: strings.headingStyle,
      fontSize: 18,
      bold: true,
    ),
    NoteTextStylePreset(id: bodyId, name: strings.bodyStyle),
    NoteTextStylePreset(
      id: captionId,
      name: strings.captionStyle,
      fontSize: 11,
      color: const Color(0xFF616161),
    ),
  ];

  /// Creates a style with a new id and appends it; selects it unless [select]
  /// is false. Returns `null` when the store is full or disposed.
  NoteTextStylePreset? addFrom({
    String name = '',
    String fontFamily = '',
    double fontSize = NoteTextStylePreset.defaultFontSize,
    double lineHeight = 0,
    Color color = const Color(0xFF000000),
    bool bold = false,
    bool italic = false,
    bool underline = false,
    NoteTextStyleAlign align = NoteTextStyleAlign.left,
    bool select = true,
  }) {
    final preset = NoteTextStylePreset(
      id: idFactory(),
      name: name,
      fontFamily: fontFamily,
      fontSize: fontSize,
      lineHeight: lineHeight,
      color: color,
      bold: bold,
      italic: italic,
      underline: underline,
      align: align,
    );

    return add(preset, select: select) ? preset : null;
  }

  @override
  NoteTextStylePreset decodePreset(JsonMap json) =>
      NoteTextStylePreset.fromJson(json);
}
