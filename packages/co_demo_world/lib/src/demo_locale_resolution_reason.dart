/// Why a requested language tag resolved to the fallback locale.
enum DemoLocaleResolutionReason {
  /// The tag matched one of the eleven demo locales.
  matched,

  /// No tag was given (`null` or blank).
  missing,

  /// The tag names Traditional Chinese (`zh-Hant`, `zh-TW`, `zh-HK`,
  /// `zh-MO`), which demos do not serve — Simplified text is never handed to
  /// Traditional readers.
  traditionalChinese,

  /// The tag is not one of the eleven demo locales.
  unsupported,
}
