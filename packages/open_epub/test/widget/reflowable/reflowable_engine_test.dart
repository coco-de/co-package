// Story: S1.5 (#11) — ReflowableEngine widget tests
// BDD: F2.1 (Reflowable 본문 렌더), F2.5 (이미지 인라인 + placeholder)

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub_engine/src/api/epub_book.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';
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
      expect(
          find.textContaining('안녕 EPUB', findRichText: true), findsOneWidget);
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
      expect(find.textContaining('done', findRichText: true), findsOneWidget);
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
            xhtmlLoader: (_) async => _wrapXhtml('<img src="missing.png"/>'),
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
      // 연속 스크롤(kobic#7572): 첫 spine부터 로드하되, 뷰포트에 다음 spine이
      // 걸리면 함께 lazy load될 수 있다.
      expect(loaded.first, 'ch01.xhtml');
      expect(find.textContaining('ch01.xhtml', findRichText: true),
          findsOneWidget);
      final state = tester.state<ReflowableEngineState>(
        find.byType(ReflowableEngine),
      );
      expect(state.spineIndex, 0);
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
      expect(find.textContaining('ch02.xhtml', findRichText: true),
          findsOneWidget);
    });

    testWidgets('nextSpine() / previousSpine() 으로 항목 이동', (tester) async {
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml', 'ch03.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            // 각 spine이 뷰포트보다 길어야 스크롤 이동이 관찰된다.
            xhtmlLoader: (href) async => _wrapXhtml(_tallBody(href)),
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
      expect(find.textContaining('ch02.xhtml', findRichText: true),
          findsOneWidget);

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

    testWidgets('연속 세로 스크롤로 다음 spine 진입 시 onSpineChanged 알림 (kobic#7572)',
        (tester) async {
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml', 'ch03.xhtml']);
      final changes = <int>[];
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml(_tallBody(href)),
            onSpineChanged: changes.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 초기 spine에 대해서는 알리지 않는다.
      expect(changes, isEmpty);

      // 세로 드래그로 ch01을 지나 ch02 상단이 뷰포트 top에 오도록 스크롤.
      final list = find.byType(ReflowableEngine);
      while (changes.isEmpty) {
        await tester.drag(list, const Offset(0, -600));
        await tester.pumpAndSettle();
      }
      expect(changes.last, 1);

      final state = tester.state<ReflowableEngineState>(list);
      expect(state.spineIndex, 1);
      expect(find.textContaining('ch02.xhtml', findRichText: true),
          findsOneWidget);
    });

    testWidgets('spine 콘텐츠가 뷰포트보다 짧아도 스크롤로 다음 spine 도달 (dead-end 회귀 방지)',
        (tester) async {
      // kobic#7572 재현 조건: spine 하나가 화면 한 장보다 짧은 책.
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml', 'ch03.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 짧은 spine 3개가 한 뷰포트 안에 연속으로 함께 렌더된다 —
      // 이전 구현(현재 spine만 렌더 + 이동 수단 없음)에서는 불가능했다.
      expect(find.textContaining('ch01.xhtml', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('ch02.xhtml', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('ch03.xhtml', findRichText: true),
          findsOneWidget);
    });

    testWidgets('initialSpineIndex가 범위 초과 시 clamp', (tester) async {
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            initialSpineIndex: 99,
            // 뷰포트보다 긴 본문 — 짧으면 스크롤 위치가 존재하지 않아
            // 연속 스크롤에서 top spine이 0으로 판정된다.
            xhtmlLoader: (href) async => _wrapXhtml(_tallBody(href)),
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

  // open-epub#221 후속 — EpubViewController.nextPage()/previousPage()가
  // 스크롤모드에서도 동작하도록, onPageStepReady로 노출한 step 함수가
  // spine 단위 이동(nextSpine/previousSpine과 동일)을 수행하는지 검증한다.
  // (paged 모드의 ReflowablePageView와 달리 스크롤모드엔 윈도우 개념이 없다.)
  group('ReflowableEngine — onPageStepReady (open-epub#221 후속)', () {
    testWidgets('step(+1)/step(-1)이 spine 단위로 이동한다', (tester) async {
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml', 'ch03.xhtml']);
      Future<void> Function(int direction)? step;
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml(_tallBody(href)),
            onPageStepReady: (s) => step = s,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(step, isNotNull);

      final state = tester.state<ReflowableEngineState>(
        find.byType(ReflowableEngine),
      );
      expect(state.spineIndex, 0);

      await step!(1);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);

      await step!(1);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 2);

      await step!(-1);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);
    });
  });

  group('ReflowableEngine — contentRevision 캐시 무효화 (open-epub#62)', () {
    testWidgets('contentRevision identity 변경 시 spine XHTML 재로드',
        (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      var version = 0;
      var loadCount = 0;
      Future<String> loader(String href) async {
        loadCount++;
        return _wrapXhtml('<p>revision v$version</p>');
      }

      Widget build(Object revision) => _wrap(
            ReflowableEngine(
              book: book,
              xhtmlLoader: loader,
              contentRevision: revision,
            ),
          );

      final rev0 = <String>['r0'];
      await tester.pumpWidget(build(rev0));
      await tester.pumpAndSettle();
      expect(find.textContaining('revision v0', findRichText: true),
          findsOneWidget);
      final loadsAfterFirst = loadCount;

      // 같은 identity → 캐시 유지, 재로드 없음.
      version = 1;
      await tester.pumpWidget(build(rev0));
      await tester.pumpAndSettle();
      expect(find.textContaining('revision v0', findRichText: true),
          findsOneWidget);
      expect(loadCount, loadsAfterFirst);

      // identity 변경 → 캐시 무효화, 새 콘텐츠 렌더.
      await tester.pumpWidget(build(<String>['r1']));
      await tester.pumpAndSettle();
      expect(find.textContaining('revision v1', findRichText: true),
          findsOneWidget);
      expect(loadCount, greaterThan(loadsAfterFirst));
    });

    testWidgets('재로드 동안 직전 콘텐츠 유지(스피너로 무너지지 않음)', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      var delayed = false;
      final gate = Completer<void>();
      Future<String> loader(String href) async {
        if (delayed) await gate.future;
        return _wrapXhtml('<p>${delayed ? 'after' : 'before'} reload</p>');
      }

      Widget build(Object revision) => _wrap(
            ReflowableEngine(
              book: book,
              xhtmlLoader: loader,
              contentRevision: revision,
            ),
          );

      await tester.pumpWidget(build(const ['r0']));
      await tester.pumpAndSettle();
      expect(find.textContaining('before reload', findRichText: true),
          findsOneWidget);

      delayed = true;
      await tester.pumpWidget(build(const ['r1']));
      await tester.pump();
      // 새 로드가 끝나기 전 — 직전 콘텐츠 유지, 스피너 없음.
      expect(find.textContaining('before reload', findRichText: true),
          findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('after reload', findRichText: true),
          findsOneWidget);
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

/// 뷰포트(600px)보다 확실히 긴 본문 — 스크롤/spine 전환 테스트용.
String _tallBody(String href) =>
    '<p>$href</p>${List.filled(40, '<p>filler line</p>').join()}';

EpubBook _fakeBook(List<String> hrefs) => _FakeEpubBook(
      spine: hrefs
          .map((h) => EpubSpineItem(
              idref: h, href: h, mediaType: 'application/xhtml+xml'))
          .toList(growable: false),
    );

class _FakeEpubBook implements EpubBook {
  _FakeEpubBook({required this.spine});
  @override
  final List<EpubSpineItem> spine;
  @override
  EpubMetadata get metadata =>
      const EpubMetadata(title: 'fake', epubVersion: '3.0');
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
