import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/pixel_diff.dart';
import 'package:co_golden/src/design/report.dart';
import 'package:co_golden/src/design/visual_regions.dart';
import 'package:flutter_test/flutter_test.dart';

GoldenReportRegion region(
  String id,
  int pixels,
  double x,
  int color,
  double delta,
) => GoldenReportRegion(
  id: id,
  region: GoldenPixelRegion(
    bounds: GoldenRect(x, 0, 2, 2),
    pixels: pixels,
    logicalPixels: pixels.toDouble(),
    referenceColor: color,
    renderColor: color,
    meanDeltaE: delta,
  ),
);

void main() {
  test('fragments share one finding without losing pixels or bounds', () {
    final raw = [
      region('node:a', 4, 0, 0, 1),
      region('node:a', 12, 10, 0xffffff, 5),
    ];
    final grouped = goldenGroupUnexplainedRegions(raw);
    expect(grouped, hasLength(1));
    expect(grouped.single.region.bounds, const GoldenRect(0, 0, 12, 2));
    expect(grouped.single.region.pixels, 16);
    expect(grouped.single.region.logicalPixels, 16);
    expect(grouped.single.region.referenceColor, 0xbfbfbf);
    expect(grouped.single.region.meanDeltaE, 4);
    expect(raw, hasLength(2));
  });
  test('more than twenty unrelated visual defects are kept', () {
    final grouped = goldenGroupUnexplainedRegions([
      for (var i = 0; i < 25; i++) region('cell:$i', 4, i * 3, 0, 4),
    ]);
    expect(grouped, hasLength(25));
    expect(grouped.map((r) => r.id).toSet(), hasLength(25));
  });
}
