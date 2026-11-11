import 'dart:math';
import 'dart:typed_data';

import 'package:co_storage/co_storage.dart';
import 'package:test/test.dart';

Disk memoryDisk() {
  return Disk(MemoryDriver(urlBase: 'https://cdn.test/'));
}

DirectUploads uploadsOn(
  Disk disk, {
  String prefix = 'editor/u1',
  Set<String> allowed = DirectUploads.imageContentTypes,
  int maxBytes = 1024,
  bool signContentLength = true,
}) {
  return DirectUploads(
    disk: disk,
    prefix: prefix,
    allowedContentTypes: allowed,
    maxBytes: maxBytes,
    signContentLength: signContentLength,
    clock: FixedClock(DateTime.utc(2026, 11, 5, 12)),
    random: Random(7),
  );
}

S3Driver s3Driver() {
  return S3Driver(
    const S3DriverConfig(
      bucket: 'my-bucket',
      region: 'us-east-1',
      accessKeyId: 'AKIDEXAMPLE',
      secretAccessKey: 'secret',
      endpoint: 'http://localhost:9000',
      forcePathStyle: true,
      supportsAcl: false,
    ),
    clock: FixedClock(DateTime.utc(2026, 11, 5, 12)),
  );
}

void main() {
  group('create', () {
    test('names the file prefix/year/month/random.extension', () async {
      DirectUploads uploads = uploadsOn(memoryDisk());

      UploadSlot slot = await uploads.create(
        contentType: 'image/png',
        size: 10,
      );

      expect(
        slot.publicUrl,
        matches(
          RegExp(r'^https://cdn\.test/editor/u1/2026/11/[0-9a-f]{32}\.png$'),
        ),
      );
      expect(slot.uploadUrl, startsWith(slot.publicUrl));
      expect(slot.headers, <String, String>{'content-type': 'image/png'});
    });

    test('every slot gets a name of its own', () async {
      DirectUploads uploads = uploadsOn(memoryDisk());
      Set<String> urls = <String>{
        for (int i = 0; i < 20; i++)
          (await uploads.create(contentType: 'image/png', size: 1)).publicUrl,
      };
      expect(urls, hasLength(20));
    });

    test(
      'the extension follows the type, not anything the client sends',
      () async {
        DirectUploads uploads = uploadsOn(memoryDisk());
        Map<String, String> expected = <String, String>{
          'image/png': 'png',
          'image/jpeg': 'jpg',
          'image/gif': 'gif',
          'image/webp': 'webp',
        };
        for (MapEntry<String, String> entry in expected.entries) {
          UploadSlot slot = await uploads.create(
            contentType: entry.key,
            size: 1,
          );
          expect(
            slot.publicUrl,
            endsWith('.${entry.value}'),
            reason: entry.key,
          );
        }
      },
    );

    test('reads the declared type without its case or parameters', () async {
      DirectUploads uploads = uploadsOn(memoryDisk());
      UploadSlot slot = await uploads.create(
        contentType: ' IMAGE/PNG; charset=binary ',
        size: 1,
      );
      expect(slot.headers['content-type'], 'image/png');
    });

    test('a type the app allows gets its own extension, or .bin', () async {
      DirectUploads uploads = uploadsOn(
        memoryDisk(),
        allowed: <String>{'application/pdf', 'application/x-made-up'},
      );
      expect(
        (await uploads.create(
          contentType: 'application/pdf',
          size: 1,
        )).publicUrl,
        endsWith('.pdf'),
      );
      expect(
        (await uploads.create(
          contentType: 'application/x-made-up',
          size: 1,
        )).publicUrl,
        endsWith('.bin'),
      );
    });

    test('a file of exactly maxBytes is allowed', () async {
      DirectUploads uploads = uploadsOn(memoryDisk());
      await uploads.create(contentType: 'image/png', size: 1024);
    });

    test(
      'refuses an empty file, a big one and a type that is not allowed',
      () async {
        DirectUploads uploads = uploadsOn(memoryDisk());

        Future<void> expectRejected(
          String contentType,
          int size,
          UploadRejection why,
        ) {
          return expectLater(
            uploads.create(contentType: contentType, size: size),
            throwsA(
              isA<UploadRejectedException>().having(
                (UploadRejectedException e) => e.rejection,
                'rejection',
                why,
              ),
            ),
          );
        }

        await expectRejected('image/png', 0, UploadRejection.empty);
        await expectRejected('image/png', -5, UploadRejection.empty);
        await expectRejected('image/png', 1025, UploadRejection.tooLarge);
        // SVG can carry script; HTML is the classic stored-XSS upload.
        await expectRejected(
          'image/svg+xml',
          10,
          UploadRejection.contentTypeNotAllowed,
        );
        await expectRejected(
          'text/html',
          10,
          UploadRejection.contentTypeNotAllowed,
        );
        await expectRejected('', 10, UploadRejection.contentTypeNotAllowed);
      },
    );

    test('a refused file leaves nothing behind', () async {
      Disk disk = memoryDisk();
      DirectUploads uploads = uploadsOn(disk, maxBytes: 10);
      await expectLater(
        uploads.create(contentType: 'image/png', size: 11),
        throwsA(isA<UploadRejectedException>()),
      );
      expect((await disk.listAll()).objects, isEmpty);
    });
  });

  group('the prefix', () {
    test('is cleaned of slashes', () {
      expect(
        uploadsOn(memoryDisk(), prefix: 'editor//u1/').prefix,
        'editor/u1',
      );
    });

    test('must name a folder: the root would let a URL delete anything', () {
      expect(() => uploadsOn(memoryDisk(), prefix: ''), throwsArgumentError);
      expect(
        () => uploadsOn(memoryDisk(), prefix: '/'),
        throwsA(isA<InvalidKeyException>()),
      );
      expect(() => uploadsOn(memoryDisk(), prefix: '.'), throwsArgumentError);
    });

    test('cannot climb out of the bucket root', () {
      expect(
        () => uploadsOn(memoryDisk(), prefix: 'a/../b'),
        throwsA(isA<InvalidKeyException>()),
      );
    });
  });

  group('signing on S3', () {
    // The URL is signed locally, so no S3 is needed to look at what it pins.
    Map<String, String> query(UploadSlot slot) {
      return Uri.parse(slot.uploadUrl).queryParameters;
    }

    test('pins the type and the size, and expires', () async {
      DirectUploads uploads = uploadsOn(Disk(s3Driver()));

      UploadSlot slot = await uploads.create(
        contentType: 'image/png',
        size: 512,
      );

      expect(
        query(slot)['X-Amz-SignedHeaders'],
        'content-length;content-type;host',
      );
      expect(query(slot)['X-Amz-Expires'], '300');
      expect(
        Uri.parse(slot.uploadUrl).path,
        matches(RegExp(r'^/my-bucket/editor/u1/2026/11/[0-9a-f]{32}\.png$')),
      );
    });

    test('without signContentLength the size is left open', () async {
      DirectUploads uploads = uploadsOn(
        Disk(s3Driver()),
        signContentLength: false,
      );
      UploadSlot slot = await uploads.create(
        contentType: 'image/png',
        size: 512,
      );
      expect(query(slot)['X-Amz-SignedHeaders'], 'content-type;host');
    });

    test('the signature changes with the declared size', () async {
      // Same seed, same key: only the size differs.
      UploadSlot small = await uploadsOn(Disk(s3Driver()))
          .create(contentType: 'image/png', size: 100);
      UploadSlot big = await uploadsOn(Disk(s3Driver()))
          .create(contentType: 'image/png', size: 101);

      expect(Uri.parse(small.uploadUrl).path, Uri.parse(big.uploadUrl).path);
      expect(
        query(small)['X-Amz-Signature'],
        isNot(query(big)['X-Amz-Signature']),
      );
    });

    test(
      'the public address is the plain object URL, not the signed one',
      () async {
        UploadSlot slot = await uploadsOn(Disk(s3Driver()))
            .create(contentType: 'image/png', size: 1);
        expect(slot.publicUrl, isNot(contains('X-Amz')));
        expect(
          slot.publicUrl,
          startsWith('http://localhost:9000/my-bucket/editor/u1/'),
        );
      },
    );
  });

  group('taking a file back out', () {
    late Disk disk;
    late DirectUploads uploads;

    setUp(() {
      disk = memoryDisk();
      uploads = uploadsOn(disk);
    });

    test(
      'deleteByUrl removes the file and a second call is harmless',
      () async {
        UploadSlot slot = await uploads.create(
          contentType: 'image/png',
          size: 3,
        );
        String key = (await uploads.keyOf(slot.publicUrl))!;
        await disk.put(key, Uint8List.fromList(<int>[1, 2, 3]));
        expect(await disk.exists(key), isTrue);

        await uploads.deleteByUrl(slot.publicUrl);
        expect(await disk.exists(key), isFalse);

        await uploads.deleteByUrl(slot.publicUrl);
      },
    );

    test('keyOf decodes the address', () async {
      expect(
        await uploads.keyOf('https://cdn.test/editor/u1/a%20b.png'),
        'editor/u1/a b.png',
      );
    });

    test(
      'refuses every address that is not a plain file of the folder',
      () async {
        // Files that must survive every attempt below.
        await disk.put('editor/u2/2026/11/a.png', 'other user');
        await disk.put('secret.txt', 'outside');
        await disk.put('editor/u1x/a.png', 'lookalike folder');

        List<String> foreign = <String>[
          '',
          'not a url',
          'https://evil.test/editor/u1/2026/11/a.png',
          'https://cdn.test/editor/u2/2026/11/a.png',
          'https://cdn.test/editor/u1',
          'https://cdn.test/editor/u1/',
          'https://cdn.test/editor/u1x/a.png',
          'https://cdn.test/editor/u1/../../secret.txt',
          'https://cdn.test/editor/u1/%2e%2e/%2e%2e/secret.txt',
          'https://cdn.test/editor/u1/%2E%2E%2Fsecret.txt',
          'https://cdn.test/editor/u1/..%5C..%5Csecret.txt',
          'https://cdn.test/editor/u1/a.png?download=1',
          'https://cdn.test/editor/u1/a.png#top',
          'https://cdn.test/editor/u1/%zz',
          'https://cdn.test/editor/u1/a%00b.png',
        ];
        for (String url in foreign) {
          expect(await uploads.keyOf(url), isNull, reason: url);
          await expectLater(
            uploads.deleteByUrl(url),
            throwsA(isA<InvalidKeyException>()),
            reason: url,
          );
        }

        expect(await disk.exists('editor/u2/2026/11/a.png'), isTrue);
        expect(await disk.exists('secret.txt'), isTrue);
        expect(await disk.exists('editor/u1x/a.png'), isTrue);
      },
    );

    test(
      'a user prefix keeps one user from removing another\'s file',
      () async {
        DirectUploads mine = uploadsOn(disk);
        DirectUploads theirs = uploadsOn(disk, prefix: 'editor/u2');
        UploadSlot slot = await theirs.create(
          contentType: 'image/png',
          size: 1,
        );
        String key = (await theirs.keyOf(slot.publicUrl))!;
        await disk.put(key, 'x');

        await expectLater(
          mine.deleteByUrl(slot.publicUrl),
          throwsA(isA<InvalidKeyException>()),
        );
        expect(await disk.exists(key), isTrue);

        await theirs.deleteByUrl(slot.publicUrl);
        expect(await disk.exists(key), isFalse);
      },
    );
  });
}
