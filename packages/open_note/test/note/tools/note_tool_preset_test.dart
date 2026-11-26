import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/tools.dart';

const _black = Color(0xFF000000);

NoteToolPreset _preset(String id, {String ink = 'pen', double width = 1}) =>
    NoteToolPreset(id: id, ink: ink, color: _black, width: width);

void main() {
  group('NoteInkTypes', () {
    test('lists exactly the preset inks of the engine', () {
      expect(NoteInkTypes.presetInks, [
        'pen',
        'pencil',
        'marker',
        'fixedPen',
        'uniformPen',
        'shape',
        'text',
      ]);
      expect(NoteInkTypes.isPresetInk('pen'), isTrue);
      expect(NoteInkTypes.isPresetInk(NoteInkTypes.erase), isFalse);
      expect(NoteInkTypes.isPresetInk(NoteInkTypes.lasso), isFalse);
      expect(NoteInkTypes.isPresetInk('Pen'), isFalse);
    });
  });

  group('NoteToolPreset', () {
    test('has the documented defaults', () {
      final preset = _preset('a');

      expect(preset.name, isEmpty);
      expect(preset.lineStyle, 'solid');
      expect(preset.shapeTarget, isEmpty);
    });

    test('clamps the width and repairs bad inks and line styles', () {
      const tiny = NoteToolPreset(
        id: 'a',
        ink: 'brush',
        color: _black,
        width: -4,
        lineStyle: '',
      );
      const huge = NoteToolPreset(
        id: 'a',
        ink: 'text',
        color: _black,
        width: 1e9,
      );
      const broken = NoteToolPreset(
        id: 'a',
        ink: 'pen',
        color: _black,
        width: double.nan,
      );

      expect(tiny.ink, 'pen');
      expect(tiny.width, NoteToolPreset.minWidth);
      expect(tiny.lineStyle, 'solid');
      expect(huge.width, NoteToolPreset.maxWidth);
      expect(broken.width, NoteToolPreset.defaultWidth);
    });

    test('widthLabel trims trailing zeros', () {
      const cases = [
        (0.3, '0.3'),
        (3.0, '3'),
        (2.5, '2.5'),
        (10.0, '10'),
        (1.25, '1.25'),
        (0.1, '0.1'),
        (100.0, '100'),
        (0.30000000000000004, '0.3'),
        (1.999, '2'),
      ];

      for (final (width, label) in cases) {
        expect(_preset('a', width: width).widthLabel, label);
      }
    });

    test('round trips through JSON', () {
      const preset = NoteToolPreset(
        id: 'p1',
        name: 'Dashed red',
        ink: 'shape',
        color: Color(0x80FF0000),
        width: 2.5,
        lineStyle: 'dashed:1.4:1.6',
        shapeTarget: 'ellipse',
      );

      final json = NoteJson.decodeMap(NoteJson.encode(preset.toJson()));

      expect(NoteToolPreset.fromJson(json), preset);
      expect(preset.toJson()['color'], 0x80FF0000);
    });

    test('never throws on malformed JSON', () {
      for (final json in <Object?>[null, 1, 'x', <Object?>[], {}]) {
        final preset = NoteToolPreset.fromJson(json);

        expect(preset.id, isEmpty);
        expect(preset.ink, 'pen');
        expect(preset.color.toARGB32(), 0xFF000000);
        expect(preset.width, NoteToolPreset.defaultWidth);
        expect(preset.lineStyle, 'solid');
      }
      final preset = NoteToolPreset.fromJson({
        'id': 'x',
        'name': 5,
        'ink': 'laser',
        'color': 'red',
        'width': 'wide',
      });

      expect(preset.ink, 'pen');
      expect(preset.name, isEmpty);
      expect(preset.width, 1);
    });

    test('compares colours by their 32 bit value', () {
      final a = _preset('a').copyWith(color: const Color(0xFF336699));
      final b = _preset('a').copyWith(
        color: Color.from(
          alpha: 1,
          red: 0x33 / 255 + 1e-9,
          green: 0x66 / 255,
          blue: 0x99 / 255,
        ),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith replaces only the given values', () {
      final preset = _preset('a').copyWith(
        name: 'n',
        ink: 'marker',
        width: 9,
        lineStyle: 'dotted',
        shapeTarget: 'line',
      );

      expect(preset.id, 'a');
      expect(preset.ink, 'marker');
      expect(preset.width, 9);
      expect(preset.copyWith(), preset);
      expect(preset.copyWith(id: 'b'), isNot(preset));
      expect(preset.toString(), contains('marker'));
    });
  });

  group('NoteToolPresetStore.defaults', () {
    test('holds black, red, blue and white pens and a yellow marker', () {
      final store = NoteToolPresetStore.defaults();
      final pens = store.byInk('pen');

      expect(store.length, 5);
      expect(store.activeId, NoteToolPresetStore.blackPenId);
      expect(pens.map((preset) => preset.color.toARGB32()), [
        0xFF000000,
        0xFFE53935,
        0xFF1E88E5,
        0xFFFFFFFF,
      ]);
      expect(pens.map((preset) => preset.width).toSet().length, 4);
      expect(
        store.byInk('marker').single.id,
        NoteToolPresetStore.yellowMarkerId,
      );
      expect(store.byInk('marker').single.color.a, lessThan(1));
    });

    test('takes names from the strings', () {
      final store = NoteToolPresetStore.defaults(
        strings: const NoteToolsStrings(blackPen: '검정 펜'),
      );

      expect(store.active?.name, '검정 펜');
    });

    test('respects maxPresets', () {
      expect(NoteToolPresetStore.defaults(maxPresets: 2).length, 2);
    });
  });

  group('NotePresetStore behaviour', () {
    late NoteToolPresetStore store;
    late int notifications;

    setUp(() {
      var next = 0;
      store = NoteToolPresetStore(
        presets: [_preset('a'), _preset('b'), _preset('c')],
        activeId: 'b',
        idFactory: () => 'new${next++}',
      );
      notifications = 0;
      store.addListener(() => notifications++);
    });

    List<String> ids() => [for (final preset in store.presets) preset.id];

    test('drops duplicate and empty ids and unknown selections', () {
      final odd = NoteToolPresetStore(
        presets: [_preset('a'), _preset(''), _preset('a'), _preset('b')],
        activeId: 'zzz',
      );

      expect(odd.presets.map((preset) => preset.id), ['a', 'b']);
      expect(odd.activeId, isNull);
      expect(odd.active, isNull);
    });

    test('caps the presets it starts with at maxPresets', () {
      final capped = NoteToolPresetStore(
        presets: [for (var i = 0; i < 9; i++) _preset('$i')],
        maxPresets: 4,
      );

      expect(capped.length, 4);
      expect(capped.isFull, isTrue);
      expect(NoteToolPresetStore().maxPresets, 24);
    });

    test('exposes an unmodifiable snapshot', () {
      final snapshot = store.presets;

      expect(() => snapshot.add(_preset('x')), throwsUnsupportedError);
      store.remove('a');
      expect(snapshot.length, 3);
    });

    test('add appends and selects by default', () {
      expect(store.add(_preset('d')), isTrue);

      expect(ids(), ['a', 'b', 'c', 'd']);
      expect(store.activeId, 'd');
      expect(notifications, 1);
    });

    test('add can keep the selection', () {
      store.add(_preset('d'), select: false);

      expect(store.activeId, 'b');
    });

    test('add refuses duplicates, empty ids and a full store', () {
      expect(store.add(_preset('a')), isFalse);
      expect(store.add(_preset('')), isFalse);
      final full = NoteToolPresetStore(presets: [_preset('a')], maxPresets: 1);

      expect(full.add(_preset('b')), isFalse);
      expect(full.addFrom(ink: 'pen', color: _black, width: 1), isNull);
      expect(full.length, 1);
      expect(notifications, 0);
    });

    test('addFrom creates a preset with a new id', () {
      final created = store.addFrom(
        ink: 'marker',
        color: const Color(0x80FFFF00),
        width: 6,
        name: 'Lime',
        lineStyle: 'wavy:2:8',
        shapeTarget: 'line',
      );

      expect(created?.id, 'new0');
      expect(store.activeId, 'new0');
      expect(store.find('new0'), created);
      expect(created?.lineStyle, 'wavy:2:8');
      expect(
        store.addFrom(ink: 'pen', color: _black, width: 1, select: false)?.id,
        'new1',
      );
      expect(store.activeId, 'new0');
    });

    test('update replaces in place and ignores no-ops', () {
      expect(store.update(_preset('b', width: 3)), isTrue);
      expect(store.update(_preset('b', width: 3)), isFalse);
      expect(store.update(_preset('zzz')), isFalse);

      expect(ids(), ['a', 'b', 'c']);
      expect(store.find('b')?.width, 3);
      expect(store.activeId, 'b');
      expect(notifications, 1);
    });

    test('remove clears the selection only for the selected one', () {
      expect(store.remove('a'), isTrue);
      expect(store.activeId, 'b');

      expect(store.remove('b'), isTrue);
      expect(store.activeId, isNull);
      expect(store.remove('b'), isFalse);
      expect(notifications, 2);
    });

    test('move puts the entry at its final index', () {
      expect(store.move(0, 2), isTrue);
      expect(ids(), ['b', 'c', 'a']);

      expect(store.move(2, 0), isTrue);
      expect(ids(), ['a', 'b', 'c']);
      expect(store.activeId, 'b');
    });

    test('move clamps the target and rejects no-ops', () {
      expect(store.move(0, 99), isTrue);
      expect(ids(), ['b', 'c', 'a']);
      expect(store.move(1, -5), isTrue);
      expect(ids(), ['c', 'b', 'a']);
      expect(store.move(1, 1), isFalse);
      expect(store.move(-1, 0), isFalse);
      expect(store.move(3, 0), isFalse);
      expect(notifications, 2);
    });

    test('select changes only for real, known ids', () {
      expect(store.select('c'), isTrue);
      expect(store.select('c'), isFalse);
      expect(store.select('zzz'), isFalse);
      expect(store.select(null), isTrue);
      expect(store.active, isNull);
      expect(notifications, 2);
    });

    test('selectNext cycles and wraps around', () {
      expect(store.selectNext()?.id, 'c');
      expect(store.selectNext()?.id, 'a');
      store.select(null);
      expect(store.selectNext()?.id, 'a');
      expect(NoteToolPresetStore().selectNext(), isNull);
    });

    test('byInk filters in display order', () {
      store
        ..add(_preset('m', ink: 'marker'))
        ..add(_preset('t', ink: 'text'));

      expect(store.byInk('marker').map((preset) => preset.id), ['m']);
      expect(store.byInk('pen').length, 3);
      expect(store.byInk('pencil'), isEmpty);
    });

    test('does nothing after dispose', () async {
      final memory = MemoryNoteStore();
      store.dispose();

      expect(store.isDisposed, isTrue);
      expect(store.add(_preset('d')), isFalse);
      expect(store.update(_preset('a', width: 9)), isFalse);
      expect(store.remove('a'), isFalse);
      expect(store.move(0, 1), isFalse);
      expect(store.select('a'), isFalse);
      expect(store.selectNext(), isNull);
      await store.save(memory);
      expect(memory.length, 0);
      expect(await store.load(memory), isFalse);
    });
  });

  group('NoteToolPresetStore persistence', () {
    test('saves under tools/presets.json and loads it back', () async {
      final memory = MemoryNoteStore();
      final original = NoteToolPresetStore.defaults()
        ..select(NoteToolPresetStore.bluePenId);

      await original.save(memory);
      final loaded = NoteToolPresetStore();
      var notifications = 0;
      loaded.addListener(() => notifications++);

      expect(await memory.exists('tools/presets.json'), isTrue);
      expect(await loaded.load(memory), isTrue);
      expect(loaded.presets, original.presets);
      expect(loaded.activeId, NoteToolPresetStore.bluePenId);
      expect(notifications, 1);

      await loaded.load(memory);
      expect(notifications, 1, reason: 'nothing changed');
    });

    test('keeps the current presets when there is no file', () async {
      final store = NoteToolPresetStore.defaults();

      expect(await store.load(MemoryNoteStore()), isFalse);
      expect(store.length, 5);
    });

    test('keeps the current presets when the file is corrupt', () async {
      final memory = MemoryNoteStore();
      final store = NoteToolPresetStore.defaults();

      for (final content in ['', '{', '[]', '"x"', '{"presets": 3}', '{}']) {
        await memory.writeString(NoteToolPresetStore.key, content);

        expect(await store.load(memory), isFalse, reason: content);
        expect(store.length, 5, reason: content);
      }
    });

    test('accepts an empty list', () async {
      final memory = MemoryNoteStore();
      await memory.writeString(NoteToolPresetStore.key, '{"presets": []}');
      final store = NoteToolPresetStore.defaults();

      expect(await store.load(memory), isTrue);
      expect(store.presets, isEmpty);
      expect(store.activeId, isNull);
    });

    test('skips bad entries and unknown selections', () async {
      final memory = MemoryNoteStore();
      await memory.writeString(
        NoteToolPresetStore.key,
        NoteJson.encode({
          'activeId': 'ghost',
          'presets': [
            7,
            'x',
            {'name': 'no id'},
            {'id': 'ok', 'ink': 'pencil', 'width': 3},
            {'id': 'ok', 'ink': 'pen'},
          ],
        }),
      );
      final store = NoteToolPresetStore();

      expect(await store.load(memory), isTrue);
      expect(store.presets.single.ink, 'pencil');
      expect(store.activeId, isNull);
    });

    test('caps loaded presets at maxPresets', () async {
      final memory = MemoryNoteStore();
      await NoteToolPresetStore(
        presets: [for (var i = 0; i < 6; i++) _preset('$i')],
      ).save(memory);
      final store = NoteToolPresetStore(maxPresets: 3);

      await store.load(memory);

      expect(store.length, 3);
    });

    test('stores a version and the selection', () {
      final json = NoteToolPresetStore.defaults().toJson();

      expect(json['v'], 1);
      expect(json['activeId'], NoteToolPresetStore.blackPenId);
      expect(json['presets'], hasLength(5));
    });
  });
}
