import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/open_board.dart';
import 'package:open_board_example/i18n/strings.g.dart';
import 'package:open_board_example/widgets/drawing_toolbar.dart';

void main() {
  testWidgets('custom colors retain alpha and a long palette wraps', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.ko));
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final colors = <Color>[
      const Color(0x00000000),
      const Color(0x80FF0000),
      const Color(0xFF123456),
      for (var index = 0; index < 17; index++) Color(0xFF000000 + index),
    ];
    Color? selected;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: DrawingToolbar(
              colors: colors,
              selectedTool: DrawingTool.pen,
              selectedColor: colors.first,
              selectedWidth: 2,
              onToolSelected: (_) {},
              onColorSelected: (value) => selected = value,
              onWidthChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ink color: #00000000'), findsOneWidget);
    expect(find.byTooltip('Ink color: #FF000080'), findsOneWidget);
    expect(find.byTooltip('Ink color: #123456'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('drawing-color-1')));
    expect(selected, colors[1]);
    expect(tester.takeException(), isNull);
  });

  for (final locale in AppLocale.values) {
    testWidgets('color names describe the actual swatch in ${locale.name}', (
      tester,
    ) async {
      LocaleSettings.setLocaleSync(locale);
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.ko));
      final t = locale.translations.toolbar;
      final names = [
        t.colors.black,
        t.colors.red,
        t.colors.orange,
        t.colors.green,
        t.colors.blue,
        t.colors.purple,
      ];
      Color? selected;
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingToolbar(
                selectedTool: DrawingTool.pen,
                selectedColor: Colors.black,
                selectedWidth: 2,
                onToolSelected: (_) {},
                onColorSelected: (value) => selected = value,
                onWidthChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      for (final (index, color) in DrawingToolbar.defaultColors.indexed) {
        expect(find.byTooltip('${t.color}: ${names[index]}'), findsOneWidget);
        await tester.tap(find.byKey(ValueKey('drawing-color-$index')));
        expect(selected, color);
      }
    });
  }

  for (final locale in [AppLocale.ko, AppLocale.ar, AppLocale.de]) {
    testWidgets(
      'palette remains usable at 280px with large ${locale.name} text',
      (tester) async {
        LocaleSettings.setLocaleSync(locale);
        tester.view.physicalSize = const Size(280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.ko));
        Color? selected;
        await tester.pumpWidget(
          TranslationProvider(
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: DrawingToolbar(
                  selectedTool: DrawingTool.pen,
                  selectedColor: Colors.black,
                  selectedWidth: 2,
                  onToolSelected: (_) {},
                  onColorSelected: (value) => selected = value,
                  onWidthChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var index = 0; index < 6; index++) {
          final control = find.byKey(ValueKey('drawing-color-$index'));
          expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
        }
        final purple = find.byKey(const ValueKey('drawing-color-5'));
        await tester.tap(purple);
        expect(selected, Colors.purple);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
