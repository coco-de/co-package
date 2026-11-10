import 'package:co_golden/co_golden.dart';
import 'package:co_golden/src/design/finding.dart';
import 'package:co_golden/src/design/inspection.dart';
import 'package:co_golden/src/design/package_map.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/structural_diff.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _boundary = ValueKey('boundary');

GoldenDesignSpec _spec(List<Map<String, Object?>> nodes) =>
    GoldenDesignSpec.parse({
      'schema': 'co_golden.design_spec',
      'schemaVersion': 1,
      'frame': {'id': '1:1', 'name': 'Screen', 'width': 200, 'height': 100},
      'nodes': nodes,
    });

Map<String, Object?> _instance(
  String id,
  String component,
  List<num> rect, {
  String? parent,
  String? name,
  Map<String, String> variant = const {},
}) => {
  'id': id,
  'parent': ?parent,
  'name': name ?? component,
  'type': 'INSTANCE',
  'rect': rect,
  'instance': {'set': component, 'variant': variant},
};

GoldenRenderNode _graphic(int id, GoldenRect rect) => GoldenRenderNode(
  id: id,
  kind: GoldenRenderKind.graphic,
  widget: '_RawPictureVectorGraphicWidget',
  rect: rect,
  visibleRect: rect,
);

List<GoldenDesignFinding> _compare(
  GoldenDesignSpec spec,
  GoldenRenderSnapshot snapshot, {
  Map<String, int> colorTokens = const {},
}) => compareDesignStructure(
  spec,
  snapshot,
  GoldenStructuralContext(
    tolerance: const GoldenDesignTolerance(),
    colorTokens: colorTokens,
  ),
).findings;

void main() {
  group('icon-set instances', () {
    // A CoUI Button whose leading Icon component swaps in `lucide/bell`, a
    // bare `lucide/calendar`, and an Icon whose glyph has a custom name.
    final spec = _spec([
      _instance(
        '1:2',
        'Button',
        [10, 10, 40, 40],
        variant: {'Variant': 'ghost'},
      ),
      {
        'id': '1:3',
        'parent': '1:2',
        'name': 'leading',
        'type': 'FRAME',
        'rect': [21, 21, 18, 18],
      },
      _instance('1:4', 'Icon', [21, 21, 18, 18], parent: '1:3'),
      _instance('1:5', 'lucide/bell', [21, 21, 18, 18], parent: '1:4'),
      {
        'id': '1:6',
        'parent': '1:5',
        'name': 'Vector',
        'type': 'VECTOR',
        'rect': [22.5, 22.5, 15, 15],
        'strokes': [
          {'type': 'SOLID', 'color': '#14161AFF'},
        ],
      },
      _instance('1:7', 'lucide/calendar', [60, 21, 18, 18]),
      _instance('1:8', 'Icon', [120, 21, 18, 18]),
      _instance('1:9', 'custom/arrow', [120, 21, 18, 18], parent: '1:8'),
      // A small component that is not an icon.
      _instance('1:10', 'Badge', [160, 10, 20, 20]),
      _instance('1:11', 'mdi:home', [160, 60, 16, 16]),
    ]);
    final snapshot = GoldenRenderSnapshot(
      width: 200,
      height: 100,
      components: const [
        GoldenRenderComponent(
          id: 0,
          name: 'Button',
          rect: GoldenRect(10, 10, 40, 40),
          properties: {'variant': 'ghost'},
        ),
        GoldenRenderComponent(
          id: 1,
          name: 'Icon',
          rect: GoldenRect(21, 21, 18, 18),
          parent: 0,
        ),
        GoldenRenderComponent(
          id: 2,
          name: 'Icon',
          rect: GoldenRect(60, 21, 18, 18),
        ),
        GoldenRenderComponent(
          id: 3,
          name: 'Icon',
          rect: GoldenRect(120, 21, 18, 18),
        ),
      ],
      nodes: [
        _graphic(0, const GoldenRect(21, 21, 18, 18)),
        _graphic(1, const GoldenRect(60, 21, 18, 18)),
        _graphic(2, const GoldenRect(120, 21, 18, 18)),
        _graphic(3, const GoldenRect(160, 60, 16, 16)),
      ],
    );

    test('are compared as icons, not as components', () {
      final findings = _compare(spec, snapshot);
      final components = findings
          .where((f) => f.category == GoldenFindingCategory.component)
          .toList();
      // Only the badge is still a component (with no catalog, an info).
      expect(components.map((f) => f.id), ['component@1:10']);
      // Every icon found its rendered glyph.
      expect(
        findings.where((f) => f.category != GoldenFindingCategory.component),
        isEmpty,
        reason: findings.map((f) => f.message).join('\n'),
      );
      expect(goldenDesignComponentNames(spec, const []), {'button', 'badge'});
    });
  });

  group('text color', () {
    const grey = Color(0xff6f757c);
    const style = TextStyle(fontSize: 14, height: 1.5, color: grey);

    testWidgets('is compared as painted, opacity included', (tester) async {
      await tester.pumpWidget(
        const RepaintBoundary(
          key: _boundary,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dimmed by an Opacity, which Figma draws as layer opacity
                // and the export folds into the text color.
                Opacity(
                  opacity: 0.7,
                  child: Text('김수연 · 10월 21일', style: style),
                ),
                Text('12명이 공감해요', style: style),
                Text(
                  '곧 개발을 시작해요',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xb26f757c),
                  ),
                ),
                Opacity(opacity: 0.7, child: Text('보조 설명', style: style)),
                Opacity(opacity: 0.5, child: Text('반투명 묶음', style: style)),
                Opacity(
                  opacity: 0.7,
                  child: Text.rich(
                    TextSpan(
                      style: style,
                      children: [
                        TextSpan(
                          text: '굵게',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' 보통'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final snapshot =
          GoldenRenderInspector(
            designSystem: GoldenDesignSystem.none,
            packages: GoldenPackageMap.discover(),
          ).inspect(
            tester.element(find.byKey(_boundary)),
            tester.renderObject<RenderBox>(find.byKey(_boundary)),
          );
      Map<String, Object?> text(
        String id,
        String characters, {
        String color = '#6F757CB2',
        String? parent,
        double? opacity,
        List<Map<String, Object?>> runs = const [],
      }) {
        final rect = tester.getRect(find.text(characters, findRichText: true));
        return {
          'id': id,
          'parent': ?parent,
          'name': 'Text',
          'type': 'TEXT',
          'opacity': ?opacity,
          'rect': [rect.left, rect.top, rect.width, rect.height],
          'text': {
            'characters': characters,
            'fontSize': 14,
            'lineHeight': {'unit': 'PIXELS', 'value': 21},
            'color': color,
            'colorVariable': 'color/placeholder',
            'runs': runs,
          },
        };
      }

      final group = tester.getRect(find.text('반투명 묶음'));
      final spec = _spec([
        text('1:2', '김수연 · 10월 21일'),
        text('1:3', '12명이 공감해요'),
        text('1:4', '곧 개발을 시작해요'),
        // Layer opacity on the design node instead of in the color.
        text('1:5', '보조 설명', color: '#6F757C', opacity: 0.7),
        // Layer opacity on a design group.
        {
          'id': '1:6',
          'name': 'Group',
          'type': 'FRAME',
          'opacity': 0.5,
          'rect': [group.left, group.top, group.width, group.height],
        },
        text('1:7', '반투명 묶음', color: '#6F757C', parent: '1:6'),
        text(
          '1:8',
          '굵게 보통',
          runs: [
            {'start': 0, 'end': 2, 'fontWeight': 700, 'color': '#6F757CB2'},
          ],
        ),
      ]);
      final findings = _compare(
        spec,
        snapshot,
        colorTokens: {'placeholder': grey.toARGB32()},
      );
      final colors = findings
          .where((f) => f.category == GoldenFindingCategory.color)
          .toList();
      // Only the text that the app does not dim differs.
      expect(colors.map((f) => f.id), ['color.text@1:3']);
      final diff = colors.single.diffs.single;
      expect(diff.expected, '#6F757CB2 (placeholder)');
      expect(diff.actual, '#6F757C (placeholder)');
      // Runs are compared as painted too.
      expect(
        findings.where((f) => f.diffs.any((d) => d.property == 'color')),
        isEmpty,
      );
    });
  });

  group('truncated text', () {
    const style = TextStyle(fontSize: 14, height: 1.5);
    const long = '응급 환자나 재진 환자를 먼저 보내야 할 때 순서를 바꿀 방법이 없어요.';

    Future<List<GoldenDesignFinding>> truncated(
      WidgetTester tester, {
      int? maxLines,
    }) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: _boundary,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 120,
                child: Text(
                  long,
                  style: style,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      );
      final snapshot =
          GoldenRenderInspector(
            designSystem: GoldenDesignSystem.none,
            packages: GoldenPackageMap.discover(),
          ).inspect(
            tester.element(find.byKey(_boundary)),
            tester.renderObject<RenderBox>(find.byKey(_boundary)),
          );
      final rect = tester.getRect(find.text(long));
      return _compare(
        _spec([
          {
            'id': '1:2',
            'name': 'Text',
            'type': 'TEXT',
            // Figma wraps the whole sentence.
            'rect': [rect.left, rect.top, rect.width, 21 * 4],
            'text': {
              'characters': long,
              'fontSize': 14,
              'lineHeight': {'unit': 'PIXELS', 'value': 21},
            },
          },
        ]),
        snapshot,
      ).where((f) => f.diffs.any((d) => d.property == 'truncated')).toList();
    }

    testWidgets('names an ellipsis without maxLines as a first-line cut', (
      tester,
    ) async {
      final finding = (await truncated(tester)).single;
      expect(finding.message, contains('첫 줄에서 끊김'));
      expect(finding.message, isNot(contains('null')));
      expect(finding.hint, contains('overflow를 clip'));
    });

    testWidgets('names the line limit when maxLines is set', (tester) async {
      final finding = (await truncated(tester, maxLines: 2)).single;
      expect(finding.message, contains('최대 2줄'));
    });
  });
}
