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
///
/// In capture mode, a variant with a [GoldenDesignReference] is compared with
/// its design: a tolerant pixel comparison and, with the design's node data,
/// a structural comparison whose findings name the font, widget, component,
/// and source line that differ ([GoldenDesignAnalysis]).
library;

import 'src/design/analysis.dart';
import 'src/design_reference.dart';

export 'src/coverage.dart';
export 'src/design/analysis.dart' show GoldenDesignAnalysis;
export 'src/design/design_system.dart'
    show
        GoldenCatalogAxis,
        GoldenCatalogComponent,
        GoldenColorTokens,
        GoldenComponentCatalog,
        GoldenComponentIdentity,
        GoldenComponentMapping,
        GoldenComponentResolver,
        GoldenDesignSystem,
        GoldenPropertyReader,
        GoldenTextRole;
export 'src/design/geometry.dart' show GoldenRect;
export 'src/design/mask.dart'
    show
        GoldenDesignFinderMask,
        GoldenDesignMask,
        GoldenDesignNodeMask,
        GoldenDesignRectMask,
        GoldenKnownDifference;
export 'src/design/report.dart'
    show
        GoldenDesignAnalysisSummary,
        GoldenDesignVerdict,
        goldenDesignReportSchema,
        goldenDesignReportSchemaVersion;
export 'src/design/spec.dart'
    show
        GoldenDesignInstance,
        GoldenDesignLayout,
        GoldenDesignNode,
        GoldenDesignPaint,
        GoldenDesignShadow,
        GoldenDesignSource,
        GoldenDesignSpec,
        GoldenDesignText,
        GoldenDesignTextRun,
        GoldenDesignTypography,
        goldenDesignSpecSchema,
        goldenDesignSpecSchemaVersion;
export 'src/design/tolerance.dart' show GoldenDesignTolerance;
export 'src/device.dart';
export 'src/design_comparison.dart';
export 'src/design_reference.dart';
export 'src/environment.dart';
export 'src/fonts.dart';
export 'src/localization.dart';
export 'src/manifest.dart';
export 'src/matrix.dart';
export 'src/naming.dart';
export 'src/pump.dart';
export 'src/theme.dart';
export 'src/variant.dart';
