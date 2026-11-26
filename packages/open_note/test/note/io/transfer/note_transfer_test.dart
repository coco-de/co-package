import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/io/transfer/loopback_note_image_transfer_channel.dart';
import 'package:open_note/src/note/io/transfer/note_image_transfer_channel.dart';
import 'package:open_note/src/note/io/transfer/note_incoming_image.dart';
import 'package:open_note/src/note/io/transfer/note_transfer_pairing.dart';

NoteIncomingImage _image(String name) =>
    NoteIncomingImage(name: name, bytes: Uint8List.fromList([1, 2]));

void main() {
  var now = DateTime.utc(2026, 1, 1, 12);
  var ids = 0;

  setUp(() {
    now = DateTime.utc(2026, 1, 1, 12);
    ids = 0;
  });

  LoopbackNoteImageTransferChannel channel() {
    final created = LoopbackNoteImageTransferChannel(
      idFactory: () => 'session ${++ids}',
      clock: () => now,
      lifetime: const Duration(minutes: 5),
    );
    addTearDown(created.close);

    return created;
  }

  test('opens a pairing the phone can read back', () async {
    final NoteImageTransferChannel receiver = channel();

    final pairing = await receiver.open();

    expect(pairing.sessionId, 'session 1');
    expect(pairing.expiresAt, now.add(const Duration(minutes: 5)));
    expect(pairing.qrPayload, startsWith('open-note-transfer://pair?v=1&'));
    expect(
      LoopbackNoteImageTransferChannel.sessionIdOf(pairing.qrPayload),
      'session 1',
    );
    expect(LoopbackNoteImageTransferChannel.sessionIdOf('https://x'), isNull);
    expect(LoopbackNoteImageTransferChannel.sessionIdOf('::bad'), isNull);
  });

  test('keeps the pairing until it expires', () async {
    final receiver = channel();
    final first = await receiver.open();
    now = now.add(const Duration(minutes: 4));
    expect(await receiver.open(), first);

    now = now.add(const Duration(minutes: 1));
    final renewed = await receiver.open();

    expect(renewed.sessionId, 'session 2');
    expect(receiver.pairing, renewed);
  });

  test('delivers pictures in order to listeners', () async {
    final receiver = channel();
    final received = <String>[];
    final subscription = receiver.incoming.listen(
      (image) => received.add(image.name),
    );
    addTearDown(subscription.cancel);
    final pairing = await receiver.open();

    expect(receiver.send(_image('1.png')), isTrue);
    expect(
      receiver.send(_image('2.png'), sessionId: pairing.sessionId),
      isTrue,
    );
    await Future<void>.delayed(Duration.zero);

    expect(received, ['1.png', '2.png']);
  });

  test('refuses unopened, expired and foreign sends', () async {
    final receiver = channel();
    final received = <NoteIncomingImage>[];
    final subscription = receiver.incoming.listen(received.add);
    addTearDown(subscription.cancel);

    expect(receiver.send(_image('early')), isFalse);
    await receiver.open();
    expect(receiver.send(_image('other'), sessionId: 'nope'), isFalse);
    now = now.add(const Duration(minutes: 5));
    expect(receiver.send(_image('late')), isFalse);
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
  });

  test('closing ends the stream for good', () async {
    final receiver = channel();
    await receiver.open();
    final done = expectLater(receiver.incoming, emitsDone);

    await receiver.close();
    await receiver.close();
    await done;

    expect(receiver.isClosed, isTrue);
    expect(receiver.pairing, isNull);
    expect(receiver.send(_image('after')), isFalse);
    await expectLater(receiver.open(), throwsStateError);
  });

  test('pairings round trip through JSON and expire', () {
    final pairing = NoteTransferPairing(
      sessionId: 's',
      qrPayload: 'q',
      expiresAt: DateTime.utc(2026, 1, 1, 12, 5),
    );

    expect(NoteTransferPairing.fromJson(pairing.toJson()), pairing);
    expect(pairing.hashCode, pairing.copyWith().hashCode);
    expect(pairing.copyWith(sessionId: 't'), isNot(pairing));
    expect(pairing.isExpiredAt(DateTime.utc(2026, 1, 1, 12, 4, 59)), isFalse);
    expect(pairing.isExpiredAt(pairing.expiresAt), isTrue);
    expect('$pairing', contains('NoteTransferPairing(s'));
    final broken = NoteTransferPairing.fromJson({'expiresAt': 'never'});
    expect(broken.isExpiredAt(DateTime.utc(2000)), isTrue);
  });

  test('incoming pictures compare by content', () {
    expect(_image('a'), _image('a'));
    expect(_image('a').hashCode, _image('a').hashCode);
    expect(_image('a'), isNot(_image('b')));
    expect('${_image('a')}', 'NoteIncomingImage(a, 2 bytes)');
  });
}
