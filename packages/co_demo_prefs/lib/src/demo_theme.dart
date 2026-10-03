/// The theme a demo accepts — the two values of the cocode sites' theme toggle
/// (the values stored under the sites' `cocode.theme` key).
enum DemoTheme {
  /// The light theme.
  light,

  /// The dark theme — the cocode sites' default.
  dark;

  /// Matches [raw] to a theme, ignoring case and surrounding whitespace. Any
  /// other value, including `system`, returns `null`.
  static DemoTheme? parse(String? raw) => switch (raw?.trim().toLowerCase()) {
    'light' => light,
    'dark' => dark,
    _ => null,
  };
}
