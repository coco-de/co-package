/// The client half of a signed direct upload: [UploadSlot] carries a file to
/// the URL a server signed for it.
///
/// It needs only `package:http`, so a Flutter app (mobile, desktop or web)
/// and a Jaspr page can import it. The server half — `DirectUploads`, the
/// disks and the S3 driver — is in `package:co_storage/co_storage.dart` and
/// belongs on a server, where the storage keys live.
library;

export 'src/uploads/upload_slot.dart';
