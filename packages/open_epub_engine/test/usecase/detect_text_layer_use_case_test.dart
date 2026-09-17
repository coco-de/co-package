// Story: S1.13 — Text Layer Detection (Fixed Layout) tests
// BDD: F5.5, F5.6, F7.4 / RFC-2 (tech-spec §3)

import 'package:test/test.dart';
import 'package:open_epub_engine/src/domain/entity/text_layer_verdict.dart';
import 'package:open_epub_engine/src/domain/usecase/detect_text_layer_use_case.dart';

void main() {
  const detector = DetectTextLayerUseCase();

  String body(String inner) => '<html><body>$inner</body></html>';

  group('detect — 텍스트 충분(text)', () {
    test('가시 텍스트 50자 이상 → available text:N', () {
      final v = detector.detect(body('<p>${'x' * 120}</p>'));
      expect(v.isAvailable, isTrue);
      expect(v.visibleCharCount, 120);
      expect(v.reason, 'text:120');
    });

    test('정확히 50자 경계 → available', () {
      final v = detector.detect(body('<p>${'x' * 50}</p>'));
      expect(v.isAvailable, isTrue);
      expect(v.reason, 'text:50');
    });

    test('49자 + 요소 1개 → too-sparse (경계 아래)', () {
      final v = detector.detect(body('<p>${'x' * 49}</p>'));
      expect(v.isUnavailable, isTrue);
      expect(v.reason, 'too-sparse:49');
      expect(v.visibleCharCount, 49);
    });
  });

  group('detect — 혼합 콘텐츠(mixed)', () {
    test('짧은 텍스트 + 비이미지 요소 3개 이상 → mixed:E/N', () {
      final v = detector.detect(
        body('<div><p>aa</p><span>bb</span><h1>cc</h1></div>'),
      );
      expect(v.isAvailable, isTrue);
      expect(v.reason, 'mixed:4/6'); // div,p,span,h1 = 4 / 'aabbcc' = 6
      expect(v.visibleCharCount, 6);
    });

    test('비이미지 요소가 이미지와 섞여도 이미지는 카운트 제외', () {
      final v = detector.detect(
        body('<div><img src="a"/><p>aa</p><span>bb</span></div>'),
      );
      // div,p,span = 3 (img 제외), 텍스트 'aabb' = 4
      expect(v.reason, 'mixed:3/4');
    });
  });

  group('detect — image-only', () {
    test('이미지만 → image-only', () {
      final v = detector.detect(body('<img src="a"/><img src="b"/>'));
      expect(v.isUnavailable, isTrue);
      expect(v.reason, 'image-only');
      expect(v.visibleCharCount, 0);
    });

    test('빈 body → image-only', () {
      final v = detector.detect(body(''));
      expect(v.reason, 'image-only');
    });

    test('svg 전용 페이지 → image-only', () {
      final v = detector.detect(body('<svg><rect/></svg>'));
      // svg/rect 모두 비텍스트, 가시 텍스트 0
      expect(v.isUnavailable, isTrue);
      expect(v.reason, 'image-only');
    });
  });

  group('detect — too-sparse', () {
    test('텍스트 약간 + 요소 적음 → too-sparse:N', () {
      final v = detector.detect(body('<p>short</p>'));
      expect(v.isUnavailable, isTrue);
      expect(v.reason, 'too-sparse:5');
    });
  });

  group('가시성 — 숨김 텍스트 제외 (tech-spec §3.3)', () {
    test('display:none 텍스트 제외', () {
      final v = detector.detect(
        body('<p style="display:none">${'x' * 100}</p><p>visible</p>'),
      );
      expect(v.visibleCharCount, 'visible'.length);
      expect(v.reason, 'too-sparse:7');
    });

    test('display : none (공백 변형)도 제외', () {
      final v = detector.detect(
        body('<p style="color:red; display : none">${'x' * 100}</p><p>ok</p>'),
      );
      expect(v.visibleCharCount, 2);
    });

    test('visibility:hidden 제외', () {
      final v = detector.detect(
        body('<span style="visibility:hidden">${'x' * 100}</span><span>ok</span>'),
      );
      expect(v.visibleCharCount, 2);
    });

    test('aria-hidden="true" 제외', () {
      final v = detector.detect(
        body('<p aria-hidden="true">${'x' * 100}</p><p>yo</p>'),
      );
      expect(v.visibleCharCount, 2);
    });

    test('숨김 부모의 자식 텍스트도 함께 제외', () {
      final v = detector.detect(
        body('<div style="display:none"><p>${'x' * 100}</p></div><p>tail</p>'),
      );
      expect(v.visibleCharCount, 'tail'.length);
    });
  });

  group('head/메타 제외', () {
    test('head의 title/meta 텍스트는 가시 텍스트에서 제외', () {
      final v = detector.detect(
        '<html><head><title>${'x' * 100}</title>'
        '<meta name="a" content="b"/></head><body><img src="x"/></body></html>',
      );
      expect(v.reason, 'image-only');
    });
  });

  group('공백 정규화', () {
    test('연속 공백·개행·탭 축약 후 trim', () {
      final v = detector.detect(body('<p>  a   b\n\n\tc  </p>'));
      expect(v.visibleCharCount, 'a b c'.length); // 5
      expect(v.reason, 'too-sparse:5');
    });
  });

  group('폴백 — 비정형 XHTML', () {
    test('미닫힘 태그 → 폴백 태그 제거 길이로 판정', () {
      final v = detector.detect('<div><p>${'x' * 60}');
      expect(v.isAvailable, isTrue);
      expect(v.reason, 'text:60');
    });

    test('미정의 엔티티(&nbsp;) → 폴백', () {
      final v = detector.detect('<p>${'x' * 60}&nbsp;tail</p>');
      expect(v.isAvailable, isTrue);
    });
  });

  group('call() 비동기', () {
    test('call은 detect와 동일 결과', () async {
      final xhtml = body('<p>${'x' * 80}</p>');
      expect(await detector.call(xhtml), detector.detect(xhtml));
    });
  });

  group('TextLayerVerdict 엔티티', () {
    test('available 팩토리', () {
      final v = TextLayerVerdict.available(visibleCharCount: 60, reason: 'text:60');
      expect(v.hasSelectableText, isTrue);
      expect(v.isAvailable, isTrue);
      expect(v.isUnavailable, isFalse);
    });

    test('unavailable 팩토리 기본 count 0', () {
      final v = TextLayerVerdict.unavailable(reason: 'image-only');
      expect(v.hasSelectableText, isFalse);
      expect(v.visibleCharCount, 0);
      expect(v.isUnavailable, isTrue);
    });

    test('== / hashCode (값 동등)', () {
      final a = TextLayerVerdict.available(visibleCharCount: 60, reason: 'text:60');
      final b = TextLayerVerdict.available(visibleCharCount: 60, reason: 'text:60');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a == TextLayerVerdict.unavailable(reason: 'image-only'),
        isFalse,
      );
    });
  });
}
