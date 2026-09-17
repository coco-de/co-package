// S10.4 (#81) — 순환 의존 차단 가드.
//
// open_epub_engine 은 pure-Dart 여야 한다(ADR-008). Flutter 렌더/위젯/컨트롤러는
// open_epub 에 잔류한다. 이 테스트는 엔진 lib/ 아래 어떤 파일도 Flutter(또는 Flutter
// 전용 바인딩 dart:ui)를 import 하지 못하도록 구조적으로 강제한다.
//
// 엔진 pubspec 에 flutter 의존이 없으므로 `import 'package:flutter/...'` 는 이미
// 컴파일 에러(uri_does_not_exist)로 차단되지만, 이 가드는 회귀를 CI에서 즉시·명시적
// 실패로 드러낸다(engine→open_epub 역방향 의존 유입도 함께 방지).
import 'dart:io';

import 'package:test/test.dart';

/// 엔진에서 금지하는 import 접두. Flutter 프레임워크와 Flutter 전용 바인딩(dart:ui).
const _forbiddenImportPrefixes = <String>[
  'package:flutter/',
  'package:flutter_test/',
  'dart:ui',
  // 역방향 의존(엔진이 상위 Flutter 패키지를 소비 → 순환) 차단.
  'package:open_epub/',
];

final _importDirective = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

void main() {
  test('open_epub_engine lib/ 는 Flutter/역방향 의존을 import 하지 않는다', () {
    final libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'lib/ 를 찾지 못했다. `dart test` 를 패키지 루트에서 실행해야 한다.',
    );

    final violations = <String>[];
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    // 가드가 공허하게 통과하지 않도록(스캔 대상 0개면 무의미) 실제 스캔을 강제한다.
    expect(
      dartFiles,
      isNotEmpty,
      reason: '엔진 lib/ 에서 .dart 파일을 하나도 찾지 못했다 — 가드가 무력화됐다.',
    );

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      for (final match in _importDirective.allMatches(content)) {
        final uri = match.group(1)!;
        for (final forbidden in _forbiddenImportPrefixes) {
          if (uri == forbidden || uri.startsWith(forbidden)) {
            violations.add('${file.path} → $uri');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: '엔진은 pure-Dart 여야 한다. 금지 import 발견:\n${violations.join('\n')}',
    );
  });
}
