import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/library.dart';

/// Midnight UTC of day [number] of January 2026.
DateTime day(int number) => DateTime.utc(2026, 1, number);

/// Ids `id-1`, `id-2`…
NoteIdFactory sequentialIds([String prefix = 'id']) {
  var next = 0;

  return () => '$prefix-${++next}';
}

/// A clock a test moves by hand.
class FakeClock {
  DateTime now = day(1);

  DateTime call() => now;
}

/// A summary with defaults for everything but the id.
NoteSummary summary(
  String id, {
  String? title,
  DateTime? createdAt,
  DateTime? modifiedAt,
  List<String> tags = const [],
  bool pinned = false,
  String? folderId,
  int pageCount = 1,
}) => NoteSummary(
  id: id,
  title: title ?? 'Note $id',
  createdAt: createdAt ?? day(1),
  modifiedAt: modifiedAt ?? createdAt ?? day(1),
  tags: tags,
  pinned: pinned,
  folderId: folderId,
  pageCount: pageCount,
);

/// A folder with defaults for everything but the id.
NoteFolder folder(
  String id, {
  String? name,
  String? parentId,
  int order = 0,
  String iconKey = NoteFolderIcons.folder,
}) => NoteFolder(
  id: id,
  name: name ?? 'Folder $id',
  parentId: parentId,
  order: order,
  iconKey: iconKey,
  createdAt: day(1),
);

/// A library with deterministic ids and [clock].
NoteLibrary testLibrary({
  List<NoteFolder> folders = const [],
  List<NoteSummary> notes = const [],
  List<NoteSummary> trash = const [],
  NoteLibraryViewState viewState = const NoteLibraryViewState(),
  FakeClock? clock,
}) => NoteLibrary(
  folders: folders,
  notes: notes,
  trash: trash,
  viewState: viewState,
  idFactory: sequentialIds(),
  clock: (clock ?? FakeClock()).call,
);

/// The ids of [notes], in order.
List<String> idsOf(Iterable<NoteSummary> notes) => [
  for (final note in notes) note.id,
];

/// The ids of [folders], in order.
List<String> folderIdsOf(Iterable<NoteFolder> folders) => [
  for (final entry in folders) entry.id,
];

/// How many times [library] has notified since this was called.
int Function() countNotifications(NoteLibrary library) {
  var count = 0;
  library.addListener(() => count++);

  return () => count;
}
