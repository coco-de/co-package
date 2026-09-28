import 'package:flutter/foundation.dart';

/// Common widget keys for BDD tests.
///
/// Assign these keys to your widgets so that step functions can
/// reliably locate them in both widget tests and Patrol E2E tests.
///
/// ```dart
/// // In your widget
/// TextField(key: CommonKeys.emailField, ...)
///
/// // In your step function
/// await driver.enterText(CommonKeys.emailField, 'test@example.com');
/// ```
///
/// To add project-specific keys, create your own key class:
/// ```dart
/// abstract final class AppKeys {
///   static const productCard = Key('product_card');
/// }
/// ```
abstract final class CommonKeys {
  // === Auth ===

  /// Email input field.
  static const emailField = Key('email_field');

  /// Password input field.
  static const passwordField = Key('password_field');

  /// Login submit button.
  static const loginButton = Key('login_button');

  /// Sign up / register button.
  static const signUpButton = Key('sign_up_button');

  /// Password visibility toggle.
  static const passwordToggle = Key('password_toggle');

  /// Logout button.
  static const logoutButton = Key('logout_button');

  // === Navigation ===

  /// Bottom navigation bar.
  static const bottomNavBar = Key('bottom_nav_bar');

  /// Back button / app bar leading.
  static const backButton = Key('back_button');

  // === Search ===

  /// Search icon / button.
  static const searchIcon = Key('search_icon');

  /// Search text field.
  static const searchField = Key('search_field');

  /// Search results list.
  static const searchResults = Key('search_results');

  // === Common UI ===

  /// Primary action FAB or CTA button.
  static const primaryAction = Key('primary_action');

  /// Confirm button in dialogs.
  static const confirmButton = Key('confirm_button');

  /// Cancel button in dialogs.
  static const cancelButton = Key('cancel_button');

  /// Refresh indicator / pull-to-refresh.
  static const refreshIndicator = Key('refresh_indicator');

  /// Loading indicator.
  static const loadingIndicator = Key('loading_indicator');

  /// Error message container.
  static const errorMessage = Key('error_message');

  /// Empty state container.
  static const emptyState = Key('empty_state');

  /// Retry button.
  static const retryButton = Key('retry_button');

  /// Scroll view / list view.
  static const scrollView = Key('scroll_view');
}
