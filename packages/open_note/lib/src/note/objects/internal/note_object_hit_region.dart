import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lets pointers through everywhere except where [isTarget] says an object (or
/// a grip) is.
///
/// Over a target the child is hit-tested as usual; with [claimsTargets] the
/// region also takes the pointer when the child ignores it (edit mode), and
/// without it the pointer then falls through to what is beneath (view mode).
class NoteObjectHitRegion extends SingleChildRenderObjectWidget {
  const NoteObjectHitRegion({
    required this.isTarget,
    required this.claimsTargets,
    required Widget super.child,
    super.key,
  });

  /// Whether something is at this local position.
  final bool Function(Offset position) isTarget;

  /// Whether a target is taken even if no child takes it.
  final bool claimsTargets;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderNoteObjectHitRegion(isTarget, claimsTargets: claimsTargets);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderNoteObjectHitRegion renderObject,
  ) {
    renderObject
      ..isTarget = isTarget
      ..claimsTargets = claimsTargets;
  }
}

/// The render object of [NoteObjectHitRegion].
class RenderNoteObjectHitRegion extends RenderProxyBox {
  /// Whether something is at this local position.
  bool Function(Offset position) isTarget;

  /// Whether a target is taken even if no child takes it.
  bool claimsTargets;

  RenderNoteObjectHitRegion(this.isTarget, {required this.claimsTargets});

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position) || !isTarget(position)) return false;
    final childHit = hitTestChildren(result, position: position);
    if (!childHit && !claimsTargets) return false;
    result.add(BoxHitTestEntry(this, position));

    return true;
  }
}
