// This is a generated file - do not edit.
//
// Generated from scribble.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pointDescriptor instead')
const Point$json = {
  '1': 'Point',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 1, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 1, '10': 'y'},
    {'1': 'p', '3': 3, '4': 1, '5': 1, '10': 'p'},
    {'1': 'altitude', '3': 4, '4': 1, '5': 1, '10': 'altitude'},
    {'1': 'azimuth', '3': 5, '4': 1, '5': 1, '10': 'azimuth'},
    {'1': 'opacity', '3': 6, '4': 1, '5': 1, '10': 'opacity'},
    {'1': 'size', '3': 7, '4': 3, '5': 1, '10': 'size'},
    {
      '1': 'deprecated_timestamp',
      '3': 8,
      '4': 1,
      '5': 1,
      '10': 'deprecatedTimestamp'
    },
    {'1': 'timestamp', '3': 9, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `Point`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pointDescriptor = $convert.base64Decode(
    'CgVQb2ludBIMCgF4GAEgASgBUgF4EgwKAXkYAiABKAFSAXkSDAoBcBgDIAEoAVIBcBIaCghhbH'
    'RpdHVkZRgEIAEoAVIIYWx0aXR1ZGUSGAoHYXppbXV0aBgFIAEoAVIHYXppbXV0aBIYCgdvcGFj'
    'aXR5GAYgASgBUgdvcGFjaXR5EhIKBHNpemUYByADKAFSBHNpemUSMQoUZGVwcmVjYXRlZF90aW'
    '1lc3RhbXAYCCABKAFSE2RlcHJlY2F0ZWRUaW1lc3RhbXASHAoJdGltZXN0YW1wGAkgASgDUgl0'
    'aW1lc3RhbXA=');

@$core.Deprecated('Use segmentDescriptor instead')
const Segment$json = {
  '1': 'Segment',
  '2': [
    {'1': 'start', '3': 1, '4': 1, '5': 11, '6': '.Point', '10': 'start'},
    {'1': 'end', '3': 2, '4': 1, '5': 11, '6': '.Point', '10': 'end'},
    {'1': 'startIndex', '3': 3, '4': 1, '5': 5, '10': 'startIndex'},
    {'1': 'endIndex', '3': 4, '4': 1, '5': 5, '10': 'endIndex'},
    {'1': 'points', '3': 5, '4': 3, '5': 11, '6': '.Point', '10': 'points'},
  ],
};

/// Descriptor for `Segment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List segmentDescriptor = $convert.base64Decode(
    'CgdTZWdtZW50EhwKBXN0YXJ0GAEgASgLMgYuUG9pbnRSBXN0YXJ0EhgKA2VuZBgCIAEoCzIGLl'
    'BvaW50UgNlbmQSHgoKc3RhcnRJbmRleBgDIAEoBVIKc3RhcnRJbmRleBIaCghlbmRJbmRleBgE'
    'IAEoBVIIZW5kSW5kZXgSHgoGcG9pbnRzGAUgAygLMgYuUG9pbnRSBnBvaW50cw==');

@$core.Deprecated('Use strokePointDescriptor instead')
const StrokePoint$json = {
  '1': 'StrokePoint',
  '2': [
    {'1': 'point', '3': 1, '4': 1, '5': 11, '6': '.Point', '10': 'point'},
    {'1': 'vector', '3': 2, '4': 1, '5': 11, '6': '.Point', '10': 'vector'},
    {'1': 'distance', '3': 3, '4': 1, '5': 1, '10': 'distance'},
    {'1': 'runningLength', '3': 4, '4': 1, '5': 1, '10': 'runningLength'},
  ],
};

/// Descriptor for `StrokePoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List strokePointDescriptor = $convert.base64Decode(
    'CgtTdHJva2VQb2ludBIcCgVwb2ludBgBIAEoCzIGLlBvaW50UgVwb2ludBIeCgZ2ZWN0b3IYAi'
    'ABKAsyBi5Qb2ludFIGdmVjdG9yEhoKCGRpc3RhbmNlGAMgASgBUghkaXN0YW5jZRIkCg1ydW5u'
    'aW5nTGVuZ3RoGAQgASgBUg1ydW5uaW5nTGVuZ3Ro');

@$core.Deprecated('Use strokeOptionsDescriptor instead')
const StrokeOptions$json = {
  '1': 'StrokeOptions',
  '2': [
    {'1': 'size', '3': 1, '4': 1, '5': 1, '10': 'size'},
    {'1': 'thinning', '3': 2, '4': 1, '5': 1, '10': 'thinning'},
    {'1': 'smoothing', '3': 3, '4': 1, '5': 1, '10': 'smoothing'},
    {'1': 'streamline', '3': 4, '4': 1, '5': 1, '10': 'streamline'},
    {'1': 'taperStart', '3': 5, '4': 1, '5': 1, '10': 'taperStart'},
    {'1': 'capStart', '3': 6, '4': 1, '5': 8, '10': 'capStart'},
    {'1': 'taperEnd', '3': 7, '4': 1, '5': 1, '10': 'taperEnd'},
    {'1': 'capEnd', '3': 8, '4': 1, '5': 8, '10': 'capEnd'},
    {'1': 'simulatePressure', '3': 9, '4': 1, '5': 8, '10': 'simulatePressure'},
    {'1': 'isComplete', '3': 10, '4': 1, '5': 8, '10': 'isComplete'},
  ],
};

/// Descriptor for `StrokeOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List strokeOptionsDescriptor = $convert.base64Decode(
    'Cg1TdHJva2VPcHRpb25zEhIKBHNpemUYASABKAFSBHNpemUSGgoIdGhpbm5pbmcYAiABKAFSCH'
    'RoaW5uaW5nEhwKCXNtb290aGluZxgDIAEoAVIJc21vb3RoaW5nEh4KCnN0cmVhbWxpbmUYBCAB'
    'KAFSCnN0cmVhbWxpbmUSHgoKdGFwZXJTdGFydBgFIAEoAVIKdGFwZXJTdGFydBIaCghjYXBTdG'
    'FydBgGIAEoCFIIY2FwU3RhcnQSGgoIdGFwZXJFbmQYByABKAFSCHRhcGVyRW5kEhYKBmNhcEVu'
    'ZBgIIAEoCFIGY2FwRW5kEioKEHNpbXVsYXRlUHJlc3N1cmUYCSABKAhSEHNpbXVsYXRlUHJlc3'
    'N1cmUSHgoKaXNDb21wbGV0ZRgKIAEoCFIKaXNDb21wbGV0ZQ==');

@$core.Deprecated('Use strokeDescriptor instead')
const Stroke$json = {
  '1': 'Stroke',
  '2': [
    {'1': 'points', '3': 1, '4': 3, '5': 11, '6': '.Point', '10': 'points'},
    {'1': 'color', '3': 2, '4': 1, '5': 13, '10': 'color'},
    {'1': 'ink', '3': 3, '4': 1, '5': 9, '10': 'ink'},
    {'1': 'createdAt', '3': 4, '4': 1, '5': 9, '10': 'createdAt'},
    {
      '1': 'options',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.StrokeOptions',
      '10': 'options'
    },
    {'1': 'shapeType', '3': 6, '4': 1, '5': 9, '10': 'shapeType'},
    {'1': 'width', '3': 7, '4': 1, '5': 1, '10': 'width'},
    {
      '1': 'segments',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.Segment',
      '10': 'segments'
    },
    {'1': 'confidence', '3': 9, '4': 1, '5': 1, '10': 'confidence'},
  ],
};

/// Descriptor for `Stroke`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List strokeDescriptor = $convert.base64Decode(
    'CgZTdHJva2USHgoGcG9pbnRzGAEgAygLMgYuUG9pbnRSBnBvaW50cxIUCgVjb2xvchgCIAEoDV'
    'IFY29sb3ISEAoDaW5rGAMgASgJUgNpbmsSHAoJY3JlYXRlZEF0GAQgASgJUgljcmVhdGVkQXQS'
    'KAoHb3B0aW9ucxgFIAEoCzIOLlN0cm9rZU9wdGlvbnNSB29wdGlvbnMSHAoJc2hhcGVUeXBlGA'
    'YgASgJUglzaGFwZVR5cGUSFAoFd2lkdGgYByABKAFSBXdpZHRoEiQKCHNlZ21lbnRzGAggAygL'
    'MgguU2VnbWVudFIIc2VnbWVudHMSHgoKY29uZmlkZW5jZRgJIAEoAVIKY29uZmlkZW5jZQ==');

@$core.Deprecated('Use textLinkSpanDescriptor instead')
const TextLinkSpan$json = {
  '1': 'TextLinkSpan',
  '2': [
    {'1': 'start', '3': 1, '4': 1, '5': 5, '10': 'start'},
    {'1': 'end', '3': 2, '4': 1, '5': 5, '10': 'end'},
    {'1': 'url', '3': 3, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `TextLinkSpan`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textLinkSpanDescriptor = $convert.base64Decode(
    'CgxUZXh0TGlua1NwYW4SFAoFc3RhcnQYASABKAVSBXN0YXJ0EhAKA2VuZBgCIAEoBVIDZW5kEh'
    'AKA3VybBgDIAEoCVIDdXJs');

@$core.Deprecated('Use textDrawableDescriptor instead')
const TextDrawable$json = {
  '1': 'TextDrawable',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'x', '3': 3, '4': 1, '5': 1, '10': 'x'},
    {'1': 'y', '3': 4, '4': 1, '5': 1, '10': 'y'},
    {'1': 'fontFamily', '3': 5, '4': 1, '5': 9, '10': 'fontFamily'},
    {'1': 'fontSize', '3': 6, '4': 1, '5': 1, '10': 'fontSize'},
    {'1': 'color', '3': 7, '4': 1, '5': 13, '10': 'color'},
    {'1': 'isBold', '3': 8, '4': 1, '5': 8, '10': 'isBold'},
    {'1': 'isItalic', '3': 9, '4': 1, '5': 8, '10': 'isItalic'},
    {'1': 'isUnderlined', '3': 10, '4': 1, '5': 8, '10': 'isUnderlined'},
    {'1': 'textAlign', '3': 11, '4': 1, '5': 9, '10': 'textAlign'},
    {'1': 'hidden', '3': 12, '4': 1, '5': 8, '10': 'hidden'},
    {'1': 'createdAt', '3': 13, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updatedAt', '3': 14, '4': 1, '5': 9, '10': 'updatedAt'},
    {'1': 'rotation', '3': 15, '4': 1, '5': 1, '10': 'rotation'},
    {
      '1': 'linkSpans',
      '3': 16,
      '4': 3,
      '5': 11,
      '6': '.TextLinkSpan',
      '10': 'linkSpans'
    },
    {'1': 'maxWidth', '3': 17, '4': 1, '5': 1, '10': 'maxWidth'},
  ],
};

/// Descriptor for `TextDrawable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textDrawableDescriptor = $convert.base64Decode(
    'CgxUZXh0RHJhd2FibGUSDgoCaWQYASABKAlSAmlkEhIKBHRleHQYAiABKAlSBHRleHQSDAoBeB'
    'gDIAEoAVIBeBIMCgF5GAQgASgBUgF5Eh4KCmZvbnRGYW1pbHkYBSABKAlSCmZvbnRGYW1pbHkS'
    'GgoIZm9udFNpemUYBiABKAFSCGZvbnRTaXplEhQKBWNvbG9yGAcgASgNUgVjb2xvchIWCgZpc0'
    'JvbGQYCCABKAhSBmlzQm9sZBIaCghpc0l0YWxpYxgJIAEoCFIIaXNJdGFsaWMSIgoMaXNVbmRl'
    'cmxpbmVkGAogASgIUgxpc1VuZGVybGluZWQSHAoJdGV4dEFsaWduGAsgASgJUgl0ZXh0QWxpZ2'
    '4SFgoGaGlkZGVuGAwgASgIUgZoaWRkZW4SHAoJY3JlYXRlZEF0GA0gASgJUgljcmVhdGVkQXQS'
    'HAoJdXBkYXRlZEF0GA4gASgJUgl1cGRhdGVkQXQSGgoIcm90YXRpb24YDyABKAFSCHJvdGF0aW'
    '9uEisKCWxpbmtTcGFucxgQIAMoCzINLlRleHRMaW5rU3BhblIJbGlua1NwYW5zEhoKCG1heFdp'
    'ZHRoGBEgASgBUghtYXhXaWR0aA==');

@$core.Deprecated('Use imageDrawableDescriptor instead')
const ImageDrawable$json = {
  '1': 'ImageDrawable',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'source', '3': 2, '4': 1, '5': 9, '10': 'source'},
    {'1': 'x', '3': 3, '4': 1, '5': 1, '10': 'x'},
    {'1': 'y', '3': 4, '4': 1, '5': 1, '10': 'y'},
    {'1': 'width', '3': 5, '4': 1, '5': 1, '10': 'width'},
    {'1': 'height', '3': 6, '4': 1, '5': 1, '10': 'height'},
    {'1': 'rotation', '3': 7, '4': 1, '5': 1, '10': 'rotation'},
    {'1': 'opacity', '3': 8, '4': 1, '5': 1, '10': 'opacity'},
    {'1': 'hidden', '3': 9, '4': 1, '5': 8, '10': 'hidden'},
    {'1': 'createdAt', '3': 10, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updatedAt', '3': 11, '4': 1, '5': 9, '10': 'updatedAt'},
    {'1': 'naturalWidth', '3': 12, '4': 1, '5': 1, '10': 'naturalWidth'},
    {'1': 'naturalHeight', '3': 13, '4': 1, '5': 1, '10': 'naturalHeight'},
  ],
};

/// Descriptor for `ImageDrawable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageDrawableDescriptor = $convert.base64Decode(
    'Cg1JbWFnZURyYXdhYmxlEg4KAmlkGAEgASgJUgJpZBIWCgZzb3VyY2UYAiABKAlSBnNvdXJjZR'
    'IMCgF4GAMgASgBUgF4EgwKAXkYBCABKAFSAXkSFAoFd2lkdGgYBSABKAFSBXdpZHRoEhYKBmhl'
    'aWdodBgGIAEoAVIGaGVpZ2h0EhoKCHJvdGF0aW9uGAcgASgBUghyb3RhdGlvbhIYCgdvcGFjaX'
    'R5GAggASgBUgdvcGFjaXR5EhYKBmhpZGRlbhgJIAEoCFIGaGlkZGVuEhwKCWNyZWF0ZWRBdBgK'
    'IAEoCVIJY3JlYXRlZEF0EhwKCXVwZGF0ZWRBdBgLIAEoCVIJdXBkYXRlZEF0EiIKDG5hdHVyYW'
    'xXaWR0aBgMIAEoAVIMbmF0dXJhbFdpZHRoEiQKDW5hdHVyYWxIZWlnaHQYDSABKAFSDW5hdHVy'
    'YWxIZWlnaHQ=');

@$core.Deprecated('Use scribbleDescriptor instead')
const Scribble$json = {
  '1': 'Scribble',
  '2': [
    {'1': 'width', '3': 1, '4': 1, '5': 1, '10': 'width'},
    {'1': 'height', '3': 2, '4': 1, '5': 1, '10': 'height'},
    {'1': 'strokes', '3': 3, '4': 3, '5': 11, '6': '.Stroke', '10': 'lines'},
    {'1': 'updatedAt', '3': 4, '4': 1, '5': 9, '10': 'updatedAt'},
    {'1': 'createdAt', '3': 5, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'version', '3': 6, '4': 1, '5': 9, '10': 'version'},
    {'1': 'x', '3': 7, '4': 1, '5': 1, '10': 'x'},
    {'1': 'y', '3': 8, '4': 1, '5': 1, '10': 'y'},
    {
      '1': 'textDrawables',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.TextDrawable',
      '10': 'textDrawables'
    },
    {
      '1': 'imageDrawables',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.ImageDrawable',
      '10': 'imageDrawables'
    },
  ],
  '9': [
    {'1': 11, '2': 12},
    {'1': 12, '2': 13},
  ],
};

/// Descriptor for `Scribble`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scribbleDescriptor = $convert.base64Decode(
    'CghTY3JpYmJsZRIUCgV3aWR0aBgBIAEoAVIFd2lkdGgSFgoGaGVpZ2h0GAIgASgBUgZoZWlnaH'
    'QSHwoHc3Ryb2tlcxgDIAMoCzIHLlN0cm9rZVIFbGluZXMSHAoJdXBkYXRlZEF0GAQgASgJUgl1'
    'cGRhdGVkQXQSHAoJY3JlYXRlZEF0GAUgASgJUgljcmVhdGVkQXQSGAoHdmVyc2lvbhgGIAEoCV'
    'IHdmVyc2lvbhIMCgF4GAcgASgBUgF4EgwKAXkYCCABKAFSAXkSMwoNdGV4dERyYXdhYmxlcxgJ'
    'IAMoCzINLlRleHREcmF3YWJsZVINdGV4dERyYXdhYmxlcxI2Cg5pbWFnZURyYXdhYmxlcxgKIA'
    'MoCzIOLkltYWdlRHJhd2FibGVSDmltYWdlRHJhd2FibGVzSgQICxAMSgQIDBAN');
