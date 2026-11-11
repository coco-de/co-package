import 'package:co_golden/src/design/design_system.dart';
import 'package:co_golden/src/design/inspection.dart';
import 'package:co_golden/src/design/package_map.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_TriangleClipper oldClipper) => false;
}

void main() {
  for (final custom in [false, true]) {
    testWidgets('verifies Container decoration, rejects custom path: $custom', (
      tester,
    ) async {
      final boundary = GlobalKey();
      const image = RawImage(width: 40, height: 40, fit: BoxFit.cover);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: boundary,
            child: Center(
              child: custom
                  ? ClipPath(clipper: _TriangleClipper(), child: image)
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: image,
                    ),
            ),
          ),
        ),
      );
      final snapshot =
          GoldenRenderInspector(
            designSystem: const GoldenDesignSystem(),
            packages: GoldenPackageMap.discover(),
          ).inspect(
            boundary.currentContext! as Element,
            boundary.currentContext!.findRenderObject()! as RenderBox,
          );
      final imageNode = snapshot.nodes.singleWhere((n) => n.kind == 'image');
      expect(imageNode.imagePaint['verifiedGeometry'], !custom);
      expect(
        imageNode.imagePaint['clipRadius'],
        custom ? [0.0, 0.0, 0.0, 0.0] : [10.0, 10.0, 10.0, 10.0],
      );
    });
  }
}
