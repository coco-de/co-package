import 'package:flutter_test/flutter_test.dart';

/// Advances the widget tree after it is built and after each interaction.
typedef GoldenPump = Future<void> Function(WidgetTester tester);

/// Ready-made [GoldenPump] strategies.
///
/// None of them waits for an endless animation: capture a state that is
/// observable (data loaded, a widget present), then pump a bounded number of
/// frames. `pumpAndSettle` would time out on a spinner.
abstract final class GoldenPumps {
  /// Pumps one frame, then keeps pumping [step] until no frame is scheduled
  /// or [maxFrames] frames have passed. Never throws on endless animations.
  static GoldenPump settle({
    int maxFrames = 60,
    Duration step = const Duration(milliseconds: 16),
  }) => (tester) async {
    await tester.pump();
    for (var i = 0; i < maxFrames && tester.binding.hasScheduledFrame; i++) {
      await tester.pump(step);
    }
  };

  /// Pumps exactly [count] frames of [step] after the first one — a fixed
  /// frame contract for screens with running animations.
  static GoldenPump frames(
    int count, {
    Duration step = const Duration(milliseconds: 16),
  }) => (tester) async {
    await tester.pump();
    for (var i = 0; i < count; i++) {
      await tester.pump(step);
    }
  };

  /// Lets real asynchronous work finish (image decoding, work that runs in
  /// an isolate, asset loading) and then settles.
  ///
  /// Widget tests run in a fake-async zone that never delivers such events on
  /// its own, so decoded images would otherwise be captured as empty boxes.
  static GoldenPump withRealAsyncWork({
    Duration wait = const Duration(milliseconds: 300),
    int maxFrames = 60,
  }) => (tester) async {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(wait));
    await settle(maxFrames: maxFrames)(tester);
  };
}
