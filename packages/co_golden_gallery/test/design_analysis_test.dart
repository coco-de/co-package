import 'dart:convert';
import 'dart:io';

import 'package:co_golden_gallery/co_golden_gallery.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'design_fixture.dart';
import 'fixture.dart';

void main() {
  late Directory root;
  late Directory output;

  setUp(() {
    root = sampleSource();
    output = Directory.systemTemp.createTempSync('co_golden_analysis_site_');
  });
  tearDown(() {
    root.deleteSync(recursive: true);
    output.deleteSync(recursive: true);
  });

  GalleryImage light(GalleryScan scan) => scan.catalog.scenarios
      .firstWhere((s) => s.name == 'login')
      .images
      .firstWhere((image) => image.name == 'phone__light__ko');

  Future<(int, String, String)> run(List<String> arguments) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runGalleryCli(
      arguments,
      stdoutSink: out,
      stderrSink: err,
    );
    return (code, out.toString(), err.toString());
  }

  List<Object?> pageData(String html) {
    final match = RegExp(
      r'id="gallery-data">(.*?)</script>',
      dotAll: true,
    ).firstMatch(html)!;
    expect(match.group(1), isNot(contains('</script>')));
    return jsonDecode(match.group(1)!) as List<Object?>;
  }

  group('scanner', () {
    test('reads the analysis summary and the trimmed report', () {
      writeAnalysedSource(root);
      final scan = scanGallerySources([root]);
      final design = light(scan).designComparison!;
      final analysis = design.analysis!;

      expect(design.status, 'different');
      expect(design.designStatus, 'fail');
      expect(design.hasDifference, isTrue);
      expect(design.flag, '디자인 불일치 · 오류 2 · 경고 1');
      expect(analysis.report, reportPath);
      expect(analysis.diff, analysisDiffPath);
      expect(analysis.errors, 2);
      expect(analysis.known, 1);
      expect(analysis.byCategory['typography'], 1);

      final details = analysis.details!;
      expect(details.verdict, 'fail');
      expect(details.reasons, ['pixels:budget', 'findings:error']);
      expect(details.budgetRatio, 0.002);
      expect(details.budgetRegion, 32);
      expect(details.designSize, [4, 8]);
      expect(details.renderSize, [4, 8]);
      expect(details.comparedSize, [4, 8]);
      expect(details.frameName, 'Mobile-Default');
      expect(details.designSystem, 'CoUI');
      // Most severe first, known differences last, report order otherwise.
      expect(details.findings.map((f) => f.id), [
        'typography@12:350',
        'presence@12:400',
        'component@12:340',
        'content@12:351',
        'layout@12:360',
      ]);
      final typography = details.findings.first;
      expect(typography.widgetSource, 'lib/src/login_page.dart:42:9');
      expect(typography.designTextStyle, 'Title/Medium');
      expect(
        typography.componentLabel,
        'Button (coui_flutter) · variant=primary, size=md',
      );
      expect(typography.diffs.map((d) => d.text), [
        'fontWeight 700 → 600 (-100)',
        'letterSpacing -0.24 → 0px (+0.24)',
      ]);
      final known = details.findings.last;
      expect(known.known, isTrue);
      expect(known.knownIssue, 'https://github.com/coco-de/coui/issues/5652');
      expect(known.diffs.single.text, 'y (‘Footer’ 기준) 28 → 12px (-16)');
      expect(details.unexplainedRegions.map((r) => r.id), ['cell:0,0']);
      expect(details.masks.single.source, 'safeArea');
    });

    test('registers the report and the tolerant map as auxiliary files', () {
      writeAnalysedSource(root);
      final scan = scanGallerySources([root]);

      expect(scan.files.keys, containsAll([reportPath, analysisDiffPath]));
      expect(scan.catalog.imageCount, 3);
      expect(scan.catalog.scenarios, hasLength(2));
      expect(scan.catalog.designVerdicts, {
        'pass': 0,
        'fail': 1,
        'undetermined': 0,
      });
      expect(scan.catalog.designFindingCounts, {
        'error': 2,
        'warning': 1,
        'info': 1,
        'known': 1,
      });
    });

    test('counts a passing analysis as no design difference', () {
      writeAnalysedSource(
        root,
        analysis: analysisSummary(verdict: 'pass'),
        report: designReport(verdict: 'pass'),
      );
      final scan = scanGallerySources([root]);
      final design = light(scan).designComparison!;

      expect(design.status, 'different');
      expect(design.hasDifference, isFalse);
      expect(design.flag, '디자인 일치 · 경고 1');
      expect(scan.catalog.designDifferenceCount, 0);
    });

    test('keeps manifests without analysis unchanged', () {
      writeManifest(
        root,
        suite: 'auth',
        scenario: 'login',
        results: [
          {
            ...result(
              stem: 'phone__light__ko',
              theme: 'light',
              locale: 'ko',
              image: 'images/auth/login/phone__light__ko.png',
            ),
            'designComparison': exactComparison(),
          },
        ],
      );
      writePng(p.join(root.path, referencePath));
      writePng(p.join(root.path, exactDiffPath));
      final design = light(scanGallerySources([root])).designComparison!;

      expect(design.analysis, isNull);
      expect(design.designStatus, 'different');
      expect(design.flag, '디자인 차이 9.375%');
      expect(design.hasDifference, isTrue);
    });

    test('reports a missing report file instead of guessing', () {
      writeAnalysedSource(root, writeReport: false);
      final scan = scanGallerySources([root]);

      expect(scan.missingImages, contains(reportPath));
      expect(light(scan).designComparison!.analysis!.details, isNull);
    });

    test('drops issue links that are not http(s)', () {
      final report = designReport();
      final findings = report['findings']! as List<Object?>;
      final known =
          (findings.first! as Map<String, Object?>)['known']!
              as Map<String, Object?>;
      known['issue'] = 'javascript:alert(1)';
      writeAnalysedSource(root, report: report);
      final finding = light(
        scanGallerySources([root]),
      ).designComparison!.analysis!.details!.findings.last;

      expect(finding.known, isTrue);
      expect(finding.knownIssue, isNull);
    });

    final invalidSummaries = <String, Map<String, Object?>>{
      'escaping report path': {'report': '../outside.json'},
      'absolute report path': {'report': '/tmp/report.json'},
      'report without .json': {'report': 'analysis/auth/login/report.txt'},
      'diff without an image extension': {'diff': 'analysis/diff.json'},
      'unknown verdict': {'verdict': 'maybe'},
      'unknown pixel status': {'pixelStatus': 'ok'},
      'negative count': {
        'findings': {'error': -1},
      },
      'fractional count': {
        'findings': {'warning': 1.5},
      },
      'ratio above one': {'ratio': 1.5},
      'negative region': {'largestRegion': -1},
      'non-integer category': {
        'byCategory': {'typography': 'many'},
      },
    };
    for (final MapEntry(key: name, value: change) in invalidSummaries.entries) {
      test('rejects analysis with $name', () {
        writeAnalysedSource(root, analysis: {...analysisSummary(), ...change});
        expect(
          () => scanGallerySources([root]),
          throwsA(isA<GallerySourceException>()),
        );
      });
    }

    final invalidReports = <String, Object?>{
      'invalid JSON': '{"schema": ',
      'a foreign schema': {...designReport(), 'schema': 'other'},
      'a newer schema': {...designReport(), 'schemaVersion': 2},
      'an unknown verdict': {...designReport(), 'verdict': 'maybe'},
      'another variant': {...designReport(), 'fileStem': 'phone__dark__ko'},
    };
    for (final MapEntry(key: name, value: report) in invalidReports.entries) {
      test('rejects a report with $name', () {
        writeAnalysedSource(root, report: report);
        expect(
          () => scanGallerySources([root]),
          throwsA(isA<GallerySourceException>()),
        );
      });
    }
  });

  group('page', () {
    test('embeds findings, marks, and the tolerant mode', () async {
      writeAnalysedSource(root);
      final (code, _, _) = await run([
        'build',
        '-i',
        root.path,
        '-o',
        output.path,
        '--asset-base-url',
        'https://cdn.example/run',
      ]);
      expect(code, 0);
      final html = File(p.join(output.path, 'index.html')).readAsStringSync();

      expect(html, contains('id="analysis-panel"'));
      expect(html, contains('aria-label="디자인 차이 목록"'));
      expect(html, contains('<option value="tolerant">허용 오차 차이</option>'));
      expect(html, contains('<option value="diff">RGBA 차이 이미지</option>'));
      expect(html, contains('id="reference-marks"'));
      expect(html, contains('id="render-marks"'));
      expect(html, contains('id="diff-marks"'));
      expect(html, contains('id="show-regions"'));
      expect(html, contains('data-design-status="fail"'));
      expect(html, contains('디자인 불일치 · 오류 2 · 경고 1'));

      final item =
          pageData(html).firstWhere(
                (entry) => (entry! as Map)['label'] == 'phone · light · ko',
              )!
              as Map<String, Object?>;
      final design = item['design']! as Map<String, Object?>;
      final analysis = design['analysis']! as Map<String, Object?>;
      expect(analysis['verdict'], 'fail');
      expect(analysis['report'], 'https://cdn.example/run/$reportPath');
      expect(analysis['diff'], 'https://cdn.example/run/$analysisDiffPath');
      expect(analysis['designSize'], [4, 8]);
      expect(
        analysis['line'],
        '허용 오차 판정 불일치 · 픽셀 차이 10.714% (예산 0.200%) · '
        '최대 영역 2px² (예산 32px²) · 오류 2 · 경고 1 · 정보 1 · 알려진 차이 1',
      );
      final findings = (analysis['findings']! as List)
          .cast<Map<String, Object?>>();
      expect(findings.first['diffs'], [
        'fontWeight 700 → 600 (-100)',
        'letterSpacing -0.24 → 0px (+0.24)',
      ]);
      expect(findings.first['where'], 'lib/src/login_page.dart:42:9');
      expect((findings.first['design']! as Map)['rect'], [1, 2, 2, 1]);
      expect((findings.first['widget']! as Map)['rect'], [1, 2.5, 2, 1]);
      expect(findings.last['known'], {
        'reason': 'CoUI Card 본문 · 푸터 간격',
        'issue': 'https://github.com/coco-de/coui/issues/5652',
      });
      final regions = (analysis['regions']! as List)
          .cast<Map<String, Object?>>();
      expect(regions.map((r) => r['unexplained']), [false, true]);
      expect(
        (analysis['masks']! as List).single,
        containsPair('source', 'safeArea'),
      );
    });

    test('copies the report and the tolerant map with --copy-images', () async {
      writeAnalysedSource(root);
      final (code, _, _) = await run([
        'build',
        '-i',
        root.path,
        '-o',
        output.path,
        '--copy-images',
      ]);
      expect(code, 0);
      for (final path in [reportPath, analysisDiffPath]) {
        expect(
          File(p.join(output.path, path)).readAsBytesSync(),
          File(p.join(root.path, path)).readAsBytesSync(),
          reason: path,
        );
      }
      final html = File(p.join(output.path, 'index.html')).readAsStringSync();
      final analysis =
          ((pageData(html).firstWhere(
                        (entry) =>
                            (entry! as Map)['label'] == 'phone · light · ko',
                      )!
                      as Map)['design']!
                  as Map)['analysis']!
              as Map;
      expect(analysis['report'], reportPath);
    });

    test('links relative files from the output directory', () async {
      writeAnalysedSource(root);
      final (code, _, _) = await run([
        'build',
        '-i',
        root.path,
        '-o',
        output.path,
      ]);
      expect(code, 0);
      final html = File(p.join(output.path, 'index.html')).readAsStringSync();
      final analysis =
          ((pageData(html).firstWhere(
                        (entry) =>
                            (entry! as Map)['label'] == 'phone · light · ko',
                      )!
                      as Map)['design']!
                  as Map)['analysis']!
              as Map;
      expect(analysis['report'], startsWith('../'));
      expect(analysis['report'], endsWith(reportPath));
    });

    test('builds with --allow-missing when the report is missing', () async {
      writeAnalysedSource(root, writeReport: false);
      final args = ['build', '-i', root.path, '-o', output.path];
      final (failed, _, errors) = await run(args);
      expect(failed, galleryDataError);
      expect(errors, contains(reportPath));

      final (code, _, _) = await run([...args, '--allow-missing']);
      expect(code, 0);
      final html = File(p.join(output.path, 'index.html')).readAsStringSync();
      expect(html, contains('분석 리포트 파일이 없어'));
    });
  });

  group('summary and Markdown report', () {
    test('extends --summary with verdicts and flattened findings', () async {
      writeAnalysedSource(root);
      final summaryPath = p.join(output.path, 'summary.json');
      final (code, _, _) = await run([
        'build',
        '-i',
        root.path,
        '-o',
        output.path,
        '--summary',
        summaryPath,
      ]);
      expect(code, 0);
      final summary =
          jsonDecode(File(summaryPath).readAsStringSync())
              as Map<String, Object?>;

      expect(summary['designComparisons'], 1);
      expect(summary['designVerdicts'], {
        'pass': 0,
        'fail': 1,
        'undetermined': 0,
      });
      expect(summary['designFindingCounts'], containsPair('error', 2));
      final difference =
          (summary['designDifferences']! as List).single
              as Map<String, Object?>;
      expect(difference['status'], 'different');
      final analysis = difference['analysis']! as Map<String, Object?>;
      expect(analysis['verdict'], 'fail');
      expect(analysis['report'], reportPath);
      expect(analysis['reasons'], ['pixels:budget', 'findings:error']);
      final findings = (summary['designFindings']! as List)
          .cast<Map<String, Object?>>();
      expect(findings, hasLength(5));
      expect(findings.first, containsPair('suite', 'auth'));
      expect(findings.first, containsPair('variant', 'phone · light · ko'));
      expect(findings.first, containsPair('report', reportPath));
      expect(findings.first, containsPair('id', 'typography@12:350'));
      expect(findings.first, containsPair('owner', 'app'));
      expect(
        (findings.first['widget']! as Map)['source'],
        'lib/src/login_page.dart:42:9',
      );
      expect((findings.first['component']! as Map)['name'], 'Button');
      expect(findings.last['known'], isTrue);
      expect(
        findings.last['issue'],
        'https://github.com/coco-de/coui/issues/5652',
      );
    });

    test('leaves passing analyses out of designDifferences', () async {
      writeAnalysedSource(
        root,
        analysis: analysisSummary(verdict: 'pass'),
        report: designReport(verdict: 'pass'),
      );
      final summaryPath = p.join(output.path, 'summary.json');
      final (code, _, _) = await run([
        'build',
        '-i',
        root.path,
        '-o',
        output.path,
        '--summary',
        summaryPath,
      ]);
      expect(code, 0);
      final summary =
          jsonDecode(File(summaryPath).readAsStringSync())
              as Map<String, Object?>;
      // The exact status is `different` (anti-aliasing), the verdict passes.
      expect(summary['designDifferences'], isEmpty);
      expect(summary['designVerdicts'], containsPair('pass', 1));
    });

    test('writes a Markdown report for AI agents and pull requests', () async {
      writeAnalysedSource(
        root,
        extraResults: [
          {
            ...result(
              stem: 'phone__dark__ko',
              theme: 'dark',
              locale: 'ko',
              image: 'images/auth/login/phone__dark__ko.png',
            ),
            'designComparison': {
              ...exactComparison(),
              'reference': 'references/auth/login/phone__dark__ko.png',
              'diff': 'differences/auth/login/phone__dark__ko.png',
              'referenceWidth': 6,
              'referenceHeight': 9,
              'renderWidth': 6,
              'renderHeight': 9,
              'totalPixels': 54,
              'differenceRatio': 3 / 54,
            },
          },
        ],
      );
      writePng(p.join(root.path, 'references/auth/login/phone__dark__ko.png'));
      writePng(p.join(root.path, 'differences/auth/login/phone__dark__ko.png'));
      final reportFile = p.join(output.path, 'design-report.md');
      final (code, _, _) = await run([
        'build',
        '-i',
        root.path,
        '-o',
        output.path,
        '--title',
        'Unibook',
        '--design-report',
        reportFile,
      ]);
      expect(code, 0);
      final markdown = File(reportFile).readAsStringSync();

      expect(markdown, startsWith('# Unibook — 디자인 차이 리포트\n'));
      expect(markdown, contains('- 판정: 일치 0 · 불일치 1 · 판정 불가 0'));
      expect(markdown, contains('- 지적 사항: 오류 2 · 경고 1 · 정보 1 · 알려진 차이 1'));
      expect(markdown, contains('- 분류: 누락/추가 1 · 컴포넌트 1 · 서체 1 · 내용 1'));
      expect(markdown, contains('## 불일치 · auth / login · phone · light · ko'));
      expect(markdown, contains('- 판정 이유: `pixels:budget`, `findings:error`'));
      expect(markdown, contains('- 리포트: `$reportPath`'));
      expect(
        markdown,
        contains(
          '- 디자인: [Figma](<https://www.figma.com/design/KEY/App?node-id=12-345>)'
          ' · 프레임 Mobile-Default (12:345)',
        ),
      );
      expect(markdown, contains('### 지적 사항 4건'));
      expect(
        markdown,
        contains(
          '1. **[오류] 서체** ‘로그인’ — ‘로그인’ 서체가 Figma와 다릅니다 &lt;/script&gt;',
        ),
      );
      expect(
        markdown,
        contains(
          '   - 차이 (디자인 → 구현): `fontWeight 700 → 600 (-100)` · '
          '`letterSpacing -0.24 → 0px (+0.24)`',
        ),
      );
      expect(
        markdown,
        contains(
          '   - 구현: Text ‘로그인’ · 역할 .bodyMedium — `lib/src/login_page.dart:42:9`',
        ),
      );
      expect(
        markdown,
        contains(
          '   - 컴포넌트: Button (coui_flutter) · variant=primary, size=md — '
          '`lib/src/login_page.dart:40:7`',
        ),
      );
      expect(markdown, contains('   - 고칠 방향:'));
      expect(markdown, contains('   - 고칠 곳: 앱 코드'));
      expect(markdown, contains('### 알려진 차이 1건'));
      expect(
        markdown,
        contains('([추적 이슈](<https://github.com/coco-de/coui/issues/5652>))'),
      );
      expect(markdown, contains('### 설명되지 않은 픽셀 영역 1건'));
      expect(markdown, contains('- `cell:0,0` 1×1 @ (3, 6) · 1px²'));
      expect(markdown, contains('## 허용 오차 분석이 없는 디자인 비교 1건'));
      expect(
        markdown,
        contains('auth / login · phone · dark · ko — 디자인 차이 5.556%'),
      );
      expect(markdown, contains('## 다음 단계'));
      expect(markdown, isNot(contains('</script>')));
    });

    test('lists matching variants without detail', () async {
      writeAnalysedSource(
        root,
        analysis: analysisSummary(verdict: 'pass'),
        report: designReport(verdict: 'pass'),
      );
      final reportFile = p.join(output.path, 'design-report.md');
      final (code, _, _) = await run([
        'build',
        '-i',
        root.path,
        '-o',
        output.path,
        '--design-report',
        reportFile,
      ]);
      expect(code, 0);
      final markdown = File(reportFile).readAsStringSync();

      expect(markdown, contains('## 일치한 변형 1건'));
      expect(
        markdown,
        contains('- auth / login · phone · light · ko — 경고 1 · 알려진 차이 1'),
      );
      expect(markdown, isNot(contains('### 지적 사항')));
      expect(markdown, isNot(contains('## 다음 단계')));
    });
  });

  group('formatting', () {
    test('formats differences without inventing precision', () {
      expect(
        const GalleryFindingDiff(
          property: 'color',
          expected: '#14161A',
          actual: '#2A2D33',
          unit: 'ΔE',
          delta: 12.3,
        ).text,
        'color #14161A → #2A2D33 (ΔE 12.3)',
      );
      expect(
        const GalleryFindingDiff(
          property: 'fontFamily',
          expected: 'Pretendard',
          actual: null,
        ).text,
        'fontFamily Pretendard → 없음',
      );
      expect(galleryPercent(0.0000001), '<0.001%');
      expect(galleryPercent(0), '0.000%');
      expect(galleryNumber(16), '16');
      expect(galleryNumber(-0.25), '-0.25');
      expect(galleryNumber(45.5), '45.5');
    });
  });
}
