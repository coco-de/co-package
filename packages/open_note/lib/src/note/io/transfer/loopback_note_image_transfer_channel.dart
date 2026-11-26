import 'dart:async';

import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/transfer/note_image_transfer_channel.dart';
import 'package:open_note/src/note/io/transfer/note_incoming_image.dart';
import 'package:open_note/src/note/io/transfer/note_transfer_pairing.dart';

/// An in-process [NoteImageTransferChannel] for tests and the example app:
/// [send] plays the phone.
///
/// [incoming] is a broadcast stream, so a picture sent while nobody listens is
/// dropped. A closed channel cannot be opened again.
class LoopbackNoteImageTransferChannel implements NoteImageTransferChannel {
  /// A channel whose pairings last [lifetime].
  LoopbackNoteImageTransferChannel({
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
    this.lifetime = const Duration(minutes: 10),
  }) : _idFactory = idFactory,
       _clock = clock;

  static const String _scheme = 'open-note-transfer';

  /// How long a pairing accepts pictures.
  final Duration lifetime;

  final NoteIdFactory _idFactory;
  final NoteClock _clock;
  final StreamController<NoteIncomingImage> _images =
      StreamController<NoteIncomingImage>.broadcast();
  NoteTransferPairing? _pairing;
  bool _closed = false;

  /// The current pairing, if the channel was opened.
  NoteTransferPairing? get pairing => _pairing;

  /// Whether [close] was called.
  bool get isClosed => _closed;

  /// The session named by a payload made by this channel, or `null`.
  static String? sessionIdOf(String qrPayload) {
    final uri = Uri.tryParse(qrPayload);
    if (uri == null || uri.scheme != _scheme) return null;

    return uri.queryParameters['session'];
  }

  /// The current pairing while it is valid, otherwise a new one. Throws
  /// [StateError] after [close].
  @override
  Future<NoteTransferPairing> open() async {
    if (_closed) throw StateError('the transfer channel is closed');
    final now = _clock();
    final current = _pairing;
    if (current != null && !current.isExpiredAt(now)) return current;
    final sessionId = _idFactory();

    return _pairing = NoteTransferPairing(
      sessionId: sessionId,
      qrPayload: Uri(
        scheme: _scheme,
        host: 'pair',
        queryParameters: {'v': '1', 'session': sessionId},
      ).toString(),
      expiresAt: now.add(lifetime),
    );
  }

  @override
  Stream<NoteIncomingImage> get incoming => _images.stream;

  /// Delivers [image] as the paired phone would. Returns false and delivers
  /// nothing when the channel is not open, the pairing has expired, or
  /// [sessionId] (when given) is not the current session.
  bool send(NoteIncomingImage image, {String? sessionId}) {
    final current = _pairing;
    if (_closed || current == null || current.isExpiredAt(_clock())) {
      return false;
    }
    if (sessionId != null && sessionId != current.sessionId) return false;
    _images.add(image);

    return true;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _pairing = null;
    await _images.close();
  }
}
