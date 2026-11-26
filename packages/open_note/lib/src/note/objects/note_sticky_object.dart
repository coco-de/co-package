import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_reidentifiable_object.dart';

/// A sticky note: a coloured sheet of paper with wrapped text.
///
/// The text starts at the top left, [textPadding] inside the paper, and is
/// clipped to it. All lengths are page units.
///
/// JSON payload (the `payload` of [NoteObject.toJson]):
///
/// ```text
/// {"text": String,         // may contain newlines
///  "paperColor": int,      // 32-bit ARGB
///  "textColor": int,       // 32-bit ARGB
///  "fontSize": num,        // page units, clamped to 4–200
///  "shadow": bool}
/// ```
///
/// [NoteStickyObject.decode] never throws: a missing or mistyped value takes
/// its default.
@immutable
class NoteStickyObject extends NoteObject implements NoteReidentifiableObject {
  /// The `kind` of sticky notes.
  static const String kindName = 'sticky';

  /// Light yellow paper.
  static const Color defaultPaperColor = Color(0xFFFFF59D);

  /// Near-black text.
  static const Color defaultTextColor = Color(0xFF212121);

  /// The default [fontSize].
  static const double defaultFontSize = 14;

  /// The smallest decoded [fontSize].
  static const double minFontSize = 4;

  /// The largest decoded [fontSize].
  static const double maxFontSize = 200;

  /// Space between the paper edge and the text.
  static const double textPadding = 8;

  /// Corner radius of the paper.
  static const double cornerRadius = 3;

  /// Line height of the text, as a multiple of [fontSize].
  static const double lineHeight = 1.3;

  /// The shadow under the paper when [shadow] is on.
  static const BoxShadow paperShadow = BoxShadow(
    color: Color(0x33000000),
    offset: Offset(0, 2),
    blurRadius: 6,
  );

  /// The note's text.
  final String text;

  /// Colour of the paper.
  final Color paperColor;

  /// Colour of the text.
  final Color textColor;

  /// Text size in page units; drawn clamped to
  /// [minFontSize]–[maxFontSize].
  final double fontSize;

  /// Whether the paper casts a shadow.
  final bool shadow;

  const NoteStickyObject({
    required super.id,
    required super.bounds,
    this.text = '',
    this.paperColor = defaultPaperColor,
    this.textColor = defaultTextColor,
    this.fontSize = defaultFontSize,
    this.shadow = true,
    super.rotation,
    super.opacity,
    super.locked,
  });

  /// Rebuilds a sticky note from its [base] fields and [payload].
  factory NoteStickyObject.decode(NoteObjectBase base, JsonMap payload) =>
      NoteStickyObject(
        id: base.id,
        bounds: NoteObjectGeometry.normalizeRect(base.bounds),
        rotation: base.rotation,
        opacity: base.opacity,
        locked: base.locked,
        text: NoteJson.string(payload, 'text'),
        paperColor: NoteJson.color(payload, 'paperColor', defaultPaperColor),
        textColor: NoteJson.color(payload, 'textColor', defaultTextColor),
        fontSize: NoteJson.number(
          payload,
          'fontSize',
          defaultFontSize,
        ).clamp(minFontSize, maxFontSize),
        shadow: NoteJson.boolean(payload, 'shadow', true),
      );

  /// The style the text is drawn with, on screen and on export.
  TextStyle get textStyle => TextStyle(
    color: textColor,
    fontSize: fontSize.clamp(minFontSize, maxFontSize),
    height: lineHeight,
  );

  @override
  String get kind => kindName;

  @override
  int get hashCode => Object.hash(
    id,
    bounds,
    rotation,
    opacity,
    locked,
    text,
    paperColor,
    textColor,
    fontSize,
    shadow,
  );

  /// A copy with the given fields replaced; the [id] is kept.
  NoteStickyObject copyWith({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
    String? text,
    Color? paperColor,
    Color? textColor,
    double? fontSize,
    bool? shadow,
  }) => NoteStickyObject(
    id: id,
    bounds: bounds ?? this.bounds,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
    text: text ?? this.text,
    paperColor: paperColor ?? this.paperColor,
    textColor: textColor ?? this.textColor,
    fontSize: fontSize ?? this.fontSize,
    shadow: shadow ?? this.shadow,
  );

  @override
  NoteStickyObject withBase({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
  }) => copyWith(
    bounds: bounds,
    rotation: rotation,
    opacity: opacity,
    locked: locked,
  );

  @override
  NoteStickyObject withId(String id) => NoteStickyObject(
    id: id,
    bounds: bounds,
    rotation: rotation,
    opacity: opacity,
    locked: locked,
    text: text,
    paperColor: paperColor,
    textColor: textColor,
    fontSize: fontSize,
    shadow: shadow,
  );

  @override
  JsonMap payloadToJson() => {
    'text': text,
    'paperColor': NoteJson.colorToJson(paperColor),
    'textColor': NoteJson.colorToJson(textColor),
    'fontSize': fontSize,
    'shadow': shadow,
  };

  @override
  void paintToCanvas(ui.Canvas canvas, NoteObjectPaintContext context) {
    final paper = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(cornerRadius),
    );
    if (shadow) {
      canvas.drawRRect(paper.shift(paperShadow.offset), paperShadow.toPaint());
    }
    canvas.drawRRect(paper, Paint()..color = paperColor);
    _paintText(canvas);
  }

  @override
  bool operator ==(Object other) =>
      other is NoteStickyObject &&
      other.runtimeType == runtimeType &&
      other.id == id &&
      other.bounds == bounds &&
      other.rotation == rotation &&
      other.opacity == opacity &&
      other.locked == locked &&
      other.text == text &&
      other.paperColor == paperColor &&
      other.textColor == textColor &&
      other.fontSize == fontSize &&
      other.shadow == shadow;

  @override
  String toString() => 'NoteStickyObject($id, $bounds, "$text")';

  void _paintText(ui.Canvas canvas) {
    final width = bounds.width - 2 * textPadding;
    if (text.isEmpty || width <= 0) return;
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    canvas
      ..save()
      ..clipRect(bounds.deflate(math.min(textPadding, bounds.height / 2)));
    painter.paint(
      canvas,
      bounds.topLeft + const Offset(textPadding, textPadding),
    );
    canvas.restore();
    painter.dispose();
  }
}
