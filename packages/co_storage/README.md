# co_storage

File storage for Dart servers, with **direct uploads whose storage keys never
leave the server**.

- One `Disk` API over AWS S3, S3-compatible services (Cloudflare R2, MinIO,
  DigitalOcean Spaces), local disk and memory.
- `DirectUploads`: the server decides where a file goes and signs a `PUT` for
  it; the client sends the bytes straight to the storage with `UploadSlot`.
  The client never holds a key, and the server never carries the bytes.
- `DirectUploads.deleteByUrl`: takes a file back out, only when its address is
  inside the uploader's folder.

The disks and drivers are a fork of
[dox_storage](https://github.com/dartondox/dox-storage) (MIT) without its Dox
framework glue — see [FORK.md](FORK.md).

## Two imports

| Import | Goes in | Needs |
| --- | --- | --- |
| `package:co_storage/co_storage.dart` | a **server** — it holds the storage keys | `dart:io` |
| `package:co_storage/client.dart` | a **client** — Flutter (mobile, desktop, web) or a Jaspr page | `package:http` only; compiles for the web |

Depend on it by git tag until it is on pub.dev (`<package>-v<version>`):

```yaml
dependencies:
  co_storage:
    git:
      url: https://github.com/coco-de/co-package.git
      path: packages/co_storage
      ref: co_storage-v0.1.0
```

## On the server

```dart
import 'package:co_storage/co_storage.dart';

Disk disk = Disk(
  S3Driver(
    S3DriverConfig(
      bucket: 'my-bucket',
      region: 'ap-northeast-2',
      accessKeyId: env['S3_KEY']!,
      secretAccessKey: env['S3_SECRET']!,
      // Where files are read from — a CDN, or the bucket's public URL.
      urlBase: 'https://cdn.example.com',
    ),
  ),
);
```

Two endpoints are all a client needs. Authorize the caller in both, and put
the user in the prefix, so one user's address cannot remove another's file:

```dart
DirectUploads uploadsFor(String userId) =>
    DirectUploads(disk: disk, prefix: 'editor/$userId');

// createImageUpload(contentType, size)
Future<Map<String, Object?>> createImageUpload(String userId, String contentType, int size) async {
  UploadSlot slot = await uploadsFor(userId).create(
    contentType: contentType,
    size: size,
  ); // throws UploadRejectedException: empty, too big, type not allowed
  return slot.toJson();
}

// deleteImage(url)
Future<void> deleteImage(String userId, String url) {
  return uploadsFor(userId).deleteByUrl(url); // InvalidKeyException for a foreign address
}
```

`create` names the file `<prefix>/<year>/<month>/<128 random bits>.<ext>`: the
extension comes from the *type* (png, jpg, gif, webp), and nothing the client
sent goes into the key. The defaults take PNG, JPEG, GIF and WebP up to
10 MiB; change them with `allowedContentTypes` and `maxBytes`.

## On the client

```dart
import 'package:co_storage/client.dart';

UploadSlot slot = UploadSlot.fromJson(await api.createImageUpload(type, bytes.length));
await slot.upload(bytes); // throws UploadFailedException when the storage refuses
String address = slot.publicUrl; // the address to keep
```

## With CoUI's `RichEditor`

`RichEditor` shows its image button only when it gets an upload **and** the
delete that goes with it. Those two endpoints are exactly that pair:

```dart
RichEditor(
  onImageUpload: (file) async {
    UploadSlot slot = UploadSlot.fromJson(
      await api.createImageUpload(file.mimeType, file.size),
    );
    await slot.upload(file.bytes);
    return slot.publicUrl;
  },
  onImageDelete: (url) => api.deleteImage(url),
)
```

## What the signature holds, and what it does not

| | |
| --- | --- |
| **Holds** | the key (the server chose it), the content type, the exact size (`signContentLength`, on by default), and a 5-minute expiry (`expiresIn`) |
| **Does not** | *who* may ask — authorize in the endpoint; what the bytes really are — a file claiming `image/png` is not decoded or scanned |

`deleteByUrl` accepts only a plain address of a file inside the uploader's
folder: no query string, no `..`, nothing that decodes to a way out of the
folder. An uploader needs a non-empty prefix, because one on the bucket root
could remove any file.

## Setting up the bucket

- **Reading.** Files are read from the address `create` returns. Serve the
  prefix publicly (a bucket policy granting `s3:GetObject` on `editor/*`) or
  through a CDN, and set `urlBase` to it. Do not rely on object ACLs — new
  buckets have them disabled — and do not use signed read URLs for addresses
  that are kept in documents: they expire.
- **Writing and deleting.** The keys the server signs with need only
  `s3:PutObject` and `s3:DeleteObject` on the prefix.
- **Browsers.** The bucket's CORS rules must allow the page's origin to `PUT`
  with the `content-type` header.

## Tests

```sh
dart test                          # unit tests; the S3 driver is faked
dart test -t integration           # against a real MinIO, see the docker command
                                   # at the top of test/s3_minio_integration_test.dart
```

The integration tests skip themselves when MinIO is not reachable. The signed
content type and size, and the expired slot, are only verified there — and
only against MinIO: AWS S3 and R2 follow the same SigV4 rules, but nothing in
this repository runs against them.
