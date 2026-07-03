import 'package:flutter/material.dart';

// open_epub 1.0 데모 진입점. S11.1(#88)에서 레거시 EpubReaderWidget 데모를
// 제거하고, 1.0 코어(EpubBookSession + EpubReader) 데모만 노출한다.
import 'highlight_demo_page.dart' show HighlightDemoPage;
import 'v1_demo_page.dart' show V1DemoPage;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'open_epub Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// Home: 1.0 데모 런처
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('open_epub Demo'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- 1.0 코어 데모 ---
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text('1.0 코어 데모'),
              subtitle: const Text('EpubBookSession + EpubReader'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const V1DemoPage()),
              ),
            ),
          ),

          // --- 하이라이트 데모 (#43) ---
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.border_color_outlined),
              title: const Text('하이라이트 데모'),
              subtitle: const Text('텍스트 선택 → 색상 → 하이라이트 + 메모'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HighlightDemoPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
