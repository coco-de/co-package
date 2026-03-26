// This is a generated file - do not edit.
//
// Generated from scribble.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Point extends $pb.GeneratedMessage {
  factory Point({
    $core.double? x,
    $core.double? y,
    $core.double? p,
    $core.double? altitude,
    $core.double? azimuth,
    $core.double? opacity,
    $core.Iterable<$core.double>? size,
    $core.double? deprecatedTimestamp,
    $fixnum.Int64? timestamp,
  }) {
    final result = create();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (p != null) result.p = p;
    if (altitude != null) result.altitude = altitude;
    if (azimuth != null) result.azimuth = azimuth;
    if (opacity != null) result.opacity = opacity;
    if (size != null) result.size.addAll(size);
    if (deprecatedTimestamp != null)
      result.deprecatedTimestamp = deprecatedTimestamp;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  Point._();

  factory Point.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Point.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Point',
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'x')
    ..aD(2, _omitFieldNames ? '' : 'y')
    ..aD(3, _omitFieldNames ? '' : 'p')
    ..aD(4, _omitFieldNames ? '' : 'altitude')
    ..aD(5, _omitFieldNames ? '' : 'azimuth')
    ..aD(6, _omitFieldNames ? '' : 'opacity')
    ..p<$core.double>(7, _omitFieldNames ? '' : 'size', $pb.PbFieldType.KD)
    ..aD(8, _omitFieldNames ? '' : 'deprecatedTimestamp')
    ..aInt64(9, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Point clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Point copyWith(void Function(Point) updates) =>
      super.copyWith((message) => updates(message as Point)) as Point;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Point create() => Point._();
  @$core.override
  Point createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Point getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Point>(create);
  static Point? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get x => $_getN(0);
  @$pb.TagNumber(1)
  set x($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasX() => $_has(0);
  @$pb.TagNumber(1)
  void clearX() => $_clearField(1);

  /// / The vertical coordinate.
  @$pb.TagNumber(2)
  $core.double get y => $_getN(1);
  @$pb.TagNumber(2)
  set y($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasY() => $_has(1);
  @$pb.TagNumber(2)
  void clearY() => $_clearField(2);

  /// / The pressure for this point.
  @$pb.TagNumber(3)
  $core.double get p => $_getN(2);
  @$pb.TagNumber(3)
  set p($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasP() => $_has(2);
  @$pb.TagNumber(3)
  void clearP() => $_clearField(3);

  /// / The altitude for this point.
  @$pb.TagNumber(4)
  $core.double get altitude => $_getN(3);
  @$pb.TagNumber(4)
  set altitude($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAltitude() => $_has(3);
  @$pb.TagNumber(4)
  void clearAltitude() => $_clearField(4);

  /// / The azimuth for this point.
  @$pb.TagNumber(5)
  $core.double get azimuth => $_getN(4);
  @$pb.TagNumber(5)
  set azimuth($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAzimuth() => $_has(4);
  @$pb.TagNumber(5)
  void clearAzimuth() => $_clearField(5);

  /// / The opacity for this point.
  @$pb.TagNumber(6)
  $core.double get opacity => $_getN(5);
  @$pb.TagNumber(6)
  set opacity($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOpacity() => $_has(5);
  @$pb.TagNumber(6)
  void clearOpacity() => $_clearField(6);

  /// / The sizeV for this point.
  @$pb.TagNumber(7)
  $pb.PbList<$core.double> get size => $_getList(6);

  /// / The timestamp for this point.
  @$pb.TagNumber(8)
  $core.double get deprecatedTimestamp => $_getN(7);
  @$pb.TagNumber(8)
  set deprecatedTimestamp($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDeprecatedTimestamp() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeprecatedTimestamp() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get timestamp => $_getI64(8);
  @$pb.TagNumber(9)
  set timestamp($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTimestamp() => $_has(8);
  @$pb.TagNumber(9)
  void clearTimestamp() => $_clearField(9);
}

class Segment extends $pb.GeneratedMessage {
  factory Segment({
    Point? start,
    Point? end,
    $core.int? startIndex,
    $core.int? endIndex,
    $core.Iterable<Point>? points,
  }) {
    final result = create();
    if (start != null) result.start = start;
    if (end != null) result.end = end;
    if (startIndex != null) result.startIndex = startIndex;
    if (endIndex != null) result.endIndex = endIndex;
    if (points != null) result.points.addAll(points);
    return result;
  }

  Segment._();

  factory Segment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Segment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Segment',
      createEmptyInstance: create)
    ..aOM<Point>(1, _omitFieldNames ? '' : 'start', subBuilder: Point.create)
    ..aOM<Point>(2, _omitFieldNames ? '' : 'end', subBuilder: Point.create)
    ..aI(3, _omitFieldNames ? '' : 'startIndex', protoName: 'startIndex')
    ..aI(4, _omitFieldNames ? '' : 'endIndex', protoName: 'endIndex')
    ..pPM<Point>(5, _omitFieldNames ? '' : 'points', subBuilder: Point.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Segment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Segment copyWith(void Function(Segment) updates) =>
      super.copyWith((message) => updates(message as Segment)) as Segment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Segment create() => Segment._();
  @$core.override
  Segment createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Segment getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Segment>(create);
  static Segment? _defaultInstance;

  @$pb.TagNumber(1)
  Point get start => $_getN(0);
  @$pb.TagNumber(1)
  set start(Point value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);
  @$pb.TagNumber(1)
  Point ensureStart() => $_ensure(0);

  @$pb.TagNumber(2)
  Point get end => $_getN(1);
  @$pb.TagNumber(2)
  set end(Point value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => $_clearField(2);
  @$pb.TagNumber(2)
  Point ensureEnd() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get startIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set startIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStartIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartIndex() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get endIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set endIndex($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEndIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndIndex() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Point> get points => $_getList(4);
}

class StrokePoint extends $pb.GeneratedMessage {
  factory StrokePoint({
    Point? point,
    Point? vector,
    $core.double? distance,
    $core.double? runningLength,
  }) {
    final result = create();
    if (point != null) result.point = point;
    if (vector != null) result.vector = vector;
    if (distance != null) result.distance = distance;
    if (runningLength != null) result.runningLength = runningLength;
    return result;
  }

  StrokePoint._();

  factory StrokePoint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StrokePoint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StrokePoint',
      createEmptyInstance: create)
    ..aOM<Point>(1, _omitFieldNames ? '' : 'point', subBuilder: Point.create)
    ..aOM<Point>(2, _omitFieldNames ? '' : 'vector', subBuilder: Point.create)
    ..aD(3, _omitFieldNames ? '' : 'distance')
    ..aD(4, _omitFieldNames ? '' : 'runningLength', protoName: 'runningLength')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StrokePoint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StrokePoint copyWith(void Function(StrokePoint) updates) =>
      super.copyWith((message) => updates(message as StrokePoint))
          as StrokePoint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StrokePoint create() => StrokePoint._();
  @$core.override
  StrokePoint createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StrokePoint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StrokePoint>(create);
  static StrokePoint? _defaultInstance;

  @$pb.TagNumber(1)
  Point get point => $_getN(0);
  @$pb.TagNumber(1)
  set point(Point value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPoint() => $_has(0);
  @$pb.TagNumber(1)
  void clearPoint() => $_clearField(1);
  @$pb.TagNumber(1)
  Point ensurePoint() => $_ensure(0);

  @$pb.TagNumber(2)
  Point get vector => $_getN(1);
  @$pb.TagNumber(2)
  set vector(Point value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasVector() => $_has(1);
  @$pb.TagNumber(2)
  void clearVector() => $_clearField(2);
  @$pb.TagNumber(2)
  Point ensureVector() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.double get distance => $_getN(2);
  @$pb.TagNumber(3)
  set distance($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDistance() => $_has(2);
  @$pb.TagNumber(3)
  void clearDistance() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get runningLength => $_getN(3);
  @$pb.TagNumber(4)
  set runningLength($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRunningLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearRunningLength() => $_clearField(4);
}

class StrokeOptions extends $pb.GeneratedMessage {
  factory StrokeOptions({
    $core.double? size,
    $core.double? thinning,
    $core.double? smoothing,
    $core.double? streamline,
    $core.double? taperStart,
    $core.bool? capStart,
    $core.double? taperEnd,
    $core.bool? capEnd,
    $core.bool? simulatePressure,
    $core.bool? isComplete,
  }) {
    final result = create();
    if (size != null) result.size = size;
    if (thinning != null) result.thinning = thinning;
    if (smoothing != null) result.smoothing = smoothing;
    if (streamline != null) result.streamline = streamline;
    if (taperStart != null) result.taperStart = taperStart;
    if (capStart != null) result.capStart = capStart;
    if (taperEnd != null) result.taperEnd = taperEnd;
    if (capEnd != null) result.capEnd = capEnd;
    if (simulatePressure != null) result.simulatePressure = simulatePressure;
    if (isComplete != null) result.isComplete = isComplete;
    return result;
  }

  StrokeOptions._();

  factory StrokeOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StrokeOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StrokeOptions',
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'size')
    ..aD(2, _omitFieldNames ? '' : 'thinning')
    ..aD(3, _omitFieldNames ? '' : 'smoothing')
    ..aD(4, _omitFieldNames ? '' : 'streamline')
    ..aD(5, _omitFieldNames ? '' : 'taperStart', protoName: 'taperStart')
    ..aOB(6, _omitFieldNames ? '' : 'capStart', protoName: 'capStart')
    ..aD(7, _omitFieldNames ? '' : 'taperEnd', protoName: 'taperEnd')
    ..aOB(8, _omitFieldNames ? '' : 'capEnd', protoName: 'capEnd')
    ..aOB(9, _omitFieldNames ? '' : 'simulatePressure',
        protoName: 'simulatePressure')
    ..aOB(10, _omitFieldNames ? '' : 'isComplete', protoName: 'isComplete')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StrokeOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StrokeOptions copyWith(void Function(StrokeOptions) updates) =>
      super.copyWith((message) => updates(message as StrokeOptions))
          as StrokeOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StrokeOptions create() => StrokeOptions._();
  @$core.override
  StrokeOptions createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StrokeOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StrokeOptions>(create);
  static StrokeOptions? _defaultInstance;

  /// / The base size (diameter) of the stroke.
  @$pb.TagNumber(1)
  $core.double get size => $_getN(0);
  @$pb.TagNumber(1)
  set size($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSize() => $_has(0);
  @$pb.TagNumber(1)
  void clearSize() => $_clearField(1);

  /// / The effect of pressure on the stroke's size.
  @$pb.TagNumber(2)
  $core.double get thinning => $_getN(1);
  @$pb.TagNumber(2)
  set thinning($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasThinning() => $_has(1);
  @$pb.TagNumber(2)
  void clearThinning() => $_clearField(2);

  /// / Controls the density of points along the stroke's edges.
  @$pb.TagNumber(3)
  $core.double get smoothing => $_getN(2);
  @$pb.TagNumber(3)
  set smoothing($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSmoothing() => $_has(2);
  @$pb.TagNumber(3)
  void clearSmoothing() => $_clearField(3);

  /// / Controls the level of variation allowed in the input points.
  @$pb.TagNumber(4)
  $core.double get streamline => $_getN(3);
  @$pb.TagNumber(4)
  set streamline($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStreamline() => $_has(3);
  @$pb.TagNumber(4)
  void clearStreamline() => $_clearField(4);

  /// The distance to taper the front of the stroke.
  @$pb.TagNumber(5)
  $core.double get taperStart => $_getN(4);
  @$pb.TagNumber(5)
  set taperStart($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTaperStart() => $_has(4);
  @$pb.TagNumber(5)
  void clearTaperStart() => $_clearField(5);

  /// Whether to add a cap to the start of the stroke.
  @$pb.TagNumber(6)
  $core.bool get capStart => $_getBF(5);
  @$pb.TagNumber(6)
  set capStart($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCapStart() => $_has(5);
  @$pb.TagNumber(6)
  void clearCapStart() => $_clearField(6);

  /// The distance to taper the end of the stroke.
  @$pb.TagNumber(7)
  $core.double get taperEnd => $_getN(6);
  @$pb.TagNumber(7)
  set taperEnd($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTaperEnd() => $_has(6);
  @$pb.TagNumber(7)
  void clearTaperEnd() => $_clearField(7);

  /// Whether to add a cap to the end of the stroke.
  @$pb.TagNumber(8)
  $core.bool get capEnd => $_getBF(7);
  @$pb.TagNumber(8)
  set capEnd($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCapEnd() => $_has(7);
  @$pb.TagNumber(8)
  void clearCapEnd() => $_clearField(8);

  /// Whether to simulate pressure or use the point's provided pressures.
  @$pb.TagNumber(9)
  $core.bool get simulatePressure => $_getBF(8);
  @$pb.TagNumber(9)
  set simulatePressure($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSimulatePressure() => $_has(8);
  @$pb.TagNumber(9)
  void clearSimulatePressure() => $_clearField(9);

  /// Whether the line is complete.
  @$pb.TagNumber(10)
  $core.bool get isComplete => $_getBF(9);
  @$pb.TagNumber(10)
  set isComplete($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsComplete() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsComplete() => $_clearField(10);
}

class Stroke extends $pb.GeneratedMessage {
  factory Stroke({
    $core.Iterable<Point>? points,
    $core.int? color,
    $core.String? ink,
    $core.String? createdAt,
    StrokeOptions? options,
    $core.String? shapeType,
    $core.double? width,
    $core.Iterable<Segment>? segments,
    $core.double? confidence,
  }) {
    final result = create();
    if (points != null) result.points.addAll(points);
    if (color != null) result.color = color;
    if (ink != null) result.ink = ink;
    if (createdAt != null) result.createdAt = createdAt;
    if (options != null) result.options = options;
    if (shapeType != null) result.shapeType = shapeType;
    if (width != null) result.width = width;
    if (segments != null) result.segments.addAll(segments);
    if (confidence != null) result.confidence = confidence;
    return result;
  }

  Stroke._();

  factory Stroke.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Stroke.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Stroke',
      createEmptyInstance: create)
    ..pPM<Point>(1, _omitFieldNames ? '' : 'points', subBuilder: Point.create)
    ..aI(2, _omitFieldNames ? '' : 'color', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'ink')
    ..aOS(4, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..aOM<StrokeOptions>(5, _omitFieldNames ? '' : 'options',
        subBuilder: StrokeOptions.create)
    ..aOS(6, _omitFieldNames ? '' : 'shapeType', protoName: 'shapeType')
    ..aD(7, _omitFieldNames ? '' : 'width')
    ..pPM<Segment>(8, _omitFieldNames ? '' : 'segments',
        subBuilder: Segment.create)
    ..aD(9, _omitFieldNames ? '' : 'confidence')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stroke clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stroke copyWith(void Function(Stroke) updates) =>
      super.copyWith((message) => updates(message as Stroke)) as Stroke;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Stroke create() => Stroke._();
  @$core.override
  Stroke createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Stroke getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Stroke>(create);
  static Stroke? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Point> get points => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get color => $_getIZ(1);
  @$pb.TagNumber(2)
  set color($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearColor() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get ink => $_getSZ(2);
  @$pb.TagNumber(3)
  set ink($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInk() => $_has(2);
  @$pb.TagNumber(3)
  void clearInk() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get createdAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set createdAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);

  @$pb.TagNumber(5)
  StrokeOptions get options => $_getN(4);
  @$pb.TagNumber(5)
  set options(StrokeOptions value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOptions() => $_has(4);
  @$pb.TagNumber(5)
  void clearOptions() => $_clearField(5);
  @$pb.TagNumber(5)
  StrokeOptions ensureOptions() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get shapeType => $_getSZ(5);
  @$pb.TagNumber(6)
  set shapeType($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasShapeType() => $_has(5);
  @$pb.TagNumber(6)
  void clearShapeType() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get width => $_getN(6);
  @$pb.TagNumber(7)
  set width($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasWidth() => $_has(6);
  @$pb.TagNumber(7)
  void clearWidth() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<Segment> get segments => $_getList(7);

  @$pb.TagNumber(9)
  $core.double get confidence => $_getN(8);
  @$pb.TagNumber(9)
  set confidence($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasConfidence() => $_has(8);
  @$pb.TagNumber(9)
  void clearConfidence() => $_clearField(9);
}

class TextDrawable extends $pb.GeneratedMessage {
  factory TextDrawable({
    $core.String? id,
    $core.String? text,
    $core.double? x,
    $core.double? y,
    $core.String? fontFamily,
    $core.double? fontSize,
    $core.int? color,
    $core.bool? isBold,
    $core.bool? isItalic,
    $core.bool? isUnderlined,
    $core.String? textAlign,
    $core.bool? hidden,
    $core.String? createdAt,
    $core.String? updatedAt,
    $core.double? rotation,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (text != null) result.text = text;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (fontFamily != null) result.fontFamily = fontFamily;
    if (fontSize != null) result.fontSize = fontSize;
    if (color != null) result.color = color;
    if (isBold != null) result.isBold = isBold;
    if (isItalic != null) result.isItalic = isItalic;
    if (isUnderlined != null) result.isUnderlined = isUnderlined;
    if (textAlign != null) result.textAlign = textAlign;
    if (hidden != null) result.hidden = hidden;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (rotation != null) result.rotation = rotation;
    return result;
  }

  TextDrawable._();

  factory TextDrawable.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TextDrawable.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextDrawable',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aD(3, _omitFieldNames ? '' : 'x')
    ..aD(4, _omitFieldNames ? '' : 'y')
    ..aOS(5, _omitFieldNames ? '' : 'fontFamily', protoName: 'fontFamily')
    ..aD(6, _omitFieldNames ? '' : 'fontSize', protoName: 'fontSize')
    ..aI(7, _omitFieldNames ? '' : 'color', fieldType: $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'isBold', protoName: 'isBold')
    ..aOB(9, _omitFieldNames ? '' : 'isItalic', protoName: 'isItalic')
    ..aOB(10, _omitFieldNames ? '' : 'isUnderlined', protoName: 'isUnderlined')
    ..aOS(11, _omitFieldNames ? '' : 'textAlign', protoName: 'textAlign')
    ..aOB(12, _omitFieldNames ? '' : 'hidden')
    ..aOS(13, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..aOS(14, _omitFieldNames ? '' : 'updatedAt', protoName: 'updatedAt')
    ..aD(15, _omitFieldNames ? '' : 'rotation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextDrawable clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextDrawable copyWith(void Function(TextDrawable) updates) =>
      super.copyWith((message) => updates(message as TextDrawable))
          as TextDrawable;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextDrawable create() => TextDrawable._();
  @$core.override
  TextDrawable createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TextDrawable getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TextDrawable>(create);
  static TextDrawable? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get x => $_getN(2);
  @$pb.TagNumber(3)
  set x($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasX() => $_has(2);
  @$pb.TagNumber(3)
  void clearX() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get y => $_getN(3);
  @$pb.TagNumber(4)
  set y($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasY() => $_has(3);
  @$pb.TagNumber(4)
  void clearY() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get fontFamily => $_getSZ(4);
  @$pb.TagNumber(5)
  set fontFamily($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFontFamily() => $_has(4);
  @$pb.TagNumber(5)
  void clearFontFamily() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get fontSize => $_getN(5);
  @$pb.TagNumber(6)
  set fontSize($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFontSize() => $_has(5);
  @$pb.TagNumber(6)
  void clearFontSize() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get color => $_getIZ(6);
  @$pb.TagNumber(7)
  set color($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasColor() => $_has(6);
  @$pb.TagNumber(7)
  void clearColor() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isBold => $_getBF(7);
  @$pb.TagNumber(8)
  set isBold($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsBold() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsBold() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isItalic => $_getBF(8);
  @$pb.TagNumber(9)
  set isItalic($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIsItalic() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsItalic() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isUnderlined => $_getBF(9);
  @$pb.TagNumber(10)
  set isUnderlined($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsUnderlined() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsUnderlined() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get textAlign => $_getSZ(10);
  @$pb.TagNumber(11)
  set textAlign($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasTextAlign() => $_has(10);
  @$pb.TagNumber(11)
  void clearTextAlign() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get hidden => $_getBF(11);
  @$pb.TagNumber(12)
  set hidden($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasHidden() => $_has(11);
  @$pb.TagNumber(12)
  void clearHidden() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get createdAt => $_getSZ(12);
  @$pb.TagNumber(13)
  set createdAt($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCreatedAt() => $_has(12);
  @$pb.TagNumber(13)
  void clearCreatedAt() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get updatedAt => $_getSZ(13);
  @$pb.TagNumber(14)
  set updatedAt($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasUpdatedAt() => $_has(13);
  @$pb.TagNumber(14)
  void clearUpdatedAt() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.double get rotation => $_getN(14);
  @$pb.TagNumber(15)
  set rotation($core.double value) => $_setDouble(14, value);
  @$pb.TagNumber(15)
  $core.bool hasRotation() => $_has(14);
  @$pb.TagNumber(15)
  void clearRotation() => $_clearField(15);
}

class Scribble extends $pb.GeneratedMessage {
  factory Scribble({
    $core.double? width,
    $core.double? height,
    $core.Iterable<Stroke>? strokes,
    $core.String? updatedAt,
    $core.String? createdAt,
    $core.String? version,
    $core.double? x,
    $core.double? y,
    $core.Iterable<TextDrawable>? textDrawables,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (strokes != null) result.strokes.addAll(strokes);
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (createdAt != null) result.createdAt = createdAt;
    if (version != null) result.version = version;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (textDrawables != null) result.textDrawables.addAll(textDrawables);
    return result;
  }

  Scribble._();

  factory Scribble.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Scribble.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Scribble',
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'width')
    ..aD(2, _omitFieldNames ? '' : 'height')
    ..pPM<Stroke>(3, _omitFieldNames ? '' : 'lines',
        protoName: 'strokes', subBuilder: Stroke.create)
    ..aOS(4, _omitFieldNames ? '' : 'updatedAt', protoName: 'updatedAt')
    ..aOS(5, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..aOS(6, _omitFieldNames ? '' : 'version')
    ..aD(7, _omitFieldNames ? '' : 'x')
    ..aD(8, _omitFieldNames ? '' : 'y')
    ..pPM<TextDrawable>(9, _omitFieldNames ? '' : 'textDrawables',
        protoName: 'textDrawables', subBuilder: TextDrawable.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Scribble clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Scribble copyWith(void Function(Scribble) updates) =>
      super.copyWith((message) => updates(message as Scribble)) as Scribble;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Scribble create() => Scribble._();
  @$core.override
  Scribble createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Scribble getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Scribble>(create);
  static Scribble? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get width => $_getN(0);
  @$pb.TagNumber(1)
  set width($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get height => $_getN(1);
  @$pb.TagNumber(2)
  set height($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Stroke> get strokes => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get updatedAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set updatedAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdatedAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get createdAt => $_getSZ(4);
  @$pb.TagNumber(5)
  set createdAt($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get version => $_getSZ(5);
  @$pb.TagNumber(6)
  set version($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersion() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get x => $_getN(6);
  @$pb.TagNumber(7)
  set x($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasX() => $_has(6);
  @$pb.TagNumber(7)
  void clearX() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get y => $_getN(7);
  @$pb.TagNumber(8)
  set y($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasY() => $_has(7);
  @$pb.TagNumber(8)
  void clearY() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<TextDrawable> get textDrawables => $_getList(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
