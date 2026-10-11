// `HarnessFonts.settleWith` 회귀 테스트 (coco-de/demo-ecommerce-grocery#16).
//
// 확정 규칙 셋을 고정한다 — ① 첫 알림이 없으면 [firstChange] 뒤 확정
// ② 알림이 오면 [quiet] 동안 조용해야 확정 ③ 상한을 넘으면 조용히 넘어가지
// 않고 TimeoutException 으로 실패한다.
import 'dart:async';

import 'package:co_bdd/co_bdd.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// `systemFonts` 대역 — 알림을 직접 보낸다.
class _Fonts extends ChangeNotifier {
  void change() => notifyListeners();

  bool get listening => hasListeners;
}

void main() {
  late _Fonts fonts;
  late Set<int> settled;
  late List<String> laidOut;

  setUp(() {
    fonts = _Fonts();
    settled = <int>{};
    laidOut = [];
  });
  tearDown(() => fonts.dispose());

  Future<HarnessFontsReport> settle(
    Iterable<String> texts, {
    void Function(String text)? layout,
    Duration firstChange = const Duration(milliseconds: 100),
    Duration quiet = const Duration(milliseconds: 100),
    Duration timeout = const Duration(seconds: 2),
  }) => HarnessFonts.settleWith(
    texts,
    systemFonts: fonts,
    layout: layout ?? laidOut.add,
    settled: settled,
    firstChange: firstChange,
    quiet: quiet,
    timeout: timeout,
  );

  test('웹이 아니면 레이아웃 없이 즉시 돌아온다', () async {
    final report = await HarnessFonts.settle(['한글 시나리오']);

    expect(report.codePoints, 0);
    expect(report.elapsed, Duration.zero);
  });

  test('ASCII 만 있으면 기다리지 않는다', () async {
    final report = await settle(['Successful login', 'patrol_test_explorer']);

    expect(report.codePoints, 0);
    expect(laidOut, isEmpty);
  });

  test('비 ASCII 글자를 한 번에 레이아웃한다(중복 제거)', () async {
    final report = await settle(['가나 login', '나다']);

    expect(laidOut, ['가나다']);
    expect(report.codePoints, 3);
    expect(report.changes, 0);
  });

  test('첫 알림이 없으면 firstChange 뒤 확정한다', () async {
    final stopwatch = Stopwatch()..start();
    final report = await settle([
      '가',
    ], firstChange: const Duration(milliseconds: 300));

    expect(report.changes, 0);
    expect(
      stopwatch.elapsed,
      greaterThanOrEqualTo(const Duration(milliseconds: 300)),
    );
    expect(settled, {'가'.runes.single});
  });

  test('알림이 오면 quiet 동안 조용해질 때까지 기다린다', () async {
    final stopwatch = Stopwatch()..start();
    final report = await settle(
      ['가'],
      firstChange: const Duration(seconds: 1),
      quiet: const Duration(milliseconds: 200),
      layout: (text) {
        laidOut.add(text);
        // 내려받기 세 번 — 50 · 150 · 250ms.
        for (final ms in [50, 150, 250]) {
          Timer(Duration(milliseconds: ms), fonts.change);
        }
      },
    );

    expect(report.changes, 3);
    // 마지막 알림(250ms) + quiet(200ms).
    expect(
      stopwatch.elapsed,
      greaterThanOrEqualTo(const Duration(milliseconds: 450)),
    );
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });

  test('확정한 글자는 다시 기다리지 않는다', () async {
    await settle(['가나']);
    laidOut.clear();

    final again = await settle(['나가']);
    expect(again.codePoints, 0);
    expect(laidOut, isEmpty);

    final more = await settle(['가나다']);
    expect(more.codePoints, 1);
    expect(laidOut, ['다']);
  });

  test('상한 안에 조용해지지 않으면 TimeoutException 으로 실패한다', () async {
    late Timer ticker;
    final future = settle(
      ['가'],
      quiet: const Duration(milliseconds: 100),
      timeout: const Duration(milliseconds: 400),
      layout: (_) {
        ticker = Timer.periodic(
          const Duration(milliseconds: 30),
          (_) => fonts.change(),
        );
      },
    );
    addTearDown(() => ticker.cancel());

    await expectLater(future, throwsA(isA<TimeoutException>()));
    expect(settled, isEmpty, reason: '실패한 글자는 확정으로 남기지 않는다');
    expect(fonts.listening, isFalse);
  });

  test('첫 알림 창이 상한에 잘리면 실패한다', () async {
    final future = settle(
      ['가'],
      firstChange: const Duration(seconds: 1),
      timeout: const Duration(milliseconds: 200),
    );

    await expectLater(future, throwsA(isA<TimeoutException>()));
  });

  test('확정하면 리스너를 떼어 낸다', () async {
    await settle(['가']);

    expect(fonts.listening, isFalse);
  });

  test('보고 문자열에 SETTLED 와 수치를 남긴다', () {
    const report = HarnessFontsReport(
      codePoints: 12,
      changes: 3,
      elapsed: Duration(milliseconds: 2230),
    );

    expect(
      '$report',
      'HarnessFonts: SETTLED codePoints=12 changes=3 elapsed=2230ms',
    );
  });
}
