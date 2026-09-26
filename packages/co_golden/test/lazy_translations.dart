import 'package:slang/slang.dart';

/// Builds translations for [locale].
///
/// The localization tests import this library `deferred`, the way Slang's
/// generated code imports every non-base locale of lazy settings.
FakeTranslations buildLazyTranslations(FakeAppLocale locale) =>
    FakeTranslations(locale);
