/// File storage for Dart servers: one API over AWS S3 and S3-compatible
/// services, local disk and memory — plus signed direct uploads, so an app's
/// secret keys stay on its server.
///
/// The disks and drivers are forked from dox_storage (MIT); see FORK.md. A
/// client that only has to send a file to a URL its server signed needs
/// `package:co_storage/client.dart` instead: it compiles for the web.
library;

export 'src/clock.dart';
export 'src/constants/storage_constants.dart';
export 'src/disk.dart';
export 'src/drive_manager.dart';
export 'src/driver_contract.dart';
export 'src/drivers/local_driver.dart';
export 'src/drivers/local_url_signer.dart';
export 'src/drivers/memory_driver.dart';
export 'src/drivers/s3/s3_client.dart';
export 'src/drivers/s3/s3_driver.dart';
export 'src/drivers/s3/s3_driver_config.dart';
export 'src/drivers/s3/sigv4_signer.dart';
export 'src/exceptions.dart';
export 'src/key_normalizer.dart';
export 'src/types.dart';
export 'src/uploads/direct_uploads.dart';
export 'src/uploads/upload_slot.dart';
