import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'fixture.dart';

const String reportPath = 'analysis/auth/login/phone__light__ko.json';
const String analysisDiffPath = 'analysis/auth/login/phone__light__ko.png';
const String referencePath = 'references/auth/login/phone__light__ko.png';
const String exactDiffPath = 'differences/auth/login/phone__light__ko.png';

/// A design reference with exact metadata, as co_golden writes it.
Map<String, Object?> exactComparison() => {
  'reference': referencePath,
  'label': 'Figma',
  'sourceUrl': 'https://www.figma.com/design/KEY/App?node-id=12-345',
  'status': 'different',
  'referenceWidth': 4,
  'referenceHeight': 8,
  'renderWidth': 4,
  'renderHeight': 8,
  'diff': exactDiffPath,
  'differentPixels': 3,
  'totalPixels': 32,
  'differenceRatio': 3 / 32,
};

/// The manifest summary of [designReport] (`GoldenDesignAnalysisSummary`).
Map<String, Object?> analysisSummary({String verdict = 'fail'}) => {
  'report': reportPath,
  'verdict': verdict,
  'pixelStatus': verdict == 'pass' ? 'pass' : 'fail',
  'findings': {'error': 2, 'warning': 1, 'info': 1, 'known': 1},
  'byCategory': {'presence': 1, 'component': 1, 'typography': 1, 'content': 1},
  'ratio': 0.107143,
  'largestRegion': 2,
  'regionCount': 2,
  'diff': analysisDiffPath,
};

Map<String, Object?> _designRef(
  String id,
  String name,
  String type,
  List<num> rect, {
  String? textStyle,
  String? component,
  String? path,
  String? role,
}) => {
  'id': id,
  'name': name,
  'type': type,
  'rect': rect,
  'component': ?component,
  'textStyle': ?textStyle,
  'path': ?path,
  'role': ?role,
};

/// A co_golden design report (`GoldenDesignReport.toJson`) for the light
/// variant of `auth/login`, with typography, presence, component, content
/// and known layout findings, an explained and an unexplained region.
Map<String, Object?> designReport({String verdict = 'fail'}) => {
  'schema': 'co_golden.design_report',
  'schemaVersion': 1,
  'suite': 'auth',
  'scenario': 'login',
  'fileStem': 'phone__light__ko',
  'variant': {
    'device': {'name': 'phone'},
    'theme': 'light',
    'locale': 'ko',
    'textScale': 1,
    'platform': 'android',
  },
  'verdict': verdict,
  'verdictReasons': ['pixels:budget', 'findings:error'],
  'summary': {
    'errors': 2,
    'warnings': 1,
    'infos': 1,
    'known': 1,
    'byCategory': analysisSummary()['byCategory'],
    'designNodes': 12,
    'matchedDesignNodes': 10,
    'renderNodes': 30,
    'matchedRenderNodes': 10,
  },
  'design': {
    'label': 'Figma',
    'sourceUrl': 'https://www.figma.com/design/KEY/App?node-id=12-345',
    'reference': referencePath,
    'referenceSha256': 'a' * 64,
    'spec': 'test/design/login.json',
    'specSha256': 'b' * 64,
    'source': {
      'format': 'co_golden.design_spec',
      'tool': 'figma',
      'fileKey': 'KEY',
      'fileName': 'App',
      'nodeId': '12:345',
      'version': '42',
      'lastModified': '2026-10-20T00:00:00Z',
      'url': 'https://www.figma.com/design/KEY/App?node-id=12-345',
    },
    'frame': {
      'id': '12:345',
      'name': 'Mobile-Default',
      'width': 4,
      'height': 8,
    },
    'hasStyles': true,
  },
  'render': {
    'image': 'images/auth/login/phone__light__ko.png',
    'width': 4,
    'height': 8,
    'sourceLocations': true,
  },
  'designSystem': {
    'name': 'CoUI',
    'catalog': 'components.json',
    'components': 148,
  },
  'tolerance': {
    'pixel': 1,
    'colorDeltaE': 3,
    'textPixel': 2,
    'textDeltaE': 10,
    'budgetRatio': 0.002,
    'budgetRegion': 32,
    'maxMaskRatio': 0.15,
    'position': 1,
    'textPosition': 2,
    'size': 1,
    'majorOffset': 4,
    'fontSize': 0.5,
    'lineHeight': 1,
    'letterSpacing': 0.1,
    'radius': 1,
    'strokeWidth': 0.5,
    'propertyDeltaE': 3,
    'majorDeltaE': 10,
    'antialias': true,
  },
  'masks': [
    {
      'rect': [0, 0, 4, 1],
      'reason': '상태 바 — 앱이 그리지 않는다',
      'source': 'safeArea',
    },
  ],
  'pixels': {
    'status': 'fail',
    'scale': 1,
    'width': 4,
    'height': 8,
    'differentPixels': 3,
    'antialiasedPixels': 0,
    'comparablePixels': 28,
    'maskedRatio': 0.125,
    'ratio': 0.107143,
    'largestRegion': 2,
    'regionCount': 2,
    'textBoxes': 1,
    'transparentPixels': {'design': 0, 'render': 0},
    'diff': analysisDiffPath,
  },
  'regions': [
    {
      'id': 'node:12:350',
      'rect': [1, 2, 2, 1],
      'pixels': 2,
      'logicalPixels': 2,
      'designColor': '#14161A',
      'renderColor': '#2A2D33',
      'meanDeltaE': 12.3,
      'design': _designRef('12:350', 'Title', 'TEXT', [1, 2, 2, 1]),
      'widget': {
        'id': 3,
        'kind': 'text',
        'type': 'Text',
        'text': '로그인',
        'rect': [1, 2, 2, 1],
        'source': 'lib/src/login_page.dart:42:9',
      },
      'findings': ['typography@12:350'],
    },
    {
      'id': 'cell:0,0',
      'rect': [3, 6, 1, 1],
      'pixels': 1,
      'logicalPixels': 1,
      'designColor': '#FFFFFF',
      'renderColor': '#000000',
      'meanDeltaE': 100,
      'widget': {
        'id': 9,
        'kind': 'graphic',
        'type': 'SvgPicture',
        'rect': [3, 6, 1, 1],
        'source': 'lib/src/login_page.dart:88:5',
      },
    },
  ],
  'findings': [
    {
      'id': 'layout@12:360',
      'category': 'layout',
      'severity': 'warning',
      'message': 'Card 본문과 푸터 사이 간격이 Figma보다 16px 좁습니다',
      'diffs': [
        {
          'property': 'y',
          'expected': 28,
          'actual': 12,
          'unit': 'px',
          'delta': -16,
          'scope': '‘Footer’ 기준',
          'severity': 'warning',
        },
      ],
      'design': _designRef('12:360', 'Footer', 'FRAME', [0, 5, 4, 2]),
      'known': {
        'reason': 'CoUI Card 본문 · 푸터 간격',
        'designNode': '12:360',
        'issue': 'https://github.com/coco-de/coui/issues/5652',
      },
    },
    {
      'id': 'typography@12:350',
      'category': 'typography',
      'severity': 'error',
      'message': '‘로그인’ 서체가 Figma와 다릅니다 </script>',
      'diffs': [
        {
          'property': 'fontWeight',
          'expected': 700,
          'actual': 600,
          'delta': -100,
          'severity': 'error',
        },
        {
          'property': 'letterSpacing',
          'expected': -0.24,
          'actual': 0,
          'unit': 'px',
          'delta': 0.24,
          'severity': 'warning',
        },
      ],
      'design': _designRef(
        '12:350',
        'Title',
        'TEXT',
        [1, 2, 2, 1],
        textStyle: 'Title/Medium',
        path: 'Mobile-Default / Header / Title',
        role: 'titleMedium',
      ),
      'widget': {
        'id': 3,
        'kind': 'text',
        'type': 'Text',
        'text': '로그인',
        'rect': [1, 2.5, 2, 1],
        'source': 'lib/src/login_page.dart:42:9',
        'path': 'LoginPage › Column › Button › Text',
        'role': 'bodyMedium',
      },
      'component': {
        'id': 0,
        'name': 'Button',
        'library': 'coui_flutter',
        'properties': {'variant': 'primary', 'size': 'md'},
        'rect': [0, 2, 4, 2],
        'source': 'lib/src/login_page.dart:40:7',
      },
      'rect': [1, 2, 2, 1.5],
      'owner': 'app',
      'hint': "Text('로그인').titleMedium 로 바꿉니다 (Figma 텍스트 스타일 Title/Medium)",
    },
    {
      'id': 'presence@12:400',
      'category': 'presence',
      'severity': 'error',
      'message': 'Figma의 ‘Badge/New’가 구현에 없습니다',
      'diffs': [
        {
          'property': 'present',
          'expected': true,
          'actual': false,
          'severity': 'error',
        },
      ],
      'design': _designRef('12:400', 'Badge/New', 'INSTANCE', [
        3,
        1,
        1,
        1,
      ], component: 'Badge'),
      'rect': [3, 1, 1, 1],
      'hint': 'CoUI Badge 를 추가합니다',
    },
    {
      'id': 'component@12:340',
      'category': 'component',
      'severity': 'warning',
      'message': 'Button 변형이 Figma와 다릅니다',
      'diffs': [
        {
          'property': 'variant',
          'expected': 'secondary',
          'actual': 'primary',
          'severity': 'warning',
        },
      ],
      'design': _designRef('12:340', 'Button', 'INSTANCE', [
        0,
        2,
        4,
        2,
      ], component: 'Button'),
      'component': {
        'id': 0,
        'name': 'Button',
        'library': 'coui_flutter',
        'properties': {'variant': 'primary', 'size': 'md'},
        'rect': [0, 2, 4, 2],
        'source': 'lib/src/login_page.dart:40:7',
      },
      'hint': 'variant: CoreButtonVariant.secondary',
    },
    {
      'id': 'content@12:351',
      'category': 'content',
      'severity': 'info',
      'message': '줄 수가 Figma와 다릅니다',
      'diffs': [
        {
          'property': 'lines',
          'expected': 1,
          'actual': 2,
          'delta': 1,
          'severity': 'info',
        },
      ],
      'widget': {
        'id': 4,
        'kind': 'text',
        'type': 'Text',
        'text': '비밀번호를 잊으셨나요?',
        'rect': [0, 4, 4, 2],
        'source': 'lib/src/login_page.dart:57:11',
      },
    },
  ],
  'warnings': ['Figma 변수 이름이 없어 토큰은 값으로만 비교했습니다.'],
  'inspection': {
    'width': 4,
    'height': 8,
    'sourceLocations': true,
    'components': <Object?>[],
    'nodes': <Object?>[],
  },
};

/// Writes the auxiliary files and a manifest whose light variant carries an
/// analysis. Returns the design comparison written to the manifest.
Map<String, Object?> writeAnalysedSource(
  Directory root, {
  Map<String, Object?>? analysis,
  Object? report,
  bool writeReport = true,
  List<Map<String, Object?>> extraResults = const [],
}) {
  writePng(p.join(root.path, referencePath));
  writePng(p.join(root.path, exactDiffPath));
  writePng(p.join(root.path, analysisDiffPath));
  if (writeReport) {
    File(p.join(root.path, reportPath))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        report is String ? report : jsonEncode(report ?? designReport()),
      );
  }
  final comparison = {
    ...exactComparison(),
    'analysis': analysis ?? analysisSummary(),
  };
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
        'designComparison': comparison,
      },
      ...extraResults,
    ],
  );
  return comparison;
}
