/// 하네스 글꼴 확정 — Patrol 웹 시험이 첫 시험 전에 폴백 글꼴을 다 받게 한다.
///
/// ## 왜 필요한가 (coco-de/demo-ecommerce-grocery#16)
///
/// 웹(CanvasKit)에서 시험 이름을 그리는 라벨은 둘이다 — patrol 라벨
/// (`PatrolBinding.wrapWithDefaultView` 의 `Text`, 엔진 기본 글꼴)과
/// flutter_test Live 바인딩 라벨(`setLabel` 의 `TextPainter`, `sans-serif`).
/// 둘 다 기본 글꼴(Roboto)에 없는 글자(한글 등)를 만나면 엔진이 폴백 글꼴
/// 서브셋을 `fonts.gstatic.com` 에서 내려받고, 받을 때마다 `fontsChange` 를
/// 보낸다. 그 알림이 시험 사이 warm-up 창에 오면 트리의 모든 `RenderParagraph`
/// 에 대기 플래그가 서고 `object.dart` 의
/// `!_hasPendingSystemFontsDidChangeCallBack` 단언 → GlobalKey 연쇄로 시험이
/// 간헐 실패한다(A/B: 기준선 4/10 실패).
///
/// [HarnessFonts.settle] 은 라벨이 그릴 글자를 첫 시험 전에 미리 레이아웃해
/// 폴백 내려받기를 앞당기고, `systemFonts` 알림이 조용해질 때까지 기다린다.
/// 그 뒤로는 받을 글자가 없어 시험 중에 `fontsChange` 가 오지 않는다
/// (실험: 0/10 실패 · 확정 뒤 글꼴 요청 0 — 80/80 페이지, 페이지당 약 2.2 s).
///
/// co_bdd 가 생성하는 `*.patrol_test.dart` 는 그 파일의 시나리오 이름 전부로
/// `setUpAll(() => HarnessFonts.settle(...))` 을 낸다. Patrol 은 페이지마다 묶음
/// 전체를 다시 도므로 `setUpAll` 이 페이지마다 첫 시험 전에 한 번 돈다.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// [HarnessFonts.settle] 한 번의 결과.
@immutable
class HarnessFontsReport {
  /// 결과를 만든다.
  const HarnessFontsReport({
    required this.codePoints,
    required this.changes,
    required this.elapsed,
  });

  /// 할 일이 없었던 결과 — 웹이 아니거나 새로 확정할 글자가 없다.
  static const HarnessFontsReport none = HarnessFontsReport(
    codePoints: 0,
    changes: 0,
    elapsed: Duration.zero,
  );

  /// 이번에 레이아웃한 (아직 확정되지 않았던 비 ASCII) 코드 포인트 수.
  final int codePoints;

  /// 기다리는 동안 받은 `systemFonts` 알림 수.
  final int changes;

  /// 확정까지 걸린 시간.
  final Duration elapsed;

  @override
  String toString() =>
      'HarnessFonts: SETTLED codePoints=$codePoints changes=$changes '
      'elapsed=${elapsed.inMilliseconds}ms';
}

/// 하네스 글꼴 확정 유틸. [settle] 참고.
abstract final class HarnessFonts {
  /// 첫 `systemFonts` 알림을 기다리는 시간. 이 안에 알림이 없으면 받을 폴백
  /// 글꼴이 없었던 것으로 보고 확정한다.
  static const Duration defaultFirstChange = Duration(seconds: 10);

  /// 알림 뒤 이만큼 조용하면 확정한다.
  static const Duration defaultQuiet = Duration(seconds: 2);

  /// 한 번의 [settle] 전체 상한. 넘으면 [TimeoutException] 으로 실패한다.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// 이 페이지(isolate)에서 이미 확정한 코드 포인트 — 한 runner 가 생성 파일
  /// 여럿을 조립하면 [settle] 이 여러 번 불리는데, 겹치는 글자는 다시 기다리지
  /// 않는다.
  static final Set<int> _settled = <int>{};

  /// [texts] 의 글자를 레이아웃해 폴백 글꼴 내려받기를 끝내고 기다린다.
  ///
  /// - **웹이 아니면 즉시 돌아온다**(비용 0). 네이티브 · VM 은 폴백 글꼴을
  ///   내려받지 않는다.
  /// - ASCII 와 이미 확정한 글자는 건너뛴다. 남는 글자가 없으면 즉시 돌아온다.
  /// - 기본 글꼴(patrol 라벨)과 `sans-serif`(flutter_test 라벨) 두 스타일로
  ///   레이아웃한 뒤 `PaintingBinding.instance.systemFonts` 를 듣는다.
  ///   [firstChange] 안에 알림이 없으면 받을 글꼴이 없었던 것으로 확정하고,
  ///   알림이 오면 [quiet] 동안 조용해질 때까지 기다린다.
  /// - **상한**: 전체가 [timeout] 을 넘도록 조용해지지 않으면
  ///   [TimeoutException] 을 던진다. `setUpAll` 이 실패하므로 그 묶음의 시험이
  ///   모두 실패로 드러난다 — 확정 없이 조용히 넘어가지 않는다.
  ///
  /// 확정되면 [HarnessFontsReport] 를 `debugPrint` 로 한 줄 남긴다
  /// (`HarnessFonts: SETTLED …`).
  static Future<HarnessFontsReport> settle(
    Iterable<String> texts, {
    Duration firstChange = defaultFirstChange,
    Duration quiet = defaultQuiet,
    Duration timeout = defaultTimeout,
  }) async {
    if (!kIsWeb) return HarnessFontsReport.none;
    final report = await settleWith(
      texts,
      systemFonts: PaintingBinding.instance.systemFonts,
      layout: _layout,
      settled: _settled,
      firstChange: firstChange,
      quiet: quiet,
      timeout: timeout,
    );
    if (report.codePoints > 0) debugPrint('$report');
    return report;
  }

  /// [settle] 의 플랫폼 독립 본체 — 시험에서 알림원 · 레이아웃을 바꿔 끼운다.
  @visibleForTesting
  static Future<HarnessFontsReport> settleWith(
    Iterable<String> texts, {
    required Listenable systemFonts,
    required void Function(String text) layout,
    required Set<int> settled,
    Duration firstChange = defaultFirstChange,
    Duration quiet = defaultQuiet,
    Duration timeout = defaultTimeout,
  }) async {
    final pending = <int>{
      for (final text in texts)
        for (final rune in text.runes)
          if (rune >= 0x80 && !settled.contains(rune)) rune,
    };
    if (pending.isEmpty) return HarnessFontsReport.none;

    final stopwatch = Stopwatch()..start();
    var changes = 0;
    Completer<void>? signal;
    void onChange() {
      changes++;
      final current = signal;
      if (current != null && !current.isCompleted) current.complete();
    }

    systemFonts.addListener(onChange);
    try {
      layout(String.fromCharCodes(pending));

      var window = firstChange;
      while (true) {
        final remaining = timeout - stopwatch.elapsed;
        if (remaining <= Duration.zero) {
          throw _timeout(timeout, changes, pending.length);
        }
        final capped = remaining < window;
        final before = changes;
        final current = signal = Completer<void>();
        final timer = Timer(capped ? remaining : window, () {
          if (!current.isCompleted) current.complete();
        });
        await current.future;
        timer.cancel();

        if (changes == before) {
          // 창이 상한에 잘렸으면 조용함을 다 확인하지 못한 것이다.
          if (capped) throw _timeout(timeout, changes, pending.length);
          break;
        }
        window = quiet;
      }
    } finally {
      signal = null;
      systemFonts.removeListener(onChange);
    }

    settled.addAll(pending);
    return HarnessFontsReport(
      codePoints: pending.length,
      changes: changes,
      elapsed: stopwatch.elapsed,
    );
  }

  static TimeoutException _timeout(
    Duration timeout,
    int changes,
    int codePoints,
  ) => TimeoutException(
    'HarnessFonts: systemFonts 가 ${timeout.inMilliseconds}ms 안에 조용해지지 '
    '않았다 (changes=$changes, codePoints=$codePoints) — 폴백 글꼴 내려받기가 '
    '끝나지 않아 시험 중 fontsChange 가 올 수 있다',
    timeout,
  );

  /// 두 라벨이 쓰는 스타일로 [text] 를 레이아웃해 폴백 글꼴을 요청한다.
  static void _layout(String text) {
    // null = 엔진 기본 글꼴(patrol 라벨) · 'sans-serif' = flutter_test 라벨.
    for (final family in const <String?>[null, 'sans-serif']) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: family))
        ..addText(text);
      builder.build()
        ..layout(const ui.ParagraphConstraints(width: 100000))
        ..dispose();
    }
  }
}
