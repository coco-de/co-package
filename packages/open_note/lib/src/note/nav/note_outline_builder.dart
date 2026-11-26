import 'dart:math' as math;

import 'package:open_note/src/note/core/note_ids.dart';
import 'package:open_note/src/note/nav/note_nav_strings.dart';
import 'package:open_note/src/note/nav/note_outline.dart';
import 'package:open_note/src/note/nav/note_outline_entry.dart';

/// Builds ready-made outlines.
abstract final class NoteOutlineBuilder {
  /// A diary outline: one root for [year] with one child per month.
  ///
  /// `monthPageIds[0]` is the page of January, `[1]` of February and so on;
  /// empty strings skip a month, a short list stops early and entries after the
  /// twelfth are ignored. [titleOf] names a month (1–12) and defaults to the
  /// English month names of [NoteNavStrings]; the root is titled [yearTitle]
  /// (the year number by default) and targets the page of the first month
  /// present. Without any month page the outline is empty.
  static NoteOutline calendar({
    required int year,
    required List<String> monthPageIds,
    String Function(int month)? titleOf,
    String? yearTitle,
    NoteIdFactory idFactory = generateNoteId,
  }) {
    final monthTitle = titleOf ?? const NoteNavStrings().monthName;
    final present = [
      for (var index = 0; index < math.min(12, monthPageIds.length); index++)
        if (monthPageIds[index].isNotEmpty) index,
    ];
    if (present.isEmpty) return NoteOutline(idFactory: idFactory);
    final rootId = idFactory();

    return NoteOutline(
      entries: [
        NoteOutlineEntry(
          id: rootId,
          title: yearTitle ?? '$year',
          pageId: monthPageIds[present.first],
          children: [
            for (final index in present)
              NoteOutlineEntry(
                id: idFactory(),
                title: monthTitle(index + 1),
                pageId: monthPageIds[index],
              ),
          ],
        ),
      ],
      idFactory: idFactory,
    );
  }
}
