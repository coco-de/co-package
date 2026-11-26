import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import 'note_view_test_support.dart';

void main() {
  test('has sane defaults and clamps columns', () {
    final grid = NoteThumbnailGridController();

    expect(grid.columns, 3);
    expect(grid.sidebarVisible, isFalse);
    expect(grid.selectionMode, isFalse);
    expect(grid.selection, isEmpty);
    expect(NoteThumbnailGridController(columns: 0).columns, 1);
    expect(NoteThumbnailGridController(columns: 99).columns, 6);
    expect(NoteThumbnailGridController(pinchStep: 0.5).pinchStep, 1.25);
  });

  test('setColumns clamps and notifies only on change', () {
    final grid = NoteThumbnailGridController();
    final counter = NotifyCounter(grid);

    grid.setColumns(3);
    grid.setColumns(10);
    grid.setColumns(6);

    expect(grid.columns, 6);
    expect(counter.count, 1);
  });

  group('pinch hysteresis', () {
    test('needs the full step before changing columns', () {
      final grid = NoteThumbnailGridController();

      grid.scaleBy(1.2);
      expect(grid.columns, 3);

      grid.scaleBy(1.05); // 1.26 in total
      expect(grid.columns, 2);
      expect(grid.pinchProgress, closeTo(1.008, 1e-9));
    });

    test('does not flip back on a small reversal', () {
      final grid = NoteThumbnailGridController();
      grid.scaleBy(1.26);
      expect(grid.columns, 2);

      grid.scaleBy(0.9); // 0.907: above 0.8
      expect(grid.columns, 2);
      grid.scaleBy(1.1); // back and forth around the old threshold
      grid.scaleBy(0.9);
      expect(grid.columns, 2);

      grid.scaleBy(0.85); // 0.763 in total: past 0.8
      expect(grid.columns, 3);
    });

    test('changes exactly at the thresholds', () {
      final zoomIn = NoteThumbnailGridController();
      zoomIn.scaleBy(1.25);
      expect(zoomIn.columns, 2);

      final zoomOut = NoteThumbnailGridController();
      zoomOut.scaleBy(0.8);
      expect(zoomOut.columns, 4);

      final below = NoteThumbnailGridController();
      below.scaleBy(1.2499);
      expect(below.columns, 3);
      below.beginPinch();
      below.scaleBy(0.8001);
      expect(below.columns, 3);
    });

    test('takes several steps for a big pinch', () {
      final grid = NoteThumbnailGridController(columns: 4);

      grid.scaleBy(2); // 1.25^3 = 1.953

      expect(grid.columns, 1);
    });

    test('forgets the surplus at a limit so reversing reacts at once', () {
      final grid = NoteThumbnailGridController(columns: 1);

      grid.scaleBy(5);
      expect(grid.columns, 1);
      expect(grid.pinchProgress, 1);

      grid.scaleBy(0.8);
      expect(grid.columns, 2);
    });

    test('also stops at the most columns', () {
      final grid = NoteThumbnailGridController(columns: 6);

      grid.scaleBy(0.1);
      grid.scaleBy(1.25);

      expect(grid.columns, 5);
    });

    test('beginPinch forgets the collected factor', () {
      final grid = NoteThumbnailGridController();
      grid.scaleBy(1.2);

      grid.beginPinch();
      grid.scaleBy(1.1);

      expect(grid.columns, 3);
    });

    test('ignores non-positive and non-finite factors', () {
      final grid = NoteThumbnailGridController();
      for (final factor in [0.0, -2.0, double.nan, double.infinity]) {
        grid.scaleBy(factor);
      }

      expect(grid.columns, 3);
      expect(grid.pinchProgress, 1);
    });

    test('honours a custom step', () {
      final grid = NoteThumbnailGridController(pinchStep: 2);

      grid.scaleBy(1.9);
      expect(grid.columns, 3);
      grid.scaleBy(1.1);
      expect(grid.columns, 2);
    });
  });

  group('sidebar and selection', () {
    test('toggles the sidebar', () {
      final grid = NoteThumbnailGridController();

      grid.toggleSidebar();
      expect(grid.sidebarVisible, isTrue);
      grid.setSidebarVisible(true);
      grid.toggleSidebar();
      expect(grid.sidebarVisible, isFalse);
    });

    test('toggleSelect enters selection mode', () {
      final grid = NoteThumbnailGridController();

      grid.toggleSelect(2);
      grid.toggleSelect(4);
      grid.toggleSelect(2);
      grid.toggleSelect(-1);

      expect(grid.selectionMode, isTrue);
      expect(grid.selection, {4});
      expect(grid.isSelected(4), isTrue);
    });

    test('leaving selection mode clears the selection', () {
      final grid = NoteThumbnailGridController()..toggleSelect(1);

      grid.setSelectionMode(false);

      expect(grid.selection, isEmpty);
    });

    test('selectAll, clear and retainPages', () {
      final grid = NoteThumbnailGridController();
      final counter = NotifyCounter(grid);

      grid.selectAll(5);
      grid.selectAll(5);
      expect(counter.count, 1);
      grid.retainPages(3);
      expect(grid.selection, {0, 1, 2});
      grid.retainPages(3);
      grid.clearSelection();
      expect(grid.selection, isEmpty);
      expect(grid.selectionMode, isTrue);
      expect(counter.count, 3);
      grid.selectAll(0);
      expect(grid.selection, isEmpty);
    });

    test('selection is read-only', () {
      final grid = NoteThumbnailGridController();

      expect(() => grid.selection.add(1), throwsUnsupportedError);
    });
  });

  group('json', () {
    test('round-trips columns and sidebar', () {
      final grid = NoteThumbnailGridController(
        columns: 5,
        sidebarVisible: true,
      );

      final restored = NoteThumbnailGridController.fromJson(grid.toJson());

      expect(restored.columns, 5);
      expect(restored.sidebarVisible, isTrue);
      expect(grid.toJson(), {'columns': 5, 'sidebarVisible': true});
    });

    test('survives junk', () {
      for (final junk in <Object?>[null, 'x', 3]) {
        expect(NoteThumbnailGridController.fromJson(junk).columns, 3);
      }
      expect(NoteThumbnailGridController.fromJson({'columns': 100}).columns, 6);
      expect(
        NoteThumbnailGridController.fromJson({
          'columns': 'two',
          'sidebarVisible': 1,
        }).sidebarVisible,
        isFalse,
      );
    });
  });

  test('does nothing after dispose', () {
    final grid = NoteThumbnailGridController()..dispose();

    grid.scaleBy(2);
    grid.setColumns(1);
    grid.toggleSelect(1);
    grid.selectAll(3);
    grid.clearSelection();
    grid.retainPages(0);
    grid.toggleSidebar();
    grid.setSelectionMode(true);

    expect(grid.columns, 3);
    expect(grid.selection, isEmpty);
  });
}
