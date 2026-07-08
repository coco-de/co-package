import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

// open_epub 1.0 데모 진입점. S11.1(#88)에서 레거시 EpubReaderWidget 데모를
// 제거하고, 1.0 코어(EpubBookSession + EpubReader) 데모만 노출한다.
import 'fixed_layout_demo_page.dart' show FixedLayoutDemoPage;
import 'highlight_demo_page.dart' show HighlightDemoPage;
import 'sample_library_page.dart' show SampleLibraryPage;
import 'v1_demo_page.dart' show V1DemoPage;

const bool _isFlutterTest =
    bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

void main() {
  // marionette 통합테스트용 바인딩(디버그 전용). Material IconButton/InkWell 등은
  // 기본 상호작용 위젯으로 감지되고, 데모 컨트롤에는 ValueKey를 부착했다.
  if (kDebugMode && !_isFlutterTest) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
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
          // --- EPUB3 샘플 라이브러리 (marionette 통합테스트 대상) ---
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              key: const ValueKey('demo-sample-library'),
              leading: const Icon(Icons.local_library),
              title: const Text('EPUB3 샘플 라이브러리'),
              subtitle: const Text('RTL·MathML·세로쓰기·Media Overlay·CFI 기능 검증'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SampleLibraryPage()),
              ),
            ),
          ),

          // --- 1.0 코어 데모 ---
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              key: const ValueKey('demo-v1-core'),
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

          // --- Fixed Layout A4 데모 ---
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              key: const ValueKey('demo-fixed-layout-a4'),
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('Fixed Layout A4 데모'),
              subtitle: const Text('pre-paginated 본문을 A4(794×1123) 크기로 렌더'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FixedLayoutDemoPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
