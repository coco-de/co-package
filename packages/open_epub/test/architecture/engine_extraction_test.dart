// S10.4 (#81) — 엔진 추출 구조 불변식 가드.
//
// S10.3 에서 순수-Dart 레이어(api·domain·data)를 open_epub_engine 으로 이동했다.
// open_epub 에는 Flutter 의존 컨트롤러만 잔류해야 한다(게이트 C1, ADR-008).
// 이 가드는 이동 레이어가 open_epub 로 되돌아오는 회귀를 구조적으로 막는다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('engine 추출 구조 불변식', () {
    test('lib/src/domain, lib/src/data 는 open_epub 에 남지 않는다(엔진 이동)', () {
      expect(
        Directory('lib/src/domain').existsSync(),
        isFalse,
        reason: 'domain/ 은 open_epub_engine 으로 이동됐다(S10.3).',
      );
      expect(
        Directory('lib/src/data').existsSync(),
        isFalse,
        reason: 'data/ 는 open_epub_engine 으로 이동됐다(S10.3).',
      );
    });

    test('lib/src/api 에는 Flutter 컨트롤러만 잔류한다', () {
      final apiDir = Directory('lib/src/api');
      expect(apiDir.existsSync(), isTrue);

      final remaining = apiDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.endsWith('.dart'))
          .toList()
        ..sort();

      expect(
        remaining,
        equals(<String>['epub_reader_controller.dart']),
        reason: '순수-Dart api 파일은 open_epub_engine 소관이다. open_epub 에는 '
            'Flutter 의존 컨트롤러만 잔류해야 한다(S10.4). 발견: $remaining',
      );
    });
  });
}
