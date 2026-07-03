// Story: S1.7 (#13) — ViewportFitter math tests
// BDD: F3.1 (viewport fit), F3.3 (auto spread breakpoint)

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/domain/entity/epub_metadata.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/viewport_fitter.dart';

void main() {
  const fitter = ViewportFitter();

  group('computeScale — BoxFit.contain 비율 유지', () {
    test('정사각 페이지 + 정사각 viewport → scale = viewport/page', () {
      final s = fitter.computeScale(
        pageWidth: 100,
        pageHeight: 100,
        viewportWidth: 400,
        viewportHeight: 400,
      );
      expect(s, 4.0);
    });

    test('가로 페이지가 viewport보다 크면 축소 (가로 기준)', () {
      // page 1024x768, viewport 800x600 → scaleX=800/1024=0.781, scaleY=600/768=0.781
      final s = fitter.computeScale(
        pageWidth: 1024,
        pageHeight: 768,
        viewportWidth: 800,
        viewportHeight: 600,
      );
      expect(s, closeTo(0.78125, 0.0001));
    });

    test('비율 다를 때 작은 축 기준 (contain)', () {
      // page 100x100, viewport 200x50 → scaleX=2.0, scaleY=0.5 → min=0.5
      final s = fitter.computeScale(
        pageWidth: 100,
        pageHeight: 100,
        viewportWidth: 200,
        viewportHeight: 50,
      );
      expect(s, 0.5);
    });

    test('page 0/음수 → safe default 1.0', () {
      expect(
        fitter.computeScale(
          pageWidth: 0,
          pageHeight: 100,
          viewportWidth: 200,
          viewportHeight: 200,
        ),
        1.0,
      );
      expect(
        fitter.computeScale(
          pageWidth: -10,
          pageHeight: 100,
          viewportWidth: 200,
          viewportHeight: 200,
        ),
        1.0,
      );
    });

    test('viewport 0/음수 → safe default 1.0', () {
      expect(
        fitter.computeScale(
          pageWidth: 100,
          pageHeight: 100,
          viewportWidth: 0,
          viewportHeight: 0,
        ),
        1.0,
      );
    });
  });

  group('shouldUseTwoPageSpread — FR-3.4 / BDD F3.3', () {
    test('rendition:spread = none → 항상 false', () {
      expect(
        fitter.shouldUseTwoPageSpread(
          screenWidth: 4000,
          screenHeight: 4000,
          spread: EpubSpread.none,
        ),
        isFalse,
      );
    });

    test('rendition:spread = both → 항상 true', () {
      expect(
        fitter.shouldUseTwoPageSpread(
          screenWidth: 320,
          screenHeight: 240,
          spread: EpubSpread.both,
        ),
        isTrue,
      );
    });

    test('rendition:spread = auto → 1024px breakpoint', () {
      // UX Spec §3 — Architecture §10.2
      final cases = <int, bool>{
        480: false,
        768: false,
        1023: false,
        1024: true,
        1440: true,
      };
      for (final entry in cases.entries) {
        expect(
          fitter.shouldUseTwoPageSpread(
            screenWidth: entry.key.toDouble(),
            screenHeight: 768,
            spread: EpubSpread.auto,
          ),
          entry.value,
          reason: 'screenWidth=${entry.key}',
        );
      }
    });

    test('rendition:spread = landscape → width > height일 때만', () {
      expect(
        fitter.shouldUseTwoPageSpread(
          screenWidth: 1024,
          screenHeight: 768,
          spread: EpubSpread.landscape,
        ),
        isTrue,
      );
      expect(
        fitter.shouldUseTwoPageSpread(
          screenWidth: 768,
          screenHeight: 1024,
          spread: EpubSpread.landscape,
        ),
        isFalse,
      );
    });

    test('rendition:spread = portrait → height > width일 때만', () {
      expect(
        fitter.shouldUseTwoPageSpread(
          screenWidth: 768,
          screenHeight: 1024,
          spread: EpubSpread.portrait,
        ),
        isTrue,
      );
      expect(
        fitter.shouldUseTwoPageSpread(
          screenWidth: 1024,
          screenHeight: 768,
          spread: EpubSpread.portrait,
        ),
        isFalse,
      );
    });
  });
}
