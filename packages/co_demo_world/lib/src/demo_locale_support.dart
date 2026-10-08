import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:co_faker/co_faker.dart';

import 'demo_faker_locales.dart';
import 'demo_world_config.dart';
import 'display_field_set.dart';
import 'display_key.dart';
import 'display_projector.dart';
import 'locale_field_report.dart';
import 'locale_field_status.dart';

/// Measures, from real co_faker output, which display fields a demo actually
/// gets in each of the eleven UI languages.
///
/// It checks the values the demo consumes, not the locale it asked for:
/// co_faker silently falls back to English for languages and fields it has
/// no data for, so asking for `ar` alone proves nothing.
abstract final class DemoLocaleSupport {
  /// Generates every field of [fields] for [sampleCount] synthetic ids (or
  /// the given [samples] keys per `entity.field`) in all eleven languages and
  /// classifies each (language, field).
  static List<LocaleFieldReport> evaluate({
    required DemoWorldConfig config,
    required DisplayFieldSet fields,
    Map<String, List<DisplayKey>>? samples,
    int sampleCount = 12,
    List<CoFakerDomain> domains = const <CoFakerDomain>[],
    Map<String, CoFakerLocale> customLocales = const <String, CoFakerLocale>{},
  }) {
    final projector = DisplayProjector(
      config: config,
      fields: fields,
      domains: domains,
      customLocales: customLocales,
    );
    final reports = <LocaleFieldReport>[];
    for (final fieldKey in fields.generators.keys) {
      final keys = samples?[fieldKey] ?? _syntheticKeys(fieldKey, sampleCount);
      final english = [
        for (final key in keys) projector.generated(key, locale: DemoLocale.en),
      ];
      for (final locale in DemoLocale.values) {
        final values = [
          for (final key in keys) projector.generated(key, locale: locale),
        ];
        reports.add(_classify(locale, fieldKey, values, english));
      }
    }
    return reports;
  }

  /// A Markdown table: one row per field, one column per language.
  static String markdownTable(List<LocaleFieldReport> reports) {
    final fieldKeys = <String>[];
    for (final report in reports) {
      if (!fieldKeys.contains(report.fieldKey)) fieldKeys.add(report.fieldKey);
    }
    final buffer = StringBuffer()
      ..writeln(
        '| field | ${DemoLocale.values.map((locale) => locale.tag).join(' | ')} |',
      )
      ..writeln(
        '|---|${List.filled(DemoLocale.values.length, '---').join('|')}|',
      );
    for (final fieldKey in fieldKeys) {
      final cells = [
        for (final locale in DemoLocale.values)
          _label(
            reports
                .firstWhere(
                  (report) =>
                      report.fieldKey == fieldKey && report.locale == locale,
                )
                .status,
          ),
      ];
      buffer.writeln('| `$fieldKey` | ${cells.join(' | ')} |');
    }
    return buffer.toString();
  }

  static String _label(LocaleFieldStatus status) => switch (status) {
    LocaleFieldStatus.native => 'native',
    LocaleFieldStatus.partialFallback => 'partial',
    LocaleFieldStatus.englishFallback => 'en-fallback',
    LocaleFieldStatus.koreanResidue => 'ko-residue',
    LocaleFieldStatus.scriptMismatch => 'script?',
  };

  static List<DisplayKey> _syntheticKeys(String fieldKey, int count) {
    final parts = fieldKey.split('.');
    return [
      for (var index = 1; index <= count; index++)
        DisplayKey(
          parts[0],
          'sample-${index.toString().padLeft(3, '0')}',
          parts[1],
        ),
    ];
  }

  static LocaleFieldReport _classify(
    DemoLocale locale,
    String fieldKey,
    List<String> values,
    List<String> english,
  ) {
    final count = values.length;
    var sameAsEnglish = 0;
    var withScript = 0;
    var withHangul = 0;
    final script = _scriptOf(locale);
    for (var index = 0; index < count; index++) {
      if (values[index] == english[index]) sameAsEnglish++;
      if (script == null || script.hasMatch(values[index])) withScript++;
      if (_hangul.hasMatch(values[index])) withHangul++;
    }
    final englishShare = count == 0 ? 0.0 : sameAsEnglish / count;
    final scriptShare = count == 0 ? 0.0 : withScript / count;
    final LocaleFieldStatus status;
    if (locale == DemoLocale.en) {
      status = withHangul > 0
          ? LocaleFieldStatus.koreanResidue
          : LocaleFieldStatus.native;
    } else if (locale != DemoLocale.ko && withHangul > 0) {
      status = LocaleFieldStatus.koreanResidue;
    } else if (_dataIsEnglish(locale) || englishShare >= 0.8) {
      status = LocaleFieldStatus.englishFallback;
    } else if (script != null && scriptShare < 0.5) {
      status = englishShare > 0
          ? LocaleFieldStatus.partialFallback
          : LocaleFieldStatus.scriptMismatch;
    } else if (englishShare >= 0.3) {
      status = LocaleFieldStatus.partialFallback;
    } else {
      status = LocaleFieldStatus.native;
    }
    return LocaleFieldReport(
      locale: locale,
      fieldKey: fieldKey,
      status: status,
      englishShare: englishShare,
      scriptShare: scriptShare,
      sample: values.isEmpty ? '' : values.first,
    );
  }

  /// Whether co_faker has no data for [locale] and generates it from English
  /// data — the values then differ from the `en_US` values but are English.
  static bool _dataIsEnglish(DemoLocale locale) =>
      DemoFakerLocales.fakerDataLocaleOf(locale).split('_').first == 'en';

  static final RegExp _hangul = RegExp('[ᄀ-ᇿ㄰-㆏가-힣]');

  /// The script a language's display text must contain, or `null` for
  /// Latin-script languages (judged by their difference from English).
  static RegExp? _scriptOf(DemoLocale locale) => switch (locale) {
    DemoLocale.ko => _hangul,
    DemoLocale.zhHans => RegExp('[㐀-䶿一-鿿]'),
    DemoLocale.ja => RegExp('[぀-ヿ㐀-䶿一-鿿]'),
    DemoLocale.ru => RegExp('[Ѐ-ӿ]'),
    DemoLocale.ar => RegExp('[؀-ۿݐ-ݿ]'),
    _ => null,
  };
}
