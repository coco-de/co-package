import '../co_faker.dart';
import 'co_fake_booking_slot.dart';

/// Seeded, offline booking blocks for veterinary, fitness and rental recipes.
class CoFakerBooking {
  /// Uses only the supplied faker clock and derived streams.
  const CoFakerBooking(this.faker);

  /// Locale, clock and source of derived streams.
  final CoFaker faker;

  /// Creates one UTC block. Consecutive indices proceed through days in order.
  CoFakeBookingSlot slot({
    int index = 0,
    DateTime? startDate,
    int blocksPerDay = 16,
    int durationMinutes = 30,
    int startHour = 9,
    int capacity = 3,
    bool sundayClosed = false,
  }) {
    if (index < 0 ||
        blocksPerDay < 1 ||
        blocksPerDay > 48 ||
        durationMinutes < 1 ||
        durationMinutes > 1440 ||
        startHour < 0 ||
        startHour > 23 ||
        startHour * 60 + blocksPerDay * durationMinutes > 1440 ||
        capacity < 0) {
      throw ArgumentError('Invalid booking block geometry/capacity');
    }
    final utc = (startDate ?? faker.now).toUtc();
    final day = DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
    ).add(Duration(days: index ~/ blocksPerDay));
    final start = day.add(
      Duration(
        hours: startHour,
        minutes: (index % blocksPerDay) * durationMinutes,
      ),
    );
    final available = sundayClosed && day.weekday == DateTime.sunday
        ? 0
        : capacity;
    return CoFakeBookingSlot(
      startsAt: start,
      endsAt: start.add(Duration(minutes: durationMinutes)),
      capacity: available,
      remaining: faker
          .derive('booking/${start.toIso8601String()}')
          .number
          .int(max: available),
    );
  }

  /// Returns a grid with optional Sunday closure. Extending it preserves slots.
  List<CoFakeBookingSlot> slots({
    int days = 7,
    DateTime? startDate,
    int blocksPerDay = 16,
    int durationMinutes = 30,
    int startHour = 9,
    int capacity = 3,
    bool sundayClosed = false,
  }) {
    if (days < 1 || days > 366) {
      throw ArgumentError.value(days, 'days', '1..366');
    }
    return List.generate(
      days * blocksPerDay,
      (i) => slot(
        index: i,
        startDate: startDate,
        blocksPerDay: blocksPerDay,
        durationMinutes: durationMinutes,
        startHour: startHour,
        capacity: capacity,
        sundayClosed: sundayClosed,
      ),
      growable: false,
    );
  }
}
