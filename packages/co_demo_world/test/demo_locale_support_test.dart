import 'package:co_demo_world/co_demo_world.dart';
import 'package:test/test.dart';

import 'support/sample_world.dart';

void main() {
  group('DemoLocaleSupport', () {
    late List<LocaleFieldReport> reports;

    setUpAll(() {
      reports = DemoLocaleSupport.evaluate(
        config: sampleConfig,
        fields: sampleFields(),
      );
    });

    LocaleFieldReport report(String fieldKey, DemoLocale locale) => reports
        .firstWhere((row) => row.fieldKey == fieldKey && row.locale == locale);

    test('has one row per field and language', () {
      expect(reports, hasLength(4 * DemoLocale.values.length));
    });

    test('measures the real output, not the requested locale', () {
      // Korean and English data exist for every sampled field.
      for (final field in ['pet.name', 'guardian.name', 'note.text']) {
        expect(report(field, DemoLocale.ko).status, LocaleFieldStatus.native);
        expect(report(field, DemoLocale.en).status, LocaleFieldStatus.native);
      }
      // A language co_faker serves in English is reported as such, whatever
      // was requested.
      for (final locale in DemoLocale.values) {
        if (!DemoFakerLocales.resolve(locale.tag).dataFallsBackToEnglish) {
          continue;
        }
        for (final field in ['pet.name', 'guardian.name', 'note.text']) {
          expect(
            report(field, locale).status,
            LocaleFieldStatus.englishFallback,
            reason: '${locale.tag} $field',
          );
        }
      }
    });

    test('a native verdict means the language script is really there', () {
      for (final row in reports) {
        if (row.status == LocaleFieldStatus.native) {
          expect(row.scriptShare, greaterThanOrEqualTo(0.5), reason: '$row');
        }
      }
    });

    test('Korean never leaks into another language', () {
      for (final row in reports) {
        expect(
          row.status,
          isNot(LocaleFieldStatus.koreanResidue),
          reason: '$row',
        );
      }
    });

    test('renders a Markdown table with all eleven languages', () {
      final table = DemoLocaleSupport.markdownTable(reports);
      final lines = table.trim().split('\n');
      expect(lines, hasLength(2 + 4));
      for (final locale in DemoLocale.values) {
        expect(lines.first, contains(' ${locale.tag} '));
      }
      expect(lines[2], startsWith('| `pet.name` |'));
    });
  });
}
