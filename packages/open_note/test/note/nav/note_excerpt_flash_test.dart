import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/nav/nav.dart';

import '../support/note_test_host.dart';
import 'nav_test_support.dart';

const Duration _second = Duration(seconds: 1);

NoteExcerptFlashController _flash(FakeFlashTicker ticker) =>
    NoteExcerptFlashController(duration: _second, ticker: ticker);

void main() {
  group('NoteExcerptFlashController', () {
    test('drives progress from 1 to 0 and becomes idle', () {
      final ticker = FakeFlashTicker();
      final controller = _flash(ticker);
      final counter = NotifyCounter(controller);

      expect(controller.isFlashing, isFalse);
      expect(controller.progress, 0);
      controller.flash('e1');
      expect(controller.excerptId, 'e1');
      expect(controller.progress, 1);

      ticker.advance(const Duration(milliseconds: 250));
      expect(controller.progress, 0.75);
      ticker.advance(const Duration(milliseconds: 750));
      expect(controller.progress, 0.25);
      ticker.advance(const Duration(milliseconds: 1200));
      expect(controller.isFlashing, isFalse);
      expect(controller.progress, 0);
      expect(ticker.isRunning, isFalse);
      expect(counter.count, 4);
    });

    test('notifies only on real changes', () {
      final ticker = FakeFlashTicker();
      final controller = _flash(ticker)..flash('e1');
      final counter = NotifyCounter(controller);

      ticker.advance(Duration.zero);
      controller.flash('e1');
      expect(counter.count, 0);
      ticker.advance(const Duration(milliseconds: 100));
      ticker.advance(const Duration(milliseconds: 100));
      expect(counter.count, 1);
    });

    test('flashing again restarts at full strength', () {
      final ticker = FakeFlashTicker();
      final controller = _flash(ticker)..flash('e1');
      ticker.advance(const Duration(milliseconds: 600));

      controller.flash('e2');

      expect(controller.excerptId, 'e2');
      expect(controller.progress, 1);
      expect(ticker.starts, 2);
    });

    test('cancel stops at once; empty ids are ignored', () {
      final ticker = FakeFlashTicker();
      final controller = _flash(ticker)..flash('');

      expect(controller.isFlashing, isFalse);
      controller
        ..flash('e1')
        ..cancel();
      expect(controller.isFlashing, isFalse);
      expect(ticker.isRunning, isFalse);
      final counter = NotifyCounter(controller);
      controller.cancel();
      expect(counter.count, 0);
    });

    test('dispose releases the ticker and silences the controller', () {
      final ticker = FakeFlashTicker();
      final controller = _flash(ticker)..flash('e1');
      final onTick = ticker.onTick!;

      controller
        ..dispose()
        ..dispose();

      expect(ticker.disposed, isTrue);
      controller
        ..flash('e2')
        ..cancel();
      onTick(const Duration(milliseconds: 10));
      expect(ticker.starts, 1);
    });

    test('has a default duration', () {
      final controller = NoteExcerptFlashController(ticker: FakeFlashTicker());

      expect(controller.duration, const Duration(milliseconds: 1200));
    });

    testWidgets('the default ticker follows the frame clock', (tester) async {
      final controller = NoteExcerptFlashController(duration: _second);
      addTearDown(controller.dispose);
      await tester.pumpWidget(const SizedBox());

      controller.flash('e1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(controller.progress, closeTo(0.75, 0.001));

      controller.flash('e1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.progress, closeTo(0.5, 0.001));

      await tester.pump(const Duration(milliseconds: 600));
      expect(controller.isFlashing, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('the default ticker can be disposed mid-flash', (tester) async {
      final controller = NoteExcerptFlashController(duration: _second);
      await tester.pumpWidget(const SizedBox());

      controller.flash('e1');
      await tester.pump();
      controller.dispose();
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });

  group('NoteExcerptFlashOverlay', () {
    late FakeFlashTicker ticker;
    late NoteExcerptFlashController controller;
    late NoteExcerpts excerpts;
    late NoteExcerpt excerpt;
    var taps = 0;

    setUp(() {
      ticker = FakeFlashTicker();
      controller = _flash(ticker);
      excerpts = NoteExcerpts(idFactory: countingIds('x'), clock: frozenClock);
      excerpt = excerpts.add(
        pageId: 'p1',
        rect: const Rect.fromLTRB(0.125, 0.25, 0.5, 0.5),
      )!;
      taps = 0;
    });

    tearDown(() {
      controller.dispose();
      excerpts.dispose();
    });

    Future<void> pumpOverlay(WidgetTester tester, {String page = 'p1'}) =>
        tester.pumpWidget(
          noteTestHost(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 800,
                height: 400,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => taps++,
                    ),
                    NoteExcerptFlashOverlay(
                      controller: controller,
                      excerpts: excerpts,
                      pageId: page,
                      borderWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    final painted = find.descendant(
      of: find.byType(NoteExcerptFlashOverlay),
      matching: find.byType(CustomPaint),
    );

    testWidgets('paints the excerpt rect in page coordinates', (tester) async {
      await pumpOverlay(tester);
      expect(painted, findsNothing);

      controller.flash(excerpt.id);
      await tester.pump();

      final shape = RRect.fromRectAndRadius(
        const Rect.fromLTRB(100, 100, 400, 200),
        const Radius.circular(4),
      );
      expect(
        painted,
        paints
          ..rrect(rrect: shape, style: PaintingStyle.fill)
          ..rrect(rrect: shape, style: PaintingStyle.stroke, strokeWidth: 3),
      );
    });

    testWidgets('fades with the progress and disappears', (tester) async {
      await pumpOverlay(tester);
      controller.flash(excerpt.id);
      await tester.pump();
      expect(
        painted,
        paints..rrect(color: const Color(0xFFFFC107).withValues(alpha: 0.35)),
      );

      ticker.advance(const Duration(milliseconds: 500));
      await tester.pump();
      expect(
        painted,
        paints..rrect(color: const Color(0xFFFFC107).withValues(alpha: 0.175)),
      );

      ticker.advance(_second);
      await tester.pump();
      expect(painted, findsNothing);
    });

    testWidgets('uses the colour of the excerpt', (tester) async {
      const green = Color(0xFF00C853);
      excerpts.update(excerpt.copyWith(color: green));
      await pumpOverlay(tester);

      controller.flash(excerpt.id);
      await tester.pump();

      expect(painted, paints..rrect(color: green.withValues(alpha: 0.35)));
    });

    testWidgets('shows nothing for another page or a removed excerpt', (
      tester,
    ) async {
      await pumpOverlay(tester, page: 'p2');
      controller.flash(excerpt.id);
      await tester.pump();
      expect(painted, findsNothing);

      await pumpOverlay(tester);
      expect(painted, findsOneWidget);
      excerpts.remove(excerpt.id);
      await tester.pump();
      expect(painted, findsNothing);
    });

    testWidgets('never takes pointer events', (tester) async {
      await pumpOverlay(tester);
      controller.flash(excerpt.id);
      await tester.pump();

      await tester.tapAt(const Offset(200, 150));

      expect(taps, 1);
    });
  });
}
