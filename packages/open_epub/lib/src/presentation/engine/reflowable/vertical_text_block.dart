// Presentation Engine — open_epub 1.0
// Story: S15.4 (#111) — 세로쓰기(vertical-rl) 실용 조판 (gap #4 조판분)
//
// Flutter 텍스트 엔진은 세로 조판을 네이티브 지원하지 않는다. CJK 텍스트 문단을
// 대상으로 한 실용(pragmatic) 구현 — 글자를 upright로 위→아래 쌓고, 컬럼을
// vertical-rl은 우→좌(기본), vertical-lr은 좌→우로 배치한다. 복잡한 HTML(이미지·
// SVG·수식·표)은 이 경로를 쓰지 않고 기존 가로 렌더로 폴백한다([isSimpleTextContent]).

import 'package:flutter/material.dart';

/// XHTML이 세로쓰기(`writing-mode: vertical-rl|vertical-lr`)를 인라인으로
/// 선언하는지. 스타일시트로만 선언한 책은 호스트가 override로 강제한다.
bool declaresVerticalWriting(String html) =>
    RegExp(r'writing-mode\s*:\s*vertical-(rl|lr)', caseSensitive: false)
        .hasMatch(html);

/// 세로쓰기 방향이 vertical-lr(컬럼 좌→우)인지. 그 외/미선언은 false(vertical-rl).
bool isVerticalLr(String html) =>
    RegExp(r'writing-mode\s*:\s*vertical-lr', caseSensitive: false)
        .hasMatch(html);

/// 세로 조판으로 렌더해도 안전한 단순 텍스트 콘텐츠인지 — 이미지·SVG·수식·표가
/// 없으면 true. 복잡 콘텐츠는 가로 렌더로 폴백해야 한다(안전).
bool isSimpleTextContent(String html) {
  final lower = html.toLowerCase();
  return !lower.contains('<img') &&
      !lower.contains('<svg') &&
      !lower.contains('<image') &&
      !lower.contains('<math') &&
      !lower.contains('<table');
}

/// [text]를 한 컬럼당 [perColumn]자로 나눠, **시각적 좌→우** 순서의 컬럼 문자열
/// 목록으로 반환한다.
///
/// vertical-rl([leftToRight]=false, 기본): 첫 글자 컬럼이 오른쪽 → 리스트의 끝.
/// vertical-lr([leftToRight]=true): 첫 글자 컬럼이 왼쪽 → 리스트의 시작.
/// grapheme 대신 rune 단위(CJK 1자=1rune)로 나눈다.
List<String> verticalColumns(
  String text,
  int perColumn, {
  bool leftToRight = false,
}) {
  final runes = text.runes.toList();
  final cols = <String>[];
  final step = perColumn < 1 ? 1 : perColumn;
  for (var i = 0; i < runes.length; i += step) {
    final end = i + step < runes.length ? i + step : runes.length;
    cols.add(String.fromCharCodes(runes.sublist(i, end)));
  }
  if (cols.isEmpty) cols.add('');
  return leftToRight ? cols : cols.reversed.toList();
}

/// 세로 조판 텍스트 블록(실용 구현). 글자를 upright로 위→아래 쌓고 컬럼을 방향에
/// 맞춰 배치하며, 폭을 넘치면 가로 스크롤(vertical-rl은 오른쪽에서 시작)한다.
class VerticalTextBlock extends StatelessWidget {
  const VerticalTextBlock({
    super.key,
    required this.text,
    this.fontSize = 16.0,
    this.lineHeight = 1.6,
    this.leftToRight = false,
  });

  final String text;
  final double fontSize;
  final double lineHeight;

  /// vertical-lr이면 true(컬럼 좌→우), 기본 false(vertical-rl, 우→좌).
  final bool leftToRight;

  @override
  Widget build(BuildContext context) {
    final charBox = fontSize * lineHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > charBox
            ? constraints.maxHeight
            : charBox * 20;
        final perColumn = (h / charBox).floor().clamp(1, 4096);
        final columns = verticalColumns(
          text,
          perColumn,
          leftToRight: leftToRight,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // vertical-rl: 오른쪽(첫 글자)에서 시작. vertical-lr: 왼쪽.
          reverse: !leftToRight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final col in columns)
                _VerticalColumn(
                  text: col,
                  fontSize: fontSize,
                  charBox: charBox,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _VerticalColumn extends StatelessWidget {
  const _VerticalColumn({
    required this.text,
    required this.fontSize,
    required this.charBox,
  });

  final String text;
  final double fontSize;
  final double charBox;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final rune in text.runes)
            SizedBox(
              height: charBox,
              child: Center(
                child: Text(
                  String.fromCharCode(rune),
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
