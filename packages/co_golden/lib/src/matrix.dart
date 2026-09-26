import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'coverage.dart';
import 'environment.dart';
import 'localization.dart';
import 'manifest.dart';
import 'naming.dart';
import 'pump.dart';
import 'variant.dart';

/// Builds the app root around the scenario widget — the place to install
/// the theme, localizations, and routing of the app under test.
typedef GoldenAppBuilder<T> =
    Widget Function(GoldenVariant<T> variant, Widget child);

/// Builds the widget under test for one variant.
typedef GoldenWidgetBuilder<T> = Widget Function(GoldenVariant<T> variant);

/// Scenario hook that runs with the variant's [GoldenMatrixContext].
typedef GoldenHook<T> = FutureOr<void> Function(GoldenMatrixContext<T> context);

/// What a scenario hook can see while one variant runs.
final class GoldenMatrixContext<T> {
  GoldenMatrixContext._({
    required this.tester,
    required this.variant,
    required this.suite,
    required this.scenario,
  });

  /// Tester of the running variant.
  final WidgetTester tester;

  /// Running variant.
  final GoldenVariant<T> variant;

  /// Suite of the scenario.
  final String suite;

  /// Scenario name.
  final String scenario;
}

/// A suite of golden scenarios that share coverage, app root, and
/// localization.
///
/// Each [scenario] registers one test per planned variant, tagged `golden`
/// and `co_golden`. The [environment] decides what those tests do; by
/// default ([GoldenMatrixMode.skip]) they are skipped, so a matrix never
/// fails an ordinary `flutter test` run.
///
/// ```dart
/// final matrix = GoldenMatrix<ThemeData>(
///   suite: 'auth',
///   coverage: GoldenCoverage(
///     devices: GoldenDevice.presets,
///     themes: const [
///       GoldenTheme(name: 'light', data: lightTheme),
///       GoldenTheme(name: 'dark', data: darkTheme, brightness: .dark),
///     ],
///     locales: const [Locale('ko'), Locale('en')],
///   ),
///   app: (variant, child) => MaterialApp(
///     theme: variant.theme.data,
///     locale: variant.locale,
///     home: child,
///   ),
/// );
///
/// void main() {
///   matrix.scenario('login', build: (_) => const LoginPage());
/// }
/// ```
final class GoldenMatrix<T> {
  /// Creates a matrix. [suite] becomes a path segment and must pass
  /// [isGoldenName].
  GoldenMatrix({
    required this.suite,
    required this.coverage,
    required this.app,
    this.localization = GoldenLocalization.none,
    GoldenMatrixEnvironment? environment,
    this.pump,
    this.captureScale,
    this.renderShadows = true,
    this.freezeAnimations = true,
    this.failOnErrors = true,
  }) : environment = environment ?? GoldenMatrixEnvironment.fromEnvironment() {
    checkGoldenName(suite, 'suite');
    final scale = captureScale;
    if (scale != null && (!scale.isFinite || scale <= 0)) {
      throw ArgumentError.value(
        scale,
        'captureScale',
        'must be finite and greater than zero',
      );
    }
  }

  /// Suite name — usually the package under test.
  final String suite;

  /// Default coverage of every scenario.
  final GoldenCoverage<T> coverage;

  /// App root builder.
  final GoldenAppBuilder<T> app;

  /// Locale switching of the app's own translation layer.
  final GoldenLocalization localization;

  /// Mode and output directory.
  final GoldenMatrixEnvironment environment;

  /// Default pump strategy, [GoldenPumps.settle] when `null`.
  final GoldenPump? pump;

  /// Raster scale of captured images, the device pixel ratio when `null`.
  final double? captureScale;

  /// Paints real shadows instead of the flat test shadows.
  final bool renderShadows;

  /// Disables tickers so animations stay on their first frame.
  final bool freezeAnimations;

  /// Fails a variant when Flutter reported errors (such as overflows) while
  /// it rendered. The image is captured either way.
  final bool failOnErrors;

  final Set<String> _scenarios = {};

  /// Registers one test per planned variant of [name].
  ///
  /// [build] creates a fresh widget for every variant. [prepare] runs before
  /// the build (install fixtures), [interact] after the first pump (tap,
  /// type), and [dispose] after capture even when the variant failed.
  /// [coverage] replaces the matrix coverage for this scenario only.
  ///
  /// Throws an [ArgumentError] when [name] is not a valid golden name or is
  /// already registered in this matrix.
  @isTestGroup
  void scenario(
    String name, {
    required GoldenWidgetBuilder<T> build,
    String? description,
    GoldenCoverage<T>? coverage,
    GoldenHook<T>? prepare,
    GoldenHook<T>? interact,
    GoldenHook<T>? dispose,
    GoldenPump? pump,
    Timeout? timeout,
    Iterable<String> tags = const [],
  }) {
    checkGoldenName(name, 'scenario');
    if (!_scenarios.add(name)) {
      throw ArgumentError.value(
        name,
        'scenario',
        'is already registered in suite "$suite"',
      );
    }
    final plan = (coverage ?? this.coverage).plan();
    final mode = environment.mode;
    final definition = _Scenario<T>(
      name: name,
      build: build,
      prepare: prepare,
      interact: interact,
      dispose: dispose,
      pump: pump ?? this.pump ?? GoldenPumps.settle(),
    );
    final report = GoldenScenarioReport(
      suite: suite,
      scenario: name,
      description: description,
      mode: mode,
      plan: plan,
    );

    group(
      '$suite/$name',
      () {
        if (mode == GoldenMatrixMode.capture) {
          tearDownAll(() => report.write(environment.outputDirectory));
        }
        for (final variant in plan.variants) {
          testWidgets(
            variant.label,
            (tester) => _runVariant(tester, variant, definition, report),
            timeout: timeout,
            tags: ['golden', 'co_golden', ...tags],
          );
        }
      },
      skip: mode == GoldenMatrixMode.skip
          ? 'golden matrix — set ${GoldenMatrixEnvironment.modeVariable}='
                'capture or compare to run it'
          : false,
    );
  }

  Future<void> _runVariant(
    WidgetTester tester,
    GoldenVariant<T> variant,
    _Scenario<T> scenario,
    GoldenScenarioReport report,
  ) async {
    final stopwatch = Stopwatch()..start();
    final context = GoldenMatrixContext<T>._(
      tester: tester,
      variant: variant,
      suite: suite,
      scenario: scenario.name,
    );
    final view = _GoldenView.apply(tester, variant);
    final previousShadows = debugDisableShadows;
    debugDisableShadows = !renderShadows;
    final reported = <FlutterErrorDetails>[];
    final boundaryKey = UniqueKey();
    Object? failure;
    StackTrace? failureStack;
    String? failurePhase;
    String? image;
    var phase = 'localization';
    var prepared = false;

    try {
      await localization.activate(variant.locale);
      phase = 'prepare';
      prepared = true;
      await scenario.prepare?.call(context);
      phase = 'build';
      final previousOnError = FlutterError.onError;
      FlutterError.onError = reported.add;
      try {
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: TickerMode(
              enabled: !freezeAnimations,
              child: localization.wrap(app(variant, scenario.build(variant))),
            ),
          ),
        );
        await scenario.pump(tester);
        final interact = scenario.interact;
        if (interact != null) {
          phase = 'interact';
          await interact(context);
          await scenario.pump(tester);
        }
      } finally {
        FlutterError.onError = previousOnError;
      }
      phase = 'capture';
      image = await _capture(tester, boundaryKey, variant, scenario.name);
    } on Object catch (error, stack) {
      failure = error;
      failureStack = stack;
      failurePhase = phase;
    } finally {
      if (prepared) {
        try {
          await scenario.dispose?.call(context);
        } on Object catch (error, stack) {
          failure ??= error;
          failureStack ??= stack;
          failurePhase ??= 'dispose';
        }
      }
      try {
        await localization.restore();
      } on Object catch (error, stack) {
        failure ??= error;
        failureStack ??= stack;
        failurePhase ??= 'restore';
      }
      view.reset();
      debugDisableShadows = previousShadows;
      stopwatch.stop();
      final errors = [
        for (final details in reported) _describe(details),
        if (failure != null) '$failurePhase: $failure',
      ];
      report.add(
        GoldenResult.of(
          variant,
          status: errors.isEmpty
              ? GoldenResultStatus.passed
              : GoldenResultStatus.failed,
          duration: stopwatch.elapsed,
          image: image,
          overflowCount: reported.where(_isOverflow).length,
          errors: errors,
          failurePhase: failurePhase,
        ),
      );
    }

    if (failure != null) {
      Error.throwWithStackTrace(failure, failureStack!);
    }
    if (failOnErrors && reported.isNotEmpty) {
      fail(
        '${reported.length} Flutter error(s) while rendering '
        '$suite/${scenario.name} [${variant.label}]:\n'
        '${reported.map(_describe).join('\n')}',
      );
    }
  }

  Future<String> _capture(
    WidgetTester tester,
    Key boundaryKey,
    GoldenVariant<T> variant,
    String scenario,
  ) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final scale = captureScale ?? variant.device.devicePixelRatio;
    switch (environment.mode) {
      case GoldenMatrixMode.capture:
        final relative = p.posix.join(
          'images',
          suite,
          scenario,
          '${variant.fileStem}.png',
        );
        final bytes = await tester.runAsync(() async {
          final captured = await boundary.toImage(pixelRatio: scale);
          try {
            final data = await captured.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (data == null) {
              throw StateError('PNG encoding returned no data.');
            }
            return data.buffer.asUint8List();
          } finally {
            captured.dispose();
          }
        });
        if (bytes == null) {
          throw StateError('The capture did not complete.');
        }
        // ⚠️ Synchronous IO on purpose: the test body runs in a fake-async
        // zone, where awaiting real asynchronous IO never resumes.
        final file = File(p.join(environment.outputDirectory, relative));
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes, flush: true);
        return relative;
      case GoldenMatrixMode.compare:
        final relative = p.posix.join(
          'goldens',
          suite,
          scenario,
          '${variant.fileStem}.png',
        );
        final captured = await tester.runAsync(
          () => boundary.toImage(pixelRatio: scale),
        );
        if (captured == null) {
          throw StateError('The capture did not complete.');
        }
        try {
          await expectLater(captured, matchesGoldenFile(relative));
        } finally {
          captured.dispose();
        }
        return relative;
      case GoldenMatrixMode.skip:
        throw StateError('A skipped golden matrix does not capture.');
    }
  }
}

final class _Scenario<T> {
  const _Scenario({
    required this.name,
    required this.build,
    required this.pump,
    this.prepare,
    this.interact,
    this.dispose,
  });

  final String name;
  final GoldenWidgetBuilder<T> build;
  final GoldenPump pump;
  final GoldenHook<T>? prepare;
  final GoldenHook<T>? interact;
  final GoldenHook<T>? dispose;
}

/// Applies a variant to the test view and restores it afterwards.
final class _GoldenView {
  _GoldenView._(this._tester, this._previousPlatform);

  static _GoldenView apply(
    WidgetTester tester,
    GoldenVariant<Object?> variant,
  ) {
    final previous = debugDefaultTargetPlatformOverride;
    final device = variant.device;
    final ratio = device.devicePixelRatio;
    final inset = device.safeArea;
    final padding = FakeViewPadding(
      left: inset.left * ratio,
      top: inset.top * ratio,
      right: inset.right * ratio,
      bottom: inset.bottom * ratio,
    );
    tester.view
      ..devicePixelRatio = ratio
      ..physicalSize = device.physicalSize
      ..padding = padding
      ..viewPadding = padding;
    tester.platformDispatcher
      ..localeTestValue = variant.locale
      ..localesTestValue = [variant.locale]
      ..textScaleFactorTestValue = variant.textScale
      ..platformBrightnessTestValue = variant.brightness;
    debugDefaultTargetPlatformOverride = variant.platform;
    return _GoldenView._(tester, previous);
  }

  final WidgetTester _tester;
  final TargetPlatform? _previousPlatform;

  void reset() {
    _tester.view.reset();
    _tester.platformDispatcher.clearAllTestValues();
    debugDefaultTargetPlatformOverride = _previousPlatform;
  }
}

bool _isOverflow(FlutterErrorDetails details) =>
    details.exceptionAsString().contains('overflowed by');

String _describe(FlutterErrorDetails details) {
  final lines = details
      .exceptionAsString()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty);
  return lines.take(2).join(' ');
}
