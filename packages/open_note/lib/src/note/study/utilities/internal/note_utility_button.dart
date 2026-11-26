import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_style.dart';

/// How prominent a [NoteUtilityButton] is.
enum NoteUtilityButtonKind {
  /// Filled with the accent color.
  primary,

  /// Neutral fill.
  secondary,

  /// Neutral fill with accent text.
  accentText,

  /// Neutral fill with danger text.
  danger,
}

/// A plain button for the study-utility widgets (the package has no design
/// system). Not part of the public API.
class NoteUtilityButton extends StatelessWidget {
  /// A button showing [text] or [icon], disabled while [onPressed] is null.
  const NoteUtilityButton({
    required this.semanticLabel,
    required this.onPressed,
    required this.style,
    super.key,
    this.text,
    this.icon,
    this.kind = NoteUtilityButtonKind.secondary,
    this.minSize = const Size(40, 36),
  }) : assert(text != null || icon != null, 'a button needs text or an icon');

  /// What a screen reader announces.
  final String semanticLabel;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  /// Colors and sizes.
  final NoteStudyUtilitiesStyle style;

  /// The visible label.
  final String? text;

  /// Shown instead of [text] when given.
  final Widget? icon;

  /// How prominent it looks.
  final NoteUtilityButtonKind kind;

  /// The smallest size it takes.
  final Size minSize;

  Color get _fill => kind == NoteUtilityButtonKind.primary
      ? style.accent
      : style.buttonBackground;

  /// The color of text and icons of a button of this [kind].
  Color get foreground => switch (kind) {
    NoteUtilityButtonKind.primary => style.onAccent,
    NoteUtilityButtonKind.secondary => style.foreground,
    NoteUtilityButtonKind.accentText => style.accent,
    NoteUtilityButtonKind.danger => style.danger,
  };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minSize.width,
                minHeight: minSize.height,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _fill,
                  borderRadius: BorderRadius.circular(style.cornerRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: style.spacing),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: icon ?? _label(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label() => Text(
    text!,
    maxLines: 1,
    overflow: TextOverflow.clip,
    softWrap: false,
    textAlign: TextAlign.center,
    style: style.text(color: foreground),
  );
}
