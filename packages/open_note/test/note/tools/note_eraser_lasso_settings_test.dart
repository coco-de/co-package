import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/tools.dart';

void main() {
  group('NoteEraserSettings', () {
    test('has the documented defaults', () {
      const settings = NoteEraserSettings();

      expect(settings.mode, NoteEraserMode.stroke);
      expect(settings.size, 12);
      expect(settings.pressureSwitchEnabled, isFalse);
      expect(settings.pressureThreshold, 0.8);
    });

    test('clamps size to 2-80 and threshold to 0.1-1', () {
      const low = NoteEraserSettings(size: 0, pressureThreshold: 0);
      const high = NoteEraserSettings(size: 500, pressureThreshold: 5);
      const broken = NoteEraserSettings(
        size: double.nan,
        pressureThreshold: double.infinity,
      );

      expect(low.size, 2);
      expect(low.pressureThreshold, 0.1);
      expect(high.size, 80);
      expect(high.pressureThreshold, 1);
      expect(broken.size, 12);
      expect(broken.pressureThreshold, 0.8);
    });

    test('switches only when enabled and the pressure reaches it', () {
      const on = NoteEraserSettings(pressureSwitchEnabled: true);

      expect(on.switchesAt(0.79), isFalse);
      expect(on.switchesAt(0.8), isTrue);
      expect(on.switchesAt(1), isTrue);
      expect(on.switchesAt(double.nan), isFalse);
      expect(const NoteEraserSettings().switchesAt(1), isFalse);
    });

    test('round trips through JSON', () {
      const settings = NoteEraserSettings(
        mode: NoteEraserMode.pixel,
        size: 33.5,
        pressureSwitchEnabled: true,
        pressureThreshold: 0.45,
      );
      final json = NoteJson.decodeMap(NoteJson.encode(settings.toJson()));

      expect(NoteEraserSettings.fromJson(json), settings);
      expect(settings.toJson()['mode'], 'pixel');
      expect(settings.copyWith(), settings);
      expect(settings.copyWith().hashCode, settings.hashCode);
      expect(settings.copyWith(size: 4), isNot(settings));
      expect(settings.toString(), contains('pixel'));
    });

    test('never throws on malformed JSON', () {
      for (final json in <Object?>[null, 3, 'x', <Object?>[], {}]) {
        expect(NoteEraserSettings.fromJson(json), const NoteEraserSettings());
      }
      expect(
        NoteEraserSettings.fromJson({
          'mode': 'laser',
          'size': '9',
          'pressureSwitchEnabled': 1,
          'pressureThreshold': -3,
        }),
        const NoteEraserSettings(pressureThreshold: 0.1),
      );
    });
  });

  group('NoteLassoSettings', () {
    test('defaults to freeform', () {
      expect(const NoteLassoSettings().shape, NoteLassoShape.freeform);
    });

    test('round trips through JSON', () {
      const settings = NoteLassoSettings(shape: NoteLassoShape.rectangle);

      expect(NoteLassoSettings.fromJson(settings.toJson()), settings);
      expect(settings.toJson(), {'shape': 'rectangle'});
      expect(settings.copyWith(), settings);
      expect(
        settings.copyWith(shape: NoteLassoShape.freeform),
        const NoteLassoSettings(),
      );
      expect(settings.hashCode, settings.copyWith().hashCode);
      expect(settings.toString(), contains('rectangle'));
    });

    test('never throws on malformed JSON', () {
      for (final json in <Object?>[
        null,
        3,
        {},
        {'shape': 'blob'},
      ]) {
        expect(NoteLassoSettings.fromJson(json), const NoteLassoSettings());
      }
    });
  });
}
