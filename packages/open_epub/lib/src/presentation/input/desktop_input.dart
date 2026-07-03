// Presentation Input — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S3.18 / F8.
// BDD: F8 (데스크톱 키보드 + 마우스 + 우클릭)

import 'package:flutter/widgets.dart';

/// 데스크톱 키보드 + 마우스 휠 + 우클릭 입력을 일관된 콜백으로 변환.
class DesktopInput extends StatefulWidget {
  const DesktopInput({
    super.key,
    required this.child,
    required this.onNextPage,
    required this.onPreviousPage,
    required this.onGoToStart,
    required this.onGoToEnd,
    this.onContextMenu,
  });

  final Widget child;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onGoToStart;
  final VoidCallback onGoToEnd;
  final VoidCallback? onContextMenu;

  @override
  State<DesktopInput> createState() => _DesktopInputState();
}

class _DesktopInputState extends State<DesktopInput> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('S3.18');
  }
}
