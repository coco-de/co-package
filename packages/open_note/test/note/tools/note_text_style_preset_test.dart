import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/tools.dart';

void main() {
  group('NoteTextStylePreset', () {
    test('has the documented defaults', () {
      const preset = NoteTextStylePreset(id: 'a');

      expect(preset.name, isEmpty);
      expect(preset.fontFamily, isEmpty);
      expect(preset.fontSize, 14);
      expect(preset.lineHeight, 0);
      expect(preset.color.toARGB32(), 0xFF000000);
      expect(preset.bold, isFalse);
      expect(preset.italic, isFalse);
      expect(preset.underline, isFalse);
      expect(preset.align, NoteTextStyleAlign.left);
    });

    test('uses the engine alignment names', () {
      expect(NoteTextStyleAlign.values.map((align) => align.name), [
        'left',
        'center',
        'right',
      ]);
    });

    test('clamps the font size and the line height', () {
      const small = NoteTextStylePreset(id: 'a', fontSize: 1, lineHeight: 0.1);
      const large = NoteTextStylePreset(id: 'a', fontSize: 999, lineHeight: 99);
      const broken = NoteTextStylePreset(
        id: 'a',
        fontSize: double.nan,
        lineHeight: double.nan,
      );
      const negative = NoteTextStylePreset(id: 'a', lineHeight: -2);

      expect(small.fontSize, NoteTextStylePreset.minFontSize);
      expect(small.lineHeight, NoteTextStylePreset.minLineHeight);
      expect(large.fontSize, NoteTextStylePreset.maxFontSize);
      expect(large.lineHeight, NoteTextStylePreset.maxLineHeight);
      expect(broken.fontSize, NoteTextStylePreset.defaultFontSize);
      expect(broken.lineHeight, 0);
      expect(negative.lineHeight, 0);
    });

    test('round trips through JSON', () {
      const preset = NoteTextStylePreset(
        id: 't1',
        name: 'Loud',
        fontFamily: 'Nanum Pen',
        fontSize: 20,
        lineHeight: 1.5,
        color: Color(0xCC123456),
        bold: true,
        italic: true,
        underline: true,
        align: NoteTextStyleAlign.center,
      );
      final json = NoteJson.decodeMap(NoteJson.encode(preset.toJson()));

      expect(NoteTextStylePreset.fromJson(json), preset);
      expect(preset.toJson()['align'], 'center');
      expect(preset.copyWith(), preset);
      expect(preset.copyWith().hashCode, preset.hashCode);
      expect(preset.copyWith(bold: false), isNot(preset));
      expect(preset.toString(), contains('Nanum Pen'));
    });

    test('never throws on malformed JSON', () {
      for (final json in <Object?>[null, 4, 'x', <Object?>[], {}]) {
        expect(NoteTextStylePreset.fromJson(json).id, isEmpty);
      }
      final preset = NoteTextStylePreset.fromJson({
        'id': 'x',
        'fontSize': 'big',
        'color': null,
        'bold': 'yes',
        'align': 'justify',
      });

      expect(preset.fontSize, 14);
      expect(preset.bold, isFalse);
      expect(preset.align, NoteTextStyleAlign.left);
      expect(preset.color.toARGB32(), 0xFF000000);
    });
  });

  group('NoteTextStylePresetStore', () {
    test('defaults offer four styles with body selected', () {
      final store = NoteTextStylePresetStore.defaults();

      expect(store.presets.map((preset) => preset.name), [
        'Title',
        'Heading',
        'Body',
        'Caption',
      ]);
      expect(store.activeId, NoteTextStylePresetStore.bodyId);
      expect(store.active?.fontSize, 14);
      expect(store.maxPresets, 24);
    });

    test('translates the default names', () {
      final presets = NoteTextStylePresetStore.defaultPresets(
        const NoteToolsStrings(titleStyle: '제목'),
      );

      expect(presets.first.name, '제목');
    });

    test('has the same editing API as the tool presets', () {
      var next = 0;
      final store = NoteTextStylePresetStore(idFactory: () => 'id${next++}');
      var notifications = 0;
      store.addListener(() => notifications++);

      final first = store.addFrom(name: 'One', fontSize: 30, bold: true)!;
      final second = store.addFrom(
        name: 'Two',
        fontFamily: 'Serif',
        lineHeight: 2,
        color: const Color(0xFF112233),
        italic: true,
        underline: true,
        align: NoteTextStyleAlign.right,
        select: false,
      )!;

      expect(first.id, 'id0');
      expect(second.align, NoteTextStyleAlign.right);
      expect(store.activeId, 'id0');
      expect(store.update(first.copyWith(name: 'Uno')), isTrue);
      expect(store.move(1, 0), isTrue);
      expect(store.presets.first.id, 'id1');
      expect(store.select('id1'), isTrue);
      expect(store.remove('id1'), isTrue);
      expect(store.activeId, isNull);
      expect(store.selectNext()?.id, 'id0');
      expect(notifications, 7);
    });

    test('persists under tools/text_styles.json', () async {
      final memory = MemoryNoteStore();
      final original = NoteTextStylePresetStore.defaults()
        ..select(NoteTextStylePresetStore.titleId);

      await original.save(memory);
      final loaded = NoteTextStylePresetStore();

      expect(await memory.list('tools/'), ['tools/text_styles.json']);
      expect(await loaded.load(memory), isTrue);
      expect(loaded.presets, original.presets);
      expect(loaded.activeId, NoteTextStylePresetStore.titleId);
    });

    test('keeps the current styles when the file is corrupt', () async {
      final memory = MemoryNoteStore();
      await memory.writeString(NoteTextStylePresetStore.key, 'not json');
      final store = NoteTextStylePresetStore.defaults();

      expect(await store.load(memory), isFalse);
      expect(store.length, 4);
    });

    test('shares no storage key with the tool presets', () {
      expect(NoteTextStylePresetStore.key, isNot(NoteToolPresetStore.key));
      expect(NoteTextStylePresetStore().storageKey, 'tools/text_styles.json');
      expect(NoteToolPresetStore().storageKey, 'tools/presets.json');
    });
  });
}
