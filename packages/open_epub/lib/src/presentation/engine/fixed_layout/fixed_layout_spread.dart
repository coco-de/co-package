// Presentation Engine — open_epub 1.0
// Story: S1.9 (#15) — Fixed Layout spread (1-page / 2-page) + L/R 슬롯
// BDD: F3.3 (auto spread breakpoint), F3.5 (page-spread-left/right 슬롯 존중)

import 'package:flutter/material.dart';

import 'package:open_epub_engine/open_epub_engine.dart';

/// Spread 모드에서 한 슬롯에 표시되는 자리.
enum SpreadSlot { left, right, center }

/// 한 spine 항목의 spread slot 판정.
///
/// EPUB 3 표준 properties:
/// - `page-spread-left` → left slot 강제
/// - `page-spread-right` → right slot 강제
/// - `rendition:page-spread-center` → center (single page, fill row)
/// - 미명시 → null (caller가 흐름에 따라 좌→우 배치)
SpreadSlot? slotFromSpineProperties(List<String> properties) {
  if (properties.contains('rendition:page-spread-center')) {
    return SpreadSlot.center;
  }
  if (properties.contains('page-spread-left')) return SpreadSlot.left;
  if (properties.contains('page-spread-right')) return SpreadSlot.right;
  return null;
}

/// 2-page spread 한 줄을 구성하는 표시 단위.
class SpreadRow {
  const SpreadRow({this.left, this.right, this.center})
    : assert(
        center == null || (left == null && right == null),
        'center page must be alone in a row',
      );

  /// center page (page-spread-center)인 경우 하나만 채움.
  final EpubSpineItem? center;

  /// left slot에 표시될 spine.
  final EpubSpineItem? left;

  /// right slot에 표시될 spine.
  final EpubSpineItem? right;

  bool get isCenter => center != null;
  bool get isEmpty => center == null && left == null && right == null;
}

/// spine 목록 → 2-page spread row 목록 변환.
///
/// 규칙:
/// 1. page-spread-center는 단독 row.
/// 2. 명시적 page-spread-left/right는 해당 슬롯으로 강제(물리적 위치 — RTL에도
///    불변).
/// 3. 미명시 항목은 흐름에 따라 좌→우 채움. 단, 다음 항목이 left/center 강제면
///    빈 칸을 두지 않고 cur는 단독 row로 배치.
///
/// [rightToLeft](RTL, `page-progression-direction=rtl`)는 **양쪽 다 미명시인
/// 흐름 페어링**과 **미명시 단독 페이지**에만 반전을 적용한다 — 먼저 읽는
/// 페이지가 물리적으로 오른쪽에 온다(cur=right, next=left). 명시 슬롯
/// (page-spread-left/right/center)은 물리적 위치이므로 RTL에도 그대로 유지되어
/// LTR과 동일하게 배치된다(회귀 0). row 진행(다음 row=다음 spine)은 방향과
/// 무관하게 spine 읽기 순서를 유지한다. (S14.1, gap #4 페이지 방향 반전)
List<SpreadRow> buildSpreadRows(
  List<EpubSpineItem> spine, {
  bool rightToLeft = false,
}) {
  final rows = <SpreadRow>[];
  var i = 0;
  while (i < spine.length) {
    final cur = spine[i];
    final curSlot = slotFromSpineProperties(cur.properties);

    if (curSlot == SpreadSlot.center) {
      rows.add(SpreadRow(center: cur));
      i++;
      continue;
    }

    if (curSlot == SpreadSlot.right) {
      // left가 빈 row (cur만 오른쪽).
      rows.add(SpreadRow(right: cur));
      i++;
      continue;
    }

    // curSlot == left 또는 null
    // 다음 항목 확인
    if (i + 1 < spine.length) {
      final next = spine[i + 1];
      final nextSlot = slotFromSpineProperties(next.properties);
      if (nextSlot == SpreadSlot.left || nextSlot == SpreadSlot.center) {
        // 다음이 left 강제면 cur는 단독 또는 right로 둘 수 없음
        // (cur가 left 강제거나 미명시) → cur만 단독 row. RTL·미명시면 물리적
        // 오른쪽, 그 외(LTR 또는 명시 left)는 왼쪽.
        final soloRight = rightToLeft && curSlot == null;
        rows.add(soloRight ? SpreadRow(right: cur) : SpreadRow(left: cur));
        i++;
        continue;
      }
      // next가 right 강제 또는 미명시 → cur=left, next=right.
      // RTL이면서 양쪽 다 미명시일 때만 좌우를 반전한다(명시 슬롯은 물리적 유지).
      final reversePair =
          rightToLeft && curSlot == null && nextSlot == null;
      rows.add(
        reversePair
            ? SpreadRow(left: next, right: cur)
            : SpreadRow(left: cur, right: next),
      );
      i += 2;
    } else {
      // 마지막 단독. RTL·미명시면 물리적 오른쪽, 그 외는 왼쪽.
      final soloRight = rightToLeft && curSlot == null;
      rows.add(soloRight ? SpreadRow(right: cur) : SpreadRow(left: cur));
      i++;
    }
  }
  return rows;
}

/// 한 SpreadRow를 두 FixedLayoutPage(또는 빈 칸 + 한쪽)로 배치하는 widget.
class FixedLayoutSpreadRow extends StatelessWidget {
  const FixedLayoutSpreadRow({
    super.key,
    required this.row,
    required this.pageBuilder,
  });

  final SpreadRow row;

  /// SpineItem → FixedLayoutPage widget builder.
  final Widget Function(EpubSpineItem item) pageBuilder;

  @override
  Widget build(BuildContext context) {
    if (row.isCenter) {
      return Center(child: pageBuilder(row.center!));
    }
    final left = row.left;
    final right = row.right;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: left == null ? const SizedBox.shrink() : pageBuilder(left)),
        Expanded(child: right == null ? const SizedBox.shrink() : pageBuilder(right)),
      ],
    );
  }
}
