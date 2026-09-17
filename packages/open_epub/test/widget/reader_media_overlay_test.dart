// Story: S15.3 (#110) — EpubReader 낭독 하이라이트 동기화 (gap #6 동기화분)
//
// MO 컨트롤러의 활성 par가 현재 spine을 가리키면, 그 fragment 요소가 본문
// 렌더(HtmlWidget.html)에 배경색으로 강조되는지 검증한다. par 전환 시 이동,
// 정지 시 해제. 재생 제어는 fake player로 결정적.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:open_epub/open_epub.dart';
import 'package:open_epub_engine/testing.dart';

void main() {
  group('EpubReader — MO 낭독 하이라이트 동기화 (S15.3)', () {
    testWidgets('활성 par의 fragment가 본문에 배경색으로 강조된다', (tester) async {
      final player = FakeMediaAudioPlayer();
      final controller = MediaOverlayController(player: player);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_reader(controller));
      await tester.pumpAndSettle();

      // ch1.xhtml#s1 par 재생 시작 → s1 요소 강조.
      await controller.start(_overlay(), loadAudio: _loader);
      await tester.pumpAndSettle();

      final html = _htmlForFragment(tester, 's1');
      expect(html, isNotNull, reason: 's1 하이라이트가 본문에 주입되어야 함');
      expect(html!.html, contains('background-color'));
      expect(html.html, matches(RegExp(r'id="s1"[^>]*style=')));
    });

    testWidgets('par 전환 시 하이라이트가 다음 문장으로 이동', (tester) async {
      final player = FakeMediaAudioPlayer();
      final controller = MediaOverlayController(player: player);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_reader(controller));
      await tester.pumpAndSettle();
      await controller.start(_overlay(), loadAudio: _loader);
      await tester.pumpAndSettle();

      // par0(s1) clipEnd 도달 → par1(s2)로 전환.
      player.emitPosition(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();

      expect(controller.activeParIndex.value, 1);
      final data = _anyHtmlData(tester);
      expect(data, matches(RegExp(r'id="s2"[^>]*style=')));
      // s1은 더 이상 강조되지 않음
      expect(data, isNot(matches(RegExp(r'id="s1"[^>]*style='))));
    });

    testWidgets('정지 시 하이라이트 해제', (tester) async {
      final player = FakeMediaAudioPlayer();
      final controller = MediaOverlayController(player: player);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_reader(controller));
      await tester.pumpAndSettle();
      await controller.start(_overlay(), loadAudio: _loader);
      await tester.pumpAndSettle();
      expect(_anyHtmlData(tester), contains('background-color'));

      await controller.stop();
      await tester.pumpAndSettle();
      expect(controller.activeParIndex.value, -1);
      expect(_anyHtmlData(tester), isNot(contains('background-color')));
    });

    testWidgets('MO 컨트롤러 없으면 본문 강조 없음(회귀)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpubReader(
              source: EpubSource.bytes(mediaOverlayEpub3()),
              paged: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_anyHtmlData(tester), isNot(contains('background-color')));
    });
  });
}

// -------- helpers --------

Widget _reader(MediaOverlayController controller) => MaterialApp(
      home: Scaffold(
        body: EpubReader(
          source: EpubSource.bytes(mediaOverlayEpub3()),
          paged: true,
          mediaOverlayController: controller,
        ),
      ),
    );

/// ch1의 par 2개(s1/s2, 같은 오디오). audioSrc는 fake라 로드만 되면 됨.
EpubMediaOverlay _overlay() => const EpubMediaOverlay(pars: [
      EpubMediaPar(
        textSrc: 'ch1.xhtml#s1',
        audioSrc: 'audio/ch1.mp3',
        clipBegin: Duration.zero,
        clipEnd: Duration(milliseconds: 2500),
      ),
      EpubMediaPar(
        textSrc: 'ch1.xhtml#s2',
        audioSrc: 'audio/ch1.mp3',
        clipBegin: Duration(milliseconds: 2500),
        clipEnd: Duration(seconds: 5),
      ),
    ]);

Future<Uint8List?> _loader(String src) async => Uint8List.fromList([1, 2, 3]);

/// [fragmentId]를 style과 함께 담은 HtmlWidget을 찾는다(없으면 null).
HtmlWidget? _htmlForFragment(WidgetTester tester, String fragmentId) {
  final re = RegExp('id="$fragmentId"[^>]*style=');
  for (final w in tester.widgetList<HtmlWidget>(find.byType(HtmlWidget))) {
    if (re.hasMatch(w.html)) return w;
  }
  return null;
}

/// 렌더된 모든 HtmlWidget.html를 합친 문자열(강조 유무 검사용).
String _anyHtmlData(WidgetTester tester) => tester
    .widgetList<HtmlWidget>(find.byType(HtmlWidget))
    .map((w) => w.html)
    .join('\n');

class FakeMediaAudioPlayer implements MediaAudioPlayer {
  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast();

  void emitPosition(Duration d) => _positions.add(d);

  @override
  Future<void> load(Uint8List bytes,
      {String contentType = 'audio/mpeg'}) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Stream<Duration> get positionStream => _positions.stream;
  @override
  Future<void> dispose() async => _positions.close();
}
