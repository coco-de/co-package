import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// An open image transfer: what the phone scans to send pictures to this
/// device.
///
/// JSON schema: `{"sessionId": String, "qrPayload": String, "expiresAt":
/// ISO-8601 String}`.
@immutable
class NoteTransferPairing {
  /// A pairing [sessionId] advertised as [qrPayload] until [expiresAt].
  const NoteTransferPairing({
    required this.sessionId,
    required this.qrPayload,
    required this.expiresAt,
  });

  /// Lenient decoding: a bad date is the Unix epoch (so it reads as expired).
  factory NoteTransferPairing.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? <String, Object?>{};

    return NoteTransferPairing(
      sessionId: NoteJson.string(json, 'sessionId'),
      qrPayload: NoteJson.string(json, 'qrPayload'),
      expiresAt:
          DateTime.tryParse(NoteJson.string(json, 'expiresAt')) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /// Identifies the transfer.
  final String sessionId;

  /// The text to show as a QR code.
  final String qrPayload;

  /// After this moment the pairing no longer accepts pictures.
  final DateTime expiresAt;

  /// Whether the pairing is over at [now].
  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  /// A copy with the given fields replaced.
  NoteTransferPairing copyWith({
    String? sessionId,
    String? qrPayload,
    DateTime? expiresAt,
  }) => NoteTransferPairing(
    sessionId: sessionId ?? this.sessionId,
    qrPayload: qrPayload ?? this.qrPayload,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'sessionId': sessionId,
    'qrPayload': qrPayload,
    'expiresAt': expiresAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is NoteTransferPairing &&
      other.sessionId == sessionId &&
      other.qrPayload == qrPayload &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(sessionId, qrPayload, expiresAt);

  @override
  String toString() => 'NoteTransferPairing($sessionId, until $expiresAt)';
}
