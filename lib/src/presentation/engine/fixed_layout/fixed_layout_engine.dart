// Presentation Engine — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.7~S1.9.
// BDD: F3 (Fixed Layout 본문 렌더링)

import 'package:flutter/widgets.dart';

import '../../../api/epub_book.dart';

class FixedLayoutEngine extends StatefulWidget {
  const FixedLayoutEngine({super.key, required this.book});

  final EpubBook book;

  @override
  State<FixedLayoutEngine> createState() => _FixedLayoutEngineState();
}

class _FixedLayoutEngineState extends State<FixedLayoutEngine> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('S1.7');
  }
}
