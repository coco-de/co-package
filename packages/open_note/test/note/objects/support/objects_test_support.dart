import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/objects/objects.dart';

import '../../support/note_test_host.dart';

/// The page the layer tests use; it is centred on the 800x600 test surface.
const Size testPageSize = Size(400, 500);

/// A kind as another module would ship it: only the core contract, no
/// [NoteReidentifiableObject].
@immutable
class BoxObject extends NoteObject {
  const BoxObject({
    required super.id,
    required super.bounds,
    this.label = '',
    super.rotation,
    super.opacity,
    super.locked,
  });

  factory BoxObject.decode(NoteObjectBase base, JsonMap payload) => BoxObject(
    id: base.id,
    bounds: base.bounds,
    rotation: base.rotation,
    opacity: base.opacity,
    locked: base.locked,
    label: NoteJson.string(payload, 'label'),
  );

  final String label;

  @override
  String get kind => 'box';

  @override
  BoxObject withBase({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
  }) => BoxObject(
    id: id,
    bounds: bounds ?? this.bounds,
    label: label,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
  );

  BoxObject relabel(String next) => BoxObject(
    id: id,
    bounds: bounds,
    label: next,
    rotation: rotation,
    opacity: opacity,
    locked: locked,
  );

  @override
  JsonMap payloadToJson() => {'label': label};

  @override
  bool operator ==(Object other) =>
      other is BoxObject &&
      other.id == id &&
      other.bounds == bounds &&
      other.rotation == rotation &&
      other.opacity == opacity &&
      other.locked == locked &&
      other.label == label;

  @override
  int get hashCode => Object.hash(id, bounds, rotation, opacity, locked, label);

  @override
  String toString() => 'BoxObject($id, $bounds, $rotation)';
}

/// A box with sensible test defaults.
BoxObject box(
  String id, {
  Rect bounds = const Rect.fromLTWH(100, 100, 100, 80),
  double rotation = 0,
  double opacity = 1,
  bool locked = false,
  String label = '',
}) => BoxObject(
  id: id,
  bounds: bounds,
  rotation: rotation,
  opacity: opacity,
  locked: locked,
  label: label,
);

/// What the box widgets saw: their last scope and the taps they received.
class BoxLog {
  final Map<String, NoteObjectViewScope> scopes = {};
  final List<String> taps = [];
}

/// Registers every module kind plus `box`, whose widget takes taps while
/// interactive.
NoteObjectRegistry testRegistry([BoxLog? log]) {
  final registry = NoteObjectRegistry();
  registerNoteObjects(registry);
  registry.register(
    'box',
    decoder: BoxObject.decode,
    builder: (context, object, scope) {
      log?.scopes[object.id] = scope;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: scope.interactive ? () => log?.taps.add(object.id) : null,
        child: ColoredBox(
          key: ValueKey('box-view-${object.id}'),
          color: const Color(0xFF80CBC4),
        ),
      );
    },
  );

  return registry;
}

/// Ids `id-1`, `id-2`, … in order.
NoteIdFactory counterIds([String prefix = 'id']) {
  var next = 0;

  return () => '$prefix-${++next}';
}

/// Everything a layer test needs to look at.
class LayerHarness {
  LayerHarness(
    this.tester, {
    List<NoteObject> objects = const [],
    NoteUndoStack? history,
  }) : history = history ?? NoteUndoStack(),
       log = BoxLog() {
    controller = NoteObjectController(
      objects: objects,
      history: this.history,
      idFactory: counterIds('copy'),
    );
    registry = testRegistry(log);
  }

  final WidgetTester tester;
  final NoteUndoStack history;
  final BoxLog log;
  late final NoteObjectController controller;
  late final NoteObjectRegistry registry;

  /// Taps that reached the widget under the layer.
  int beneathTaps = 0;

  /// Links followed.
  final List<NoteLinkTarget> links = [];

  Widget layer(NoteObjectLayerMode mode) => NoteObjectLayer(
    controller: controller,
    registry: registry,
    size: testPageSize,
    mode: mode,
    onLinkActivated: links.add,
  );

  /// Pumps the layer over a widget that counts the taps it receives.
  Future<void> pump([NoteObjectLayerMode mode = NoteObjectLayerMode.edit]) =>
      tester.pumpWidget(
        noteTestHost(
          Center(
            child: SizedBox.fromSize(
              size: testPageSize,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => beneathTaps++,
                    ),
                  ),
                  layer(mode),
                ],
              ),
            ),
          ),
        ),
      );

  /// The screen position of the page point [point].
  Offset at(Offset point) =>
      tester.getTopLeft(find.byType(NoteObjectLayer)) + point;

  /// Taps the page point and waits past the double-tap window.
  Future<void> tap(Offset point) async {
    await tester.tapAt(at(point));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Two quick taps on the page point.
  Future<void> doubleTap(Offset point) async {
    await tester.tapAt(at(point));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(at(point));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Drags from the page point [from] by [offset] and pumps a frame.
  Future<void> drag(Offset from, Offset offset) async {
    await tester.dragFrom(at(from), offset);
    await tester.pump();
  }

  /// The object with [id] as the controller has it now.
  NoteObject object(String id) => controller.find(id)!;

  /// The centre of the widget with [key], in page coordinates.
  Offset centerOfKey(String key) =>
      tester.getCenter(find.byKey(ValueKey(key))) -
      tester.getTopLeft(find.byType(NoteObjectLayer));
}

/// Matches a [Rect] within [tolerance] on every edge.
Matcher rectCloseTo(Rect expected, [double tolerance = 0.001]) => isA<Rect>()
    .having((r) => r.left, 'left', closeTo(expected.left, tolerance))
    .having((r) => r.top, 'top', closeTo(expected.top, tolerance))
    .having((r) => r.right, 'right', closeTo(expected.right, tolerance))
    .having((r) => r.bottom, 'bottom', closeTo(expected.bottom, tolerance));

/// Matches an [Offset] within [tolerance] on both axes.
Matcher offsetCloseTo(Offset expected, [double tolerance = 0.001]) =>
    isA<Offset>()
        .having((o) => o.dx, 'dx', closeTo(expected.dx, tolerance))
        .having((o) => o.dy, 'dy', closeTo(expected.dy, tolerance));
