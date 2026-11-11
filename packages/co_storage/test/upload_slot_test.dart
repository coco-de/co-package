import 'dart:typed_data';

import 'package:co_storage/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  UploadSlot slot = const UploadSlot(
    uploadUrl: 'https://s3.test/b/editor/a.png?X-Amz-Signature=abc',
    publicUrl: 'https://cdn.test/editor/a.png',
    headers: <String, String>{'content-type': 'image/png'},
  );

  group('upload', () {
    test('PUTs the bytes to the signed URL with the signed headers', () async {
      http.Request? seen;
      MockClient client = MockClient((http.Request request) async {
        seen = request;
        return http.Response('', 200);
      });
      Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);

      await slot.upload(bytes, client: client);

      expect(seen!.method, 'PUT');
      expect(seen!.url.toString(), slot.uploadUrl);
      expect(seen!.bodyBytes, bytes);
      // The signature pins the type and the size: both must arrive as signed.
      expect(seen!.headers['content-type'], 'image/png');
      expect(seen!.contentLength, 5);
    });

    test('any 2xx is success', () async {
      MockClient client = MockClient((http.Request request) async {
        return http.Response('', 204);
      });
      await slot.upload(Uint8List(1), client: client);
    });

    test('a refusal throws with the status and the storage explanation', () {
      MockClient client = MockClient((http.Request request) async {
        return http.Response(
          '<Error><Code>SignatureDoesNotMatch</Code></Error>',
          403,
        );
      });

      expect(
        slot.upload(Uint8List(1), client: client),
        throwsA(
          isA<UploadFailedException>()
              .having(
                (UploadFailedException e) => e.statusCode,
                'statusCode',
                403,
              )
              .having(
                (UploadFailedException e) => e.body,
                'body',
                contains('SignatureDoesNotMatch'),
              ),
        ),
      );
    });

    test('a client passed in is left open for the caller', () async {
      bool closed = false;
      MockClient client = _TrackingClient(() => closed = true);
      await slot.upload(Uint8List(1), client: client);
      expect(closed, isFalse);
    });
  });

  group('JSON', () {
    test('round trips', () {
      UploadSlot back = UploadSlot.fromJson(slot.toJson());
      expect(back.uploadUrl, slot.uploadUrl);
      expect(back.publicUrl, slot.publicUrl);
      expect(back.headers, slot.headers);
    });

    test('headers are optional', () {
      UploadSlot back = UploadSlot.fromJson(<String, Object?>{
        'uploadUrl': 'https://s3.test/x',
        'publicUrl': 'https://cdn.test/x',
      });
      expect(back.headers, isEmpty);
    });

    test('toJson hands out a copy of the headers', () {
      Map<String, Object?> json = slot.toJson();
      (json['headers']! as Map<String, String>)['x'] = 'y';
      expect(slot.headers, <String, String>{'content-type': 'image/png'});
    });

    test('a missing or mistyped field is a FormatException', () {
      expect(
        () => UploadSlot.fromJson(<String, Object?>{
          'uploadUrl': 'https://s3.test/x',
        }),
        throwsFormatException,
      );
      expect(
        () => UploadSlot.fromJson(<String, Object?>{
          'uploadUrl': 1,
          'publicUrl': 'https://cdn.test/x',
        }),
        throwsFormatException,
      );
      expect(
        () => UploadSlot.fromJson(<String, Object?>{
          'uploadUrl': 'https://s3.test/x',
          'publicUrl': 'https://cdn.test/x',
          'headers': <String, Object?>{'content-type': 7},
        }),
        throwsFormatException,
      );
      expect(
        () => UploadSlot.fromJson(<String, Object?>{
          'uploadUrl': 'https://s3.test/x',
          'publicUrl': 'https://cdn.test/x',
          'headers': 'content-type',
        }),
        throwsFormatException,
      );
    });
  });
}

/// A client that says when it is closed.
class _TrackingClient extends MockClient {
  _TrackingClient(this.onClose)
    : super((http.Request request) async => http.Response('', 200));

  final void Function() onClose;

  @override
  void close() {
    onClose();
    super.close();
  }
}
