/// BDD Dual Test Generator — build_runner entry point.
///
/// Generates `.widget_test.dart` and `.patrol_test.dart` from `.feature` files.
library;

import 'package:build/build.dart';
import 'package:co_test_gen/src/generator/dual_test_builder.dart';

/// build_runner entry point.
Builder dualTestBuilder(BuilderOptions options) =>
    DualTestBuilder(options: options);
