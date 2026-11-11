import 'package:co_golden/src/design/design_system.dart';
import 'package:co_golden/src/design/inspection.dart';
import 'package:co_golden/src/design/package_map.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReaderWidget extends StatelessWidget {
  const _ReaderWidget();
  @override
  Widget build(BuildContext context) => const Text('inherited context');
}

void main() {
  testWidgets('resolved readers receive inherited context and fail closed', (
    tester,
  ) async {
    final boundary = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(key: boundary, child: const _ReaderWidget()),
      ),
    );
    final snapshot =
        GoldenRenderInspector(
          designSystem: GoldenDesignSystem(
            components: [
              GoldenComponentMapping(
                widget: '_ReaderWidget',
                resolvedReaders: {
                  'direction': (_, context) => Directionality.of(context).name,
                  'unavailable': (_, _) =>
                      throw StateError('No paint evidence'),
                },
              ),
            ],
          ),
          packages: GoldenPackageMap.discover(),
        ).inspect(
          boundary.currentContext! as Element,
          boundary.currentContext!.findRenderObject()! as RenderBox,
        );
    expect(snapshot.components.single.properties, {'direction': 'rtl'});
  });
}
