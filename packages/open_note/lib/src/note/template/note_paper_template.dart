import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_page_size.dart';
import 'package:open_note/src/note/style/note_style_values.dart';
import 'package:open_note/src/note/template/note_paper_image_fit.dart';
import 'package:open_note/src/note/template/note_paper_kind.dart';

/// An immutable paper: the background of a page.
///
/// Lengths are in page units (PDF points). [margins] are the insets of the
/// writable area, which also defines the layout of the ruling:
///
/// * `lined`: rules across the writable area, one [lineSpacing] apart.
/// * `grid` / `dotted`: a lattice of whole cells centred in the writable area.
/// * `cornell`: `margins.left` is the cue column, `margins.top` the title area
///   and `margins.bottom` the summary area; their dividers use [accentColor].
/// * `music`: five-line staves ([lineSpacing] between lines), nine spacings
///   apart, centred in the writable area.
///
/// Numbers are clamped: [lineSpacing] 6 – 120, [lineWidth] 0.25 – 4,
/// [imageOpacity] 0 – 1; non-finite ones take the default. Margins are made
/// non-negative and shrunk evenly when two opposite sides exceed the page.
/// Colours are rounded to 8 bits per channel.
///
/// JSON: `{id, name, kind, size: {w, h}, lineSpacing, lineWidth, lineColor,
/// backgroundColor, accentColor, margins: {left, top, right, bottom},
/// showMarginLine, imageSource?, imageFit, imageOpacity}` (colours are ARGB
/// integers). [NotePaperTemplate.fromJson] never throws: missing or bad fields
/// take the defaults of the kind, an unknown kind reads as `blank`, page sides
/// are limited to 1 – 14400 and a value that is not an object reads as the
/// built-in blank paper.
@immutable
class NotePaperTemplate {
  /// Smallest [lineSpacing].
  static const double minLineSpacing = 6;

  /// Largest [lineSpacing].
  static const double maxLineSpacing = 120;

  /// Smallest [lineWidth].
  static const double minLineWidth = 0.25;

  /// Largest [lineWidth].
  static const double maxLineWidth = 4;

  /// Default [lineWidth].
  static const double defaultLineWidth = 0.6;

  /// Largest page side read from JSON (the PDF limit).
  static const double maxPageSide = 14400;

  /// Default [backgroundColor].
  static const Color defaultBackgroundColor = Color(0xFFFFFFFF);

  /// Default [accentColor].
  static const Color defaultAccentColor = Color(0xFFE57373);

  /// Stable identifier, unique in a catalog.
  final String id;

  /// Display name. `NotePaperStrings.templateName` translates default names.
  final String name;

  /// What is drawn on the paper.
  final NotePaperKind kind;

  /// Page size the paper is made for.
  final NotePageSize size;

  /// Distance between rules, dots or staff lines.
  final double lineSpacing;

  /// Thickness of rules; dots have a radius of one and a half times this.
  final double lineWidth;

  /// Colour of rules and dots.
  final Color lineColor;

  /// Paper colour.
  final Color backgroundColor;

  /// Colour of the Cornell dividers and the margin line.
  final Color accentColor;

  /// Insets of the writable area from the page edges.
  final EdgeInsets margins;

  /// Draws a vertical [accentColor] line at `margins.left` (every kind except
  /// `cornell` and `image`).
  final bool showMarginLine;

  /// File path, URL or app identifier of the picture (`image` kind only).
  final String? imageSource;

  /// How the picture fills the page.
  final NotePaperImageFit imageFit;

  /// 0 – 1.
  final double imageOpacity;

  /// Creates a paper. Omitted values take the defaults of [kind].
  NotePaperTemplate({
    required this.id,
    this.name = '',
    this.kind = NotePaperKind.blank,
    this.size = NotePageSize.a4,
    double? lineSpacing,
    double lineWidth = defaultLineWidth,
    Color? lineColor,
    Color backgroundColor = defaultBackgroundColor,
    Color accentColor = defaultAccentColor,
    EdgeInsets? margins,
    this.showMarginLine = false,
    this.imageSource,
    this.imageFit = NotePaperImageFit.contain,
    double imageOpacity = 1,
  }) : lineSpacing = NoteStyleValues.clamped(
         lineSpacing,
         defaultLineSpacing(kind),
         minLineSpacing,
         maxLineSpacing,
       ),
       lineWidth = NoteStyleValues.clamped(
         lineWidth,
         defaultLineWidth,
         minLineWidth,
         maxLineWidth,
       ),
       lineColor = NoteStyleValues.quantise(
         lineColor ?? defaultLineColor(kind),
       ),
       backgroundColor = NoteStyleValues.quantise(backgroundColor),
       accentColor = NoteStyleValues.quantise(accentColor),
       margins = _fitMargins(margins ?? defaultMargins(kind, size), size),
       imageOpacity = NoteStyleValues.clamped(imageOpacity, 1, 0, 1);

  /// Plain paper.
  factory NotePaperTemplate.blank({
    String? id,
    String? name,
    NotePageSize size = NotePageSize.a4,
  }) => NotePaperTemplate._preset(NotePaperKind.blank, id, name, size);

  /// Ruled paper.
  factory NotePaperTemplate.lined({
    String? id,
    String? name,
    NotePageSize size = NotePageSize.a4,
    double? lineSpacing,
    double lineWidth = defaultLineWidth,
  }) => NotePaperTemplate._preset(
    NotePaperKind.lined,
    id,
    name,
    size,
    lineSpacing: lineSpacing,
    lineWidth: lineWidth,
  );

  /// Squared paper.
  factory NotePaperTemplate.grid({
    String? id,
    String? name,
    NotePageSize size = NotePageSize.a4,
    double? lineSpacing,
    double lineWidth = defaultLineWidth,
  }) => NotePaperTemplate._preset(
    NotePaperKind.grid,
    id,
    name,
    size,
    lineSpacing: lineSpacing,
    lineWidth: lineWidth,
  );

  /// Dot-grid paper.
  factory NotePaperTemplate.dotted({
    String? id,
    String? name,
    NotePageSize size = NotePageSize.a4,
    double? lineSpacing,
    double lineWidth = defaultLineWidth,
  }) => NotePaperTemplate._preset(
    NotePaperKind.dotted,
    id,
    name,
    size,
    lineSpacing: lineSpacing,
    lineWidth: lineWidth,
  );

  /// Cornell note paper.
  factory NotePaperTemplate.cornell({
    String? id,
    String? name,
    NotePageSize size = NotePageSize.a4,
    double? lineSpacing,
    double lineWidth = defaultLineWidth,
  }) => NotePaperTemplate._preset(
    NotePaperKind.cornell,
    id,
    name,
    size,
    lineSpacing: lineSpacing,
    lineWidth: lineWidth,
  );

  /// Staff paper.
  factory NotePaperTemplate.music({
    String? id,
    String? name,
    NotePageSize size = NotePageSize.a4,
    double? lineSpacing,
    double lineWidth = defaultLineWidth,
  }) => NotePaperTemplate._preset(
    NotePaperKind.music,
    id,
    name,
    size,
    lineSpacing: lineSpacing,
    lineWidth: lineWidth,
  );

  /// A picture as paper. Give it your own [id].
  factory NotePaperTemplate.image({
    required String id,
    required String imageSource,
    String? name,
    NotePageSize size = NotePageSize.a4,
    NotePaperImageFit imageFit = NotePaperImageFit.contain,
    double imageOpacity = 1,
  }) => NotePaperTemplate(
    id: id,
    name: name ?? defaultName(NotePaperKind.image),
    kind: NotePaperKind.image,
    size: size,
    imageSource: imageSource,
    imageFit: imageFit,
    imageOpacity: imageOpacity,
  );

  factory NotePaperTemplate._preset(
    NotePaperKind kind,
    String? id,
    String? name,
    NotePageSize size, {
    double? lineSpacing,
    double lineWidth = defaultLineWidth,
  }) => NotePaperTemplate(
    id: id ?? builtInId(kind),
    name: name ?? defaultName(kind),
    kind: kind,
    size: size,
    lineSpacing: lineSpacing,
    lineWidth: lineWidth,
  );

  /// Reads [toJson]; never throws.
  factory NotePaperTemplate.fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return NotePaperTemplate.blank();
    final kind = NoteJson.enumByName(
      NotePaperKind.values,
      json['kind'],
      NotePaperKind.blank,
    );
    final size = _sizeFromJson(json['size']);
    final base = NotePaperTemplate(id: '', kind: kind, size: size);

    return NotePaperTemplate(
      id: NoteJson.string(json, 'id'),
      name: NoteJson.string(json, 'name'),
      kind: kind,
      size: size,
      lineSpacing: NoteJson.number(json, 'lineSpacing', base.lineSpacing),
      lineWidth: NoteJson.number(json, 'lineWidth', base.lineWidth),
      lineColor: NoteJson.color(json, 'lineColor', base.lineColor),
      backgroundColor: NoteJson.color(
        json,
        'backgroundColor',
        base.backgroundColor,
      ),
      accentColor: NoteJson.color(json, 'accentColor', base.accentColor),
      margins: _marginsFromJson(json['margins'], base.margins),
      showMarginLine: NoteJson.boolean(json, 'showMarginLine'),
      imageSource: NoteJson.stringOrNull(json, 'imageSource'),
      imageFit: NoteJson.enumByName(
        NotePaperImageFit.values,
        json['imageFit'],
        NotePaperImageFit.contain,
      ),
      imageOpacity: NoteJson.number(json, 'imageOpacity', 1),
    );
  }

  /// The identifier of the built-in paper of [kind] (`builtin.lined`).
  static String builtInId(NotePaperKind kind) => 'builtin.${kind.name}';

  /// The English name of [kind].
  static String defaultName(NotePaperKind kind) => switch (kind) {
    NotePaperKind.blank => 'Blank',
    NotePaperKind.lined => 'Lined',
    NotePaperKind.grid => 'Grid',
    NotePaperKind.dotted => 'Dotted',
    NotePaperKind.cornell => 'Cornell',
    NotePaperKind.music => 'Music',
    NotePaperKind.image => 'Image',
  };

  /// The default [lineSpacing] of [kind]: lined 28, grid 24, dotted 24,
  /// cornell 28, music 10 (28 for the unruled kinds, which ignore it).
  static double defaultLineSpacing(NotePaperKind kind) => switch (kind) {
    NotePaperKind.grid || NotePaperKind.dotted => 24,
    NotePaperKind.music => 10,
    _ => 28,
  };

  /// The default [lineColor] of [kind].
  static Color defaultLineColor(NotePaperKind kind) => switch (kind) {
    NotePaperKind.grid => const Color(0xFFD3DAE3),
    NotePaperKind.dotted => const Color(0xFF9AA7B5),
    NotePaperKind.music => const Color(0xFF616161),
    _ => const Color(0xFFBFCBD9),
  };

  /// The default [margins] of [kind] on a page of [size].
  static EdgeInsets defaultMargins(NotePaperKind kind, NotePageSize size) =>
      switch (kind) {
        NotePaperKind.blank || NotePaperKind.image => EdgeInsets.zero,
        NotePaperKind.lined => const EdgeInsets.fromLTRB(40, 56, 24, 32),
        NotePaperKind.grid || NotePaperKind.dotted => const EdgeInsets.all(24),
        NotePaperKind.cornell => EdgeInsets.fromLTRB(
          (size.width * 0.28).roundToDouble(),
          (size.height * 0.08).roundToDouble(),
          24,
          (size.height * 0.18).roundToDouble(),
        ),
        NotePaperKind.music => const EdgeInsets.fromLTRB(40, 56, 40, 40),
      };

  static EdgeInsets _fitMargins(EdgeInsets margins, NotePageSize size) {
    final (left, right) = _fitPair(margins.left, margins.right, size.width);
    final (top, bottom) = _fitPair(margins.top, margins.bottom, size.height);

    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  static (double, double) _fitPair(double first, double second, double room) {
    double side(double value) => NoteStyleValues.clamped(value, 0, 0, room);
    final a = side(first);
    final b = side(second);
    // A small tolerance keeps the result stable when it is read back.
    if (a + b <= room + 1e-6) return (a, b);
    final scale = room / (a + b);

    return (a * scale, b * scale);
  }

  static NotePageSize _sizeFromJson(Object? value) {
    final size = NotePageSize.fromJson(value);

    return NotePageSize(
      size.width.clamp(1.0, maxPageSide),
      size.height.clamp(1.0, maxPageSide),
    );
  }

  static EdgeInsets _marginsFromJson(Object? value, EdgeInsets fallback) {
    final json = NoteJson.asMap(value);
    if (json == null) return fallback;

    return EdgeInsets.fromLTRB(
      NoteJson.number(json, 'left', fallback.left),
      NoteJson.number(json, 'top', fallback.top),
      NoteJson.number(json, 'right', fallback.right),
      NoteJson.number(json, 'bottom', fallback.bottom),
    );
  }

  /// The area inside [margins], in page coordinates.
  Rect get writableArea => margins.deflateRect(size.toRect());

  /// The same paper on a page of [target]: margins are scaled in proportion to
  /// the width (left, right) and height (top, bottom); spacing, line width,
  /// colours and picture settings are unchanged. Returns `this` for the same
  /// size.
  NotePaperTemplate fitted(NotePageSize target) {
    if (target == size) return this;
    final horizontal = target.width / size.width;
    final vertical = target.height / size.height;

    return copyWith(
      size: target,
      margins: EdgeInsets.fromLTRB(
        margins.left * horizontal,
        margins.top * vertical,
        margins.right * horizontal,
        margins.bottom * vertical,
      ),
    );
  }

  /// A copy with some fields replaced (the others are kept, also when [kind]
  /// changes). [clearImageSource] removes the picture.
  NotePaperTemplate copyWith({
    String? id,
    String? name,
    NotePaperKind? kind,
    NotePageSize? size,
    double? lineSpacing,
    double? lineWidth,
    Color? lineColor,
    Color? backgroundColor,
    Color? accentColor,
    EdgeInsets? margins,
    bool? showMarginLine,
    String? imageSource,
    bool clearImageSource = false,
    NotePaperImageFit? imageFit,
    double? imageOpacity,
  }) => NotePaperTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    size: size ?? this.size,
    lineSpacing: lineSpacing ?? this.lineSpacing,
    lineWidth: lineWidth ?? this.lineWidth,
    lineColor: lineColor ?? this.lineColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    accentColor: accentColor ?? this.accentColor,
    margins: margins ?? this.margins,
    showMarginLine: showMarginLine ?? this.showMarginLine,
    imageSource: clearImageSource ? null : imageSource ?? this.imageSource,
    imageFit: imageFit ?? this.imageFit,
    imageOpacity: imageOpacity ?? this.imageOpacity,
  );

  /// The persisted form (see the class documentation).
  JsonMap toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'size': size.toJson(),
    'lineSpacing': lineSpacing,
    'lineWidth': lineWidth,
    'lineColor': NoteJson.colorToJson(lineColor),
    'backgroundColor': NoteJson.colorToJson(backgroundColor),
    'accentColor': NoteJson.colorToJson(accentColor),
    'margins': {
      'left': margins.left,
      'top': margins.top,
      'right': margins.right,
      'bottom': margins.bottom,
    },
    'showMarginLine': showMarginLine,
    if (imageSource != null) 'imageSource': imageSource,
    'imageFit': imageFit.name,
    'imageOpacity': imageOpacity,
  };

  @override
  bool operator ==(Object other) =>
      other is NotePaperTemplate &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.size == size &&
      other.lineSpacing == lineSpacing &&
      other.lineWidth == lineWidth &&
      other.lineColor == lineColor &&
      other.backgroundColor == backgroundColor &&
      other.accentColor == accentColor &&
      other.margins == margins &&
      other.showMarginLine == showMarginLine &&
      other.imageSource == imageSource &&
      other.imageFit == imageFit &&
      other.imageOpacity == imageOpacity;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    size,
    lineSpacing,
    lineWidth,
    lineColor,
    backgroundColor,
    accentColor,
    margins,
    showMarginLine,
    imageSource,
    imageFit,
    imageOpacity,
  );

  @override
  String toString() => 'NotePaperTemplate($id, ${kind.name}, $size)';
}
