import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';

/// Deterministic ids `p1`, `p2`…
NoteIdFactory counterIds([String prefix = 'p']) {
  var count = 0;

  return () => '$prefix${++count}';
}

/// Counts the notifications of [listenable].
class NotifyCounter {
  NotifyCounter(Listenable listenable) {
    listenable.addListener(() => count++);
  }

  int count = 0;
}

/// A widget that keeps a counter in its state, to check that rebuilding around
/// it does not recreate it.
class StatefulProbe extends StatefulWidget {
  const StatefulProbe({super.key, this.size = const Size(40, 40)});

  final Size size;

  @override
  State<StatefulProbe> createState() => StatefulProbeState();
}

class StatefulProbeState extends State<StatefulProbe> {
  /// Set by a test; survives only if the state does.
  int marker = 0;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(size: widget.size);
}
