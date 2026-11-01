@Tags(<String>['integration'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:co_storage/co_storage.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

/// Runs against a real MinIO, set up as in `s3_minio_integration_test.dart`:
///
/// docker run -d --rm --name co-storage-minio -p 9100:9000 -p 9101:9001 \
///   -e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=minioadmin \
///   cgr.dev/chainguard/minio:latest server /tmp/data --console-address :9001
///
/// Skipped when MinIO is not reachable. Override with MINIO_ENDPOINT,
/// MINIO_ACCESS_KEY and MINIO_SECRET_KEY.
///
/// What only a real server can say: that the *signed* content type and size
/// are enforced on the upload, and that an expired slot is refused.
String endpoint =
    Platform.environment['MINIO_ENDPOINT'] ?? 'http://localhost:9100';
String accessKey = Platform.environment['MINIO_ACCESS_KEY'] ?? 'minioadmin';
String secretKey = Platform.environment['MINIO_SECRET_KEY'] ?? 'minioadmin';
const String bucket = 'co-storage-uploads-test';

Future<bool> minioIsUp() async {
  try {
    http.Response response = await http
        .get(Uri.parse('$endpoint/minio/health/live'))
        .timeout(const Duration(seconds: 2));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

S3Driver minioDriver({Clock clock = const Clock()}) {
  return S3Driver(
    S3DriverConfig(
      bucket: bucket,
      region: 'us-east-1',
      accessKeyId: accessKey,
      secretAccessKey: secretKey,
      endpoint: endpoint,
      forcePathStyle: true,
      supportsAcl: false,
    ),
    clock: clock,
  );
}

Future<void> createBucket(S3Driver driver) async {
  http.Response response = await driver.client.send(
    'PUT',
    driver.client.bucketUri(),
  );
  // 409 means the bucket is already there.
  if (response.statusCode != 200 && response.statusCode != 409) {
    throw StateError('Could not create bucket: ${response.body}');
  }
}

Future<void> main() async {
  bool up = await minioIsUp();
  String? skip = up ? null : 'MinIO is not reachable at $endpoint';

  group('DirectUploads on MinIO', () {
    late S3Driver driver;
    late Disk disk;
    late DirectUploads uploads;

    setUpAll(() async {
      driver = minioDriver();
      await createBucket(driver);
      disk = Disk(driver);
      uploads = DirectUploads(disk: disk, prefix: 'editor-it', maxBytes: 1024);
    });

    tearDownAll(() async {
      await disk.deleteAll('editor-it');
      await disk.deleteAll('outside');
      driver.close();
    });

    Uint8List bytes(int length) {
      return Uint8List.fromList(List<int>.filled(length, 7));
    }

    test(
      'the client puts the file where the server said, as declared',
      () async {
        UploadSlot slot = await uploads.create(
          contentType: 'image/png',
          size: 5,
        );

        await slot.upload(bytes(5));

        String key = (await uploads.keyOf(slot.publicUrl))!;
        ObjectMetaData meta = await disk.getMetaData(key);
        expect(meta.size, 5);
        expect(meta.contentType, 'image/png');
        expect(await disk.get(key), bytes(5));
      },
    );

    test('a body of another size than signed is refused', () async {
      UploadSlot slot = await uploads.create(contentType: 'image/png', size: 5);

      await expectLater(
        slot.upload(bytes(6)),
        throwsA(
          isA<UploadFailedException>().having(
            (UploadFailedException e) => e.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
      expect(
        await disk.exists((await uploads.keyOf(slot.publicUrl))!),
        isFalse,
      );
    });

    test('a content type other than signed is refused', () async {
      UploadSlot slot = await uploads.create(contentType: 'image/png', size: 5);
      UploadSlot forged = UploadSlot(
        uploadUrl: slot.uploadUrl,
        publicUrl: slot.publicUrl,
        headers: const <String, String>{'content-type': 'text/html'},
      );

      await expectLater(
        forged.upload(bytes(5)),
        throwsA(isA<UploadFailedException>()),
      );
      expect(
        await disk.exists((await uploads.keyOf(slot.publicUrl))!),
        isFalse,
      );
    });

    test(
      'without signContentLength the size is only the client\'s word',
      () async {
        // The contrast that shows the signature is what holds the size.
        DirectUploads open = DirectUploads(
          disk: disk,
          prefix: 'editor-it',
          maxBytes: 1024,
          signContentLength: false,
        );
        UploadSlot slot = await open.create(contentType: 'image/png', size: 5);

        await slot.upload(bytes(900));

        expect(
          (await disk.getMetaData((await open.keyOf(slot.publicUrl))!)).size,
          900,
        );
      },
    );

    test('a slot is good for its few minutes only', () async {
      S3Driver late = minioDriver(
        clock: FixedClock(
          DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
        ),
      );
      addTearDown(late.close);
      DirectUploads stale = DirectUploads(
        disk: Disk(late),
        prefix: 'editor-it',
        expiresIn: const Duration(minutes: 1),
      );
      UploadSlot slot = await stale.create(contentType: 'image/png', size: 5);

      await expectLater(
        slot.upload(bytes(5)),
        throwsA(isA<UploadFailedException>()),
      );
    });

    test(
      'deleteByUrl removes an uploaded file, and again is harmless',
      () async {
        UploadSlot slot = await uploads.create(
          contentType: 'image/webp',
          size: 3,
        );
        await slot.upload(bytes(3));
        String key = (await uploads.keyOf(slot.publicUrl))!;
        expect(await disk.exists(key), isTrue);

        await uploads.deleteByUrl(slot.publicUrl);
        expect(await disk.exists(key), isFalse);

        await uploads.deleteByUrl(slot.publicUrl);
      },
    );

    test('an address outside the folder deletes nothing', () async {
      await disk.put('outside/keep.txt', 'mine');
      String foreign = await disk.getUrl('outside/keep.txt');

      await expectLater(
        uploads.deleteByUrl(foreign),
        throwsA(isA<InvalidKeyException>()),
      );
      expect(await disk.exists('outside/keep.txt'), isTrue);
    });
  }, skip: skip);
}
