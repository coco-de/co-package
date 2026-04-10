import 'package:co_test_gen/src/driver/test_driver.dart';
import 'package:co_test_gen/src/key/common_keys.dart';
import 'package:flutter/widgets.dart';

/// Reusable authentication step functions.
///
/// Works with both widget tests and Patrol E2E tests via [TestDriver].
///
/// ```dart
/// final auth = AuthSteps(driver);
/// await auth.enterEmail('user@example.com');
/// await auth.enterPassword('secret');
/// await auth.tapLogin();
/// ```
///
/// Override keys if your app uses different ones:
/// ```dart
/// final auth = AuthSteps(
///   driver,
///   emailKey: const Key('my_email'),
///   passwordKey: const Key('my_password'),
///   loginKey: const Key('my_login'),
/// );
/// ```
class AuthSteps {
  /// Creates auth steps with optional custom keys.
  const AuthSteps(
    this.driver, {
    this.emailKey = CommonKeys.emailField,
    this.passwordKey = CommonKeys.passwordField,
    this.loginKey = CommonKeys.loginButton,
    this.passwordToggleKey = CommonKeys.passwordToggle,
  });

  /// The test driver.
  final TestDriver driver;

  /// Key for the email input field.
  final Key emailKey;

  /// Key for the password input field.
  final Key passwordKey;

  /// Key for the login button.
  final Key loginKey;

  /// Key for the password visibility toggle.
  final Key passwordToggleKey;

  /// Enters [email] in the email field.
  Future<void> enterEmail(String email) => driver.enterText(emailKey, email);

  /// Enters [password] in the password field.
  Future<void> enterPassword(String password) =>
      driver.enterText(passwordKey, password);

  /// Taps the login button.
  Future<void> tapLogin() => driver.tap(loginKey);

  /// Taps the password visibility toggle.
  Future<void> tapPasswordToggle() => driver.tap(passwordToggleKey);

  /// Full login flow: enter email + password, then tap login.
  Future<void> loginWith({
    required String email,
    required String password,
  }) async {
    await enterEmail(email);
    await enterPassword(password);
    await tapLogin();
  }
}
