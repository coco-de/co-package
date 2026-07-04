// BDD widget tests — epub_security.feature
// Story: S1.24 (#40), S5.7 — 보안 가드 (zip slip / script / CORS / size limit)
//
// Source: test/src/bdd/epub_security.feature
// Steps:  test/src/bdd/step/epub_security_steps.dart + _common_steps.dart
//
// 시나리오 'Web CORS 위반 이미지'는 실브라우저 CORS 동작이 필요해 skip(E4).
// 100MB/메모리 peak·실파일 측정은 E4 — 여기서는 VM smoke로 검증한다.

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_security_steps.dart';

void main() {
  group('Edge: 보안 가드 (zip slip / script / CORS / size limit)', () {
    late BddWorld world;

    setUp(() => world = BddWorld());
    tearDown(() => world.dispose());

    test('zip slip 시도 (@P0 @edge @security)', () async {
      await epubContainsPathResource(world, '../../../etc/passwd');
      await epubIsOpened(world);
      await resourceIgnoredSecurityWarning(world);
      await noFilesCreatedOutsideSandbox(world);
    });

    test('외부 script 차단 (@P0 @edge @security)', () async {
      await epubXhtmlHasExternalScript(world);
      await pageRenders(world);
      await scriptNotExecuted(world);
      await onlyBodyTextDisplayed(world);
    });

    test(
      'Web CORS 위반 이미지 (@P0 @edge)',
      () async {
        await webOpensEpubWithCrossOriginImage(world);
        await domainDoesNotAllowCors(world);
        await pageRenders(world);
        await imageShownAsPlaceholder(world);
        await bodyTextDisplayedNormally(world);
        await diagnosticsContainsItem(world, 'image-cors-blocked');
      },
      skip: '실브라우저 CORS 차단 — E4 범위 (VM 테스트에는 CORS 개념이 없음)',
    );

    test('매우 큰 EPUB (100MB) — 열기 성능 smoke (@P0 @edge)', () async {
      await nMbEpubExists(world, 100);
      final stopwatch = Stopwatch()..start();
      await epubIsOpened(world);
      stopwatch.stop();
      await firstPageShownWithinSeconds(world, 5.0);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
      await memoryPeakNoMoreThan(world, 600);
    });

    test('매우 작은 EPUB (10KB) (@P0 @edge)', () async {
      await nKbEpubExists(world, 10);
      final stopwatch = Stopwatch()..start();
      await epubIsOpened(world);
      stopwatch.stop();
      await firstPageShownWithinMs(world, 100);
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 100)));
    });

    testWidgets('손상된 EPUB (@P0 @edge)', (tester) async {
      await epubFileCorruptedOpfParseFails(world);
      await epubIsOpened(world);
      await errorScreenShown(world, tester, '이 파일을 열 수 없습니다');
      await diagnosticsRecordsUnresolvedIssue(world);
      await kobicEmitsAnalyticsEvent(world, 'book_open_failed');
    });

    test('200MB 초과 파일 거부 (@P0 @edge @security)', () async {
      await nMbEpubViaBytesSource(world, 250);
      await epubIsOpened(world);
      await epubFileTooLargeErrorReturned(world);
      await parsingDoesNotStart(world);
    });
  });
}
