// Pure-Dart, Flutter-free example for `open_epub_engine`.
//
// Opens an EPUB 2/3 file from a command-line path and prints its metadata,
// table of contents (outline), compatibility diagnostics, and — when a query
// is given — full-text search hits with an exported CFI for the first hit.
//
// Run (from the repository root):
//
//   dart run packages/open_epub_engine/example/open_epub_engine_example.dart \
//       path/to/book.epub "search term"
//
// The `.epub` path is required; the search term is optional. With no arguments
// the program prints usage and exits with code 64 (EX_USAGE).
//
// Only the public barrel `package:open_epub_engine/open_epub_engine.dart` is
// used — no Flutter, no internal `src/` imports.

import 'dart:io';

import 'package:open_epub_engine/open_epub_engine.dart';

const String _usage = '''
open_epub_engine example — inspect an EPUB with the pure-Dart engine.

Usage:
  dart run packages/open_epub_engine/example/open_epub_engine_example.dart <book.epub> [search-query]

Arguments:
  <book.epub>      Path to an EPUB 2 or EPUB 3 file (required).
  [search-query]   Optional term to run against the built search index.

Example:
  dart run packages/open_epub_engine/example/open_epub_engine_example.dart alice.epub whale''';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(_usage);
    exitCode = 64; // EX_USAGE
    return;
  }

  final path = args.first;
  final query = args.length > 1 ? args[1] : null;

  if (!File(path).existsSync()) {
    stderr.writeln('error: file not found: $path');
    exitCode = 66; // EX_NOINPUT
    return;
  }

  // `EpubSource.bytes(...)` and `EpubSource.url(...)` are also available; the
  // file factory is the most convenient for a headless CLI.
  final EpubBookSession session;
  try {
    session = await EpubBookSession.open(EpubSource.file(path));
  } on Object catch (error) {
    stderr.writeln('error: failed to open EPUB: $error');
    exitCode = 65; // EX_DATAERR
    return;
  }

  try {
    _printMetadata(session.book);
    _printOutline(session.outline);
    _printDiagnostics(session.diagnostics);
    if (query != null) {
      await _printSearch(session, query);
    }
  } finally {
    await session.dispose();
  }
}

void _printMetadata(EpubBook book) {
  final meta = book.metadata;
  stdout
    ..writeln('== Metadata ==')
    ..writeln('Title:    ${meta.title}')
    ..writeln('Author:   ${meta.author ?? '(unknown)'}')
    ..writeln('Language: ${meta.language ?? '(unspecified)'}')
    ..writeln('EPUB:     ${meta.epubVersion} (${meta.version.name})')
    ..writeln('Layout:   ${book.layout.name}')
    ..writeln('Spine:    ${book.spine.length} document(s)')
    ..writeln();
}

void _printOutline(EpubOutline outline) {
  stdout.writeln('== Table of contents ==');
  if (outline.items.isEmpty) {
    stdout
      ..writeln('(no navigation document / NCX)')
      ..writeln();
    return;
  }
  for (final item in outline.items) {
    _printOutlineItem(item, 0);
  }
  stdout.writeln();
}

void _printOutlineItem(EpubOutlineItem item, int depth) {
  final indent = '  ' * depth;
  stdout.writeln('$indent- ${item.title}  ->  ${item.spineHref}');
  for (final child in item.children) {
    _printOutlineItem(child, depth + 1);
  }
}

void _printDiagnostics(BookSessionDiagnostics diagnostics) {
  final patches = diagnostics.appliedPatches;
  final issues = diagnostics.unresolvedIssues;
  if (patches.isEmpty && issues.isEmpty) return;

  stdout.writeln('== Diagnostics ==');
  for (final patch in patches) {
    stdout.writeln('applied: ${patch.patchId} — ${patch.description}');
  }
  for (final issue in issues) {
    stdout.writeln('issue:   ${issue.code} — ${issue.message}');
  }
  stdout.writeln();
}

Future<void> _printSearch(EpubBookSession session, String query) async {
  stdout.writeln('== Search: "$query" ==');
  final index = await session.buildSearchIndex();
  final hits = await index.search(query);

  if (hits.isEmpty) {
    stdout
      ..writeln('(no matches)')
      ..writeln();
    return;
  }

  const maxShown = 10;
  final shown = hits.take(maxShown);
  for (final hit in shown) {
    stdout.writeln(
      '${hit.spineHref}@${hit.charOffset}: ${hit.snippet.trim()}',
    );
  }
  if (hits.length > maxShown) {
    stdout.writeln('… and ${hits.length - maxShown} more');
  }

  // Turn the first hit into a jumpable position and export a standard EPUB CFI
  // (interop string) for it — demonstrates the CFI subsystem end to end.
  final position = session.positionForHit(hits.first);
  final cfi = session.exportPositionCfi(position);
  stdout.writeln(
    'first hit CFI: ${cfi ?? '(unavailable for this position)'}',
  );
  stdout.writeln();
}
