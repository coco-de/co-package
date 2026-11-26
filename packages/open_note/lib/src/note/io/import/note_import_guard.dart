// Internal to the importers: wraps host plug-in failures. Not exported from the
// module barrel.
import 'package:open_note/src/note/io/import/note_import_exception.dart';

/// Runs a host plug-in call, turning its exceptions into
/// [NoteImportException]s that name the [step] that failed.
Future<T> noteGuardImport<T>(String step, Future<T> Function() call) async {
  try {
    return await call();
  } on NoteImportException {
    rethrow;
  } on Exception catch (error) {
    throw NoteImportException('$step failed', cause: error);
  }
}
