// EPUB3 기능 검증용 샘플 카탈로그.
//
// IDPF/W3C 공식 epub3-samples(20230704 릴리스) + 실제 EPUB2(노회찬평전)를
// 우리 리더의 E10~E15 기능별로 밟도록 큐레이션했다. 각 항목은 어떤 기능을
// 검증하는지(featureTag)와 리더에 적용할 기본 설정(autoRtl 등)을 갖는다.
//
// 자산 8종 중 라이선스가 명확한 6종(georgia-cfi·linear-algebra·moby-dick-mo·
// mymedia_lite·regime-anticancer-arabic·wasteland)은 `.gitignore`에서
// 예외 처리되어 저장소에 실제로 커밋돼 있다(#248, 고지는 THIRD_PARTY_LICENSES
// 참조). 나머지 2종(nohoechan, accessible_epub_3)은 저작권 사유로 여전히
// `*.epub` gitignore 규칙을 따르는 로컬 전용 픽스처다 — 부재 시 리더가
// 안내 메시지를 표시한다(reader_demo_page.dart).
import 'package:flutter/material.dart';

/// 샘플 EPUB 한 권의 카탈로그 항목.
class SampleBook {
  const SampleBook({
    required this.id,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.featureTag,
    required this.icon,
    this.autoRtl = false,
    this.autoVertical = false,
    this.hasMediaOverlay = false,
  });

  /// marionette ValueKey/화면 식별용 짧은 슬러그.
  final String id;

  /// `assets/…epub` 경로.
  final String asset;

  final String title;
  final String subtitle;

  /// 이 샘플이 검증하는 대표 기능(칩 라벨).
  final String featureTag;

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
    subtitle: '실제 EPUB2 리플로우 · 22MB 대용량',
    featureTag: 'EPUB2 · 대용량',
    icon: Icons.menu_book,
  ),
  SampleBook(
    id: 'wasteland',
    asset: 'assets/wasteland.epub',
    title: 'The Waste Land',
    subtitle: 'T.S. Eliot · EPUB3 기본(nav·CSS)',
    featureTag: 'EPUB3 기본',
    icon: Icons.article_outlined,
  ),
  SampleBook(
    id: 'arabic-rtl',
    asset: 'assets/regime-anticancer-arabic.epub',
    title: 'Le Régime anti-cancer (عربى)',
    subtitle: '아랍어 · page-progression-direction=rtl',
    featureTag: 'RTL 넘김 (E14)',
    icon: Icons.format_textdirection_r_to_l,
    autoRtl: true,
  ),
  SampleBook(
    id: 'mathml',
    asset: 'assets/linear-algebra.epub',
    title: 'Linear Algebra',
    subtitle: 'MathML 71수식 · TeX 변환/폴백',
    featureTag: 'MathML (E14)',
    icon: Icons.functions,
  ),
  SampleBook(
    id: 'vertical',
    asset: 'assets/mymedia_lite.epub',
    title: 'ガリ版の話',
    subtitle: '일본어 세로쓰기(vertical-rl) + RTL',
    featureTag: '세로쓰기 (E15)',
    icon: Icons.view_column,
    autoVertical: true,
    autoRtl: true,
  ),
  SampleBook(
    id: 'media-overlay',
    asset: 'assets/moby-dick-mo.epub',
    title: 'Moby-Dick (Media Overlay)',
    subtitle: 'SMIL 낭독 + 오디오 동기 하이라이트',
    featureTag: 'Media Overlay (E15)',
    icon: Icons.record_voice_over,
    hasMediaOverlay: true,
  ),
  SampleBook(
    id: 'accessible',
    asset: 'assets/accessible_epub_3.epub',
    title: 'Accessible EPUB 3',
    subtitle: 'O\'Reilly · landmarks·목차 계층',
    featureTag: '종합 EPUB3 (E13)',
    icon: Icons.accessibility_new,
  ),
  SampleBook(
    id: 'cfi',
    asset: 'assets/georgia-cfi.epub',
    title: 'Georgia (CFI)',
    subtitle: 'EPUB CFI · page-list 7',
    featureTag: 'CFI (E12)',
    icon: Icons.my_location,
  ),
];
