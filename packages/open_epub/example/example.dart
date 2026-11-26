// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:open_epub/open_epub.dart';

// Run with --dart-define=EPUB_URL=https://example.com/book.epub.
void main() {
  const bookUrl = String.fromEnvironment('EPUB_URL');
  runApp(
    MaterialApp(
      home: Scaffold(
        body: bookUrl.isEmpty
            ? const Center(child: Text('Pass an EPUB_URL dart-define.'))
            : EpubReader(source: EpubSource.url(Uri.parse(bookUrl))),
      ),
    ),
  );
}
