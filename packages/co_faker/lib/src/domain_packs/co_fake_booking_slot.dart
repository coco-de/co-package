/// A UTC time block with consistent capacity and remaining seats.
class CoFakeBookingSlot {
  /// Creates an illustrative booking time block.
  const CoFakeBookingSlot({
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.remaining,
  });

  /// Inclusive UTC start.
  final DateTime startsAt;

  /// Exclusive UTC end, after [startsAt].
  final DateTime endsAt;

  /// Nonnegative capacity; zero for a closed slot.
  final int capacity;

  /// Seats in 0..capacity.
  final int remaining;

  /// Human-readable time range, using the UTC fixture clock.
  String get label =>
      '${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}–${endsAt.hour.toString().padLeft(2, '0')}:${endsAt.minute.toString().padLeft(2, '0')}';

  /// Primitive JSON adapter with UTC dates.
  Map<String, Object?> toJson() => {
    'label': label,
    'startsAt': startsAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'capacity': capacity,
    'remaining': remaining,
  };
}
