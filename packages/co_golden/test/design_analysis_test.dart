import 'dart:convert';
import 'dart:io';

import 'package:co_golden/co_golden.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

final _output = Directory.systemTemp.createTempSync('co_golden_analysis_');
const _phone = GoldenDevice(
  name: 'phone',
  logicalSize: Size(200, 300),
  safeArea: EdgeInsets.only(top: 20),
);

/// A tiny stand-in for a design-system component.
enum FakeVariant { primary, secondary }

/// Sizes of [FakeButton].
enum FakeSize { sm, md }

/// A design-system-like button with a variant and a size.
class FakeButton extends StatelessWidget {
  /// Creates the button.
  const FakeButton({
    required this.label,
    super.key,
    this.variant = FakeVariant.primary,
    this.size = FakeSize.md,
  });

  /// Label.
  final String label;

  /// Variant.
  final FakeVariant variant;

  /// Size.
  final FakeSize size;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: variant == FakeVariant.primary
          ? const Color(0xff5be0c8)
          : const Color(0xffe0e0e0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: _style(14, FontWeight.w500, 0xff0b0d0e)),
  );
}

TextStyle _style(double size, FontWeight weight, int color, {double? line}) =>
    TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      height: (line ?? (size == 24 ? 32 : 20)) / size,
      fontWeight: weight,
      color: Color(color),
    );

Widget _screen({required bool design}) => ColoredBox(
  color: const Color(0xffffffff),
  child: Stack(
    children: [
      Positioned(
        left: 16,
        top: 40,
        child: Text(
          '로그인',
          style: _style(
            24,
            design ? FontWeight.w700 : FontWeight.w600,
            0xff14161a,
          ),
        ),
      ),
      Positioned(
        left: 16,
        top: design ? 80 : 88,
        child: Text(
          '계정으로 계속하세요',
          style: _style(14, FontWeight.w400, design ? 0xff545961 : 0xff9aa1a3),
        ),
      ),
      if (design)
        Positioned(
          left: 150,
          top: 44,
          child: Text('NEW', style: _style(12, FontWeight.w700, 0xffe38b78)),
        ),
      Positioned(
        left: 16,
        top: 120,
        child: Container(
          width: 168,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xffeff6ff),
            borderRadius: BorderRadius.circular(design ? 12 : 4),
          ),
        ),
      ),
      Positioned(
        left: 16,
        top: 270,
        child: Text(
          design ? '9:41' : '10:02',
          key: const ValueKey('clock'),
          style: _style(14, FontWeight.w400, 0xff14161a),
        ),
      ),
      if (!design)
        Positioned(
          left: 140,
          top: 270,
          child: Text('Beta', style: _style(14, FontWeight.w400, 0xff14161a)),
        ),
      Positioned(
        left: 16,
        top: 220,
        width: 168,
        child: FakeButton(
          label: '계속',
          variant: design ? FakeVariant.secondary : FakeVariant.primary,
        ),
      ),
    ],
  ),
);

Map<String, Object?> _text(
  String id,
  String name,
  String characters,
  List<num> rect, {
  required int weight,
  required num size,
  required num line,
  required String color,
  String? variable,
  String? style,
  String align = 'LEFT',
  String? parent,
}) => {
  'id': id,
  'parent': ?parent,
  'name': name,
  'type': 'TEXT',
  'rect': rect,
  'text': {
    'characters': characters,
    'fontFamily': 'Pretendard',
    'fontWeight': weight,
    'fontSize': size,
    'lineHeight': {'unit': 'PIXELS', 'value': line},
    'letterSpacing': {'unit': 'PIXELS', 'value': 0},
    'color': color,
    'colorVariable': ?variable,
    'style': ?style,
    'align': align,
    'autoResize': 'WIDTH_AND_HEIGHT',
  },
};

final Map<String, Object?> _spec = {
  'schema': 'co_golden.design_spec',
  'schemaVersion': 1,
  'source': {
    'tool': 'figma',
    'fileKey': 'KEY',
    'nodeId': '1:1',
    'url': 'https://www.figma.com/design/KEY/App?node-id=1-1',
  },
  'frame': {
    'id': '1:1',
    'name': 'Mobile-Default',
    'width': 200,
    'height': 300,
    'fills': [
      {'type': 'SOLID', 'color': '#FFFFFFFF', 'variable': 'color/surface'},
    ],
  },
  'nodes': [
    _text(
      '1:2',
      'Title',
      '로그인',
      [16, 40, 72, 32],
      weight: 700,
      size: 24,
      line: 32,
      color: '#14161AFF',
      variable: 'color/on-surface',
      style: 'Title/Medium',
    ),
    _text(
      '1:3',
      'Subtitle',
      '계정으로 계속하세요',
      [16, 80, 140, 20],
      weight: 400,
      size: 14,
      line: 20,
      color: '#545961FF',
      variable: 'color/on-surface-variant',
      style: 'Body/Medium',
    ),
    _text(
      '1:4',
      'Badge',
      'NEW',
      [150, 44, 36, 20],
      weight: 700,
      size: 12,
      line: 20,
      color: '#E38B78FF',
    ),
    {
      'id': '1:5',
      'name': 'Card',
      'type': 'RECTANGLE',
      'rect': [16, 120, 168, 60],
      'radius': 12,
      'fills': [
        {
          'type': 'SOLID',
          'color': '#EFF6FFFF',
          'variable': 'color/info-container',
        },
      ],
    },
    _text(
      '1:6',
      'Clock',
      '9:41',
      [16, 270, 56, 20],
      weight: 400,
      size: 14,
      line: 20,
      color: '#14161AFF',
    ),
    {
      'id': '1:7',
      'name': 'Button',
      'type': 'INSTANCE',
      'rect': [16, 220, 168, 40],
      'radius': 8,
      'fills': [
        {'type': 'SOLID', 'color': '#E0E0E0FF'},
      ],
      'instance': {
        'set': 'Button',
        'component': 'Variant=secondary, Size=md',
        'variant': {'Variant': 'secondary', 'Size': 'md'},
      },
    },
    _text(
      '1:8',
      'Label',
      '계속',
      [86, 230, 28, 20],
      weight: 500,
      size: 14,
      line: 20,
      color: '#0B0D0EFF',
      align: 'CENTER',
      parent: '1:7',
    ),
  ],
};

GoldenMatrix<Color> _matrix(GoldenDesignAnalysis analysis) =>
    GoldenMatrix<Color>(
      suite: 'analysis',
      coverage: const GoldenCoverage(
        devices: [_phone],
        themes: [GoldenTheme(name: 'light', data: Color(0xffffffff))],
        locales: [Locale('ko')],
      ),
      environment: GoldenMatrixEnvironment(
        mode: GoldenMatrixMode.capture,
        outputDirectory: _output.path,
      ),
      app: (variant, child) =>
          Directionality(textDirection: TextDirection.ltr, child: child),
      designAnalysis: analysis,
    );

final _analysis = GoldenDesignAnalysis(
  designSystem: GoldenDesignSystem(
    discoverCoui: false,
    components: const [
      GoldenComponentMapping(widget: 'FakeButton', figma: 'Button'),
    ],
    textRoles: const [
      GoldenTextRole(
        name: 'titleMedium',
        fontSize: 24,
        fontWeight: 700,
        lineHeight: 32 / 24,
      ),
      GoldenTextRole(
        name: 'bodyMedium',
        fontSize: 14,
        fontWeight: 400,
        lineHeight: 20 / 14,
      ),
    ],
    colorTokens: (context) => const {
      'surface': Color(0xffffffff),
      'on-surface': Color(0xff14161a),
      'on-surface-variant': Color(0xff545961),
      'surface-dim': Color(0xff9aa1a3),
      'info-container': Color(0xffeff6ff),
    },
  ),
  masks: [
    GoldenDesignMask.finder(
      find.byKey(const ValueKey('clock')),
      reason: '실시간 시계',
    ),
  ],
  knownDifferences: [
    GoldenKnownDifference(
      designNode: '1:3',
      category: 'color',
      reason: '보조 글자색 토큰 교체 대기',
      issue: 'https://github.com/coco-de/coui/issues/1',
    ),
  ],
);

Map<String, Object?> _json(String relative) =>
    jsonDecode(File(p.join(_output.path, relative)).readAsStringSync())
        as Map<String, Object?>;

Map<String, Object?> _result(String scenario) =>
    ((_json('runs/analysis/$scenario.json')['results']! as List<Object?>)
            .single!
        as Map<String, Object?>);

List<Map<String, Object?>> _findings(Map<String, Object?> report) =>
    (report['findings']! as List<Object?>).cast<Map<String, Object?>>();

Map<String, Object?> _finding(Map<String, Object?> report, String id) =>
    _findings(report).singleWhere(
      (f) => f['id'] == id,
      orElse: () => throw StateError(
        'No finding $id in ${_findings(report).map((f) => f['id']).toList()}',
      ),
    );

List<Map<String, Object?>> _diffs(Map<String, Object?> finding) =>
    (finding['diffs']! as List<Object?>).cast<Map<String, Object?>>();

/// The flutter executable of the SDK that runs this test.
File _flutter() {
  var root = Directory.current;
  while (!File(
    p.join(root.path, '.dart_tool/package_config.json'),
  ).existsSync()) {
    root = root.parent;
  }
  final config = File(p.join(root.path, '.dart_tool/package_config.json'));
  final packages =
      ((jsonDecode(config.readAsStringSync())
                  as Map<String, Object?>)['packages']!
              as List<Object?>)
          .cast<Map<String, Object?>>();
  final flutter = Directory.fromUri(
    config.uri.resolve(
      packages.singleWhere((p) => p['name'] == 'flutter')['rootUri']! as String,
    ),
  );
  return File(
    p.normalize(
      p.join(
        flutter.path,
        '..',
        '..',
        'bin',
        Platform.isWindows ? 'flutter.bat' : 'flutter',
      ),
    ),
  );
}

void main() {
  tearDownAll(() => _output.deleteSync(recursive: true));
  final specFile = File(p.join(_output.path, 'design', 'login.design.json'))
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(_spec));

  final matrix = _matrix(_analysis);
  matrix.scenario('design', build: (_) => _screen(design: true));
  matrix.scenario(
    'login',
    build: (_) => _screen(design: false),
    designReference: (variant) => GoldenDesignReference(
      imagePath: p.join(
        _output.path,
        'images',
        'analysis',
        'design',
        '${variant.fileStem}.png',
      ),
      specPath: specFile.path,
      nodeId: '1-1',
      sourceUrl: 'https://www.figma.com/design/KEY/App?node-id=1-1',
    ),
  );
  _matrix(GoldenDesignAnalysis.off).scenario(
    'exact-only',
    build: (_) => _screen(design: false),
    designReference: (variant) => GoldenDesignReference(
      imagePath: p.join(
        _output.path,
        'images',
        'analysis',
        'design',
        '${variant.fileStem}.png',
      ),
    ),
  );

  // A second design system in the same process: its own text roles.
  GoldenMatrix<Color>(
    suite: 'analysis-roles',
    coverage: const GoldenCoverage(
      devices: [_phone],
      themes: [GoldenTheme(name: 'light', data: Color(0xffffffff))],
      locales: [Locale('ko')],
    ),
    environment: GoldenMatrixEnvironment(
      mode: GoldenMatrixMode.capture,
      outputDirectory: _output.path,
    ),
    app: (variant, child) =>
        Directionality(textDirection: TextDirection.ltr, child: child),
    designAnalysis: const GoldenDesignAnalysis(
      designSystem: GoldenDesignSystem(
        discoverCoui: false,
        name: 'Other',
        textRoles: [
          GoldenTextRole(name: 'caption', fontSize: 12, fontWeight: 400),
        ],
      ),
    ),
  ).scenario(
    'roles',
    build: (_) => _screen(design: false),
    designReference: (variant) => GoldenDesignReference(
      imagePath: p.join(
        _output.path,
        'images',
        'analysis',
        'design',
        '${variant.fileStem}.png',
      ),
      specPath: specFile.path,
    ),
  );
  _matrix(const GoldenDesignAnalysis()).scenario(
    'masked',
    build: (_) => const ColoredBox(color: Color(0xffffffff)),
    designReference: (variant) => GoldenDesignReference(
      imagePath: p.join(
        _output.path,
        'images',
        'analysis',
        'design',
        '${variant.fileStem}.png',
      ),
      masks: const [
        GoldenDesignMask.rect(Rect.fromLTWH(0, 0, 200, 150), reason: 'test'),
      ],
    ),
  );

  // Runs after the matrix groups above, whose tearDownAll writes manifests.
  group('analysis report', () {
    late Map<String, Object?> report;
    setUpAll(
      () => report = _json('analysis/analysis/login/phone__light__ko.json'),
    );

    test('the manifest summarizes the analysis next to the exact result', () {
      final result = _result('login');
      expect(result['status'], 'passed');
      final comparison = result['designComparison']! as Map<String, Object?>;
      expect(comparison['status'], 'different');
      final analysis = comparison['analysis']! as Map<String, Object?>;
      expect(
        analysis['report'],
        'analysis/analysis/login/phone__light__ko.json',
      );
      expect(analysis['verdict'], 'fail');
      final counts = analysis['findings']! as Map<String, Object?>;
      expect(counts['error'], greaterThanOrEqualTo(6));
      expect(counts['known'], 1);
      expect(
        File(p.join(_output.path, analysis['diff']! as String)).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(
            _output.path,
            'references/analysis/login/phone__light__ko.design.json',
          ),
        ).existsSync(),
        isTrue,
      );
    });

    test('the report records the design source, masks, and tolerances', () {
      expect(report['schema'], 'co_golden.design_report');
      expect(report['verdict'], 'fail');
      final design = report['design']! as Map<String, Object?>;
      expect(design['referenceSha256'], hasLength(64));
      expect(design['specSha256'], hasLength(64));
      expect((design['frame']! as Map)['id'], '1:1');
      final masks = (report['masks']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(masks.map((m) => m['source']), ['safeArea', 'finder:Text']);
      expect(masks.last['reason'], '실시간 시계');
      expect((report['render']! as Map)['sourceLocations'], isTrue);
    });

    test('a one-step font weight change is reported with its source line', () {
      final finding = _finding(report, 'typography@1:2');
      expect(finding['severity'], 'error');
      final diffs = _diffs(finding);
      expect(
        diffs.map((d) => d['property']),
        containsAll(['role', 'fontWeight']),
      );
      final weight = diffs.singleWhere((d) => d['property'] == 'fontWeight');
      expect(weight['expected'], 700);
      expect(weight['actual'], 600);
      final widget = finding['widget']! as Map<String, Object?>;
      expect(widget['text'], '로그인');
      expect(widget['type'], 'Text');
      final source = File('test/design_analysis_test.dart').readAsLinesSync();
      // The title label line; the Text( call that created it is just above.
      final label = source.indexWhere((l) => l.trim() == "'로그인',");
      expect(source[label - 1], contains('Text('));
      expect(
        widget['source'],
        startsWith('test/design_analysis_test.dart:$label:'),
      );
      expect(finding['owner'], 'app');
      final design = finding['design']! as Map<String, Object?>;
      expect(design['role'], 'titleMedium');
      expect(design['path'], 'Mobile-Default / Title');
    });

    test('a shifted element reports its offset and the gap that changed', () {
      final finding = _finding(report, 'layout@1:3');
      expect(finding['severity'], 'error');
      final diffs = _diffs(finding);
      final y = diffs.singleWhere((d) => d['property'] == 'y');
      expect([y['expected'], y['actual'], y['delta']], [80, 88, 8]);
      final gap = diffs.singleWhere((d) => d['property'] == 'gap');
      expect([gap['expected'], gap['actual']], [8, 16]);
      expect(gap['scope'], '‘Title’ 다음');
    });

    test('radius, missing and extra text, component variant, and fill', () {
      final shape = _diffs(_finding(report, 'shape@1:5'));
      expect(shape.single['property'], 'radius');
      expect([shape.single['expected'], shape.single['actual']], ['12', '4']);

      final missing = _finding(report, 'presence.missing@1:4');
      expect(missing['severity'], 'error');
      expect(_diffs(missing).single['expected'], 'NEW');

      final extra = _findings(
        report,
      ).singleWhere((f) => (f['id']! as String).startsWith('presence.extra@'));
      expect((extra['widget']! as Map)['text'], 'Beta');

      final variant = _finding(report, 'component@1:7');
      final component = variant['component']! as Map<String, Object?>;
      expect(component['name'], 'FakeButton');
      expect(component['properties'], {'variant': 'primary', 'size': 'md'});
      expect(_diffs(variant).single['property'], 'variant');
      expect(_diffs(variant).single['expected'], 'secondary');
      expect(variant['hint'], 'FakeButton(variant: secondary)');

      final fill = _finding(report, 'color.fill@1:7');
      expect(_diffs(fill).single['expected'], startsWith('#E0E0E0'));
    });

    test('colors carry token names, and known differences stay visible', () {
      final color = _finding(report, 'color.text@1:3');
      expect(color['known'], {
        'reason': '보조 글자색 토큰 교체 대기',
        'designNode': '1:3',
        'category': 'color',
        'issue': 'https://github.com/coco-de/coui/issues/1',
      });
      final diff = _diffs(color).single;
      expect(diff['expected'], '#545961 (on-surface-variant)');
      expect(diff['actual'], '#9AA1A3 (surface-dim)');
    });

    test('unloaded fonts are named, masked elements are not compared', () {
      final font = _finding(report, 'font@Pretendard');
      expect(font['severity'], 'error');
      expect(font['hint'], contains('loadGoldenFonts'));
      final ids = _findings(report).map((f) => f['id']! as String).toList();
      expect(ids.where((id) => id.contains('1:6')), isEmpty);
      expect(ids.where((id) => id.contains('1:8')), isEmpty);
      expect(ids.where((id) => id.startsWith('typography@1:3')), isEmpty);
    });

    test('pixel regions point at the design node and widget under them', () {
      final regions = (report['regions']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(regions, isNotEmpty);
      final card = regions.where((r) => r['id'] == 'node:1:5');
      expect(card, isNotEmpty);
      expect(card.first['findings'], contains('shape@1:5'));
      final pixels = report['pixels']! as Map<String, Object?>;
      expect(pixels['status'], 'fail');
      expect(pixels['maskedRatio'], greaterThan(0));
    });

    test('failOnMismatch fails the variant and records why', () async {
      final gate = Directory(p.join(_output.path, 'gate'));
      final result = await Process.run(
        _flutter().path,
        ['test', '--no-pub', 'test/fixtures/design_analysis_gate.dart'],
        environment: {'CO_GOLDEN_GATE_OUTPUT': gate.path},
      );
      expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
      final manifest =
          jsonDecode(
                File(
                  p.join(gate.path, 'runs/gate/screen.json'),
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final entry =
          (manifest['results']! as List<Object?>).single!
              as Map<String, Object?>;
      expect(entry['status'], 'failed');
      expect(entry['failurePhase'], isNull);
      final error = (entry['errors']! as List<Object?>).single! as String;
      expect(error, startsWith('design: fail ('));
      expect(error, contains('pixels:budget'));
      expect(error, contains('analysis/gate/screen/tiny__light__en.json'));
      final analysis =
          (entry['designComparison']! as Map<String, Object?>)['analysis']!
              as Map<String, Object?>;
      expect(analysis['verdict'], 'fail');

      final missing =
          ((jsonDecode(
                            File(
                              p.join(gate.path, 'runs/gate/spec-missing.json'),
                            ).readAsStringSync(),
                          )
                          as Map<String, Object?>)['results']!
                      as List<Object?>)
                  .single!
              as Map<String, Object?>;
      expect(missing['status'], 'failed');
      expect(missing['failurePhase'], 'designAnalysis');
      final exact = missing['designComparison']! as Map<String, Object?>;
      expect(exact['status'], 'matched');
      expect(exact.containsKey('analysis'), isFalse);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('each design system keeps its own catalog in one process', () {
      final first = report['designSystem']! as Map<String, Object?>;
      expect(first['textRoles'], 2);
      final second =
          _json(
                'analysis/analysis-roles/roles/phone__light__ko.json',
              )['designSystem']!
              as Map<String, Object?>;
      expect(second['name'], 'Other');
      expect(second['textRoles'], 1);
    });

    test('regions follow their findings for known differences', () {
      final regions = (report['regions']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .where((r) => r['id'] == 'node:1:3');
      expect(regions, isNotEmpty);
      // Only the color finding of 1:3 is known; the layout finding still
      // counts, so its regions are not accepted.
      for (final region in regions) {
        expect(region.containsKey('known'), isFalse);
      }
    });

    test('an over-masked frame is undetermined, not a pass', () {
      final masked = _json('analysis/analysis/masked/phone__light__ko.json');
      expect(masked['verdict'], 'undetermined');
      final pixels = masked['pixels']! as Map<String, Object?>;
      expect(pixels['reason'], 'over-masked');
    });

    test('known differences read Figma URL node ids', () {
      expect(
        GoldenKnownDifference(designNode: '12-345', reason: 'r').designNode,
        '12:345',
      );
    });

    test('GoldenDesignAnalysis.off keeps only the exact comparison', () {
      final comparison =
          _result('exact-only')['designComparison']! as Map<String, Object?>;
      expect(comparison.containsKey('analysis'), isFalse);
      expect(
        Directory(
          p.join(_output.path, 'analysis/analysis/exact-only'),
        ).existsSync(),
        isFalse,
      );
    });
  });
}
