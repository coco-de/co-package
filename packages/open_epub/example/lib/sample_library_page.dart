// EPUB3 샘플 라이브러리 — 기능별 큐레이션 샘플 목록(marionette 통합테스트 진입).
//
// 각 카드는 `sample-<id>` ValueKey를 달아 marionette가 안정적으로 탭할 수 있다.
// 탭 → ReaderDemoPage(book)으로 해당 샘플을 연다.
//
// 저장소에 없는 로컬 전용 픽스처(nohoechan · accessible_epub_3)는 앱 번들에
// 들어 있을 때만 보인다 — 공개 데모(Pages)에서는 열 수 없는 항목을 숨긴다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'i18n/strings.g.dart';
import 'l10n.dart';
import 'reader_demo_page.dart' show ReaderDemoPage;
import 'sample_book.dart';

class SampleLibraryPage extends StatefulWidget {
  const SampleLibraryPage({super.key, this.bundle});

  /// 샘플 자산이 들어 있는지 확인할 번들. 기본은 [rootBundle].
  final AssetBundle? bundle;

  @override
  State<SampleLibraryPage> createState() => _SampleLibraryPageState();
}

class _SampleLibraryPageState extends State<SampleLibraryPage> {
  late final Future<List<SampleBook>> _books = _availableBooks();

  /// 번들에 자산이 있는 샘플만 — 합성 샘플(bytesLoader)은 항상 연다.
  Future<List<SampleBook>> _availableBooks() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(
        widget.bundle ?? rootBundle,
      );
      final assets = manifest.listAssets().toSet();
      return [
        for (final book in kSampleBooks)
          if (book.bytesLoader != null || assets.contains(book.asset)) book,
      ];
    } on Object {
      // 매니페스트를 못 읽으면 전부 보여 준다 — 없는 책은 리더가 안내한다.
      return kSampleBooks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tr;
    return Scaffold(
      appBar: AppBar(title: Text(t.home.library.title), centerTitle: true),
      body: FutureBuilder<List<SampleBook>>(
        future: _books,
        builder: (context, snapshot) {
          final books = snapshot.data;
          if (books == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            key: const ValueKey('sample-library-list'),
            padding: const EdgeInsets.all(12),
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final book = books[i];
              final text = sampleTexts(t, book);
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  key: ValueKey('sample-${book.id}'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      book.icon,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    text.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _FeatureChip(label: text.tag),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReaderDemoPage(book: book),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 샘플의 목록 문구. 책 제목은 고유명이라 원문 그대로 두고, 설명 · 기능 칩만
/// 번역한다. 합성 A4 샘플은 책이 아니라 데모 이름이므로 제목도 번역한다.
({String title, String subtitle, String tag}) sampleTexts(
  Translations t,
  SampleBook book,
) {
  final s = t.samples;
  final (subtitle, tag) = switch (book.id) {
    'nohoechan' => (s.nohoechan.subtitle, s.nohoechan.tag),
    'wasteland' => (s.wasteland.subtitle, s.wasteland.tag),
    'arabic-rtl' => (s.arabicRtl.subtitle, s.arabicRtl.tag),
    'mathml' => (s.mathml.subtitle, s.mathml.tag),
    'vertical' => (s.vertical.subtitle, s.vertical.tag),
    'media-overlay' => (s.mediaOverlay.subtitle, s.mediaOverlay.tag),
    'accessible' => (s.accessible.subtitle, s.accessible.tag),
    'cfi' => (s.cfi.subtitle, s.cfi.tag),
    'fixed-a4' => (s.fixedA4.subtitle, s.fixedA4.tag),
    _ => ('', ''),
  };
  final title = book.id == 'fixed-a4' ? t.home.fixedLayout.title : book.title;
  return (title: title, subtitle: subtitle, tag: tag);
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
