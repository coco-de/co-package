// EPUB3 기능 검증용 샘플 카탈로그.
//
// IDPF/W3C 공식 epub3-samples(20230704 릴리스) + 실제 EPUB2(노회찬평전)를
// 우리 리더의 E10~E15 기능별로 밟도록 큐레이션했다. 각 항목은 리더에 적용할
// 기본 설정(autoRtl 등)을 갖고, 어떤 기능을 검증하는지(설명 · 기능 칩)는 번역
// 파일의 `samples.<id>` 에 있다(11개 언어, co-package#44).
//
// 자산 8종 중 라이선스가 명확한 6종(georgia-cfi·linear-algebra·moby-dick-mo·
// mymedia_lite·regime-anticancer-arabic·wasteland)은 `.gitignore`에서
// 예외 처리되어 저장소에 실제로 커밋돼 있다(#248, 고지는 THIRD_PARTY_LICENSES
// 참조). 나머지 2종(nohoechan, accessible_epub_3)은 저작권 사유로 여전히
// `*.epub` gitignore 규칙을 따르는 로컬 전용 픽스처다 — 부재 시 리더가
// 안내 메시지를 표시한다(reader_demo_page.dart).
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'demo_epub.dart' show buildFixedLayoutA4DemoEpub;

/// 샘플 EPUB 한 권의 카탈로그 항목.
class SampleBook {
  const SampleBook({
    required this.id,
    this.asset,
    this.bytesLoader,
    required this.title,
    required this.icon,
    this.autoRtl = false,
    this.autoVertical = false,
    this.hasMediaOverlay = false,
  }) : assert(
         asset != null || bytesLoader != null,
         'asset 또는 bytesLoader 중 하나는 있어야 한다',
       );

  /// marionette ValueKey/화면 식별용 짧은 슬러그.
  final String id;

  /// `assets/…epub` 경로. [bytesLoader]가 있으면 무시된다.
  final String? asset;

  /// asset 없이 합성 EPUB을 바로 만들어 여는 로더(#235와 동일한 이유 —
  /// 대용량/라이선스 사유로 커밋되지 않는 asset 대신, 순수 Dart로 생성해
  /// 클린 체크아웃/웹 배포에서도 항상 열리는 샘플용). 있으면 [asset]보다 우선한다.
  /// `kSampleBooks`가 const 리스트이므로 top-level 함수 tear-off만 대입 가능
  /// (클로저 불가) — 동기 반환이면 충분해 `Future`로 감싸지 않는다.
  final Uint8List Function()? bytesLoader;

  /// 책 제목(고유명 — 번역하지 않는다). 목록의 설명 · 기능 칩 문구는 번역
  /// 파일(`samples.<id>`)에 있다 — sample_library_page.dart 의 sampleTexts.
  final String title;

  final IconData icon;

  /// 열 때 RTL 넘김을 기본 적용(책 capabilities로도 감지되지만 라벨/기본값용).
  final bool autoRtl;

  /// 열 때 세로쓰기를 기본 적용.
  final bool autoVertical;

  /// Media Overlay(낭독) 컨트롤 노출.
  final bool hasMediaOverlay;
}

/// 라이브러리에 노출할 샘플 목록(위→아래 = 기능 커버리지 순).
const List<SampleBook> kSampleBooks = [
  SampleBook(
    id: 'nohoechan',
    asset: 'assets/nohoechan.epub',
    title: '노회찬평전',
    icon: Icons.menu_book,
  ),
  SampleBook(
    id: 'wasteland',
    asset: 'assets/wasteland.epub',
    title: 'The Waste Land',
    icon: Icons.article_outlined,
  ),
  SampleBook(
    id: 'arabic-rtl',
    asset: 'assets/regime-anticancer-arabic.epub',
    title: 'Le Régime anti-cancer (عربى)',
    icon: Icons.format_textdirection_r_to_l,
    autoRtl: true,
  ),
  SampleBook(
    id: 'mathml',
    asset: 'assets/linear-algebra.epub',
    title: 'Linear Algebra',
    icon: Icons.functions,
  ),
  SampleBook(
    id: 'vertical',
    asset: 'assets/mymedia_lite.epub',
    title: 'ガリ版の話',
    icon: Icons.view_column,
    autoVertical: true,
    autoRtl: true,
  ),
  SampleBook(
    id: 'media-overlay',
    asset: 'assets/moby-dick-mo.epub',
    title: 'Moby-Dick (Media Overlay)',
    icon: Icons.record_voice_over,
    hasMediaOverlay: true,
  ),
  SampleBook(
    id: 'accessible',
    asset: 'assets/accessible_epub_3.epub',
    title: 'Accessible EPUB 3',
    icon: Icons.accessibility_new,
  ),
  SampleBook(
    id: 'cfi',
    asset: 'assets/georgia-cfi.epub',
    title: 'Georgia (CFI)',
    icon: Icons.my_location,
  ),
  SampleBook(
    id: 'fixed-a4',
    bytesLoader: buildFixedLayoutA4DemoEpub,
    title: 'Fixed Layout A4 데모',
    icon: Icons.insert_drive_file_outlined,
  ),
];
