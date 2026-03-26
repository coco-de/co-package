// 🐦 Flutter imports:
import 'package:flutter/material.dart';

// 🌎 Project imports:
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

final class ScribbleStateBuilder extends StatefulWidget {
  const ScribbleStateBuilder({
    super.key,
    required this.notifier,
    required this.builder,
  });

  final ScribbleModeNotifierBase notifier;
  final ValueWidgetBuilder<ScribbleModeState> builder;

  @override
  State<ScribbleStateBuilder> createState() => _ScribbleStateBuilderState();
}

final class _ScribbleStateBuilderState extends State<ScribbleStateBuilder> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScribbleModeState>(
      valueListenable: widget.notifier,
      builder: widget.builder,
    );
  }
}
