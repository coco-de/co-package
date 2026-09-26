## 0.1.0

- Initial release: `GoldenMatrix` registers one widget test per variant of a
  device × theme × locale × text scale coverage (`full`, `smoke`, `pairwise`
  sampling, exclusion rules, a hard variant budget).
- Theme-agnostic `GoldenTheme<T>` and device presets with pixel ratio, safe
  area, and platform applied to the test view.
- `SlangGoldenLocalization` switches Slang `LocaleSettings` per variant and
  fails on locales the app does not ship.
- `CO_GOLDEN_MODE` selects skip (default), capture (PNG + JSON run manifest,
  no comparison), or compare (`matchesGoldenFile`).
- Flutter errors such as overflows fail the variant while the image is still
  captured; `loadGoldenFonts` registers package fonts under their plain name.
