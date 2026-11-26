import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:open_note/src/core/utils/stroke_id.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/internal/note_page_link_remap.dart';
import 'package:open_note/src/note/document/note_ink_transforms.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/layer/note_layer.dart';
import 'package:open_note/src/note/layer/note_layer_content.dart';
import 'package:open_note/src/note/objects/note_reidentifiable_object.dart';
import 'package:protobuf/protobuf.dart';

/// A side of a page.
enum NoteMarginSide { left, top, right, bottom }

/// Pure page operations: each returns a new [NotePage] (or the same one when
/// nothing changes).
abstract final class NotePageOps {
  /// Turns the whole page — paper, ink and objects — clockwise by
  /// [quarterTurns] × 90°.
  static NotePage rotate(NotePage page, int quarterTurns) {
    final turns = quarterTurns % 4;
    if (turns == 0) return page;
    final oldSize = page.size.toSize();
    final map = NoteInkTransforms.pointRotation(turns, oldSize);
    final angle = turns * math.pi / 2;
    var margins = page.margins;
    for (var i = 0; i < turns; i++) {
      margins = EdgeInsets.fromLTRB(
        margins.bottom,
        margins.left,
        margins.top,
        margins.right,
      );
    }

    return page.copyWith(
      size: turns.isOdd ? page.size.rotated : page.size,
      margins: margins,
      paperTurns: (page.paperTurns + turns) % 4,
      layers: [
        for (final content in page.layers)
          content.copyWith(
            scribble: NoteInkTransforms.rotate(
              content.scribble,
              turns,
              oldSize,
            ),
          ),
      ],
      objects: [
        for (final object in page.objects)
          object.withBase(
            bounds: Rect.fromCenter(
              center: map(object.bounds.center),
              width: object.bounds.width,
              height: object.bounds.height,
            ),
            rotation: NoteInkTransforms.normalizeAngle(object.rotation + angle),
          ),
      ],
    );
  }

  /// Sets the extended margins. The paper keeps its size; the page grows or
  /// shrinks, and ink and objects move with the paper.
  static NotePage setMargins(NotePage page, EdgeInsets margins) {
    assert(margins.isNonNegative);
    if (margins == page.margins) return page;
    final content = page.contentRect.size;
    final shift = Offset(
      margins.left - page.margins.left,
      margins.top - page.margins.top,
    );

    return page.copyWith(
      size: NotePageSize(
        content.width + margins.horizontal,
        content.height + margins.vertical,
      ),
      margins: margins,
      layers: [
        for (final layer in page.layers)
          layer.copyWith(
            scribble: NoteInkTransforms.translate(layer.scribble, shift),
          ),
      ],
      objects: shift == Offset.zero
          ? page.objects
          : [
              for (final object in page.objects)
                object.withBase(bounds: object.bounds.shift(shift)),
            ],
    );
  }

  /// Adds [amount] to the margin on [side] (a negative amount shrinks it,
  /// never below zero).
  static NotePage extendMargin(
    NotePage page,
    NoteMarginSide side,
    double amount,
  ) => setMargins(page, extended(page.margins, side, amount));

  /// [margins] with [amount] added on [side], clamped at zero.
  static EdgeInsets extended(
    EdgeInsets margins,
    NoteMarginSide side,
    double amount,
  ) {
    double add(double value) => math.max(0, value + amount);

    return switch (side) {
      NoteMarginSide.left => margins.copyWith(left: add(margins.left)),
      NoteMarginSide.top => margins.copyWith(top: add(margins.top)),
      NoteMarginSide.right => margins.copyWith(right: add(margins.right)),
      NoteMarginSide.bottom => margins.copyWith(bottom: add(margins.bottom)),
    };
  }

  /// Points the `pageid:` links of [page] (objects and ink text) at the ids in
  /// [pageIds]. Use it after copying a set of pages, so that links between them
  /// follow the copies.
  static NotePage remapLinks(
    NotePage page,
    Map<String, String> pageIds, {
    required NoteObjectRegistry registry,
  }) {
    var changed = false;
    final objects = [
      for (final object in page.objects)
        NotePageLinkRemap.object(object, pageIds, registry: registry),
    ];
    for (var i = 0; i < objects.length; i++) {
      changed = changed || !identical(objects[i], page.objects[i]);
    }
    final layers = [
      for (final content in page.layers) _remapLayerLinks(content, pageIds),
    ];
    for (var i = 0; i < layers.length; i++) {
      changed = changed || !identical(layers[i], page.layers[i]);
    }

    return changed ? page.copyWith(layers: layers, objects: objects) : page;
  }

  static NoteLayerContent _remapLayerLinks(
    NoteLayerContent content,
    Map<String, String> pageIds,
  ) {
    final linksToCopies = content.scribble.textDrawables.any(
      (text) => text.linkSpans.any(
        (span) => NotePageLinkRemap.link(span.url, pageIds) != span.url,
      ),
    );
    if (!linksToCopies) return content;
    final scribble = content.scribble.deepCopy();
    NotePageLinkRemap.scribble(scribble, pageIds);

    return content.copyWith(scribble: scribble);
  }

  /// A copy with a new id for the page, every layer, stroke, text, image and
  /// object (so links and sync never confuse it with the original). A link of
  /// the page to itself points at the copy.
  static NotePage duplicate(
    NotePage page, {
    required NoteObjectRegistry registry,
    NoteIdFactory idFactory = generateNoteId,
    String Function() strokeIdFactory = generateStrokeId,
    NoteClock clock = systemNoteClock,
  }) {
    final now = clock();
    final layerIds = {
      for (final content in page.layers) content.layer.id: idFactory(),
    };
    final layers = <NoteLayerContent>[];
    for (final content in page.layers) {
      final scribble = content.scribble.deepCopy();
      for (final stroke in scribble.strokes) {
        stroke.id = strokeIdFactory();
      }
      for (final text in scribble.textDrawables) {
        text.id = idFactory();
      }
      for (final image in scribble.imageDrawables) {
        image.id = idFactory();
      }
      final source = content.layer;
      layers.add(
        NoteLayerContent(
          layer: NoteLayer(
            id: layerIds[source.id]!,
            name: source.name,
            visible: source.visible,
            locked: source.locked,
            opacity: source.opacity,
          ),
          scribble: scribble,
        ),
      );
    }

    final copy = NotePage(
      id: idFactory(),
      size: page.size,
      template: page.template,
      margins: page.margins,
      marginTemplate: page.marginTemplate,
      paperTurns: page.paperTurns,
      autoGrows: page.autoGrows,
      pdf: page.pdf,
      layers: layers,
      activeLayerId: layerIds[page.activeLayerId],
      objects: [
        for (final object in page.objects)
          _withId(object, idFactory(), registry),
      ],
      createdAt: now,
    );

    return remapLinks(copy, {page.id: copy.id}, registry: registry);
  }

  static NoteObject _withId(
    NoteObject object,
    String id,
    NoteObjectRegistry registry,
  ) => object is NoteReidentifiableObject
      ? (object as NoteReidentifiableObject).withId(id)
      : registry.decode({...object.toJson(), 'id': id})!;
}
