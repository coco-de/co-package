import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/utilities/internal/note_utility_button.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_controller.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_key.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_strings.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_style.dart';

/// A calculator: a two-line display above a keypad.
///
/// The upper line shows the evaluated expression while a result is shown, or
/// the error message after a failed evaluation; the lower one reads
/// [NoteCalculatorController.display]. With a bounded height the keys fill it;
/// otherwise each row is [NoteStudyUtilitiesStyle.keyHeight] tall.
class NoteCalculatorView extends StatefulWidget {
  /// A calculator showing [controller], or one it creates and disposes itself.
  const NoteCalculatorView({
    super.key,
    this.controller,
    this.strings = const NoteStudyUtilitiesStrings(),
    this.style = const NoteStudyUtilitiesStyle(),
    this.showScientificKeys = true,
  });

  /// The state to show; the view owns (and disposes) one when `null`.
  final NoteCalculatorController? controller;

  /// Labels and messages.
  final NoteStudyUtilitiesStrings strings;

  /// Colors and sizes.
  final NoteStudyUtilitiesStyle style;

  /// Whether the function and `^` rows are shown (for small windows).
  final bool showScientificKeys;

  /// The keypad rows, top to bottom.
  static const List<List<NoteCalculatorKey>> keyRows = [
    [
      NoteCalculatorKey.memoryClear,
      NoteCalculatorKey.memoryRecall,
      NoteCalculatorKey.memoryAdd,
      NoteCalculatorKey.memorySubtract,
    ],
    [
      NoteCalculatorKey.sqrt,
      NoteCalculatorKey.sin,
      NoteCalculatorKey.cos,
      NoteCalculatorKey.tan,
    ],
    [
      NoteCalculatorKey.log,
      NoteCalculatorKey.ln,
      NoteCalculatorKey.abs,
      NoteCalculatorKey.power,
    ],
    [
      NoteCalculatorKey.pi,
      NoteCalculatorKey.e,
      NoteCalculatorKey.openParenthesis,
      NoteCalculatorKey.closeParenthesis,
    ],
    [
      NoteCalculatorKey.clear,
      NoteCalculatorKey.backspace,
      NoteCalculatorKey.percent,
      NoteCalculatorKey.divide,
    ],
    [
      NoteCalculatorKey.digit7,
      NoteCalculatorKey.digit8,
      NoteCalculatorKey.digit9,
      NoteCalculatorKey.multiply,
    ],
    [
      NoteCalculatorKey.digit4,
      NoteCalculatorKey.digit5,
      NoteCalculatorKey.digit6,
      NoteCalculatorKey.subtract,
    ],
    [
      NoteCalculatorKey.digit1,
      NoteCalculatorKey.digit2,
      NoteCalculatorKey.digit3,
      NoteCalculatorKey.add,
    ],
    [
      NoteCalculatorKey.digit0,
      NoteCalculatorKey.decimalPoint,
      NoteCalculatorKey.equals,
    ],
  ];

  @override
  State<NoteCalculatorView> createState() => _NoteCalculatorViewState();
}

class _NoteCalculatorViewState extends State<NoteCalculatorView> {
  NoteCalculatorController? _owned;

  NoteCalculatorController get _controller =>
      widget.controller ?? (_owned ??= NoteCalculatorController());

  @override
  void didUpdateWidget(NoteCalculatorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && _owned != null) {
      _owned?.dispose();
      _owned = null;
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  List<List<NoteCalculatorKey>> get _rows => widget.showScientificKeys
      ? NoteCalculatorView.keyRows
      : [
          for (final row in NoteCalculatorView.keyRows)
            if (!row.contains(NoteCalculatorKey.sqrt) &&
                !row.contains(NoteCalculatorKey.log))
              row,
        ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final style = widget.style;

    return ColoredBox(
      color: style.background,
      child: Padding(
        padding: EdgeInsets.all(style.spacing),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keypad = _Keypad(
              rows: _rows,
              view: widget,
              controller: controller,
              fill: constraints.hasBoundedHeight,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => _Display(
                    controller: controller,
                    strings: widget.strings,
                    style: style,
                  ),
                ),
                SizedBox(height: style.spacing),
                if (constraints.hasBoundedHeight)
                  Expanded(child: keypad)
                else
                  keypad,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Display extends StatelessWidget {
  const _Display({
    required this.controller,
    required this.strings,
    required this.style,
  });

  final NoteCalculatorController controller;
  final NoteStudyUtilitiesStrings strings;
  final NoteStudyUtilitiesStyle style;

  @override
  Widget build(BuildContext context) {
    final error = controller.error;
    final detail = error != null
        ? strings.calculatorError(error)
        : controller.result != null
        ? '${controller.expression} ='
        : '';

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: style.border),
        borderRadius: BorderRadius.circular(style.cornerRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(style.spacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _detailLine(detail, isError: error != null),
            _mainLine(),
          ],
        ),
      ),
    );
  }

  Widget _detailLine(String detail, {required bool isError}) => Row(
    children: [
      Text(
        controller.hasMemory ? strings.calculatorMemory : '',
        style: style.text(color: style.accent),
      ),
      SizedBox(width: style.spacing),
      Expanded(
        child: Text(
          detail,
          key: const ValueKey('calculator-detail'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: style.text(
            color: isError ? style.danger : style.mutedForeground,
          ),
        ),
      ),
    ],
  );

  Widget _mainLine() => Semantics(
    label: strings.calculatorDisplay,
    value: controller.display,
    liveRegion: true,
    excludeSemantics: true,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        controller.display,
        key: const ValueKey('calculator-display'),
        maxLines: 1,
        style: style.digits(),
      ),
    ),
  );
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.rows,
    required this.view,
    required this.controller,
    required this.fill,
  });

  final List<List<NoteCalculatorKey>> rows;
  final NoteCalculatorView view;
  final NoteCalculatorController controller;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final gap = view.style.spacing / 2;
    final lines = [
      for (final row in rows)
        _KeyRow(keys: row, view: view, controller: controller, gap: gap),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, line) in lines.indexed) ...[
          if (index > 0) SizedBox(height: gap),
          if (fill)
            Expanded(child: line)
          else
            SizedBox(height: view.style.keyHeight, child: line),
        ],
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.keys,
    required this.view,
    required this.controller,
    required this.gap,
  });

  final List<NoteCalculatorKey> keys;
  final NoteCalculatorView view;
  final NoteCalculatorController controller;
  final double gap;

  static NoteUtilityButtonKind _kindOf(NoteCalculatorKey key) {
    if (key == NoteCalculatorKey.equals) return NoteUtilityButtonKind.primary;
    if (key == NoteCalculatorKey.clear) return NoteUtilityButtonKind.danger;

    return key.arithmeticOperator != null
        ? NoteUtilityButtonKind.accentText
        : NoteUtilityButtonKind.secondary;
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, key) in keys.indexed) ...[
        if (index > 0) SizedBox(width: gap),
        Expanded(
          flex: key == NoteCalculatorKey.equals ? 2 : 1,
          child: NoteUtilityButton(
            key: ValueKey(key),
            text: view.strings.calculatorKeyText(key),
            semanticLabel: view.strings.calculatorKeyLabel(key),
            style: view.style,
            kind: _kindOf(key),
            minSize: Size.zero,
            onPressed: () => controller.press(key),
          ),
        ),
      ],
    ],
  );
}
