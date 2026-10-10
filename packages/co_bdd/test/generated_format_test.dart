import 'dart:io';

import 'package:co_bdd/src/generator/feature_parser.dart';
import 'package:co_bdd/src/generator/test_generator.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

/// 데모 저장소가 쓰는 형태를 한데 모은 feature — 태그 · Background ·
/// Given/When/Then/And · 표 · 다국어 인자 · 80자를 넘는 시나리오 이름과
/// step 호출 · 실행 대상 태그.
const _feature = '''
# 송금 견적 분해 — 라인은 KRW, 받는 금액은 헤더에만.
@remit @smoke
Feature: Remittance quote

  Background:
    Given the app is open as the sender at {'/quote?recipient=recipient-1'}

  Scenario: The tour quote splits the KRW lines and shows the receive amount in the header
    Then the {'remittance_quote_total'} widget should contain {'1,003,000원'} text
    And the {'remittance_quote_receive'} widget should contain {'17,850,000동'} text
    And the {'-2,000원'} text should be displayed

  @widget-only @validation
  Scenario: 만료된 견적은 다시 계산하기 전까지 다음 단계로 넘어가지 않는다
    When the quote validity time has passed
    Then the {'remittance_quote_expired'} widget should be displayed
    And the {'remittance_quote_next'} widget should be disabled
    And the {'تم تحديث سعر الصرف، يرجى المراجعة مرة أخرى'} text should be displayed

  @patrol-only
  Scenario: The recipient list shows every saved recipient
    Given the recipients are
      | name    | country |
      | Nguyễn  | VN      |
      | Santos  | PH      |
    Then the {'remittance_recipient_list'} widget should be displayed
''';

/// 생성기의 기본 언어 버전 — 빌더는 대상 패키지의 언어 버전을 넘긴다.
final _languageVersion = DartFormatter.latestLanguageVersion;

void main() {
  final feature = parseFeature(_feature);

  final outputs = <String, String Function()>{
    'widget_test': () =>
        generateWidgetTest(feature, stepFolder: 'step', useSharedSteps: true),
    'patrol_test': () =>
        generatePatrolTest(feature, stepFolder: 'step', useSharedSteps: true),
    'widget_test (local steps)': () =>
        generateWidgetTest(feature, stepFolder: 'step'),
    'patrol_test (local steps)': () =>
        generatePatrolTest(feature, stepFolder: 'step'),
  };

  group('생성 테스트는 dart format 결과와 바이트 동일하다 (#100)', () {
    for (final MapEntry(key: name, value: generate) in outputs.entries) {
      test('$name — DartFormatter 를 다시 적용해도 바뀌지 않는다', () {
        final code = generate();
        final formatted = DartFormatter(
          languageVersion: _languageVersion,
        ).format(code);

        expect(code, formatted);
      });

      test('$name — 같은 입력은 같은 바이트를 낸다', () {
        expect(generate(), generate());
      });
    }

    test('dart format CLI 가 생성물을 바꾸지 않는다', () async {
      final dir = await Directory.systemTemp.createTemp('co_bdd_format_');
      addTearDown(() => dir.delete(recursive: true));

      final files = <File>[];
      for (final (index, generate) in outputs.values.indexed) {
        final file = File('${dir.path}/generated_$index.dart');
        await file.writeAsString(generate());
        files.add(file);
      }

      final result = await Process.run('dart', [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        '--language-version=${_languageVersion.major}.'
            '${_languageVersion.minor}',
        for (final file in files) file.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    });
  });
}
