// A stand-in for a design-system package: design_inspection_test.dart maps
// this directory to a package outside the project, so the widgets built
// here are created by design-system code, as CoUI's are.
import 'package:flutter/widgets.dart';

/// Sizes of the fake components.
enum FakeSize { sm, md, lg }

/// Variants of [FakeButton].
enum FakeVariant { primary, plain }

/// A field that composes a [FakeLabel] above its value, as CoUI's TextField
/// composes a FormLabel.
class FakeField extends StatelessWidget {
  /// Creates the field.
  const FakeField({
    required this.label,
    required this.value,
    super.key,
    this.size = FakeSize.lg,
  });

  /// Label text.
  final String label;

  /// Value text.
  final String value;

  /// Size, passed on to the label.
  final FakeSize size;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FakeLabel(label: label, size: size),
      Text(value),
    ],
  );
}

/// A form label. Like CoUI's FormLabel, its build starts with a widget that
/// Flutter's `DefaultTextStyle.merge` creates.
class FakeLabel extends StatelessWidget {
  /// Creates the label.
  const FakeLabel({required this.label, super.key, this.size = FakeSize.md});

  /// Label text.
  final String label;

  /// Size.
  final FakeSize size;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: const TextStyle(fontWeight: FontWeight.w500),
    child: SizedBox(height: 20, child: Text(label)),
  );
}

/// A toolbar of plain [FakeButton]s, as CoUI's RichEditorToolbar composes
/// Buttons.
class FakeToolbar extends StatelessWidget {
  /// Creates the toolbar.
  const FakeToolbar({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FakeButton(label: 'B', variant: FakeVariant.plain),
      FakeButton(label: 'I', variant: FakeVariant.plain),
      FakeButton(label: 'U', variant: FakeVariant.plain),
    ],
  );
}

/// A button with a variant and a size.
class FakeButton extends StatelessWidget {
  /// Creates the button.
  const FakeButton({
    required this.label,
    super.key,
    this.variant = FakeVariant.primary,
    this.size = FakeSize.md,
  });

  /// Label.
  final String label;

  /// Variant.
  final FakeVariant variant;

  /// Size.
  final FakeSize size;

  @override
  Widget build(BuildContext context) => FakeFocus(
    child: SizedBox.square(dimension: 32, child: Center(child: Text(label))),
  );
}

/// An internal helper that design files never place, as CoUI's Clickable.
class FakeFocus extends StatelessWidget {
  /// Creates the helper.
  const FakeFocus({required this.child, super.key});

  /// Child.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
