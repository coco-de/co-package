/// Deterministic demo worlds whose generated display text follows the UI
/// language.
///
/// A demo's data comes in three kinds:
///
/// * **A — business data** (ids, relations, counts, order, status codes,
///   amounts, currency, stock, booking times, results of user actions):
///   generated once on the business stream ([DemoWorldConfig.businessFaker])
///   and never changed by a language switch.
/// * **B — display data** (fictional people and organization names, product
///   and course names, address lines, generated messages, domain labels):
///   projected per language by [DisplayProjector] from stable
///   (seed, clock, language, entity, id, field) keys.
/// * **C — user input**: kept in [UserEditOverlay] and shown instead of the
///   projection.
///
/// [DemoLocaleSwitcher] commits only the latest language request, so the UI
/// language and the display projection change together. [DemoFakerLocales]
/// maps the eleven UI languages (co_demo_prefs' [DemoLocale]) to co_faker
/// locales, [DemoLocaleSupport] measures the real per-field language support,
/// and [DemoFormat] formats business values for the UI language.
library;

export 'package:co_demo_prefs/co_demo_prefs.dart' show DemoLocale;

export 'src/demo_faker_locales.dart';
export 'src/demo_format.dart';
export 'src/demo_locale_resolution.dart';
export 'src/demo_locale_resolution_reason.dart';
export 'src/demo_locale_support.dart';
export 'src/demo_locale_switcher.dart';
export 'src/demo_world_config.dart';
export 'src/display_field_set.dart';
export 'src/display_key.dart';
export 'src/display_projector.dart';
export 'src/locale_field_report.dart';
export 'src/locale_field_status.dart';
export 'src/user_edit_overlay.dart';
