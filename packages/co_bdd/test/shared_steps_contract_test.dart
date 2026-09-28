import 'dart:io';

import 'package:co_bdd/src/generator/feature_parser.dart';
import 'package:co_bdd/src/generator/test_generator.dart'
    show sharedStepFileNames;
import 'package:test/test.dart';

/// 공유 step 의 이름 계약 — **생성기와 같은 코드**로 판정한다.
///
/// 생성기는 `.feature` 문장에서 파일명과 함수명을 유도한다. 공유 step 의
/// `/// Usage:` 문장이 유도하는 이름이 실제 파일명·함수명과 다르면, 그 문장을
/// 쓴 `.feature` 는 존재하지 않는 심볼을 import 해 컴파일이 깨진다 — 그러면 소비
/// 프로젝트는 같은 step 을 로컬에 다시 만든다 (coco-de/unibook#9506 에서 20종 중
/// 2종이 이 상태였다). 예전에는 소비 측 파이썬 가드가 이름 규칙을 흉내 내 검사했다.
void main() {
  final stepDir = Directory('lib/src/shared_step');
  final barrel = File('lib/shared_steps.dart').readAsStringSync();
  final usageRe = RegExp(r'^/// Usage: (.+)$', multiLine: true);
  final functionRe = RegExp(r'^Future<void> (\w+)\(', multiLine: true);
  final exportRe = RegExp(
    r"^export 'src/shared_step/(\w+)\.dart';",
    multiLine: true,
  );

  final files =
      stepDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final exported = exportRe.allMatches(barrel).map((m) => m.group(1)!).toSet();

  test('공유 step 디렉토리가 비어 있지 않다 (검사 0건을 통과로 세지 않는다)', () {
    expect(files, isNotEmpty);
  });

  for (final file in files) {
    final stem = file.uri.pathSegments.last.replaceAll('.dart', '');
    final source = file.readAsStringSync();

    group(stem, () {
      final usage = usageRe.firstMatch(source)?.group(1);

      test('/// Usage: 문장이 있다', () {
        expect(usage, isNotNull, reason: '$stem 에 /// Usage: 가 없다');
      });

      if (usage == null) return;

      // 생성기와 같게 ` # ` 뒤 설명을 자른다 (feature_parser `_parseStep`).
      final comment = usage.indexOf(' # ');
      final text = (comment >= 0 ? usage.substring(0, comment) : usage).trim();
      final step = Step(keyword: 'When', text: text, params: const []);

      test('Usage 가 유도하는 파일명 == 파일명', () {
        expect(step.fileName, stem);
      });

      test('Usage 가 유도하는 함수명이 선언돼 있다', () {
        final declared = functionRe.allMatches(source).map((m) => m.group(1));
        expect(declared, contains(step.functionName));
      });

      test('shared_steps.dart 에서 export 된다', () {
        expect(exported, contains(stem));
      });
    });
  }

  test('생성기의 기본 공유 step 목록 == export 목록', () {
    // 목록을 생략한 build.yaml 은 이 기본값으로 공유 step 을 고른다. 어긋나면
    // 새 step 이 소비 프로젝트에 조용히 안 잡히거나(누락), 없는 심볼을 import 해
    // 생성 테스트가 컴파일되지 않는다(초과).
    expect(sharedStepFileNames, exported);
  });

  test('export 목록에 실제 파일이 없는 이름이 없다', () {
    final stems = files
        .map((file) => file.uri.pathSegments.last.replaceAll('.dart', ''))
        .toSet();
    expect(exported.difference(stems), isEmpty);
  });
}
