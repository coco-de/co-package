// Presentation Top-level Widget — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.21.
// BDD: F1 (책 열고 첫 페이지 표시)
//
// 최상위 entry widget. 내부적으로 EpubBookSession을 관리하고 ReflowableEngine
// 또는 FixedLayoutEngine으로 분기. 선택적 사용 — kobic은 자체 BLoC을 통해
// EpubBookSession을 직접 다룬다.

import 'package:flutter/widgets.dart';

import '../../api/epub_source.dart';

class EpubReader extends StatefulWidget {
  const EpubReader({super.key, required this.source});

  final EpubSource source;

  @override
  State<EpubReader> createState() => _EpubReaderState();
}

class _EpubReaderState extends State<EpubReader> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('S1.21');
  }
}
