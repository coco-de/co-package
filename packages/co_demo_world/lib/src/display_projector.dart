import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:co_faker/co_faker.dart';

import 'demo_faker_locales.dart';
import 'demo_world_config.dart';
import 'display_field_set.dart';
import 'display_key.dart';
import 'user_edit_overlay.dart';

/// Projects generated display text (B data) into the current UI language.
///
/// A value is a pure function of (world seed, reference clock, language,
/// entity, id, field): every value draws from its own stream derived from the
/// display seed and `entity/id/field`, so the order of reads never matters,
/// and switching back to a language shows exactly the text it showed before.
/// The language is not part of the derivation key, so where co_faker's word
/// lists are aligned across languages the same record comes out translated.
///
/// Reading never writes, reseeds or notifies: values are computed once per
/// language and memoized. Business data (A) is not produced here — see
/// [DemoWorldConfig.businessFaker] — and user edits (C) in [overlay] win over
/// projected values.
class DisplayProjector {
  /// Creates a projector over [fields] for the world [config].
  ///
  /// [domains] and [customLocales] are handed to co_faker unchanged.
  DisplayProjector({
    required this.config,
    required this.fields,
    DemoLocale? locale,
    this.domains = const <CoFakerDomain>[],
    this.customLocales = const <String, CoFakerLocale>{},
    UserEditOverlay? overlay,
  }) : locale = locale ?? config.baseLocale,
       overlay = overlay ?? UserEditOverlay();

  /// The world inputs.
  final DemoWorldConfig config;

  /// The display fields and their generators.
  final DisplayFieldSet fields;

  /// co_faker domain packs available to the generators.
  final List<CoFakerDomain> domains;

  /// Custom co_faker locales available to the generators.
  final Map<String, CoFakerLocale> customLocales;

  /// User edits, which win over projected values.
  final UserEditOverlay overlay;

  /// The language values are projected into.
  ///
  /// Changing it keeps the values already projected for other languages
  /// memoized, and notifies no one: switch the UI language and this value in
  /// the same step (see [DemoLocaleSwitcher]) so the two never disagree on
  /// screen.
  DemoLocale locale;

  final Map<DemoLocale, CoFaker> _roots = <DemoLocale, CoFaker>{};
  final Map<DemoLocale, Map<String, String>> _memo =
      <DemoLocale, Map<String, String>>{};

  /// The generated value of [key] in [locale] (the current language when
  /// omitted), ignoring user edits.
  String generated(DisplayKey key, {DemoLocale? locale}) {
    final language = locale ?? this.locale;
    final memo = _memo.putIfAbsent(language, () => <String, String>{});
    final cached = memo[key.path];
    if (cached != null) return cached;
    final generator = fields.generatorFor(key.fieldKey);
    final value = generator(_root(language).derive(key.path), key);
    memo[key.path] = value;
    return value;
  }

  /// The value to show for [key]: the user's edit when there is one,
  /// otherwise the generated value in the current language.
  String text(DisplayKey key) => overlay.valueOf(key) ?? generated(key);

  /// The lower-cased, space-joined [text] of [keys] in the current language —
  /// a search index entry for one record.
  String searchText(Iterable<DisplayKey> keys) =>
      keys.map(text).join(' ').toLowerCase();

  /// Projects [keys] into [locale] ahead of a language switch, so the first
  /// frame after the switch reads memoized values.
  void warm(Iterable<DisplayKey> keys, DemoLocale locale) {
    for (final key in keys) {
      generated(key, locale: locale);
    }
  }

  /// How many values are memoized for [locale] — for tests and diagnostics.
  int memoizedCount(DemoLocale locale) => _memo[locale]?.length ?? 0;

  CoFaker _root(DemoLocale language) => _roots.putIfAbsent(
    language,
    () => CoFaker(
      locale: DemoFakerLocales.fakerLocaleOf(language),
      seed: config.displaySeed,
      now: config.now,
      locales: customLocales,
      domains: domains,
    ),
  );
}
