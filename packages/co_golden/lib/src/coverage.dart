import 'dart:ui' show Locale;

import 'package:meta/meta.dart';

import 'device.dart';
import 'naming.dart';
import 'theme.dart';
import 'variant.dart';

/// How a coverage plan narrows the Cartesian product of its axes.
enum GoldenSampling {
  /// Keep every feasible combination.
  full,

  /// Keep a small greedy selection in which every axis value appears at
  /// least once.
  smoke,

  /// Keep a greedy selection in which every feasible pair of values from two
  /// different axes appears at least once.
  pairwise,
}

/// Removes combinations that cannot happen or are not worth capturing.
@immutable
final class GoldenCoverageRule<T> {
  /// Excludes every variant for which [predicate] returns `true`. [reason] is
  /// kept in the plan so the exclusion stays visible.
  const GoldenCoverageRule.exclude(this.reason, this.predicate);

  /// Why matching variants are excluded.
  final String reason;

  /// Returns `true` for variants that must be excluded.
  final bool Function(GoldenVariant<T> variant) predicate;
}

/// A variant removed by a [GoldenCoverageRule].
@immutable
final class GoldenExcludedVariant<T> {
  /// Creates an excluded entry.
  const GoldenExcludedVariant(this.variant, this.reason);

  /// The removed variant.
  final GoldenVariant<T> variant;

  /// Reason of the rule that removed it.
  final String reason;
}

/// Thrown when the sampled plan is larger than
/// [GoldenCoverage.maxVariants]. Coverage is never reduced silently: raise
/// the budget, add rules, or choose a smaller sampling strategy.
final class GoldenCoverageBudgetExceeded implements Exception {
  /// Creates the exception.
  const GoldenCoverageBudgetExceeded({
    required this.required,
    required this.budget,
    required this.sampling,
  });

  /// Number of variants the sampling strategy needs.
  final int required;

  /// Configured maximum.
  final int budget;

  /// Strategy that produced [required].
  final GoldenSampling sampling;

  @override
  String toString() =>
      'GoldenCoverageBudgetExceeded: ${sampling.name} sampling needs '
      '$required variants but maxVariants is $budget.';
}

/// The resolved variants of one scenario.
@immutable
final class GoldenPlan<T> {
  const GoldenPlan._({
    required this.variants,
    required this.excluded,
    required this.combinations,
    required this.axes,
  });

  /// Variants to run, in axis order (device, theme, locale, text scale).
  final List<GoldenVariant<T>> variants;

  /// Variants removed by rules.
  final List<GoldenExcludedVariant<T>> excluded;

  /// Size of the Cartesian product before rules and sampling.
  final int combinations;

  /// Axis values of the coverage in declaration order.
  ///
  /// Sampling and rules can leave the first device without some themes or
  /// locales, so the order in which variants first appear is not the
  /// coverage order. A gallery orders its grid by these lists instead.
  final GoldenAxes axes;

  /// Counts and axis order written to run manifests.
  Map<String, Object?> toJson() => {
    'combinations': combinations,
    'excluded': excluded.length,
    'selected': variants.length,
    'axes': axes.toJson(),
  };
}

/// Axis values of a coverage, in the order they were declared.
@immutable
final class GoldenAxes {
  /// Creates the axis lists.
  const GoldenAxes({
    required this.devices,
    required this.themes,
    required this.locales,
    required this.textScales,
  });

  /// Device names.
  final List<String> devices;

  /// Theme names.
  final List<String> themes;

  /// BCP 47 locale tags, for example `zh-Hans`.
  final List<String> locales;

  /// Text scale factors.
  final List<double> textScales;

  /// JSON form written under `plan.axes`.
  Map<String, Object?> toJson() => {
    'devices': devices,
    'themes': themes,
    'locales': locales,
    'textScales': textScales,
  };
}

/// Declares which devices, themes, locales, and text scales a scenario
/// covers.
@immutable
final class GoldenCoverage<T> {
  /// Creates a coverage definition. Every axis needs at least one value.
  const GoldenCoverage({
    required this.devices,
    required this.themes,
    required this.locales,
    this.textScales = const [1],
    this.sampling = GoldenSampling.full,
    this.rules = const [],
    this.maxVariants,
  });

  /// Device axis.
  final List<GoldenDevice> devices;

  /// Theme axis.
  final List<GoldenTheme<T>> themes;

  /// Locale axis.
  final List<Locale> locales;

  /// Text scale axis. `1` is the system default.
  final List<double> textScales;

  /// Strategy that narrows the feasible combinations.
  final GoldenSampling sampling;

  /// Exclusion rules, applied before sampling.
  final List<GoldenCoverageRule<T>> rules;

  /// Hard upper bound on the sampled plan, or `null` for no bound.
  final int? maxVariants;

  /// Returns a copy with the given fields replaced — handy for narrowing a
  /// shared coverage for one scenario.
  GoldenCoverage<T> copyWith({
    List<GoldenDevice>? devices,
    List<GoldenTheme<T>>? themes,
    List<Locale>? locales,
    List<double>? textScales,
    GoldenSampling? sampling,
    List<GoldenCoverageRule<T>>? rules,
    int? maxVariants,
  }) => GoldenCoverage<T>(
    devices: devices ?? this.devices,
    themes: themes ?? this.themes,
    locales: locales ?? this.locales,
    textScales: textScales ?? this.textScales,
    sampling: sampling ?? this.sampling,
    rules: rules ?? this.rules,
    maxVariants: maxVariants ?? this.maxVariants,
  );

  /// Expands the axes, applies [rules], and samples the feasible variants.
  ///
  /// Throws an [ArgumentError] for empty axes, invalid or duplicate names,
  /// and invalid text scales; a [StateError] when every combination is
  /// excluded; and [GoldenCoverageBudgetExceeded] when the sampled plan is
  /// larger than [maxVariants].
  GoldenPlan<T> plan() {
    _validate();
    final feasible = <GoldenVariant<T>>[];
    final excluded = <GoldenExcludedVariant<T>>[];
    var combinations = 0;
    for (final device in devices) {
      for (final theme in themes) {
        for (final locale in locales) {
          for (final textScale in textScales) {
            combinations++;
            final variant = GoldenVariant<T>(
              device: device,
              theme: theme,
              locale: locale,
              textScale: textScale,
            );
            final reason = _exclusionReason(variant);
            if (reason == null) {
              feasible.add(variant);
            } else {
              excluded.add(GoldenExcludedVariant<T>(variant, reason));
            }
          }
        }
      }
    }
    if (feasible.isEmpty) {
      throw StateError(
        'Every one of the $combinations golden combinations was excluded by '
        'a coverage rule.',
      );
    }
    final selected = switch (sampling) {
      GoldenSampling.full => feasible,
      GoldenSampling.smoke => _greedy<T>(feasible, _axisTokens<T>),
      GoldenSampling.pairwise => _greedy<T>(feasible, _pairTokens<T>),
    };
    final budget = maxVariants;
    if (budget != null && selected.length > budget) {
      throw GoldenCoverageBudgetExceeded(
        required: selected.length,
        budget: budget,
        sampling: sampling,
      );
    }
    return GoldenPlan<T>._(
      variants: List.unmodifiable(selected),
      excluded: List.unmodifiable(excluded),
      combinations: combinations,
      axes: GoldenAxes(
        devices: List.unmodifiable([for (final device in devices) device.name]),
        themes: List.unmodifiable([for (final theme in themes) theme.name]),
        locales: List.unmodifiable([
          for (final locale in locales) locale.toLanguageTag(),
        ]),
        textScales: List.unmodifiable(textScales),
      ),
    );
  }

  String? _exclusionReason(GoldenVariant<T> variant) {
    for (final rule in rules) {
      if (rule.predicate(variant)) {
        return rule.reason;
      }
    }
    return null;
  }

  void _validate() {
    if (devices.isEmpty ||
        themes.isEmpty ||
        locales.isEmpty ||
        textScales.isEmpty) {
      throw ArgumentError(
        'Every golden axis (devices, themes, locales, textScales) needs at '
        'least one value.',
      );
    }
    _requireUnique([
      for (final device in devices) checkGoldenName(device.name, 'device'),
    ], 'device');
    _requireUnique([
      for (final theme in themes) checkGoldenName(theme.name, 'theme'),
    ], 'theme');
    _requireUnique([
      for (final locale in locales) goldenLocaleToken(locale),
    ], 'locale');
    for (final scale in textScales) {
      if (!scale.isFinite || scale <= 0) {
        throw ArgumentError.value(
          scale,
          'textScales',
          'must be finite and greater than zero',
        );
      }
    }
    _requireUnique([
      for (final scale in textScales) goldenScaleToken(scale),
    ], 'text scale');
  }
}

void _requireUnique(List<String> values, String axis) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw ArgumentError('Duplicate $axis "$value" in golden coverage.');
    }
  }
}

List<String> _axisTokens<T>(GoldenVariant<T> variant) => [
  'device=${variant.device.name}',
  'theme=${variant.theme.name}',
  'locale=${goldenLocaleToken(variant.locale)}',
  'text=${goldenScaleToken(variant.textScale)}',
];

List<String> _pairTokens<T>(GoldenVariant<T> variant) {
  final values = _axisTokens(variant);
  return [
    for (var i = 0; i < values.length; i++)
      for (var j = i + 1; j < values.length; j++) '${values[i]}|${values[j]}',
  ];
}

/// Picks, one at a time, the variant that covers the most tokens not yet
/// covered (the earliest one on ties) until every token that some feasible
/// variant carries is covered. Returns the picks in plan order.
List<GoldenVariant<T>> _greedy<T>(
  List<GoldenVariant<T>> feasible,
  List<String> Function(GoldenVariant<T> variant) tokensOf,
) {
  final tokens = [for (final variant in feasible) tokensOf(variant)];
  final uncovered = {for (final list in tokens) ...list};
  final picked = <int>{};
  while (uncovered.isNotEmpty) {
    var best = -1;
    var bestGain = 0;
    for (var i = 0; i < feasible.length; i++) {
      if (picked.contains(i)) {
        continue;
      }
      final gain = tokens[i].where(uncovered.contains).length;
      if (gain > bestGain) {
        best = i;
        bestGain = gain;
      }
    }
    if (best < 0) {
      break;
    }
    picked.add(best);
    uncovered.removeAll(tokens[best]);
  }
  return [
    for (var i = 0; i < feasible.length; i++)
      if (picked.contains(i)) feasible[i],
  ];
}
