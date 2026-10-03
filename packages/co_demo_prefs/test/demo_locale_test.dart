import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:test/test.dart';

void main() {
  group('DemoLocale.parse', () {
    test('should_return_each_locale_when_given_its_own_tag', () {
      for (final locale in DemoLocale.values) {
        expect(DemoLocale.parse(locale.tag), locale, reason: locale.tag);
      }
    });

    test('should_ignore_case_separator_and_region_when_matching', () {
      expect(DemoLocale.parse('EN_us'), DemoLocale.en);
      expect(DemoLocale.parse(' de-AT '), DemoLocale.de);
      expect(DemoLocale.parse('pt-BR'), DemoLocale.pt);
      expect(DemoLocale.parse('pt_PT'), DemoLocale.pt);
      expect(DemoLocale.parse('ar-SA'), DemoLocale.ar);
    });

    test('should_map_simplified_chinese_variants_to_zh_hans_when_given', () {
      expect(DemoLocale.parse('zh'), DemoLocale.zhHans);
      expect(DemoLocale.parse('zh-CN'), DemoLocale.zhHans);
      expect(DemoLocale.parse('zh-hans'), DemoLocale.zhHans);
      expect(DemoLocale.parse('zh_Hans_CN'), DemoLocale.zhHans);
    });

    test('should_return_null_when_given_traditional_chinese', () {
      expect(DemoLocale.parse('zh-TW'), isNull);
      expect(DemoLocale.parse('zh-HK'), isNull);
      expect(DemoLocale.parse('zh-MO'), isNull);
      expect(DemoLocale.parse('zh-Hant'), isNull);
    });

    test('should_return_null_when_given_unknown_or_empty_value', () {
      expect(DemoLocale.parse(null), isNull);
      expect(DemoLocale.parse(''), isNull);
      expect(DemoLocale.parse('hi'), isNull);
      expect(DemoLocale.parse('//example.com'), isNull);
    });
  });

  group('DemoLocale subtags', () {
    test('should_split_language_and_script_when_locale_is_zh_hans', () {
      expect(DemoLocale.zhHans.languageCode, 'zh');
      expect(DemoLocale.zhHans.scriptCode, 'Hans');
      expect(DemoLocale.en.scriptCode, isNull);
    });

    test('should_flag_only_arabic_as_rtl_when_checked', () {
      expect(
        [
          for (final l in DemoLocale.values)
            if (l.isRtl) l,
        ],
        [DemoLocale.ar],
      );
    });
  });

  group('DemoTheme.parse', () {
    test('should_accept_light_and_dark_ignoring_case_when_given', () {
      expect(DemoTheme.parse('light'), DemoTheme.light);
      expect(DemoTheme.parse(' DARK '), DemoTheme.dark);
    });

    test('should_return_null_when_given_other_values', () {
      expect(DemoTheme.parse('system'), isNull);
      expect(DemoTheme.parse(''), isNull);
      expect(DemoTheme.parse(null), isNull);
    });
  });
}
