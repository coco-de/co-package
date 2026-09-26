import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Screen geometry and platform applied to the test view for one variant.
///
/// [logicalSize] drives layout and `MediaQuery.size`. [devicePixelRatio]
/// converts it to the physical size of the test view and is also the default
/// raster scale of captured images. [platform] becomes
/// `debugDefaultTargetPlatformOverride`, so platform-adaptive widgets and
/// design-system scaling (for example CoUI's mobile scaling) follow the
/// device. [safeArea] is exposed as view padding in logical pixels.
@immutable
final class GoldenDevice {
  /// Creates a device description.
  const GoldenDevice({
    required this.name,
    required this.logicalSize,
    this.devicePixelRatio = 1,
    this.platform = TargetPlatform.android,
    this.safeArea = EdgeInsets.zero,
  });

  /// Narrowest supported phone class: 320×568 at 2x on iOS.
  static const GoldenDevice phoneCompact = GoldenDevice(
    name: 'phone-compact',
    logicalSize: Size(320, 568),
    devicePixelRatio: 2,
    platform: TargetPlatform.iOS,
    safeArea: EdgeInsets.only(top: 20),
  );

  /// Common Android phone baseline: 360×800 at 3x.
  static const GoldenDevice phone = GoldenDevice(
    name: 'phone',
    logicalSize: Size(360, 800),
    devicePixelRatio: 3,
    safeArea: EdgeInsets.only(top: 24),
  );

  /// Modern iPhone with a notch: 393×852 at 3x.
  static const GoldenDevice phoneIos = GoldenDevice(
    name: 'phone-ios',
    logicalSize: Size(393, 852),
    devicePixelRatio: 3,
    platform: TargetPlatform.iOS,
    safeArea: EdgeInsets.only(top: 59, bottom: 34),
  );

  /// Ten-inch Android tablet in portrait: 800×1280 at 2x.
  static const GoldenDevice tablet = GoldenDevice(
    name: 'tablet',
    logicalSize: Size(800, 1280),
    devicePixelRatio: 2,
    safeArea: EdgeInsets.only(top: 24),
  );

  /// Laptop window on macOS: 1280×800 at 2x.
  static const GoldenDevice desktop = GoldenDevice(
    name: 'desktop',
    logicalSize: Size(1280, 800),
    devicePixelRatio: 2,
    platform: TargetPlatform.macOS,
  );

  /// Full HD window on Windows: 1920×1080 at 1x.
  static const GoldenDevice desktopWide = GoldenDevice(
    name: 'desktop-wide',
    logicalSize: Size(1920, 1080),
    platform: TargetPlatform.windows,
  );

  /// Every built-in preset, from the narrowest to the widest.
  static const List<GoldenDevice> presets = [
    phoneCompact,
    phone,
    phoneIos,
    tablet,
    desktop,
    desktopWide,
  ];

  /// Stable device name used in test names, file names, and manifests.
  final String name;

  /// Layout size in logical pixels.
  final Size logicalSize;

  /// Physical pixels per logical pixel.
  final double devicePixelRatio;

  /// Target platform applied while the variant runs.
  final TargetPlatform platform;

  /// System insets (status bar, home indicator) in logical pixels.
  final EdgeInsets safeArea;

  /// Size of the test view in physical pixels.
  Size get physicalSize => logicalSize * devicePixelRatio;

  /// Whether the device is wider than it is tall.
  bool get isLandscape => logicalSize.width > logicalSize.height;

  /// Returns the same device rotated a quarter turn.
  ///
  /// The top inset moves to the left edge and the bottom inset to the right
  /// edge, which matches how phones report insets in landscape.
  GoldenDevice rotated({String? name}) => GoldenDevice(
    name: name ?? '${this.name}-landscape',
    logicalSize: logicalSize.flipped,
    devicePixelRatio: devicePixelRatio,
    platform: platform,
    safeArea: EdgeInsets.only(left: safeArea.top, right: safeArea.bottom),
  );

  /// Returns a copy with the given fields replaced.
  GoldenDevice copyWith({
    String? name,
    Size? logicalSize,
    double? devicePixelRatio,
    TargetPlatform? platform,
    EdgeInsets? safeArea,
  }) => GoldenDevice(
    name: name ?? this.name,
    logicalSize: logicalSize ?? this.logicalSize,
    devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    platform: platform ?? this.platform,
    safeArea: safeArea ?? this.safeArea,
  );

  /// JSON description written to run manifests.
  Map<String, Object?> toJson() => {
    'name': name,
    'logicalSize': [logicalSize.width, logicalSize.height],
    'devicePixelRatio': devicePixelRatio,
    'platform': platform.name,
    'safeArea': [safeArea.left, safeArea.top, safeArea.right, safeArea.bottom],
  };

  @override
  bool operator ==(Object other) =>
      other is GoldenDevice &&
      other.name == name &&
      other.logicalSize == logicalSize &&
      other.devicePixelRatio == devicePixelRatio &&
      other.platform == platform &&
      other.safeArea == safeArea;

  @override
  int get hashCode =>
      Object.hash(name, logicalSize, devicePixelRatio, platform, safeArea);

  @override
  String toString() =>
      'GoldenDevice($name, ${logicalSize.width}×${logicalSize.height} '
      '@${devicePixelRatio}x, ${platform.name})';
}
