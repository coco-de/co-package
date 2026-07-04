// EPUB3 샘플 라이브러리 — 기능별 큐레이션 샘플 목록(marionette 통합테스트 진입).
//
// 각 카드는 `sample-<id>` ValueKey를 달아 marionette가 안정적으로 탭할 수 있다.
// 탭 → ReaderDemoPage(book)으로 해당 샘플을 연다.
import 'package:flutter/material.dart';

import 'reader_demo_page.dart' show ReaderDemoPage;
import 'sample_book.dart';

class SampleLibraryPage extends StatelessWidget {
  const SampleLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB3 샘플 라이브러리'),
        centerTitle: true,
      ),
      body: ListView.separated(
        key: const ValueKey('sample-library-list'),
        padding: const EdgeInsets.all(12),
        itemCount: kSampleBooks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final book = kSampleBooks[i];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              key: ValueKey('sample-${book.id}'),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(book.icon,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              title: Text(book.title, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.subtitle,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  _FeatureChip(label: book.featureTag),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReaderDemoPage(book: book)),
              ),
            ),
          );
        },
      ),
    );
  }
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
