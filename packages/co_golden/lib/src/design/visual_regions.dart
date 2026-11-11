import 'pixel_diff.dart';
import 'report.dart';

/// One actionable visual finding per attributed element. The original
/// connected regions remain unchanged in the report and pixel map.
List<GoldenReportRegion> goldenGroupUnexplainedRegions(
  List<GoldenReportRegion> regions,
) {
  final groups = <String, List<GoldenReportRegion>>{};
  for (final region in regions) {
    if (region.findings.isNotEmpty || region.known != null) continue;
    final key = region.widget == null
        ? region.id
        : 'widget:${region.widget!.id}';
    (groups[key] ??= []).add(region);
  }
  return [
    for (final MapEntry(:key, :value) in groups.entries) _merged(key, value),
  ];
}

GoldenReportRegion _merged(String key, List<GoldenReportRegion> regions) {
  final first = regions.first;
  var bounds = first.region.bounds;
  var pixels = 0;
  var logical = 0.0;
  var delta = 0.0;
  final reference = [0.0, 0.0, 0.0];
  final render = [0.0, 0.0, 0.0];
  for (final item in regions) {
    final r = item.region;
    bounds = bounds.union(r.bounds);
    pixels += r.pixels;
    logical += r.logicalPixels;
    delta += r.meanDeltaE * r.pixels;
    for (var i = 0; i < 3; i++) {
      final shift = (2 - i) * 8;
      reference[i] += ((r.referenceColor >> shift) & 255) * r.pixels;
      render[i] += ((r.renderColor >> shift) & 255) * r.pixels;
    }
  }
  int rgb(List<double> channels) =>
      (channels[0] / pixels).round() << 16 |
      (channels[1] / pixels).round() << 8 |
      (channels[2] / pixels).round();
  return GoldenReportRegion(
    id: key,
    region: GoldenPixelRegion(
      bounds: bounds,
      pixels: pixels,
      logicalPixels: logical,
      referenceColor: rgb(reference),
      renderColor: rgb(render),
      meanDeltaE: delta / pixels,
    ),
    design: first.design,
    widget: first.widget,
    findings: const [],
  );
}
