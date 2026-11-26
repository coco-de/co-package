import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_object.dart';

class _FlagObject extends NoteObject {
  const _FlagObject({
    required super.id,
    required super.bounds,
    required this.label,
    super.rotation,
    super.opacity,
    super.locked,
  });

  final String label;

  @override
  String get kind => 'flag';

  @override
  _FlagObject withBase({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
  }) => _FlagObject(
    id: id,
    bounds: bounds ?? this.bounds,
    label: label,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
  );

  @override
  JsonMap payloadToJson() => {'label': label};
}

NoteObjectRegistry _registry() => NoteObjectRegistry()
  ..register(
    'flag',
    decoder: (base, payload) => _FlagObject(
      id: base.id,
      bounds: base.bounds,
      label: NoteJson.string(payload, 'label'),
      rotation: base.rotation,
      opacity: base.opacity,
      locked: base.locked,
    ),
    builder: (context, object, scope) =>
        Text((object as _FlagObject).label, textDirection: TextDirection.ltr),
  );

void main() {
  const flag = _FlagObject(
    id: 'f1',
    bounds: Rect.fromLTWH(10, 20, 30, 40),
    label: 'hello',
    rotation: 0.5,
    opacity: 0.25,
    locked: true,
  );

  test('toJson then decode rebuilds an equal object', () {
    final decoded = _registry().decode(flag.toJson()) as _FlagObject;

    expect(decoded.id, 'f1');
    expect(decoded.bounds, flag.bounds);
    expect(decoded.label, 'hello');
    expect(decoded.rotation, 0.5);
    expect(decoded.opacity, 0.25);
    expect(decoded.locked, isTrue);
  });

  test('an unregistered kind survives as an unknown object, losslessly', () {
    final json = {
      ...flag.toJson(),
      'kind': 'from-the-future',
      'payload': {
        'x': 1,
        'nested': {'y': 2},
      },
    };

    final decoded = _registry().decode(json);

    expect(decoded, isA<NoteUnknownObject>());
    expect(decoded!.kind, 'from-the-future');
    expect(decoded.toJson()['payload'], {
      'x': 1,
      'nested': {'y': 2},
    });
    expect(decoded.toJson()['kind'], 'from-the-future');
  });

  test('malformed documents decode to null', () {
    final registry = _registry();

    expect(registry.decode('nope'), isNull);
    expect(registry.decode({'kind': 'flag'}), isNull);
    expect(registry.decode({'id': 'x'}), isNull);
    expect(
      registry.decodeAll([flag.toJson(), 3, null, flag.toJson()]),
      hasLength(2),
    );
  });

  test('opacity read from json is clamped to 0..1', () {
    final decoded = _registry().decode({...flag.toJson(), 'opacity': 7});

    expect(decoded!.opacity, 1);
  });

  test('withBase changes only the shared fields', () {
    final moved = flag.withBase(bounds: const Rect.fromLTWH(0, 0, 5, 5));

    expect(moved.bounds, const Rect.fromLTWH(0, 0, 5, 5));
    expect(moved.label, 'hello');
    expect(moved.locked, isTrue);
  });

  test('registering a kind again replaces it', () {
    final registry = _registry()
      ..register(
        'flag',
        decoder: (base, payload) => NoteUnknownObject(
          id: base.id,
          bounds: base.bounds,
          unknownKind: 'replaced',
          payload: payload,
        ),
        builder: (context, object, scope) => const SizedBox(),
      );

    expect(registry.decode(flag.toJson()), isA<NoteUnknownObject>());
    expect(registry.kinds, ['flag']);
  });

  testWidgets('buildView uses the registered builder or a placeholder', (
    tester,
  ) async {
    final registry = _registry();

    await tester.pumpWidget(
      Builder(
        builder: (context) => Column(
          children: [
            registry.buildView(context, flag, const NoteObjectViewScope()),
            registry.buildView(
              context,
              const NoteUnknownObject(
                id: 'u',
                bounds: Rect.zero,
                unknownKind: 'mystery',
                payload: {},
              ),
              const NoteObjectViewScope(),
            ),
          ],
        ),
      ),
    );

    expect(find.text('hello'), findsOneWidget);
    expect(find.text('mystery'), findsOneWidget);
  });
}
