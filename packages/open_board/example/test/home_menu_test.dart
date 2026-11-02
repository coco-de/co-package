import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board_example/i18n/strings.g.dart';
import 'package:open_board_example/main.dart';

void main() {
  for (final width in [320.0, 760.0, 1200.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final locale in [AppLocale.de, AppLocale.ar]) {
        testWidgets('home cards fit ${width}px at ${scale}x ${locale.name}', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          LocaleSettings.setLocaleSync(locale);
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.ko));
          await tester.pumpWidget(
            TranslationProvider(
              child: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const OpenBoardExampleApp(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            MediaQuery.textScalerOf(
              tester.element(find.byType(HomeMenuPage)),
            ).scale(10),
            10 * scale,
          );
          final t = locale.translations.home;
          expect(find.text(t.board.title), findsOneWidget);
          expect(find.text(t.split.title), findsOneWidget);
          expect(find.text(t.epub.title), findsOneWidget);
          final cards = find.byType(Card);
          expect(cards, findsNWidgets(3));
          final first = tester.getRect(cards.at(0));
          final second = tester.getRect(cards.at(1));
          final third = tester.getRect(cards.at(2));
          if (width == 320) {
            expect(second.top, greaterThan(first.bottom));
          } else {
            expect(first.top, second.top);
            expect(first.overlaps(second), isFalse);
          }
          if (width == 1200) {
            expect(first.top, third.top);
          }
          await tester.ensureVisible(find.text(t.epub.description));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
