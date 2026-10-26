import 'dart:convert';
import 'dart:io';

import 'package:co_golden/co_golden.dart';
import 'package:co_golden/src/design/design_system.dart';
import 'package:co_golden/src/design/package_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _fixtures = 'test/fixtures/design';

void main() {
  group('Figma REST nodes response', () {
    late GoldenDesignSpec spec;
    setUpAll(
      () => spec = GoldenDesignSpec.read(
        p.join(_fixtures, 'figma_rest_nodes.json'),
        nodeId: '12-345',
      ),
    );

    test('reads the frame, metadata, and skips hidden or off-canvas nodes', () {
      expect(spec.source.format, 'figma-rest');
      expect(spec.source.version, '2206113284567890123');
      expect(spec.source.fileName, 'Unibook App');
      expect(spec.frame.id, '12:345');
      expect(spec.frame.rect, const GoldenRect(0, 0, 360, 640));
      expect(spec.frame.solidFill?.color, 0xffffffff);
      expect(spec.frame.layout?.padding, [24, 16, 24, 16]);
      expect(spec.frame.layout?.gap, 8);
      expect(spec.nodes.map((n) => n.id), ['12:346', '12:350', 'I12:350;4:6']);
    });

    test('reads text typography, style names, variables, and runs', () {
      final title = spec['12:346']!;
      expect(title.rect, const GoldenRect(16, 24, 120, 32));
      expect(title.inkRect, const GoldenRect(16.5, 29, 118, 22));
      final text = title.text!;
      expect(text.characters, '로그인 하기');
      final t = text.typography;
      expect(t.fontFamily, 'Pretendard');
      expect(t.fontWeight, 700);
      expect(t.fontSize, 24);
      expect(t.lineHeight, 32);
      expect(t.letterSpacing, -0.48);
      expect(t.styleName, 'Title/Medium');
      expect(t.color, 0xff14161a);
      expect(t.colorVariable, 'VariableID:1:2');
      expect(text.autoResize, 'WIDTH_AND_HEIGHT');
      expect(text.runs, hasLength(1));
      expect(text.runs.single.start, 3);
      expect(text.runs.single.end, 6);
      expect(text.runs.single.typography.fontWeight, 400);
      expect(spec.pathOf(title), 'Mobile-Default / Title');
    });

    test('reads component sets, variant properties, paints, and effects', () {
      final button = spec['12:350']!;
      final instance = button.instance!;
      expect(instance.componentSet, 'Button');
      expect(instance.name, 'Button');
      expect(instance.variant, {'Variant': 'primary', 'Size': 'md'});
      expect(instance.properties['Child'], '계속');
      expect(instance.remote, isTrue);
      expect(button.solidFill?.color, 0x805be0c8);
      expect(button.solidStroke?.color, 0x1a000000);
      expect(button.strokeWeight, 1);
      expect(button.cornerRadii, [8, 8, 8, 8]);
      expect(button.shadows.single.offsetY, 2);
      final label = spec['I12:350;4:6']!;
      expect(label.parentId, '12:350');
      expect(label.depth, 2);
      expect(label.text!.typography.lineHeight, closeTo(19.6, 1e-9));
      expect(label.text!.align, 'CENTER');
    });

    test('needs a node id for multi-node responses', () {
      final json =
          jsonDecode(
                File(
                  p.join(_fixtures, 'figma_rest_nodes.json'),
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      (json['nodes']! as Map<String, Object?>)['1:1'] = const {
        'document': {'id': '1:1'},
      };
      expect(() => GoldenDesignSpec.parse(json), throwsFormatException);
      expect(
        () => GoldenDesignSpec.parse(json, nodeId: '9:9'),
        throwsFormatException,
      );
    });
  });

  group('neutral co_golden.design_spec', () {
    test('reads frame, insets, typography units, and instances', () {
      final spec = GoldenDesignSpec.parse({
        'schema': 'co_golden.design_spec',
        'schemaVersion': 1,
        'source': {'tool': 'figma', 'fileKey': 'KEY', 'nodeId': '1:2'},
        'frame': {
          'id': '1:2',
          'name': 'Mobile-Default',
          'width': 393,
          'height': 852,
          'insets': {'top': 59, 'bottom': 34},
        },
        'nodes': [
          {
            'id': '1:3',
            'parent': '1:2',
            'name': 'Title',
            'type': 'TEXT',
            'rect': [16, 80, 200, 32],
            'text': {
              'characters': 'Hello',
              'fontFamily': 'Pretendard',
              'fontWeight': 600,
              'fontSize': 20,
              'lineHeight': {'unit': 'PERCENT', 'value': 160},
              'letterSpacing': {'unit': 'PERCENT', 'value': -2},
              'textCase': 'UPPER',
              'style': 'Title/Large',
              'color': '#14161AFF',
              'colorVariable': 'color/on-surface',
            },
          },
          {
            'id': '1:4',
            'parent': '1:2',
            'name': 'Chip',
            'type': 'INSTANCE',
            'rect': [16, 120, 80, 32],
            'radius': 16,
            'fills': [
              {
                'type': 'SOLID',
                'color': '#5BE0C8',
                'variable': 'color/primary',
              },
            ],
            'instance': {
              'set': 'Chip',
              'variant': {'Variant': 'primary'},
              'properties': {'Label#1:2': 'New'},
            },
          },
          {
            'id': '1:5',
            'name': 'Hidden',
            'rect': [0, 0, 1, 1],
            'visible': false,
          },
        ],
      });
      expect(spec.source.format, 'co_golden.design_spec');
      expect(spec.insetTop, 59);
      expect(spec.insetBottom, 34);
      expect(spec.nodes, hasLength(2));
      final t = spec['1:3']!.text!;
      expect(t.typography.lineHeight, 32);
      expect(t.typography.letterSpacing, closeTo(-0.4, 1e-9));
      expect(t.displayed, 'HELLO');
      expect(t.typography.colorVariable, 'color/on-surface');
      final chip = spec['1:4']!;
      expect(chip.cornerRadii, [16, 16, 16, 16]);
      expect(chip.solidFill?.variable, 'color/primary');
      expect(chip.instance!.properties, {'Label': 'New'});
    });

    test('rejects a newer schema version', () {
      expect(
        () => GoldenDesignSpec.parse({
          'schema': 'co_golden.design_spec',
          'schemaVersion': 2,
          'frame': {'width': 1, 'height': 1},
          'nodes': <Object?>[],
        }),
        throwsFormatException,
      );
    });
  });

  test('reads a real design-spec recipe export of the CoUI library', () {
    final spec = GoldenDesignSpec.read(
      p.join(_fixtures, 'coui_alert_info.design.json'),
    );
    expect(spec.source.fileKey, 'FILE_KEY');
    expect(spec.frame.rect, const GoldenRect(0, 0, 340, 66));
    expect(spec.frame.cornerRadii, [12, 12, 12, 12]);
    final description = spec.nodes.firstWhere((n) => n.name == 'description');
    final t = description.text!.typography;
    expect(t.styleName, 'Body/Small');
    expect(t.lineHeight, closeTo(19.5, 1e-9));
    expect(t.letterSpacing, closeTo(-0.13, 1e-9));
    expect(t.colorVariable, 'color/on-surface-variant');
    expect(t.variables['fontSize'], 'font-size/body-small');
    expect(description.inkRect!.width, lessThan(description.rect.width));
    final icon = spec.nodes.firstWhere((n) => n.name == 'leading');
    expect(icon.instance!.componentSet, 'Icon');
    expect(icon.instance!.properties['Icon'], 'lucide/info');
    final material = spec.nodes.firstWhere((n) => n.name == 'material');
    expect(material.solidFill!.variable, 'color/info-container');
  });

  test('children of hidden nodes stay hidden, and lines keep a thickness', () {
    final spec = GoldenDesignSpec.parse({
      'schema': 'co_golden.design_spec',
      'schemaVersion': 1,
      'frame': {'id': '1:1', 'width': 100, 'height': 100},
      'nodes': [
        {
          'id': '1:2',
          'name': 'Hidden',
          'rect': [0, 0, 50, 50],
          'visible': false,
        },
        {
          'id': '1:3',
          'parent': '1:2',
          'name': 'Child',
          'rect': [0, 0, 10, 10],
        },
        {
          'id': '1:4',
          'name': 'Divider',
          'type': 'LINE',
          'rect': [0, 60, 100, 0],
          'strokeWeight': 1,
        },
      ],
    });
    expect(spec.nodes.map((n) => n.id), ['1:4']);
    expect(spec['1:4']!.rect, const GoldenRect(0, 59.5, 100, 1));
  });

  test('compare-frames output gives geometry without styles', () {
    final spec = GoldenDesignSpec.parse({
      'page': 'Screens',
      'section': {'id': '9:1', 'name': 'Login'},
      'frames': [
        {
          'id': '9:2',
          'name': 'Mobile-Default',
          'width': 390,
          'height': 844,
          'insets': {'top': 47, 'bottom': 34},
          'nodes': [
            ['9:3', 'AppBar', 0, 47, 390, 56],
            ['9:4', 'Title', 16, 120, 100, 20, 'TEXT', null],
            ['9:5', 'Button', 16, 700, 358, 48, 'INSTANCE', 'Button'],
          ],
        },
      ],
      'warnings': <Object?>[],
      'blocking': <Object?>[],
    });
    expect(spec.source.format, 'compare-frames');
    expect(spec.hasStyles, isFalse);
    expect(spec.insetTop, 47);
    expect(spec.nodes.map((n) => n.type), ['FRAME', 'TEXT', 'INSTANCE']);
    expect(spec['9:5']!.instance?.componentSet, 'Button');
    expect(spec.warnings, isNotEmpty);
  });

  group('CoUI catalog', () {
    late GoldenComponentCatalog catalog;
    setUpAll(
      () => catalog = GoldenComponentCatalog.readCoui(
        p.join(_fixtures, 'coui_components.json'),
      ),
    );

    test('reads components with axes and text roles', () {
      expect(catalog.name, 'CoUI');
      expect(catalog.components, hasLength(2));
      final button = catalog.component('button')!;
      expect(button.axes.map((a) => a.enumName), [
        'CoreButtonVariant',
        'CoreComponentSize',
        'CoreButtonShape',
      ]);
      expect(catalog.textRoles.map((r) => r.name), [
        'titleMedium',
        'bodyMedium',
        'labelXl2',
      ]);
    });

    test('maps design axes to widget fields, also by value', () {
      final button = catalog.component('Button')!;
      final shape = button.axisFor('Shape', 'circle')!;
      expect(shape.enumName, 'CoreButtonShape');
      expect(goldenAxisFields(shape, 'Button'), ['shape', 'buttonShape']);
      final chip = catalog.component('Chip')!;
      // Chip's Figma "Variant" axis holds chip colors.
      final color = chip.axisFor('Variant', 'primary')!;
      expect(color.enumName, 'CoreChipColor');
      expect(goldenAxisFields(color, 'Chip'), ['color', 'chipColor']);
    });

    test('text roles have design style names and match rendered values', () {
      final title = catalog.roleNamed('Title/Medium')!;
      expect(title.name, 'titleMedium');
      expect(title.styleName, 'Title/Medium');
      expect(catalog.roleNamed('Label/XL2')!.name, 'labelXl2');
      expect(
        title.matches(
          fontSize: 18,
          fontWeight: 700,
          height: 1.6,
          letterSpacing: -0.36,
        ),
        isTrue,
      );
      expect(
        title.matches(fontSize: 18, fontWeight: 600, height: 1.6),
        isFalse,
      );
    });
  });

  test('token names drop collection prefixes', () {
    expect(goldenTokenName('Semantic/color/on-surface'), 'on-surface');
    expect(goldenTokenName('--coui-on-surface'), 'on-surface');
    expect(goldenTokenName('onSurface'), 'on-surface');
    expect(goldenTokenName('color/primary'), 'primary');
    expect(goldenNormalizeName('Title/Medium'), 'titlemedium');
  });

  test('package map resolves project, dependency, and SDK files', () {
    final root = Directory.systemTemp.createTempSync('co_golden_pkg_');
    addTearDown(() => root.deleteSync(recursive: true));
    final app = p.join(root.path, 'app');
    final map = GoldenPackageMap.parse(
      jsonEncode({
        'configVersion': 2,
        'packages': [
          {'name': 'app', 'rootUri': '../', 'packageUri': 'lib/'},
          {'name': 'ui', 'rootUri': '../../ui', 'packageUri': 'lib/'},
          {
            'name': 'coui_flutter',
            'rootUri': 'file:///cache/git/coui-abc/packages/coui_flutter',
            'packageUri': 'lib/',
          },
        ],
      }),
      configDirectory: p.join(app, '.dart_tool'),
      workingDirectory: app,
    );
    expect(
      map.display(p.join(app, 'lib', 'src', 'page.dart')),
      'lib/src/page.dart',
    );
    expect(map.packageOf(p.join(app, 'lib', 'a.dart'))?.project, isTrue);
    expect(map.packageOf(p.join(root.path, 'ui', 'lib', 'b.dart'))?.name, 'ui');
    expect(
      map.display('/cache/git/coui-abc/packages/coui_flutter/lib/src/x.dart'),
      'package:coui_flutter/src/x.dart',
    );
    expect(
      map
          .packageOf('/cache/git/coui-abc/packages/coui_flutter/lib/x.dart')
          ?.project,
      isFalse,
    );
  });
}
