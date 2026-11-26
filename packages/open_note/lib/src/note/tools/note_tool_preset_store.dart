import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/note_ink_types.dart';
import 'package:open_note/src/note/tools/note_preset_store.dart';
import 'package:open_note/src/note/tools/note_tool_preset.dart';
import 'package:open_note/src/note/tools/note_tools_strings.dart';

/// The user's pen favourites, in order, with the selected one.
///
/// See [NotePresetStore] for the shared rules. Persisted under [key].
class NoteToolPresetStore extends NotePresetStore<NoteToolPreset> {
  /// [NoteStore] key of the persisted presets.
  static const String key = 'tools/presets.json';

  /// Id of the default black pen.
  static const String blackPenId = 'default.pen.black';

  /// Id of the default red pen.
  static const String redPenId = 'default.pen.red';

  /// Id of the default blue pen.
  static const String bluePenId = 'default.pen.blue';

  /// Id of the default white pen.
  static const String whitePenId = 'default.pen.white';

  /// Id of the default yellow marker.
  static const String yellowMarkerId = 'default.marker.yellow';

  /// Creates a store; see [NotePresetStore.new].
  NoteToolPresetStore({
    super.presets,
    super.activeId,
    super.maxPresets,
    super.idFactory,
  });

  /// A store holding [defaultPresets] with the black pen selected.
  factory NoteToolPresetStore.defaults({
    NoteToolsStrings strings = const NoteToolsStrings(),
    int maxPresets = NotePresetStore.defaultMaxPresets,
    NoteIdFactory? idFactory,
  }) => NoteToolPresetStore(
    presets: defaultPresets(strings),
    activeId: blackPenId,
    maxPresets: maxPresets,
    idFactory: idFactory,
  );

  @override
  String get storageKey => key;

  /// Black (0.5), red (0.8), blue (1.2) and white (2) pens and a translucent
  /// yellow marker (4), named from [strings].
  static List<NoteToolPreset> defaultPresets([
    NoteToolsStrings strings = const NoteToolsStrings(),
  ]) => [
    NoteToolPreset(
      id: blackPenId,
      name: strings.blackPen,
      ink: NoteInkTypes.pen,
      color: const Color(0xFF000000),
      width: 0.5,
    ),
    NoteToolPreset(
      id: redPenId,
      name: strings.redPen,
      ink: NoteInkTypes.pen,
      color: const Color(0xFFE53935),
      width: 0.8,
    ),
    NoteToolPreset(
      id: bluePenId,
      name: strings.bluePen,
      ink: NoteInkTypes.pen,
      color: const Color(0xFF1E88E5),
      width: 1.2,
    ),
    NoteToolPreset(
      id: whitePenId,
      name: strings.whitePen,
      ink: NoteInkTypes.pen,
      color: const Color(0xFFFFFFFF),
      width: 2,
    ),
    NoteToolPreset(
      id: yellowMarkerId,
      name: strings.yellowMarker,
      ink: NoteInkTypes.marker,
      color: const Color(0x7FFFE400),
      width: 4,
    ),
  ];

  /// Creates a preset with a new id and appends it; selects it unless [select]
  /// is false. Returns `null` when the store is full or disposed.
  NoteToolPreset? addFrom({
    required String ink,
    required Color color,
    required double width,
    String name = '',
    String lineStyle = NoteToolPreset.defaultLineStyle,
    String shapeTarget = '',
    bool select = true,
  }) {
    final preset = NoteToolPreset(
      id: idFactory(),
      name: name,
      ink: ink,
      color: color,
      width: width,
      lineStyle: lineStyle,
      shapeTarget: shapeTarget,
    );

    return add(preset, select: select) ? preset : null;
  }

  /// The presets that draw with [ink], in display order.
  List<NoteToolPreset> byInk(String ink) => [
    for (final preset in presets)
      if (preset.ink == ink) preset,
  ];

  @override
  NoteToolPreset decodePreset(JsonMap json) => NoteToolPreset.fromJson(json);
}
