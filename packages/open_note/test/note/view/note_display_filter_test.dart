import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';
import 'note_view_test_support.dart';

/// What `ColorFilter.matrix` does to an opaque RGB colour.
List<int> _apply(List<double> matrix, List<int> rgb) {
  final input = [...rgb, 255];

  return [
    for (var row = 0; row < 3; row++)
      (matrix[row * 5] * input[0] +
              matrix[row * 5 + 1] * input[1] +
              matrix[row * 5 + 2] * input[2] +
              matrix[row * 5 + 3] * input[3] +
              matrix[row * 5 + 4])
          .clamp(0, 255)
          .round(),
  ];
}

void main() {
  final night = NoteDisplayFilter.matrixFor(NoteDisplayMode.night)!;

  group('night', () {
    test('turns white paper black and black ink white', () {
      expect(_apply(night, [255, 255, 255]), [0, 0, 0]);
      expect(_apply(night, [0, 0, 0]), [255, 255, 255]);
      expect(_apply(night, [100, 100, 100]), [155, 155, 155]);
    });

    test('inverts lightness but keeps the hue', () {
      expect(_apply(night, [255, 0, 0]), [255, 147, 147]);
      final blue = _apply(night, [0, 0, 255]);
      expect(blue[2], greaterThan(blue[0]));
      expect(blue[0], blue[1]);
    });

    test('keeps the chroma of an unclipped colour', () {
      final result = _apply(night, [150, 120, 130]);

      expect(result[0] - result[1], 30);
      expect(result[2] - result[1], 10);
    });

    test('ignores strength', () {
      expect(
        NoteDisplayFilter.matrixFor(NoteDisplayMode.night, strength: 0),
        night,
      );
    });
  });

  group('eyeProtect', () {
    List<double> matrix(double strength) => NoteDisplayFilter.matrixFor(
      NoteDisplayMode.eyeProtect,
      strength: strength,
    )!;

    test('takes out blue and a little green', () {
      expect(_apply(matrix(1), [255, 255, 255]), [255, 224, 153]);
      expect(_apply(matrix(0.5), [255, 255, 255]), [255, 240, 204]);
      expect(_apply(matrix(1), [0, 0, 0]), [0, 0, 0]);
    });

    test('clamps the strength', () {
      expect(matrix(7), matrix(1));
      expect(matrix(double.nan), matrix(NoteDisplayFilter.defaultStrength));
      expect(
        NoteDisplayFilter.matrixFor(NoteDisplayMode.eyeProtect, strength: -1),
        isNull,
      );
    });

    test('does nothing at strength zero', () {
      expect(
        NoteDisplayFilter.colorFilterFor(
          NoteDisplayMode.eyeProtect,
          strength: 0,
        ),
        isNull,
      );
    });
  });

  test('normal needs no filter', () {
    expect(NoteDisplayFilter.matrixFor(NoteDisplayMode.normal), isNull);
    expect(NoteDisplayFilter.colorFilterFor(NoteDisplayMode.normal), isNull);
  });

  testWidgets('filters only outside normal mode and keeps child state', (
    tester,
  ) async {
    Widget build(NoteDisplayMode mode) => noteTestHost(
      NoteDisplayFilter(mode: mode, child: const StatefulProbe()),
    );

    await tester.pumpWidget(build(NoteDisplayMode.normal));
    expect(find.byType(ColorFiltered), findsNothing);
    tester.state<StatefulProbeState>(find.byType(StatefulProbe)).marker = 3;

    await tester.pumpWidget(build(NoteDisplayMode.night));
    expect(
      tester.widget<ColorFiltered>(find.byType(ColorFiltered)).colorFilter,
      ColorFilter.matrix(night),
    );
    await tester.pumpWidget(build(NoteDisplayMode.eyeProtect));
    await tester.pumpWidget(build(NoteDisplayMode.normal));

    expect(find.byType(ColorFiltered), findsNothing);
    expect(
      tester.state<StatefulProbeState>(find.byType(StatefulProbe)).marker,
      3,
    );
  });
}
