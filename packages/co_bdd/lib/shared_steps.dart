/// Shared BDD Step library.
///
/// Projects can create their own shared steps package and configure
/// `sharedStepsImport` in build.yaml to point to it.
///
/// This file serves as a template. Override it in your project's
/// test_driver (or equivalent) package with actual step implementations.
///
/// ## Usage
///
/// 1. Create shared step files in your project's test utility package:
///    ```
///    package/test_driver/lib/src/shared_step/
///    ├── then/
///    │   ├── the_error_message_should_be_displayed.dart
///    │   └── the_loading_indicator_should_be_displayed.dart
///    └── when/
///        ├── i_tap_the_search_button.dart
///        └── i_confirm_deletion.dart
///    ```
///
/// 2. Export them from a barrel file (like this one).
///
/// 3. Configure build.yaml:
///    ```yaml
///    options:
///      sharedSteps: true
///      sharedStepsImport: "package:test_driver/shared_steps.dart"
///      sharedStepNames:
///        - the_error_message_should_be_displayed
///        - the_loading_indicator_should_be_displayed
///        - i_tap_the_search_button
///    ```
library;
