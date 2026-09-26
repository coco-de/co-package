/// Golden matrix testing for Flutter.
///
/// Describe a scenario once and capture it on every combination of devices,
/// themes, locales, and text scales. Theme axes accept any theme type, so
/// design systems that do not use Material themes (for example CoUI) plug in
/// directly, and [SlangGoldenLocalization] switches Slang translations per
/// variant.
///
/// Matrix tests are skipped unless `CO_GOLDEN_MODE` is `capture` (write PNG
/// files and JSON run manifests below `build/co_golden`) or `compare`
/// (compare with baselines next to the test file).
library;

export 'src/coverage.dart';
export 'src/device.dart';
export 'src/environment.dart';
export 'src/fonts.dart';
export 'src/localization.dart';
export 'src/manifest.dart';
export 'src/matrix.dart';
export 'src/naming.dart';
export 'src/pump.dart';
export 'src/theme.dart';
export 'src/variant.dart';
