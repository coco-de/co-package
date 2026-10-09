// 공개 데모(웹)와 골든 · 위젯 테스트(VM)가 같은 세계를 보여야 한다 — 같은 seed · 기준 시각이면
// 업무 데이터와 언어별 표시 데이터가 VM · dart2js · dart2wasm 에서 같다(co-package#69 수정 위).
// 기대값은 VM 에서 계산했다. CI 는 이 파일을 VM 과 chrome 에서 돌린다.
@TestOn('vm || browser')
library;

import 'package:co_demo_world/co_demo_world.dart';
import 'package:test/test.dart';

import 'support/sample_world.dart';

void main() {
  test('business data is the same on every platform', () {
    final pets = buildSamplePets(sampleConfig, count: 3);
    expect(pets, const [
      SamplePet(
        id: 'pet-0001',
        weightGrams: 10532,
        status: 'booked',
        priceWon: 27000,
      ),
      SamplePet(
        id: 'pet-0002',
        weightGrams: 8996,
        status: 'booked',
        priceWon: 103000,
      ),
      SamplePet(
        id: 'pet-0003',
        weightGrams: 29171,
        status: 'vaccinated',
        priceWon: 489000,
      ),
    ]);
  });

  test('display data is the same on every platform', () {
    final pets = buildSamplePets(sampleConfig, count: 3);
    final keys = sampleKeys(pets).take(6).toList();
    final projector = DisplayProjector(
      config: sampleConfig,
      fields: sampleFields(),
    );
    List<String> projected(DemoLocale locale) => [
      for (final key in keys) projector.generated(key, locale: locale),
    ];

    expect(projected(DemoLocale.ko), [
      '나비',
      '양연우',
      '춘천',
      '사용자 회고 창작 세계 준비 동네.',
      '두부',
      '박채은',
    ]);
    // The domain lists of the languages are aligned: the same record comes out
    // translated (나비 ↔ Butterfly ↔ ちょうちょ, 두부 ↔ Tofu ↔ とうふ).
    expect(projected(DemoLocale.en), [
      'Butterfly',
      'Alexander White',
      'Austin',
      'Calendar archive calendar detail quiet pattern.',
      'Tofu',
      'William Williams',
    ]);
    expect(projected(DemoLocale.ja), [
      'ちょうちょ',
      '中村 颯',
      '横浜市西区',
      '記録習慣記録絵地域設計。',
      'とうふ',
      '山崎 大翔',
    ]);
  });
}
