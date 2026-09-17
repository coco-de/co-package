// Story: S1.21 (#37) — ResolvePositionUseCase tests
// BDD: F1.2 (위치 복원), F1.3 (복원 실패 fallback)

import 'package:test/test.dart';
import 'package:open_epub_engine/src/api/epub_position.dart';
import 'package:open_epub_engine/src/data/compat/patch_catalog.dart'
    show PatchedEpubBook;
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub_engine/src/domain/usecase/resolve_position_use_case.dart';

PatchedEpubBook _book({EpubLayout layout = EpubLayout.reflowable}) =>
    PatchedEpubBook(
      metadata: EpubMetadata(
        title: 't',
        epubVersion: '3.0',
        layout: layout,
      ),
      spine: const [
        EpubSpineItem(idref: 'c1', href: 'ch1.xhtml', mediaType: 'x'),
        EpubSpineItem(idref: 'c2', href: 'ch2.xhtml', mediaType: 'x'),
      ],
      outline: EpubOutline.empty,
    );

void main() {
  const resolver = ResolvePositionUseCase();

  test('spineHref 존재 시 그대로 복원 (fallback 아님)', () {
    final target = const EpubReflowablePosition(
      spineHref: 'ch2.xhtml',
      progress: 0.45,
      charOffset: 120,
    );
    final r = resolver.call(_book(), target);
    expect(r.wasFallback, isFalse);
    expect(r.position, target);
  });

  test('spineHref 소실 시 첫 페이지로 fallback (wasFallback=true)', () {
    final target = const EpubReflowablePosition(
      spineHref: 'gone.xhtml',
      progress: 0.9,
      charOffset: 5,
    );
    final r = resolver.call(_book(), target);
    expect(r.wasFallback, isTrue);
    expect(r.position.spineHref, 'ch1.xhtml');
    expect(r.position.progress, 0.0);
    expect(r.position, isA<EpubReflowablePosition>());
  });

  test('target이 없으면 첫 페이지지만 fallback은 아님 (정상 첫 열람)', () {
    final r = resolver.call(_book(), null);
    expect(r.wasFallback, isFalse);
    expect(r.position.spineHref, 'ch1.xhtml');
    expect(r.position.progress, 0.0);
  });

  test('Fixed Layout 책은 EpubFixedPosition으로 fallback', () {
    final r = resolver.call(_book(layout: EpubLayout.fixedLayout), null);
    expect(r.position, isA<EpubFixedPosition>());
  });
}
