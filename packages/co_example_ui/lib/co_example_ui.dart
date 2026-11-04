library;

import 'dart:math' as math;

import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:coui_flutter/coui_flutter.dart' as co;
import 'package:flutter/material.dart';

/// The same resolved CoUI palette drives Material content and CoUI controls.
ThemeData exampleMaterialTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark
      ? co.CoreThemePresets.darkColorScheme
      : co.CoreThemePresets.lightColorScheme;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: tokens.primary.toValue(),
        brightness: brightness,
      ).copyWith(
        primary: tokens.primary.toValue(),
        onPrimary: tokens.onPrimary.toValue(),
        surface: tokens.surface.toValue(),
        onSurface: tokens.onSurface.toValue(),
        onSurfaceVariant: tokens.onSurfaceVariant.toValue(),
        outlineVariant: tokens.outlineVariant.toValue(),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'packages/co_example_ui/Pretendard',
    fontFamilyFallback: const ['packages/co_example_ui/NotoSansArabic'],
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'packages/co_example_ui/Pretendard',
        fontFamilyFallback: const ['packages/co_example_ui/NotoSansArabic'],
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 400),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
  );
}

/// Mount inside MaterialApp.builder so routes, dialogs and overlays share it.
class ExampleThemeScope extends StatelessWidget {
  const ExampleThemeScope({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final core = Theme.of(context).brightness == Brightness.dark
        ? co.CoreThemePresets.dark
        : co.CoreThemePresets.light;
    return co.Theme(
      data: co.ThemeData.fromCore(
        core.copyWith(
          typography: core.typography.withFamily(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'packages/co_example_ui/NotoSansArabic'
                : 'packages/co_example_ui/Pretendard',
            roles: co.CoreTextStyles.values.where(
              (role) => !role.name.startsWith('code-'),
            ),
          ),
          tapSoundEnabled: false,
        ),
      ),
      child: child,
    );
  }
}

class ExampleSettings extends StatelessWidget {
  const ExampleSettings({
    required this.themeMode,
    this.locale,
    this.onLocaleChanged,
    super.key,
  });
  final ValueNotifier<ThemeMode> themeMode;
  final DemoLocale? locale;
  final ValueChanged<DemoLocale>? onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final copy = ExampleCopy.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onLocaleChanged != null)
          PopupMenuButton<DemoLocale>(
            tooltip: copy.language,
            initialValue: locale,
            icon: const Icon(Icons.translate_rounded),
            onSelected: onLocaleChanged,
            itemBuilder: (_) => [
              for (final value in DemoLocale.values)
                PopupMenuItem(value: value, child: Text(_localeNames[value]!)),
            ],
          ),
        IconButton(
          key: const ValueKey('example-theme-toggle'),
          tooltip: dark ? copy.light : copy.dark,
          onPressed: () =>
              themeMode.value = dark ? ThemeMode.light : ThemeMode.dark,
          icon: Icon(
            dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

const _localeNames = {
  DemoLocale.ko: '한국어',
  DemoLocale.en: 'English',
  DemoLocale.ja: '日本語',
  DemoLocale.zhHans: '简体中文',
  DemoLocale.es: 'Español',
  DemoLocale.fr: 'Français',
  DemoLocale.de: 'Deutsch',
  DemoLocale.pt: 'Português',
  DemoLocale.it: 'Italiano',
  DemoLocale.ru: 'Русский',
  DemoLocale.ar: 'العربية',
};

@immutable
class ExampleEntry {
  const ExampleEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.page,
    this.id,
  });
  final String title;
  final String description;
  final IconData icon;
  final Widget page;
  final String? id;
}

/// A scrollable, content-sized catalog: no fixed card heights or clipped copy.
class ExampleCatalog extends StatelessWidget {
  const ExampleCatalog({
    required this.title,
    required this.product,
    required this.entries,
    required this.settings,
    this.reading = false,
    super.key,
  });
  final String title;
  final String product;
  final List<ExampleEntry> entries;
  final Widget settings;
  final bool reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final copy = ExampleCopy.of(context);
    void open(ExampleEntry entry) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => entry.page));
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'co.',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [settings],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final intro = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$product / ${copy.playground}',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              reading ? copy.readTitle : copy.drawTitle,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              entries.first.description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.65,
                              ),
                            ),
                            const SizedBox(height: 24),
                            co.Button(
                              key: const ValueKey('example-start'),
                              onPressed: () => open(entries.first),
                              trailing: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              child: Text(copy.start),
                            ),
                          ],
                        );
                        if (constraints.maxWidth < 700) return intro;
                        return Row(
                          children: [
                            Expanded(child: intro),
                            const SizedBox(width: 56),
                            Expanded(child: ExamplePreview(reading: reading)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Text(
                          copy.explore,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        co.Badge(
                          child: Text(
                            entries.length.toString().padLeft(2, '0'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 850
                            ? 3
                            : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - 16 * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final (index, entry) in entries.indexed)
                              SizedBox(
                                width: width,
                                key: entry.id == null
                                    ? null
                                    : ValueKey<String>(entry.id!),
                                child: co.Card(
                                  onTap: () => open(entry),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            entry.icon,
                                            size: 26,
                                            color: cs.primary,
                                          ),
                                          const Spacer(),
                                          Text(
                                            '0${index + 1}',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        entry.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        entry.description,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              height: 1.55,
                                            ),
                                      ),
                                      const SizedBox(height: 20),
                                      Align(
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                          color: cs.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 20),
                    Text(
                      'Cocode  /  $product',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small non-interactive illustration of the actual workspace content.
class ExamplePreview extends StatelessWidget {
  const ExamplePreview({required this.reading, super.key});
  final bool reading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.55,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: .055),
            borderRadius: BorderRadius.circular(24),
          ),
          child: CustomPaint(painter: _PreviewPainter(reading, cs)),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.reading, this.colors);
  final bool reading;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paper = Rect.fromLTWH(12, 8, size.width - 24, size.height - 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(paper, const Radius.circular(12)),
      Paint()..color = colors.surface,
    );
    final stroke = Paint()
      ..color = colors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (reading) {
      final center = size.width / 2;
      canvas.drawLine(
        Offset(center, 20),
        Offset(center, size.height - 20),
        Paint()..color = colors.outlineVariant,
      );
      for (var page = 0; page < 2; page++) {
        final x = 28 + page * (center - 8);
        for (var row = 0; row < 7; row++) {
          final y = 38.0 + row * 15;
          if (y > size.height - 30) break;
          canvas.drawLine(
            Offset(x, y),
            Offset(
              math.min(x + center - 48 - (row % 3) * 9, size.width - 28),
              y,
            ),
            Paint()
              ..color = colors.onSurfaceVariant.withValues(alpha: .25)
              ..strokeWidth = row == 0 ? 5 : 3
              ..strokeCap = StrokeCap.round,
          );
        }
      }
      canvas.drawLine(
        Offset(28, 83),
        Offset(center - 30, 83),
        Paint()
          ..color = colors.primary.withValues(alpha: .22)
          ..strokeWidth = 12,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(center + 26, 8, 16, 40),
          const Radius.circular(3),
        ),
        Paint()..color = colors.primary,
      );
    } else {
      final path = Path()
        ..moveTo(36, size.height * .6)
        ..cubicTo(
          size.width * .25,
          2,
          size.width * .45,
          size.height,
          size.width * .62,
          size.height * .38,
        )
        ..quadraticBezierTo(
          size.width * .75,
          size.height * .1,
          size.width - 36,
          size.height * .4,
        );
      canvas.drawPath(path, stroke);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .44, size.height * .52),
          width: 70,
          height: 50,
        ),
        stroke
          ..color = const Color(0xffef9b52)
          ..strokeWidth = 2,
      );
      for (var i = 0; i < 4; i++) {
        canvas.drawCircle(
          Offset(size.width - 38 - i * 22, size.height - 30),
          6,
          Paint()
            ..color = [
              colors.primary,
              const Color(0xffef9b52),
              const Color(0xff61a593),
              colors.onSurface,
            ][i],
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) =>
      oldDelegate.reading != reading || oldDelegate.colors != colors;
}

/// Only shared navigation copy lives here; each app owns its feature copy.
class ExampleCopy {
  const ExampleCopy(this.values);
  final List<String> values;
  String get playground => values[0];
  String get drawTitle => values[1];
  String get readTitle => values[2];
  String get start => values[3];
  String get explore => values[4];
  String get language => values[5];
  String get light => values[6];
  String get dark => values[7];

  static ExampleCopy of(BuildContext context) => ExampleCopy(
    _copy[Localizations.localeOf(context).languageCode] ?? _copy['en']!,
  );
}

const _copy = {
  'en': [
    'PLAYGROUND',
    'A little space.\nA world of ideas.',
    'A new chapter\nstarts here.',
    'Try it now',
    'Explore the demos',
    'Language',
    'Light theme',
    'Dark theme',
  ],
  'ko': [
    '플레이그라운드',
    '생각을 그리는\n나만의 공간.',
    '새로운 이야기를\n펼쳐보세요.',
    '바로 시작하기',
    '데모 둘러보기',
    '언어 선택',
    '밝은 테마',
    '어두운 테마',
  ],
  'ja': [
    'プレイグラウンド',
    'アイデアを描く、\n自分だけの空間。',
    '新しい物語を\n開いてみよう。',
    '今すぐ試す',
    'デモを見る',
    '言語',
    'ライトテーマ',
    'ダークテーマ',
  ],
  'zh': [
    '体验空间',
    '描绘想法的\n自由空间。',
    '翻开故事的\n全新篇章。',
    '立即体验',
    '探索示例',
    '语言',
    '浅色主题',
    '深色主题',
  ],
  'fr': [
    'DÉCOUVERTE',
    'Un espace pour\ntoutes vos idées.',
    'Un nouveau chapitre\ncommence ici.',
    'Essayer',
    'Explorer les démos',
    'Langue',
    'Thème clair',
    'Thème sombre',
  ],
  'de': [
    'SPIELWIESE',
    'Ein Raum für\nIhre Ideen.',
    'Ein neues Kapitel\nbeginnt hier.',
    'Jetzt ausprobieren',
    'Demos entdecken',
    'Sprache',
    'Helles Design',
    'Dunkles Design',
  ],
  'es': [
    'EXPLORA',
    'Un espacio para\ntodas tus ideas.',
    'Un nuevo capítulo\ncomienza aquí.',
    'Probar ahora',
    'Explorar demos',
    'Idioma',
    'Tema claro',
    'Tema oscuro',
  ],
  'pt': [
    'EXPERIMENTE',
    'Um espaço para\ntodas as ideias.',
    'Um novo capítulo\ncomeça aqui.',
    'Experimentar',
    'Explorar demos',
    'Idioma',
    'Tema claro',
    'Tema escuro',
  ],
  'it': [
    'ESPLORA',
    'Uno spazio per\nle tue idee.',
    'Un nuovo capitolo\ninizia qui.',
    'Prova ora',
    'Esplora le demo',
    'Lingua',
    'Tema chiaro',
    'Tema scuro',
  ],
  'ru': [
    'ПЕСОЧНИЦА',
    'Пространство\nдля ваших идей.',
    'Новая глава\nначинается здесь.',
    'Попробовать',
    'Посмотреть демо',
    'Язык',
    'Светлая тема',
    'Тёмная тема',
  ],
  'ar': [
    'مساحة التجربة',
    'مساحة صغيرة\nلعالم من الأفكار.',
    'فصل جديد\nيبدأ هنا.',
    'جرّب الآن',
    'استكشف العروض',
    'اللغة',
    'المظهر الفاتح',
    'المظهر الداكن',
  ],
};
