import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/document.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

import 'support/document_fixtures.dart';

/// 늘린 여백의 괘선이 종이의 괘선과 이어지는지 픽셀로 확인한다.
void main() {
  Future<(Uint8List, int)> render(NotePage page) async {
    final recorder = ui.PictureRecorder();
    NotePageBackground.paint(ui.Canvas(recorder), page);
    final width = page.size.width.ceil();
    final image = await recorder.endRecording().toImage(
      width,
      page.size.height.ceil(),
    );
    final data = (await image.toByteData())!.buffer.asUint8List();
    image.dispose();

    return (data, width);
  }

  /// 열 [x] 에서 바탕이 아닌 행들.
  Set<int> ruledRows((Uint8List, int) picture, int x, int from, int to) {
    final (data, width) = picture;
    // 위 여백(1 행)에는 줄이 없다.
    final background = data.sublist((width + x) * 4, (width + x) * 4 + 4);

    return {
      for (var y = from; y < to; y++)
        if (!_same(
          data.sublist((y * width + x) * 4, (y * width + x) * 4 + 4),
          background,
        ))
          y,
    };
  }

  NotePage lined() => NotePage.blank(
    template: NotePaperTemplate.lined(),
    size: const NotePageSize(400, 600),
    idFactory: counterIds(),
    clock: fixedClock,
  );

  for (final (name, template) in [
    ('grid', NotePaperTemplate.grid),
    ('dotted', NotePaperTemplate.dotted),
  ]) {
    test('$name paper keeps its lattice when margins grow', () async {
      final page = NotePage.blank(
        template: template(),
        size: const NotePageSize(400, 600),
        idFactory: counterIds(),
        clock: fixedClock,
      );
      final extended = NotePageOps.setMargins(
        page,
        const EdgeInsets.only(right: 170, bottom: 130),
      );
      final before = await render(page);
      final after = await render(extended);
      // 원래 종이 안의 모든 픽셀이 그대로다(격자가 밀리지 않는다).
      var moved = 0;
      for (var y = 0; y < 560; y += 1) {
        for (var x = 0; x < 360; x += 1) {
          final a = before.$1.sublist(
            (y * before.$2 + x) * 4,
            (y * before.$2 + x) * 4 + 4,
          );
          final b = after.$1.sublist(
            (y * after.$2 + x) * 4,
            (y * after.$2 + x) * 4 + 4,
          );
          if (!_same(a, b)) moved++;
        }
      }
      expect(moved, 0);
      // 늘어난 곳에도 격자가 있다(점 줄이 행 하나를 비켜갈 수 있어 구간으로 본다).
      expect([
        for (var y = 290; y < 330; y++) ruledColumns(after, y, 420, 540),
      ], contains(isNotEmpty));
    });
  }

  /// [after] 의 [page] 종이 안쪽이 [before] 와 같은 위치에 같은 그림인지 —
  /// 다른 픽셀 수.
  Future<int> movedInside(NotePage before, NotePage after) async {
    final a = await render(before);
    final b = await render(after);
    final inner = before.contentRect.deflate(80);
    final shift = after.contentRect.topLeft - before.contentRect.topLeft;
    var moved = 0;
    for (var y = inner.top.ceil(); y < inner.bottom.floor(); y++) {
      for (var x = inner.left.ceil(); x < inner.right.floor(); x++) {
        final i = (y * a.$2 + x) * 4;
        final j = ((y + shift.dy.round()) * b.$2 + x + shift.dx.round()) * 4;
        // 옮겨 그리면 안티앨리어싱 반올림이 1 단계 달라질 수 있다.
        if (!_close(a.$1.sublist(i, i + 4), b.$1.sublist(j, j + 4))) moved++;
      }
    }

    return moved;
  }

  for (final (name, template) in [
    ('lined', NotePaperTemplate.lined),
    ('grid', NotePaperTemplate.grid),
    ('dotted', NotePaperTemplate.dotted),
    ('music', NotePaperTemplate.music),
  ]) {
    test('$name paper stays put under margins on every side', () async {
      final page = NotePage.blank(
        template: template(),
        size: const NotePageSize(400, 600),
        idFactory: counterIds(),
        clock: fixedClock,
      );
      // 정수 이동이라 픽셀을 그대로 비교할 수 있다.
      final extended = NotePageOps.setMargins(
        page,
        const EdgeInsets.fromLTRB(113, 97, 131, 109),
      );

      expect(await movedInside(page, extended), 0);

      final turned = NotePageOps.rotate(page, 1);
      expect(
        await movedInside(
          turned,
          NotePageOps.setMargins(
            turned,
            const EdgeInsets.only(left: 113, bottom: 97),
          ),
        ),
        0,
      );
    });
  }

  test('lines continue into margins added to the right and bottom', () async {
    final page = lined();
    final extended = NotePageOps.setMargins(
      page,
      const EdgeInsets.only(right: 400, bottom: 600),
    );

    final original = ruledRows(await render(page), 200, 2, 500);
    final picture = await render(extended);

    expect(original, isNotEmpty);
    // 원래 자리의 줄은 그대로이고, 오른쪽으로 늘린 곳에도 같은 높이에 있다.
    expect(ruledRows(picture, 200, 2, 500), original);
    expect(ruledRows(picture, 500, 2, 500), original);
    // 아래로 늘린 곳에도 같은 간격으로 줄이 이어진다.
    final below = _centres(ruledRows(picture, 200, 600, 1100));
    final spacing = NotePaperTemplate.lined().lineSpacing;
    final first = _centres(original).first;
    expect(below.length, greaterThan(10));
    for (final line in below) {
      final steps = (line - first) / spacing;
      expect((steps - steps.round()).abs() * spacing, lessThan(1));
    }
  });
}

/// 이어진 행들을 한 줄로 묶어 가운데를 돌려준다.
List<double> _centres(Set<int> rows) {
  final sorted = rows.toList()..sort();
  final lines = <List<int>>[];
  for (final row in sorted) {
    if (lines.isNotEmpty && row - lines.last.last <= 1) {
      lines.last.add(row);
    } else {
      lines.add([row]);
    }
  }

  return [for (final line in lines) (line.first + line.last) / 2];
}

/// 행 [y] 에서 [from]–[to] 열 가운데 바탕이 아닌 열들.
Set<int> ruledColumns((Uint8List, int) picture, int y, int from, int to) {
  final (data, width) = picture;
  // 왼쪽 위 구석(1, 1)은 어떤 괘선도 지나지 않는다.
  final background = data.sublist((width + 1) * 4, (width + 1) * 4 + 4);

  return {
    for (var x = from; x < to; x++)
      if (!_same(
        data.sublist((y * width + x) * 4, (y * width + x) * 4 + 4),
        background,
      ))
        x,
  };
}

bool _close(List<int> a, List<int> b) => Iterable<int>.generate(
  4,
).every((channel) => (a[channel] - b[channel]).abs() <= 2);

bool _same(List<int> a, List<int> b) =>
    a[0] == b[0] && a[1] == b[1] && a[2] == b[2] && a[3] == b[3];
