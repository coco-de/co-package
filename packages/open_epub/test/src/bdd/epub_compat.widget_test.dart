// BDD widget tests — epub_compat.feature
// Story: S1.14~S1.18 (#30~#34) — 호환성 보정 및 진단 패널
//
// Source: test/src/bdd/epub_compat.feature
// Steps:  test/src/bdd/step/epub_compat_steps.dart + _common_steps.dart
//
// 진단 패널/디버그 메뉴/클립보드 UI는 kobic 운영자 도구(E3) 범위 — 여기서는
// 패널이 소비하는 패키지 계약(BookSessionDiagnostics)을 하니스 치환으로 검증.

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_compat_steps.dart';

void main() {
  group('F9: 호환성 보정 및 진단 패널', () {
    late BddWorld world;

    setUp(() => world = BddWorld());
    tearDown(() => world.dispose());

    test('진단 패널 열기 (운영자 모드) (@P0 @ops)', () async {
      await operatorOpenedBookViaDebugMenu(world);
      await operatorTapsDiagnostics(world);
      await appliedPatchCardsShown(world);
      await eachCardShowsPatchFields(world);
    });

    group('보정 적용 시 진단 기록 (@P0)', () {
      const examples = [
        (issue: 'NCX 항목 30%만 있음', patchId: 'sparse-ncx', severity: 'medium'),
        (issue: 'spine[0]에 cover 메타', patchId: 'cover-skip', severity: 'low'),
        (
          issue: 'spine href가 OPF에 없음',
          patchId: 'broken-spine-href',
          severity: 'high'
        ),
        (
          issue: 'mimetype 파일 누락',
          patchId: 'missing-mimetype',
          severity: 'low'
        ),
        (issue: 'NCX/nav 모두 빈', patchId: 'empty-toc', severity: 'high'),
      ];
      for (final example in examples) {
        test('${example.issue} → ${example.patchId}', () async {
          await epubHasIssue(world, example.issue);
          await bookIsOpened(world);
          await patchApplied(world, example.patchId);
          await diagnosticsRecordsPatchWithSeverity(
              world, example.patchId, example.severity);
        });
      }
    });

    test('진단 결과 클립보드 복사 (@P1)', () async {
      await diagnosticsPanelOpen(world);
      await operatorTapsCopyToClipboard(world);
      await diagnosticsJsonCopiedToClipboard(world);
    });
  });
}
