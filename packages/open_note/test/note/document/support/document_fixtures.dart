import 'dart:ui';

import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/document.dart';
import 'package:open_note/src/note/objects/objects.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// A registry with the object kinds the document tests use.
NoteObjectRegistry documentRegistry() {
  final registry = NoteObjectRegistry();
  registerNoteObjects(registry);

  return registry;
}

/// Ids `p1`, `p2`, … in call order.
NoteIdFactory counterIds([String prefix = 'id']) {
  var next = 0;

  return () => '$prefix${++next}';
}

DateTime fixedClock() => DateTime.utc(2026, 11, 26, 9);

NoteDocument newDocument({
  String id = 'note',
  NoteObjectRegistry? registry,
  NoteIdFactory? idFactory,
  NotePaperTemplate? template,
}) => NoteDocument(
  id: id,
  registry: registry ?? documentRegistry(),
  defaultTemplate: template,
  idFactory: idFactory ?? counterIds(),
  strokeIdFactory: counterIds('s'),
  clock: fixedClock,
);

/// [page] with one pen stroke from [from] to [to] on its top layer.
NotePage withStroke(NotePage page, Offset from, Offset to) {
  final top = page.layers.last;
  final scribble = Scribble(
    strokes: [
      ...top.scribble.strokes,
      Stroke(
        id: 'ink',
        ink: 'pen',
        color: 0xFF000000,
        options: StrokeOptions(size: 4),
        points: [
          Point(x: from.dx, y: from.dy, p: 0.5),
          Point(x: to.dx, y: to.dy, p: 0.5),
        ],
      ),
    ],
  );

  return page.copyWith(
    layers: [
      ...page.layers.take(page.layers.length - 1),
      top.copyWith(scribble: scribble),
    ],
  );
}

NoteLinkObject linkTo(String target, {String id = 'link'}) => NoteLinkObject(
  id: id,
  bounds: const Rect.fromLTWH(10, 10, 50, 20),
  target: target,
);
