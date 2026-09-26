/// Builds a single-file HTML gallery from co_golden capture output and plain
/// golden PNG trees.
///
/// Scenarios that come with a co_golden run manifest are shown as a
/// device × variant grid with pass/fail status; other images are shown as
/// cards grouped by their directory. Images can stay where they are, be
/// copied next to the page, or be served from a URL prefix such as a storage
/// bucket.
library;

export 'src/cli.dart' show galleryDataError, galleryUsageError, runGalleryCli;
export 'src/favicon.dart';
export 'src/html.dart';
export 'src/model.dart';
export 'src/scanner.dart';
