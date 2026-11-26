import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/table/table.dart';

import 'support/table_invariants.dart';

const _base = NoteObjectBase(
  id: 't1',
  bounds: Rect.fromLTWH(1, 2, 300, 200),
  rotation: 0.25,
  opacity: 0.75,
  locked: true,
);

NoteObjectRegistry _registry() {
  final registry = NoteObjectRegistry();
  registerNoteTableObject(registry);

  return registry;
}

NoteTableObject _decode(JsonMap payload) =>
    NoteTableObject.fromPayload(_base, payload);

/// A random JSON-like value, biased towards the table schema.
Object? _garbage(math.Random random, [int depth = 0]) {
  const keys = [
    'rows',
    'columns',
    'columnWidths',
    'rowHeights',
    'cells',
    'style',
    'text',
    'rowSpan',
    'columnSpan',
    'covered',
    'fillColor',
    'align',
    'borderWidth',
    'fontSize',
  ];
  final pick = random.nextInt(depth > 2 ? 6 : 8);

  return switch (pick) {
    0 => null,
    1 => random.nextBool(),
    2 => random.nextInt(200) - 50,
    3 => (random.nextDouble() - 0.2) * 100,
    4 => ['', 'x', 'center', 'start', '7'][random.nextInt(5)],
    5 => [1e300, -1e300, 1 << 62, 0][random.nextInt(4)],
    6 => [
      for (var i = 0; i < random.nextInt(14); i++) _garbage(random, depth + 1),
    ],
    _ => {
      for (var i = 0; i < random.nextInt(8); i++)
        keys[random.nextInt(keys.length)]: _garbage(random, depth + 1),
    },
  };
}

void main() {
  final rich =
      labelledTable(
            id: 'rich',
            rows: 3,
            columns: 4,
            bounds: const Rect.fromLTWH(5, 6, 400, 150),
            style: const NoteTableStyle(headerRow: true, borderWidth: 2),
          )
          .mergeCells(span(0, 1, 1, 2))
          .setCell(
            2,
            0,
            const NoteTableCell(
              text: 'multi\nline',
              fillColor: Color(0x40123456),
              textColor: Color(0xFFAA0000),
              bold: true,
              align: NoteTableCellAlign.center,
            ),
          )
          .setColumnWidth(0, 0.4)
          .setRowHeight(2, 0.5)
          .withBase(rotation: 1.25, opacity: 0.5, locked: true);

  test('round-trips through the object registry', () {
    final text = jsonEncode(rich.toJson());

    final decoded = _registry().decode(jsonDecode(text));

    expect(decoded, isA<NoteTableObject>());
    expect(decoded, rich);
    expect(decoded.hashCode, rich.hashCode);
    expect(jsonEncode(decoded!.toJson()), text);
  });

  test('writes the documented keys', () {
    final json = rich.toJson();
    final payload = json['payload']! as Map<String, Object?>;

    expect(json['kind'], 'table');
    expect(
      payload.keys,
      unorderedEquals([
        'rows',
        'columns',
        'columnWidths',
        'rowHeights',
        'cells',
        'style',
      ]),
    );
    expect(payload['cells'], hasLength(12));
    expect(payload['rows'], 3);
    expect(payload['columns'], 4);
  });

  test('takes the shared fields from the base', () {
    final table = _decode(const {'rows': 2, 'columns': 2});

    expect(table.id, 't1');
    expect(table.bounds, _base.bounds);
    expect(table.rotation, 0.25);
    expect(table.opacity, 0.75);
    expect(table.locked, isTrue);
  });

  test('an empty payload is a single blank cell', () {
    final table = _decode(const {});

    expect((table.rowCount, table.columnCount), (1, 1));
    expect(table.cells, [NoteTableCell.empty]);
    expect(table.style, const NoteTableStyle());
  });

  test('reads the size from the fraction lists when it is missing', () {
    final table = _decode(const {
      'columnWidths': [0.2, 0.8],
      'rowHeights': [0.5, 0.25, 0.25],
    });

    expect((table.rowCount, table.columnCount), (3, 2));
    expect(table.columnWidths, [0.2, 0.8]);
    expectTableInvariants(table);
  });

  test('replaces fraction lists of the wrong length', () {
    final table = _decode(const {
      'rows': 2,
      'columns': 2,
      'columnWidths': [1, 2, 3, 4],
      'rowHeights': 'tall',
    });

    expect(table.rowHeights, [0.5, 0.5]);
    expectTableInvariants(table);
  });

  test('repairs bad fraction entries', () {
    final table = _decode(const {
      'columnWidths': [0.5, 'x', -3, 0.5],
      'rowHeights': [1000, 1],
    });

    expect(table.columnWidths, everyElement(closeTo(0.25, 1e-12)));
    expect(table.rowHeights.last, NoteTableObject.minFraction);
    expectTableInvariants(table);
  });

  test('blanks cells that are not objects and repairs spans', () {
    final table = _decode(const {
      'rows': 2,
      'columns': 2,
      'cells': [
        'junk',
        {'text': 'b', 'rowSpan': 99, 'columnSpan': 99},
        {'text': 'c', 'columnSpan': 2},
      ],
    });

    expect(table.cellAt(0, 0), NoteTableCell.empty);
    expect(table.cellAt(0, 1).text, 'b');
    expect(table.rangeAt(0, 1), span(0, 1, 1, 1));
    // Cell (1, 0) may not grow into the column that (0, 1) occupies.
    expect(table.rangeAt(1, 0), const NoteTableRange.cell(1, 0));
    expectTableInvariants(table);
  });

  test('clamps huge and negative sizes', () {
    final huge = _decode(const {'rows': 1e300, 'columns': -7});
    final wrong = _decode(const {'rows': 'many', 'columns': double.nan});

    expect((huge.rowCount, huge.columnCount), (NoteTableObject.maxRows, 1));
    expect((wrong.rowCount, wrong.columnCount), (1, 1));
    expectTableInvariants(huge);
  });

  test('keeps cells in their rows when columns are cut', () {
    const declared = 60;
    final table = _decode({
      'rows': 2,
      'columns': declared,
      'cells': [
        for (var i = 0; i < 2 * declared; i++) {'text': 'i$i'},
      ],
    });

    expect(table.columnCount, NoteTableObject.maxColumns);
    expect(table.cellAt(0, 0).text, 'i0');
    expect(table.cellAt(1, 0).text, 'i$declared');
    expectTableInvariants(table);
  });

  test('never throws on random garbage and always yields a sound table', () {
    final random = math.Random(2024);
    for (var trial = 0; trial < 1500; trial++) {
      final raw = _garbage(random);
      final payload = NoteJson.asMap(raw) ?? <String, Object?>{'cells': raw};
      // Half of the trials look like a table, so the repair paths run.
      if (trial.isEven) {
        payload['rows'] = random.nextInt(6);
        payload['columns'] = random.nextInt(6);
        payload['cells'] = [
          for (var i = 0; i < random.nextInt(30); i++)
            {
              'rowSpan': random.nextInt(8) - 1,
              'columnSpan': random.nextInt(8) - 1,
              if (random.nextInt(3) == 0) 'covered': true,
              'text': 'c$i',
            },
        ];
      }

      final table = _decode(payload);

      expectTableInvariants(table, reason: 'trial $trial: $payload');
      expect(
        _decode(table.payloadToJson()),
        table,
        reason: 'trial $trial is not stable',
      );
    }
  });

  test('the registry decodes a table of an unregistered kind as unknown', () {
    final decoded = NoteObjectRegistry().decode(rich.toJson());

    expect(decoded, isA<NoteUnknownObject>());
  });
}
