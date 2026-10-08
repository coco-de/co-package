import 'display_key.dart';

/// User input (C data): values the visitor typed or edited.
///
/// An edit wins over the generated display value and is kept when the UI
/// language changes — a name the visitor typed is not "translated".
class UserEditOverlay {
  final Map<DisplayKey, String> _values = <DisplayKey, String>{};

  /// The user's value for [key], or `null` when it was never edited.
  String? valueOf(DisplayKey key) => _values[key];

  /// Whether the user edited [key].
  bool has(DisplayKey key) => _values.containsKey(key);

  /// Records the user's [value] for [key].
  void set(DisplayKey key, String value) => _values[key] = value;

  /// Forgets the user's value for [key]; returns whether there was one.
  bool remove(DisplayKey key) => _values.remove(key) != null;

  /// Forgets every user value (a demo reset).
  void clear() => _values.clear();

  /// A read-only view of every user value.
  Map<DisplayKey, String> get values =>
      Map<DisplayKey, String>.unmodifiable(_values);
}
