import 'package:open_note/src/note/io/transfer/note_incoming_image.dart';
import 'package:open_note/src/note/io/transfer/note_transfer_pairing.dart';

/// Receiving pictures from a phone onto a tablet. The network transport (and
/// the phone side) is a host plug-in.
abstract interface class NoteImageTransferChannel {
  /// Starts receiving and returns what the sender needs to pair.
  Future<NoteTransferPairing> open();

  /// The received pictures. Listen before showing the pairing; it ends when
  /// the channel is closed.
  Stream<NoteIncomingImage> get incoming;

  /// Stops receiving and releases the channel.
  Future<void> close();
}
