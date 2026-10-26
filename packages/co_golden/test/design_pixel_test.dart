import 'package:co_golden/src/design/color.dart';
import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/mask.dart';
import 'package:co_golden/src/design/pixel_diff.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/report.dart';
import 'package:co_golden/src/design/tolerance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

// The cases mirror the visual-verify skill's test_figma_compare.py, so the
// Dart comparator and the Python gate agree on the same inputs.

const _w = 40;
const _h = 30;
const _s = 2;

image.Image _canvas({int w = _w * _s, int h = _h * _s}) {
  final png = image.Image(width: w, height: h, numChannels: 4);
  image.fill(png, color: image.ColorRgba8(255, 255, 255, 255));
  return png;
}

void _rect(image.Image img, int x0, int y0, int x1, int y1, List<int> rgb) {
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      img.setPixelRgba(x, y, rgb[0], rgb[1], rgb[2], 255);
    }
  }
}

(image.Image, image.Image) _pair([
  void Function(image.Image render)? mutate,
  image.Image? base,
]) {
  final a = base?.clone() ?? _canvas();
  _rect(a, 20, 20, 60, 40, [30, 90, 200]);
  final b = a.clone();
  mutate?.call(b);
  return (a, b);
}

GoldenPixelDiff _diff(
  (image.Image, image.Image) pair, {
  GoldenDesignTolerance tolerance = const GoldenDesignTolerance(),
  List<GoldenRect> masks = const [],
  List<GoldenRect> textBoxes = const [],
}) => compareDesignPixels(
  reference: GoldenRgbImage.fromImage(pair.$1),
  render: GoldenRgbImage.fromImage(pair.$2),
  logicalWidth: _w.toDouble(),
  tolerance: tolerance,
  masks: masks,
  textBoxes: textBoxes,
);

void main() {
  group('CIEDE2000', () {
    test('matches the Sharma reference pairs', () {
      const pairs = [
        ((50.0, 2.6772, -79.7751), (50.0, 0.0, -82.7485), 2.0425),
        ((50.0, 3.1571, -77.2803), (50.0, 0.0, -82.7485), 2.8615),
        ((50.0, 0.0, 0.0), (50.0, -1.0, 2.0), 2.3669),
        ((50.0, 2.5, 0.0), (73.0, 25.0, -18.0), 27.1492),
        ((60.2574, -34.0099, 36.2677), (60.4626, -34.1751, 39.4387), 1.2644),
      ];
      for (final (a, b, want) in pairs) {
        expect(GoldenColorMath.ciede2000(a, b), closeTo(want, 1e-4));
        expect(GoldenColorMath.ciede2000(b, a), closeTo(want, 1e-4));
      }
    });

    test('Lab of white and black', () {
      final (l, a, b) = GoldenColorMath.rgbToLab(0xffffff);
      expect(l, closeTo(100, 0.01));
      expect(a, closeTo(0, 0.01));
      expect(b, closeTo(0, 0.01));
      expect(GoldenColorMath.rgbToLab(0x000000).$1, closeTo(0, 1e-6));
    });

    test('hex helpers round-trip and composite like the Python gate', () {
      expect(GoldenColorMath.parseHex('#1E5AC8'), 0xff1e5ac8);
      expect(GoldenColorMath.parseHex('#1e5ac880'), 0x801e5ac8);
      expect(GoldenColorMath.hexArgb(0x801e5ac8), '#1E5AC880');
      expect(GoldenColorMath.over(0x800000ff, 0x808080), 0x4040c0);
    });
  });

  group('tolerant comparison', () {
    test('identical images have no difference', () {
      final result = _diff(_pair());
      expect(result.differentPixels, 0);
      expect(result.withinBudget(const GoldenDesignTolerance()), isTrue);
    });

    test('a wrong color block fails and is located', () {
      final result = _diff(
        _pair((b) => _rect(b, 20, 20, 60, 40, [200, 40, 40])),
      );
      expect(result.withinBudget(const GoldenDesignTolerance()), isFalse);
      expect(result.regions, hasLength(1));
      final region = result.regions.single;
      expect(region.bounds, const GoldenRect(10, 10, 20, 10));
      expect(GoldenColorMath.hex(region.referenceColor), '#1E5AC8');
      expect(GoldenColorMath.hex(region.renderColor), '#C82828');
      expect(region.logicalPixels, 200);
    });

    test('a shift within the positional tolerance passes', () {
      final result = _diff(
        _pair((b) {
          _rect(b, 20, 20, 60, 40, [255, 255, 255]);
          _rect(b, 22, 20, 62, 40, [30, 90, 200]);
        }),
      );
      expect(result.differentPixels, 0);
    });

    test('a shift beyond the tolerance fails', () {
      final result = _diff(
        _pair((b) {
          _rect(b, 20, 20, 60, 40, [255, 255, 255]);
          _rect(b, 26, 20, 66, 40, [30, 90, 200]);
        }),
      );
      expect(result.differentPixels, greaterThan(0));
    });

    test('a small color change within ΔE passes', () {
      final result = _diff(
        _pair((b) => _rect(b, 20, 20, 60, 40, [31, 91, 201])),
      );
      expect(result.differentPixels, 0);
    });

    test('anti-aliased edges are not counted unless disabled', () {
      final base = _canvas();
      _rect(base, 0, 0, 10, _h * _s, [0, 0, 0]);
      _rect(base, 10, 0, 11, _h * _s, [128, 128, 128]);
      final pair = _pair(
        (b) => _rect(b, 10, 0, 11, _h * _s, [100, 100, 100]),
        base,
      );
      final tolerance = const GoldenDesignTolerance(pixel: 0);
      final result = _diff(pair, tolerance: tolerance);
      expect(result.differentPixels, 0);
      expect(result.antialiasedPixels, greaterThan(0));
      final strict = _diff(
        pair,
        tolerance: const GoldenDesignTolerance(pixel: 0, antialias: false),
      );
      expect(strict.differentPixels, greaterThan(0));
    });

    test('masks hide their area and an over-masked frame is undetermined', () {
      final pair = _pair((b) => _rect(b, 20, 20, 60, 40, [200, 40, 40]));
      final masked = _diff(
        pair,
        masks: const [GoldenRect(10, 10, 20, 10)],
        tolerance: const GoldenDesignTolerance(maxMaskRatio: 0.2),
      );
      expect(masked.differentPixels, 0);
      expect(masked.maskedRatio, closeTo(200 / 1200, 1e-3));
      expect(
        () => _diff(_pair(), masks: const [GoldenRect(0, 0, 40, 10)]),
        throwsA(
          isA<GoldenPixelUndetermined>().having(
            (e) => e.reason,
            'reason',
            'over-masked',
          ),
        ),
      );
    });

    test('a wrong size is undetermined, an integer multiple is downscaled', () {
      expect(
        () => _diff((_canvas(), _canvas(w: 120, h: 90))),
        throwsA(
          isA<GoldenPixelUndetermined>().having(
            (e) => e.reason,
            'reason',
            'size-mismatch',
          ),
        ),
      );
      final downscaled = _diff((_canvas(), _canvas(w: 160, h: 120)));
      expect(downscaled.differentPixels, 0);
      expect(downscaled.notes, isNotEmpty);
    });

    test('text boxes forgive horizontal glyph drift but not vertical', () {
      const tolerance = GoldenDesignTolerance(textPixel: 3);
      const text = [GoldenRect(10, 10, 20, 10)];
      final drift = _diff(
        _pair((b) {
          _rect(b, 20, 20, 60, 40, [255, 255, 255]);
          _rect(b, 26, 20, 66, 40, [30, 90, 200]);
        }),
        tolerance: tolerance,
        textBoxes: text,
      );
      expect(drift.differentPixels, 0);
      final sink = _diff(
        _pair((b) {
          _rect(b, 20, 20, 60, 40, [255, 255, 255]);
          _rect(b, 20, 26, 60, 46, [30, 90, 200]);
        }),
        tolerance: tolerance,
        textBoxes: text,
      );
      expect(sink.differentPixels, greaterThan(0));
    });

    test('transparent pixels composite over the gray backdrop', () {
      final png = image.Image(width: 3, height: 1, numChannels: 4)
        ..setPixelRgba(0, 0, 255, 0, 0, 255)
        ..setPixelRgba(1, 0, 255, 0, 0, 0)
        ..setPixelRgba(2, 0, 0, 0, 255, 128);
      final rgb = GoldenRgbImage.fromImage(png);
      expect(rgb.transparentPixels, 2);
      expect(rgb.pixel(0, 0), 0xff0000);
      expect(rgb.pixel(1, 0), 0x808080);
      expect(rgb.pixel(2, 0), 0x4040c0);
    });

    test('known regions keep the verdict ratio and the shown ratio equal', () {
      final diff = _diff(_pair((b) => _rect(b, 20, 20, 60, 40, [200, 40, 40])));
      GoldenDesignReport report(GoldenKnownDifference? known) =>
          GoldenDesignReport(
            suite: 's',
            scenario: 'c',
            fileStem: 'f',
            variant: const {},
            label: 'Figma',
            reference: 'r.png',
            render: 'i.png',
            tolerance: const GoldenDesignTolerance(),
            pixels: GoldenReportPixels.compared(diff, diffPath: 'd.png'),
            snapshot: GoldenRenderSnapshot(width: 40, height: 30, nodes: []),
            regions: [
              GoldenReportRegion(
                id: 'node:1:2',
                region: diff.regions.single,
                known: known,
              ),
            ],
          );
      final open = report(null);
      expect(open.pixelStatus, 'fail');
      expect(open.verdict, GoldenDesignVerdict.fail);
      expect(open.effectiveRatio, closeTo(diff.ratio, 1e-12));
      final accepted = report(
        GoldenKnownDifference(designNode: '1:2', reason: 'tracked'),
      );
      expect(accepted.pixelStatus, 'pass');
      expect(accepted.verdict, GoldenDesignVerdict.pass);
      expect(accepted.effectiveRatio, 0);
      final pixels = accepted.toJson()['pixels']! as Map<String, Object?>;
      expect(pixels['ratio'], 0);
      expect(pixels['rawRatio'], closeTo(diff.ratio, 1e-6));
      expect(GoldenDesignAnalysisSummary.of(accepted, 'a.json').ratio, 0);
    });

    test('the difference map marks differences red', () {
      final pair = _pair((b) => _rect(b, 20, 20, 60, 40, [200, 40, 40]));
      final result = _diff(pair);
      final map = result.diffMap(GoldenRgbImage.fromImage(pair.$1));
      final pixel = map.getPixel(30, 30);
      expect([pixel.r, pixel.g, pixel.b], [230, 20, 20]);
    });
  });
}
