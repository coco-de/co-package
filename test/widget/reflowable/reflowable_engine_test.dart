// Story: S1.5 (#11) — ReflowableEngine widget tests
// BDD: F2.1 (Reflowable 본문 렌더), F2.5 (이미지 인라인 + placeholder)

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_book.dart';
import 'package:open_epub/src/domain/entity/epub_metadata.dart';
import 'package:open_epub/src/domain/entity/epub_outline.dart';
import 'package:open_epub/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';

void main() {
  group('ReflowableEngine — XHTML 렌더 (BDD F2.1)', () {
    testWidgets('단일 spine 항목의 본문 텍스트 표시', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml('<p>안녕 EPUB</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('안녕 EPUB'), findsOneWidget);
    });

    testWidgets('로딩 중 CircularProgressIndicator 표시', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      final completer = _DelayedLoader();
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(book: book, xhtmlLoader: completer.load),
        ),
      );
      // 첫 frame은 로딩 상태
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete('<p>done</p>');
      await tester.pumpAndSettle();
      expect(find.textContaining('done'), findsOneWidget);
    });

    testWidgets('xhtmlLoader가 throw 시 에러 메시지 표시', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (_) async => throw Exception('I/O failure'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('본문을 불러올 수 없습니다'), findsOneWidget);
      expect(find.textContaining('I/O failure'), findsOneWidget);
    });

    testWidgets('spine이 비어 있으면 empty state', (tester) async {
      final book = _fakeBook([]);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (_) async => '',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('표시할 내용이 없습니다'), findsOneWidget);
    });
  });

  group('ReflowableEngine — 이미지 인라인 + placeholder (BDD F2.5)', () {
    testWidgets('img src의 이미지 로드 성공 시 Image.memory 표시', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      final pngBytes = _onePixelPng();
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (_) async => _wrapXhtml(
              '<p>before</p><img src="fig1.png"/><p>after</p>',
            ),
            imageLoader: (src) async => pngBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);
    });

    testWidgets('imageLoader가 null 반환 시 placeholder 표시', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (_) async =>
                _wrapXhtml('<img src="missing.png"/>'),
            imageLoader: (_) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('imageLoader가 throw 시 placeholder 표시', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (_) async => _wrapXhtml('<img src="broken.png"/>'),
            imageLoader: (_) async => throw Exception('network error'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('imageLoader 미제공 시 placeholder 표시', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (_) async => _wrapXhtml('<img src="x.png"/>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('img src 빈 문자열은 placeholder', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (_) async => _wrapXhtml('<img src=""/>'),
            imageLoader: (_) async => _onePixelPng(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });
  });

  group('ReflowableEngine — spine 이동', () {
    testWidgets('initialSpineIndex가 책 spine 첫 항목 (default 0)', (tester) async {
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml']);
      final loaded = <String>[];
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (href) async {
              loaded.add(href);
              return _wrapXhtml('<p>$href</p>');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(loaded, ['ch01.xhtml']);
      expect(find.textContaining('ch01.xhtml'), findsOneWidget);
    });

    testWidgets('initialSpineIndex 직접 지정', (tester) async {
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            initialSpineIndex: 1,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('ch02.xhtml'), findsOneWidget);
    });

    testWidgets('nextSpine() / previousSpine() 으로 항목 이동', (tester) async {
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml', 'ch03.xhtml']);
      final loaded = <String>[];
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (href) async {
              loaded.add(href);
              return _wrapXhtml('<p>$href</p>');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<ReflowableEngineState>(
        find.byType(ReflowableEngine),
      );

      expect(state.spineIndex, 0);
      expect(state.spineCount, 3);

      expect(state.nextSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);
      expect(find.textContaining('ch02.xhtml'), findsOneWidget);

      expect(state.nextSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 2);

      // 끝 도달 후 nextSpine는 false
      expect(state.nextSpine(), isFalse);

      expect(state.previousSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);

      expect(state.previousSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 0);

      // 시작 도달 후 previousSpine는 false
      expect(state.previousSpine(), isFalse);
    });

    testWidgets('initialSpineIndex가 범위 초과 시 clamp', (tester) async {
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            initialSpineIndex: 99,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowableEngineState>(
        find.byType(ReflowableEngine),
      );
      expect(state.spineIndex, 1); // last valid
    });
  });
}

// -------- helpers --------

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
    );

String _wrapXhtml(String body) => '''
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"><body>$body</body></html>
''';

EpubBook _fakeBook(List<String> hrefs) => _FakeEpubBook(
      spine: hrefs
          .map((h) => EpubSpineItem(idref: h, href: h, mediaType: 'application/xhtml+xml'))
          .toList(growable: false),
    );

class _FakeEpubBook implements EpubBook {
  _FakeEpubBook({required this.spine});
  @override
  final List<EpubSpineItem> spine;
  @override
  EpubMetadata get metadata => const EpubMetadata(title: 'fake', epubVersion: '3.0');
  @override
  EpubOutline get outline => EpubOutline.empty;
  @override
  EpubLayout get layout => EpubLayout.reflowable;
}

class _DelayedLoader {
  final List<Completer<String>> _completers = [];
  Future<String> load(String href) {
    final c = Completer<String>();
    _completers.add(c);
    return c.future;
  }
  void complete(String value) {
    for (final c in _completers) {
      if (!c.isCompleted) c.complete(value);
    }
  }
}

/// 1×1 red PNG (smallest valid PNG)
Uint8List _onePixelPng() => Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG sig
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0x99, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x5B, 0xFE, 0xB1,
      0xCC, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
      0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
