import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

void main() {
  group('NoteDurationFormat.clock', () {
    test('reads mm:ss below an hour', () {
      expect(NoteDurationFormat.clock(Duration.zero), '00:00');
      expect(NoteDurationFormat.clock(const Duration(seconds: 59)), '00:59');
      expect(NoteDurationFormat.clock(const Duration(seconds: 61)), '01:01');
      expect(
        NoteDurationFormat.clock(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
    });

    test('reads h:mm:ss from one hour up', () {
      expect(NoteDurationFormat.clock(const Duration(hours: 1)), '1:00:00');
      expect(
        NoteDurationFormat.clock(
          const Duration(hours: 25, minutes: 3, seconds: 7),
        ),
        '25:03:07',
      );
    });

    test('cuts partial seconds off unless rounding up', () {
      const value = Duration(seconds: 1, milliseconds: 500);

      expect(NoteDurationFormat.clock(value), '00:01');
      expect(NoteDurationFormat.clock(value, roundUp: true), '00:02');
      expect(
        NoteDurationFormat.clock(const Duration(seconds: 2), roundUp: true),
        '00:02',
      );
      expect(
        NoteDurationFormat.clock(
          const Duration(microseconds: 1),
          roundUp: true,
        ),
        '00:01',
      );
    });

    test('rounding up carries into the hour', () {
      expect(
        NoteDurationFormat.clock(
          const Duration(minutes: 59, seconds: 59, milliseconds: 1),
          roundUp: true,
        ),
        '1:00:00',
      );
    });

    test('negative values read zero', () {
      expect(NoteDurationFormat.clock(const Duration(seconds: -5)), '00:00');
      expect(
        NoteDurationFormat.clock(const Duration(seconds: -5), roundUp: true),
        '00:00',
      );
    });
  });
}
