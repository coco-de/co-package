import 'dart:async';

import 'package:co_demo_world/co_demo_world.dart';
import 'package:test/test.dart';

void main() {
  group('DemoLocaleSwitcher', () {
    test('commits a request after its preparation', () async {
      final committed = <String>[];
      final switcher = DemoLocaleSwitcher(
        initial: DemoLocale.ko,
        onCommit: (previous, next) =>
            committed.add('${previous.tag}→${next.tag}'),
      );
      final result = await switcher.request(DemoLocale.en);
      expect(result, DemoLocale.en);
      expect(switcher.current, DemoLocale.en);
      expect(switcher.isSwitching, isFalse);
      expect(committed, ['ko→en']);
    });

    test('drops an older request that finishes after a newer one', () async {
      final gates = <DemoLocale, Completer<void>>{
        DemoLocale.en: Completer<void>(),
        DemoLocale.ja: Completer<void>(),
      };
      final switcher = DemoLocaleSwitcher(
        initial: DemoLocale.ko,
        prepare: (locale) => gates[locale]!.future,
      );
      final commits = <DemoLocale>[];
      switcher.commits.listen(commits.add);

      final en = switcher.request(DemoLocale.en);
      final ja = switcher.request(DemoLocale.ja);
      expect(switcher.pending, DemoLocale.ja);

      gates[DemoLocale.ja]!.complete();
      expect(await ja, DemoLocale.ja);
      gates[DemoLocale.en]!.complete();
      expect(await en, DemoLocale.ja);

      expect(commits, [DemoLocale.ja]);
      expect(switcher.current, DemoLocale.ja);
    });

    test('drops an older request that finishes first', () async {
      final gates = <DemoLocale, Completer<void>>{
        DemoLocale.en: Completer<void>(),
        DemoLocale.ar: Completer<void>(),
      };
      final switcher = DemoLocaleSwitcher(
        initial: DemoLocale.ko,
        prepare: (locale) => gates[locale]!.future,
      );
      final commits = <DemoLocale>[];
      switcher.commits.listen(commits.add);

      final en = switcher.request(DemoLocale.en);
      final ar = switcher.request(DemoLocale.ar);
      gates[DemoLocale.en]!.complete();
      expect(await en, DemoLocale.ko);
      expect(switcher.isSwitching, isTrue);
      gates[DemoLocale.ar]!.complete();
      expect(await ar, DemoLocale.ar);
      expect(commits, [DemoLocale.ar]);
    });

    test('keeps only the last of many rapid requests', () async {
      final switcher = DemoLocaleSwitcher(
        initial: DemoLocale.ko,
        prepare: (_) => Future<void>.delayed(Duration.zero),
      );
      final commits = <DemoLocale>[];
      switcher.commits.listen(commits.add);
      await Future.wait([
        switcher.request(DemoLocale.en),
        switcher.request(DemoLocale.ja),
        switcher.request(DemoLocale.ar),
        switcher.request(DemoLocale.de),
      ]);
      expect(commits, [DemoLocale.de]);
      expect(switcher.current, DemoLocale.de);
    });

    test('asking for the current language cancels a pending request', () async {
      final gate = Completer<void>();
      final switcher = DemoLocaleSwitcher(
        initial: DemoLocale.ko,
        prepare: (_) => gate.future,
      );
      final commits = <DemoLocale>[];
      switcher.commits.listen(commits.add);
      final en = switcher.request(DemoLocale.en);
      expect(await switcher.request(DemoLocale.ko), DemoLocale.ko);
      expect(switcher.isSwitching, isFalse);
      gate.complete();
      expect(await en, DemoLocale.ko);
      expect(commits, isEmpty);
    });

    test('a failed preparation keeps the current language', () async {
      final switcher = DemoLocaleSwitcher(
        initial: DemoLocale.ko,
        prepare: (locale) => locale == DemoLocale.ru
            ? Future<void>.error(StateError('no data'))
            : null,
      );
      expect(await switcher.request(DemoLocale.ru), DemoLocale.ko);
      expect(switcher.current, DemoLocale.ko);
      expect(switcher.isSwitching, isFalse);
      expect(switcher.lastError, isA<StateError>());

      expect(await switcher.request(DemoLocale.en), DemoLocale.en);
      expect(switcher.lastError, isNull);
    });

    test('switches the projection and the UI language in one step', () async {
      final projector = DisplayProjector(
        config: DemoWorldConfig(seed: 1, now: DateTime.utc(2026)),
        fields: DisplayFieldSet({
          'person.name': (faker, _) => faker.person.fullName(),
        }),
      );
      var uiLocale = DemoLocale.ko;
      final observed = <String>[];
      final key = DisplayKey('person', 'p-1', 'name');
      final switcher = DemoLocaleSwitcher(
        initial: DemoLocale.ko,
        prepare: (locale) => projector.warm([key], locale),
        onCommit: (_, next) {
          projector.locale = next;
          uiLocale = next;
        },
      );
      switcher.commits.listen((_) {
        observed.add('${uiLocale.tag}:${projector.locale.tag}');
      });
      await switcher.request(DemoLocale.ja);
      expect(observed, ['ja:ja']);
      expect(
        projector.text(key),
        projector.generated(key, locale: DemoLocale.ja),
      );
    });

    test('ignores requests after dispose', () async {
      final switcher = DemoLocaleSwitcher(initial: DemoLocale.ko);
      await switcher.dispose();
      expect(await switcher.request(DemoLocale.en), DemoLocale.ko);
    });
  });
}
