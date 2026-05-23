// Presentation Engine — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.5.
// BDD: F2.1 (XHTML 렌더)

import 'package:flutter/widgets.dart';

import '../../../api/epub_book.dart';

class ReflowableEngine extends StatefulWidget {
  const ReflowableEngine({super.key, required this.book});

  final EpubBook book;

  @override
  State<ReflowableEngine> createState() => _ReflowableEngineState();
}

class _ReflowableEngineState extends State<ReflowableEngine> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('S1.5');
  }
}
