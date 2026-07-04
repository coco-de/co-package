// Presentation Input — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story F8.1.
// BDD: F8.1 (모바일 좌/우 스와이프)

import 'package:flutter/widgets.dart';

class TouchInput extends StatelessWidget {
  const TouchInput({
    super.key,
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final Widget child;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('F8.1');
  }
}
