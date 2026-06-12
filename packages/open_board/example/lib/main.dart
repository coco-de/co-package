import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'drawing_demo_page.dart';
import 'epub_annotation_demo_page.dart';
import 'split_drawing_page.dart';

void main() {
  // AI 에이전트 런타임 구동(탭/스크린샷 등) 지원 — 디버그 모드 전용
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  }
  runApp(const OpenBoardExampleApp());
}

class OpenBoardExampleApp extends StatelessWidget {
  const OpenBoardExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Board Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const HomeMenuPage(),
    );
  }
}

/// 데모 선택 홈 메뉴
class HomeMenuPage extends StatelessWidget {
  const HomeMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Board Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DemoCard(
            icon: Icons.draw,
            title: 'Board Demo',
            description: '필기 도구 8종, 다중 페이지, 녹화/리플레이 데모',
            page: DrawingPage(),
          ),
          SizedBox(height: 12),
          _DemoCard(
            icon: Icons.vertical_split,
            title: 'Split Drawing Demo',
            description: '좌우 분할 필기 + 플로팅 필기 도구 패널 데모',
            page: SplitDrawingPage(),
          ),
          SizedBox(height: 12),
          _DemoCard(
            icon: Icons.menu_book,
            title: 'EPUB Annotation Demo',
            description: 'open_epub 리더 위에 페이지 연동 필기 (읽기/필기 모드 토글)',
            page: EpubAnnotationDemoPage(),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget page;

  const _DemoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(icon, color: cs.onPrimaryContainer),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => page),
        ),
      ),
    );
  }
}
