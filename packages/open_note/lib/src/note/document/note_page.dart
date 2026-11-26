import 'package:flutter/painting.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/layer/note_layer.dart';
import 'package:open_note/src/note/layer/note_layer_content.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// A saved snapshot of one page: its size, paper, margin extension, ink layers
/// and objects. Editing produces new snapshots (see `NotePageSession`).
///
/// Coordinates: ink and objects are relative to the top-left corner of the
/// whole page. The paper covers [contentRect]; extended margins around it show
/// [marginTemplate] (or the paper continued).
///
/// JSON (ink excluded, it is stored per layer): `{id, size: {w, h}, template,
/// margins: {left, top, right, bottom}, marginTemplate?, paperTurns: 0..3,
/// autoGrows?, pdf?, layers: [NoteLayer], activeLayerId, objects: [...],
/// createdAt, modifiedAt}`.
class NotePage {
  NotePage({
    required this.id,
    required this.size,
    required this.template,
    required List<NoteLayerContent> layers,
    required this.createdAt,
    DateTime? modifiedAt,
    this.margins = EdgeInsets.zero,
    this.marginTemplate,
    this.paperTurns = 0,
    this.autoGrows = false,
    this.pdf,
    String? activeLayerId,
    List<NoteObject> objects = const [],
  }) : assert(layers.isNotEmpty, 'a page has at least one layer'),
       assert(paperTurns >= 0 && paperTurns < 4),
       assert(margins.isNonNegative),
       layers = List.unmodifiable(layers),
       objects = List.unmodifiable(objects),
       activeLayerId =
           layers.any((content) => content.layer.id == activeLayerId)
           ? activeLayerId!
           : layers.last.layer.id,
       modifiedAt = modifiedAt ?? createdAt;

  /// An empty page of [size] (default: the template's size) with one layer.
  factory NotePage.blank({
    required NotePaperTemplate template,
    NotePageSize? size,
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
    String layerName = 'Layer 1',
  }) {
    final pageSize = size ?? template.size;

    return NotePage(
      id: idFactory(),
      size: pageSize,
      template: template.fitted(pageSize),
      layers: [
        NoteLayerContent(
          layer: NoteLayer(id: idFactory(), name: layerName),
        ),
      ],
      createdAt: clock(),
    );
  }

  /// Decodes a page. [ink] holds the decoded scribble of each layer id (a
  /// missing one is empty); objects are rebuilt with [registry]. Returns null
  /// when [value] has no id.
  static NotePage? fromJson(
    Object? value, {
    required NoteObjectRegistry registry,
    Map<String, Scribble> ink = const {},
    NoteClock clock = systemNoteClock,
  }) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final id = NoteJson.string(json, 'id');
    if (id.isEmpty) return null;
    final size = NotePageSize.fromJson(json['size']);
    final template = NotePaperTemplate.fromJson(json['template']);
    final layers = <NoteLayerContent>[];
    for (final (index, raw) in NoteJson.list(json, 'layers').indexed) {
      final layer = NoteLayer.fromJson(raw, fallbackId: '$id-layer-$index');
      if (layers.any((content) => content.layer.id == layer.id)) continue;
      layers.add(NoteLayerContent(layer: layer, scribble: ink[layer.id]));
    }
    if (layers.isEmpty) {
      layers.add(
        NoteLayerContent(
          layer: NoteLayer(id: '$id-layer-0', name: 'Layer 1'),
        ),
      );
    }
    final margins = NoteJson.map(json, 'margins');
    double inset(String key) =>
        NoteJson.number(margins, key).clamp(0, size.width + size.height);
    final createdAt = _date(json, 'createdAt') ?? clock();

    return NotePage(
      id: id,
      size: size,
      template: template,
      layers: layers,
      createdAt: createdAt,
      modifiedAt: _date(json, 'modifiedAt'),
      margins: EdgeInsets.fromLTRB(
        inset('left'),
        inset('top'),
        inset('right'),
        inset('bottom'),
      ),
      marginTemplate: json['marginTemplate'] == null
          ? null
          : NotePaperTemplate.fromJson(json['marginTemplate']),
      paperTurns: NoteJson.integer(json, 'paperTurns') % 4,
      autoGrows: NoteJson.boolean(json, 'autoGrows'),
      pdf: NotePdfOrigin.fromJson(json['pdf']),
      activeLayerId: NoteJson.stringOrNull(json, 'activeLayerId'),
      objects: registry.decodeAll(NoteJson.list(json, 'objects')),
    );
  }

  /// Stable across reordering; bookmarks, outline entries, excerpts and links
  /// refer to it.
  final String id;

  /// The whole page, extended margins included.
  final NotePageSize size;

  /// The paper under [contentRect], described before [paperTurns].
  final NotePaperTemplate template;

  /// Extra space added around the paper, for notes in the margin.
  final EdgeInsets margins;

  /// Paper for the extended margins; null continues [template].
  final NotePaperTemplate? marginTemplate;

  /// Clockwise quarter turns applied to the paper (set by rotating the page).
  final int paperTurns;

  /// Whether the page is endless: the editor extends its margins as writing
  /// gets near an edge (growing left or up moves the content along).
  final bool autoGrows;

  /// The PDF page this page was imported from, if any.
  final NotePdfOrigin? pdf;

  /// Ink layers, bottom to top; at least one.
  final List<NoteLayerContent> layers;
  final String activeLayerId;

  /// Objects above the ink, bottom to top.
  final List<NoteObject> objects;

  final DateTime createdAt;
  final DateTime modifiedAt;

  /// The area inside the extended margins.
  Rect get contentRect => margins.deflateRect(size.toRect());

  /// The size the paper is ruled at, before [paperTurns].
  NotePageSize get paperSize {
    final content = contentRect;
    final width = content.width < 1 ? 1.0 : content.width;
    final height = content.height < 1 ? 1.0 : content.height;

    return paperTurns.isOdd
        ? NotePageSize(height, width)
        : NotePageSize(width, height);
  }

  /// Whether any layer holds a stroke, text or image.
  bool get hasInk => layers.any((content) => !content.isEmpty);

  /// Whether the page holds ink or objects.
  bool get hasContent => hasInk || objects.isNotEmpty;

  NotePage copyWith({
    NotePageSize? size,
    NotePaperTemplate? template,
    EdgeInsets? margins,
    NotePaperTemplate? Function()? marginTemplate,
    int? paperTurns,
    bool? autoGrows,
    NotePdfOrigin? pdf,
    List<NoteLayerContent>? layers,
    String? activeLayerId,
    List<NoteObject>? objects,
    DateTime? modifiedAt,
  }) => NotePage(
    id: id,
    size: size ?? this.size,
    template: template ?? this.template,
    margins: margins ?? this.margins,
    marginTemplate: marginTemplate == null
        ? this.marginTemplate
        : marginTemplate(),
    paperTurns: paperTurns ?? this.paperTurns,
    autoGrows: autoGrows ?? this.autoGrows,
    pdf: pdf ?? this.pdf,
    layers: layers ?? this.layers,
    activeLayerId: activeLayerId ?? this.activeLayerId,
    objects: objects ?? this.objects,
    createdAt: createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
  );

  JsonMap toJson() => {
    'id': id,
    'size': size.toJson(),
    'template': template.toJson(),
    'margins': {
      'left': margins.left,
      'top': margins.top,
      'right': margins.right,
      'bottom': margins.bottom,
    },
    if (marginTemplate != null) 'marginTemplate': marginTemplate!.toJson(),
    'paperTurns': paperTurns,
    if (autoGrows) 'autoGrows': true,
    if (pdf != null) 'pdf': pdf!.toJson(),
    'layers': [for (final content in layers) content.layer.toJson()],
    'activeLayerId': activeLayerId,
    'objects': [for (final object in objects) object.toJson()],
    'createdAt': createdAt.toUtc().toIso8601String(),
    'modifiedAt': modifiedAt.toUtc().toIso8601String(),
  };

  static DateTime? _date(JsonMap json, String key) =>
      DateTime.tryParse(NoteJson.string(json, key));
}
