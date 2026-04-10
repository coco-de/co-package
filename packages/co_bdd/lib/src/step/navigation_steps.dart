import 'package:co_test_gen/src/driver/test_driver.dart';
import 'package:flutter/widgets.dart';

/// Reusable bottom navigation step functions.
///
/// Supports any number of tabs with customizable keys and settle duration.
///
/// ```dart
/// final nav = NavigationSteps(
///   driver,
///   tabs: {
///     'home': const Key('nav_home'),
///     'search': const Key('nav_search'),
///     'profile': const Key('nav_profile'),
///   },
/// );
/// await nav.navigateTo('home');
/// ```
class NavigationSteps {
  /// Creates navigation steps with tab [Key] mapping.
  const NavigationSteps(
    this.driver, {
    required this.tabs,
    this.settleDuration = const Duration(seconds: 3),
  });

  /// The test driver.
  final TestDriver driver;

  /// Tab name → Key mapping.
  final Map<String, Key> tabs;

  /// Duration to wait after tapping a tab.
  final Duration settleDuration;

  /// Navigates to the tab with the given [name].
  ///
  /// Throws [ArgumentError] if [name] is not in [tabs].
  Future<void> navigateTo(String name) async {
    final key = tabs[name];
    if (key == null) {
      throw ArgumentError.value(
        name,
        'name',
        'Tab not found. Available: ${tabs.keys.join(', ')}',
      );
    }
    await driver.tap(key);
    await driver.wait(settleDuration);
  }
}
