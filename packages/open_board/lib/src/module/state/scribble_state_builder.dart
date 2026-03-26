// 🐦 Flutter imports:

// 📦 Package imports:
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';

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
    return StateNotifierBuilder<ScribbleModeState>(
      stateNotifier: widget.notifier,
      builder: widget.builder,
    );
  }
}
