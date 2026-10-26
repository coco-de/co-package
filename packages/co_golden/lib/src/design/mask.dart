import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

import 'geometry.dart';

/// An area that the design analysis must not compare, with the reason.
///
/// Mask what changes on every run or what the app does not draw — a live
/// clock, a spinner, a map tile, a status bar — never a difference you would
/// rather not see. Every mask needs a [reason]; it is written to the report.
/// Masks apply to the pixel comparison and to the structural comparison:
/// nodes that lie inside a mask are not matched or reported. When masks
/// cover more than [GoldenDesignTolerance.maxMaskRatio] of the frame, the
/// pixel verdict becomes `undetermined`.
@immutable
sealed class GoldenDesignMask {
  const GoldenDesignMask(this.reason);

  /// A logical rectangle of the frame.
  const factory GoldenDesignMask.rect(Rect rect, {required String reason}) =
      GoldenDesignRectMask;

  /// The bounds of a node of the design specification.
  const factory GoldenDesignMask.figmaNode(
    String nodeId, {
    required String reason,
  }) = GoldenDesignNodeMask;

  /// The rendered bounds of every widget that [finder] finds.
  const factory GoldenDesignMask.finder(
    Finder finder, {
    required String reason,
  }) = GoldenDesignFinderMask;

  /// Why this area is not compared.
  final String reason;
}

/// A [GoldenDesignMask] over a logical rectangle.
final class GoldenDesignRectMask extends GoldenDesignMask {
  /// Creates the mask.
  const GoldenDesignRectMask(this.rect, {required String reason})
    : super(reason);

  /// Masked rectangle in logical pixels.
  final Rect rect;
}

/// A [GoldenDesignMask] over a design node.
final class GoldenDesignNodeMask extends GoldenDesignMask {
  /// Creates the mask.
  const GoldenDesignNodeMask(this.nodeId, {required String reason})
    : super(reason);

  /// Design node id, such as `12:345`.
  final String nodeId;
}

/// A [GoldenDesignMask] over found widgets.
final class GoldenDesignFinderMask extends GoldenDesignMask {
  /// Creates the mask.
  const GoldenDesignFinderMask(this.finder, {required String reason})
    : super(reason);

  /// Finds the widgets whose bounds are masked.
  final Finder finder;
}

/// A mask resolved to a logical rectangle, as written to the report.
@immutable
final class GoldenResolvedMask {
  /// Creates a resolved mask.
  const GoldenResolvedMask(this.rect, this.reason, this.source);

  /// Masked rectangle in logical pixels.
  final GoldenRect rect;

  /// Why the area is masked.
  final String reason;

  /// `safeArea`, `rect`, `figmaNode:<id>`, or `finder:<description>`.
  final String source;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'rect': rect.toJson(),
    'reason': reason,
    'source': source,
  };
}

/// A difference between design and implementation that is known and
/// tracked elsewhere, so it does not fail the design verdict.
///
/// Use it for differences the app cannot fix — a design-system issue that is
/// already reported, or an intentional deviation that design approved — and
/// link the tracking issue. Known differences stay visible in the report and
/// the gallery, marked as known with the [reason] and [issue].
///
/// Every given field must match a finding: [designNode] (design node id),
/// [widget] (widget type such as `Card`), [category] (such as `layout`), and
/// [property] (such as `offset`). At least one must be given.
@immutable
final class GoldenKnownDifference {
  /// Creates a known difference. Throws an [ArgumentError] without a matcher.
  GoldenKnownDifference({
    required this.reason,
    String? designNode,
    this.widget,
    this.category,
    this.property,
    this.issue,
  }) : designNode = designNode?.replaceAll('-', ':') {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'must not be empty');
    }
    if (designNode == null &&
        widget == null &&
        category == null &&
        property == null) {
      throw ArgumentError(
        'A known difference needs designNode, widget, category, or property.',
      );
    }
    final link = issue;
    if (link != null) {
      final uri = Uri.tryParse(link);
      if (uri == null ||
          !const {'http', 'https'}.contains(uri.scheme) ||
          uri.host.isEmpty) {
        throw ArgumentError.value(link, 'issue', 'must be an HTTP(S) URL');
      }
    }
  }

  /// Why the difference is accepted.
  final String reason;

  /// Design node id the difference belongs to; `12-345` (as in Figma URLs)
  /// is read as `12:345`.
  final String? designNode;

  /// Widget type the difference belongs to.
  final String? widget;

  /// Finding category, such as `typography`, `layout`, or `visual`.
  final String? category;

  /// Property inside the category, such as `fontWeight` or `offset`.
  final String? property;

  /// Link to the issue that tracks the difference.
  final String? issue;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'reason': reason,
    if (designNode != null) 'designNode': designNode,
    if (widget != null) 'widget': widget,
    if (category != null) 'category': category,
    if (property != null) 'property': property,
    if (issue != null) 'issue': issue,
  };
}
