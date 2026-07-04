// Story: S12.1 (#94) — 이식한 epub_pro CFI 프리미티브(core+dom) 동작 검증.
// CFI 문자열 파싱/직렬화 round-trip, 비교/범위, DOM 탐색/경로 생성 왕복.

import 'package:open_epub_engine/src/cfi/core/cfi.dart';
import 'package:open_epub_engine/src/cfi/core/cfi_structure.dart';
import 'package:open_epub_engine/src/cfi/dom/dom_abstraction.dart';
import 'package:open_epub_engine/src/cfi/dom/html_navigator.dart';
import 'package:test/test.dart';

void main() {
  group('S12.1 — CFI 문자열 파싱/직렬화', () {
    test('point CFI parse → toString round-trip', () {
      final cfi = CFI('epubcfi(/6/4[chap01]!/4/10/2:3)');
      expect(cfi.isPoint, isTrue);
      expect(cfi.isRange, isFalse);
      // 재파싱 시 구조 동등 (정규화 무손실)
      final reparsed = CFI(cfi.toString());
      expect(reparsed, equals(cfi));
      expect(reparsed.structure, equals(cfi.structure));
    });

    test('range CFI parse → isRange + collapse', () {
      final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
      expect(range.isRange, isTrue);
      final start = range.collapse();
      final end = range.collapse(toEnd: true);
      expect(start.isPoint, isTrue);
      expect(end.isPoint, isTrue);
      // start는 end보다 앞선다.
      expect(start.compare(end), lessThan(0));
    });

    test('잘못된 CFI 문자열은 FormatException', () {
      expect(() => CFI('not-a-cfi'), throwsA(isA<FormatException>()));
    });
  });

  group('S12.1 — CFI 비교(reading order)', () {
    test('같은 경로에서 더 큰 offset이 뒤에 온다', () {
      final a = CFI('epubcfi(/6/4!/4/10/2:3)');
      final b = CFI('epubcfi(/6/4!/4/10/2:5)');
      expect(a.compare(b), lessThan(0));
      expect(b.compare(a), greaterThan(0));
      expect(a.compare(a), equals(0));
    });
  });

  group('S12.1 — DOM 탐색 (HTMLNavigator)', () {
    late DOMDocument doc;

    setUp(() {
      const html = '''
        <html>
          <body>
            <div id="container">
              <h1 id="title">Main Title</h1>
              <p>First paragraph</p>
              <p>Second paragraph</p>
            </div>
          </body>
        </html>
      ''';
      doc = DOMDocument.parseHTML(html);
    });

    test('인덱스 경로로 element 탐색', () {
      final path = CFIPath(parts: [
        const CFIPart(index: 2), // html
        const CFIPart(index: 2), // body
        const CFIPart(index: 2), // div
      ]);
      final pos = HTMLNavigator.navigateToPosition(doc, path);
      expect(pos, isNotNull);
      expect(pos!.container.tagName, equals('div'));
      expect(pos.container.id, equals('container'));
    });

    test('ID assertion 직접 탐색', () {
      final path = CFIPath(parts: [
        const CFIPart(index: 0, id: 'title'),
      ]);
      final pos = HTMLNavigator.navigateToPosition(doc, path);
      expect(pos, isNotNull);
      expect(pos!.container.id, equals('title'));
    });

    test('position → path → position 왕복 (createPathFromPosition ↔ navigateToPosition)', () {
      // div로 먼저 이동
      final divPath = CFIPath(parts: [
        const CFIPart(index: 2),
        const CFIPart(index: 2),
        const CFIPart(index: 2),
      ]);
      final divPos = HTMLNavigator.navigateToPosition(doc, divPath);
      expect(divPos, isNotNull);

      // 그 위치에서 path 재생성 → 다시 탐색 → 같은 노드
      final rebuiltPath = HTMLNavigator.createPathFromPosition(divPos!);
      final roundTrip = HTMLNavigator.navigateToPosition(doc, rebuiltPath);
      expect(roundTrip, isNotNull);
      expect(roundTrip!.container.tagName, equals('div'));
      expect(roundTrip.container.id, equals('container'));
    });

    test('범위 밖 인덱스는 null', () {
      final path = CFIPath(parts: [const CFIPart(index: 99)]);
      expect(HTMLNavigator.navigateToPosition(doc, path), isNull);
    });
  });
}
