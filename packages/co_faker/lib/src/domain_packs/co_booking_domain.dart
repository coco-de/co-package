import '../co_faker.dart';
import '../domain.dart';
import 'authored_roles.dart';
import 'co_fake_booking_slot.dart';
import 'co_faker_booking.dart';

/// Common reusable booking numbers, time labels and coherent slot fields.
class CoBookingDomain extends CoFakerDomain {
  /// Creates the pack.
  const CoBookingDomain();
  @override
  String get name => 'booking';
  static CoFakeBookingSlot _slot(CoFaker f, CoDomainRoleContext c) =>
      CoFakerBooking(f.derive('booking/slot')).slot(index: c.index);
  @override
  Map<String, CoDomainRole> get roles => {
    'bookingNo': codeRole('DEMO-BK', dated: true),
    'reservationNo': codeRole('DEMO-RS', dated: true),
    'timeSlotLabel': authoredRole((f, c) => _slot(f, c).label, coherent: true),
    'slotLabel': authoredRole((f, c) => _slot(f, c).label, coherent: true),
    'cancelReason': textRole('booking.cancelReason'),
    'startsAt': authoredRole(
      (f, c) => _slot(f, c).startsAt,
      type: 'DateTime',
      coherent: true,
    ),
    'endsAt': authoredRole(
      (f, c) => _slot(f, c).endsAt,
      type: 'DateTime',
      coherent: true,
    ),
    'remaining': authoredRole(
      (f, c) => _slot(f, c).remaining,
      type: 'int',
      coherent: true,
    ),
    'capacity': authoredRole(
      (f, c) => _slot(f, c).capacity,
      type: 'int',
      coherent: true,
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'booking_slot': {
      'id': 'int',
      'label': 'String',
      'startsAt': 'DateTime',
      'endsAt': 'DateTime',
      'remaining': 'int',
      'capacity': 'int',
    },
    'reservation': {
      'id': 'int',
      'bookingNo': 'String',
      'slotId': 'int',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'booking_slot': {
      'label': 'timeSlotLabel',
      'startsAt': 'startsAt',
      'endsAt': 'endsAt',
      'remaining': 'remaining',
      'capacity': 'capacity',
    },
    'reservation': {'bookingNo': 'bookingNo'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'reservation': {
      'status': ['requested', 'confirmed', 'completed', 'cancelled', 'no_show'],
    },
  };
}
