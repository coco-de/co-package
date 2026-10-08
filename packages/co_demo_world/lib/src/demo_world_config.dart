import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:co_faker/co_faker.dart';

/// The fixed inputs of one demo world: seed, reference clock and the business
/// jurisdiction (locale, currency, time zone).
///
/// A demo world has two independent random streams derived from [seed]:
///
/// * the **business** stream ([businessSeed], [businessFaker]) generates
///   stable business data — ids, relations, counts, order, status codes,
///   amounts, stock, booking times. It always uses [businessLocale] and never
///   the UI language, so switching the language cannot change it.
/// * the **display** stream ([displaySeed]) roots the per-language display
///   projection ([DisplayProjector]).
///
/// Changing the UI language never changes the business jurisdiction:
/// [currencyCode] and [timeZone] stay as configured.
class DemoWorldConfig {
  /// Creates the inputs of a demo world.
  const DemoWorldConfig({
    required this.seed,
    required this.now,
    this.baseLocale = DemoLocale.ko,
    this.businessLocale = 'ko',
    this.currencyCode = 'KRW',
    this.timeZone = 'Asia/Seoul',
  });

  /// The world seed. The same seed always rebuilds the same world.
  final int seed;

  /// The reference clock ("today" in the demo), fixed so that relative
  /// values such as "D-5" stay the same between runs.
  final DateTime now;

  /// The UI language the demo opens in when nothing else is requested.
  final DemoLocale baseLocale;

  /// The co_faker locale used for business data. It never follows the UI
  /// language.
  final String businessLocale;

  /// The ISO 4217 code of the business currency. It never follows the UI
  /// language; only its formatting does.
  final String currencyCode;

  /// The IANA time zone of the business. It never follows the UI language.
  final String timeZone;

  /// The seed of the business stream.
  int get businessSeed => CoRandom.deriveSeed(seed, 'co_demo_world/business');

  /// The seed of the display stream.
  int get displaySeed => CoRandom.deriveSeed(seed, 'co_demo_world/display');

  /// A generator for business data in [businessLocale] on the business
  /// stream.
  ///
  /// Pass [key] to get an independent derived stream (one per collection or
  /// entity), so that adding records to one collection does not shift the
  /// values of another.
  CoFaker businessFaker({
    String? key,
    List<CoFakerDomain> domains = const <CoFakerDomain>[],
  }) {
    final faker = CoFaker(
      locale: businessLocale,
      seed: businessSeed,
      now: now,
      domains: domains,
    );
    return key == null ? faker : faker.derive(key);
  }
}
