import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import 'note_view_test_support.dart';

void main() {
  group('NoteZoomPresets', () {
    test('toggle adds sorted levels and removes them again', () {
      final presets = NoteZoomPresets();
      final counter = NotifyCounter(presets);

      expect(presets.toggle(2), isTrue);
      expect(presets.toggle(0.5), isTrue);
      expect(presets.toggle(1), isTrue);
      expect(presets.levels, [0.5, 1, 2]);
      expect(presets.toggle(1), isFalse);
      expect(presets.levels, [0.5, 2]);
      expect(counter.count, 4);
    });

    test('clamps to 0.25–8', () {
      final presets = NoteZoomPresets()
        ..toggle(100)
        ..toggle(0.01);

      expect(presets.levels, [0.25, 8]);
      expect(presets.toggle(20), isFalse, reason: '8 is already there');
      expect(presets.levels, [0.25]);
    });

    test('treats nearly equal factors as one', () {
      final presets = NoteZoomPresets()..toggle(1);

      expect(presets.contains(1.004), isTrue);
      expect(presets.contains(1.01), isFalse);
      expect(presets.toggle(1.0000001), isFalse);
      expect(presets.levels, isEmpty);
    });

    test('holds at most eight', () {
      final presets = NoteZoomPresets([for (var i = 1; i <= 12; i++) i * 0.5]);

      expect(presets.levels, hasLength(8));
      expect(presets.isFull, isTrue);
      final counter = NotifyCounter(presets);
      expect(presets.toggle(7.5), isFalse);
      expect(counter.count, 0);
      expect(presets.toggle(0.5), isFalse, reason: 'removal still works');
      expect(presets.levels, hasLength(7));
    });

    test('ignores non-finite input', () {
      final presets = NoteZoomPresets([double.nan, 2]);

      expect(presets.levels, [2]);
      expect(presets.toggle(double.infinity), isFalse);
      expect(presets.contains(double.nan), isFalse);
    });

    test('nextAfter cycles through the favourites', () {
      final presets = NoteZoomPresets([1, 2, 4]);

      expect(presets.nextAfter(0.5), 1);
      expect(presets.nextAfter(1), 2);
      expect(presets.nextAfter(3), 4);
      expect(presets.nextAfter(4), 1);
      expect(NoteZoomPresets().nextAfter(1), isNull);
    });

    test('levels cannot be edited from outside', () {
      expect(() => NoteZoomPresets([1]).levels.add(2), throwsUnsupportedError);
    });

    test('round-trips through json', () {
      final presets = NoteZoomPresets([0.75, 1.5, 3]);

      expect(presets.toJson(), {
        'levels': [0.75, 1.5, 3.0],
      });
      expect(NoteZoomPresets.fromJson(presets.toJson()).levels, presets.levels);
    });

    test('survives junk', () {
      for (final junk in <Object?>[
        null,
        'x',
        5,
        {'levels': 'many'},
      ]) {
        expect(NoteZoomPresets.fromJson(junk).levels, isEmpty);
      }
      expect(
        NoteZoomPresets.fromJson({
          'levels': [null, 'a', 2, 2, 1000, -3],
        }).levels,
        [0.25, 2, 8],
      );
    });

    test('does nothing after dispose', () {
      final presets = NoteZoomPresets([1])..dispose();

      expect(presets.toggle(2), isFalse);
      expect(presets.levels, [1]);
    });
  });

  group('NoteZoomLock', () {
    test('toggles and notifies only on change', () {
      final lock = NoteZoomLock();
      final counter = NotifyCounter(lock);

      lock.setLocked(false);
      lock.toggle();
      expect(lock.locked, isTrue);
      lock.setLocked(true);
      expect(counter.count, 1);
    });

    test('round-trips through json and survives junk', () {
      final lock = NoteZoomLock(locked: true);

      expect(lock.toJson(), {'locked': true});
      expect(NoteZoomLock.fromJson(lock.toJson()).locked, isTrue);
      expect(NoteZoomLock.fromJson('junk').locked, isFalse);
      expect(NoteZoomLock.fromJson({'locked': 'yes'}).locked, isFalse);
    });

    test('does nothing after dispose', () {
      final lock = NoteZoomLock()..dispose();

      lock.toggle();

      expect(lock.locked, isFalse);
    });
  });
}
