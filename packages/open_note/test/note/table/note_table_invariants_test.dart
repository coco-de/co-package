// Seeded pseudo-random operation sequences: whatever the order of operations,
// the grid stays rectangular, spans never overlap or leave it, fractions sum to
// 1 with none below the minimum, and text is only lost by deletion.
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/table/table.dart';

import 'support/table_invariants.dart';

/// What an operation may do to the text of the table.
enum _Text { keeps, mayLose, rewrites }

typedef _Step = ({String name, NoteTableObject table, _Text text});

int _index(math.Random random, int count) => random.nextInt(count + 4) - 2;

NoteTableRange _range(math.Random random, NoteTableObject table) => span(
  _index(random, table.rowCount),
  _index(random, table.columnCount),
  _index(random, table.rowCount),
  _index(random, table.columnCount),
);

double _fraction(math.Random random) => switch (random.nextInt(12)) {
  0 => double.nan,
  1 => double.infinity,
  2 => -1,
  3 => 2,
  _ => random.nextDouble(),
};

NoteTableCell _cell(math.Random random, int step) => NoteTableCell(
  text: random.nextBool() ? 'n$step' : '',
  rowSpan: 1 + random.nextInt(4),
  columnSpan: 1 + random.nextInt(4),
  covered: random.nextBool(),
  bold: random.nextBool(),
  fillColor: random.nextBool() ? const Color(0xFF336699) : null,
  align: NoteTableCellAlign.values[random.nextInt(3)],
);

_Step _apply(math.Random random, NoteTableObject table, int step) {
  final row = _index(random, table.rowCount);
  final column = _index(random, table.columnCount);
  // Deletes are weighted up when the table is large so it stays small.
  final large = table.rowCount * table.columnCount > 60;
  final choice = large && random.nextBool()
      ? 2 + random.nextInt(2)
      : random.nextInt(11);

  return switch (choice) {
    0 => (
      name: 'insertRow $row',
      table: table.insertRow(row),
      text: _Text.keeps,
    ),
    1 => (
      name: 'insertColumn $column',
      table: table.insertColumn(column),
      text: _Text.keeps,
    ),
    2 => (
      name: 'deleteRow $row',
      table: table.deleteRow(row),
      text: _Text.mayLose,
    ),
    3 => (
      name: 'deleteColumn $column',
      table: table.deleteColumn(column),
      text: _Text.mayLose,
    ),
    4 || 5 => _merge(random, table),
    6 => (
      name: 'splitCell $row $column',
      table: table.splitCell(row, column),
      text: _Text.keeps,
    ),
    7 => (
      name: 'setCell $row $column',
      table: random.nextBool()
          ? table.setCellText(row, column, 't$step')
          : table.setCell(row, column, _cell(random, step)),
      text: _Text.rewrites,
    ),
    8 => (
      name: 'setColumnWidth $column',
      table: table.setColumnWidth(column, _fraction(random)),
      text: _Text.keeps,
    ),
    9 => (
      name: 'setRowHeight $row',
      table: table.setRowHeight(row, _fraction(random)),
      text: _Text.keeps,
    ),
    _ => (
      name: 'withSize',
      table: table.withSize(random.nextInt(8), random.nextInt(8)),
      text: _Text.mayLose,
    ),
  };
}

_Step _merge(math.Random random, NoteTableObject table) {
  final range = _range(random, table);

  return (
    name: 'merge $range',
    table: table.mergeCells(range),
    text: _Text.keeps,
  );
}

void _expectTextRule(_Step step, NoteTableObject before, String reason) {
  final old = textFragments(before);
  final now = textFragments(step.table);
  switch (step.text) {
    case _Text.keeps:
      expect(now, old, reason: '$reason must keep every text');
    case _Text.mayLose:
      final left = List<String>.of(old);
      for (final fragment in now) {
        expect(left.remove(fragment), isTrue, reason: '$reason made text');
      }
    case _Text.rewrites:
      break;
  }
}

void main() {
  test('random operation sequences keep every invariant', () {
    for (var seed = 0; seed < 40; seed++) {
      final random = math.Random(seed);
      var table = labelledTable(
        rows: 1 + random.nextInt(5),
        columns: 1 + random.nextInt(5),
      );
      for (var step = 0; step < 150; step++) {
        final result = _apply(random, table, step);
        final reason = 'seed $seed step $step (${result.name})';

        expectTableInvariants(result.table, reason: reason);
        _expectTextRule(result, table, reason);
        table = result.table;
      }
    }
  });

  test('every reached table survives a JSON round trip', () {
    final registry = NoteObjectRegistry();
    registerNoteTableObject(registry);
    for (var seed = 100; seed < 120; seed++) {
      final random = math.Random(seed);
      var table = labelledTable(rows: 4, columns: 4);
      for (var step = 0; step < 60; step++) {
        table = _apply(random, table, step).table;

        final text = jsonEncode(table.toJson());

        expect(
          registry.decode(NoteJson.decodeMap(text)),
          table,
          reason: 'seed $seed step $step',
        );
      }
    }
  });

  test('operations never change the table they start from', () {
    final random = math.Random(7);
    var table = labelledTable(rows: 4, columns: 4);
    for (var step = 0; step < 200; step++) {
      final snapshot = jsonEncode(table.toJson());

      final next = _apply(random, table, step).table;

      expect(jsonEncode(table.toJson()), snapshot, reason: 'step $step');
      table = next;
    }
  });

  test('the toolbar actions keep the table and selection sound', () {
    for (var seed = 200; seed < 230; seed++) {
      final random = math.Random(seed);
      var table = labelledTable(rows: 3, columns: 3);
      for (var step = 0; step < 100; step++) {
        final action = NoteTableAction.values[random.nextInt(8)];
        final selection = _range(random, table);
        final reason = 'seed $seed step $step $action $selection';
        final enabled = action.isEnabled(table, selection);

        final result = action.apply(table, selection);

        expectTableInvariants(result.table, reason: reason);
        expect(result.table == table, !enabled, reason: reason);
        expect(
          result.table.expandToMerges(result.selection),
          result.selection,
          reason: '$reason left an invalid selection',
        );
        table = result.table.rowCount * result.table.columnCount > 80
            ? labelledTable(rows: 3, columns: 3)
            : result.table;
      }
    }
  });
}
