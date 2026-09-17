import 'package:coarc_tui/coarc_tui.dart';
import 'package:test/test.dart';

/// SGR을 붙인 문자열 — 실제 뷰가 렌더러에 넘기는 형태다.
String _styled(String s) => '\x1b[38;5;45m$s\x1b[0m';

void main() {
  group('visibleWidth', () {
    test('ANSI SGR은 폭 0으로 센다', () {
      // 이걸 1칸씩 세면 색이 붙은 줄이 실제보다 훨씬 넓다고 판단돼,
      // 멀쩡한 줄을 잘라 글자를 잃는다.
      expect(visibleWidth(_styled('abc')), 3);
      expect(visibleWidth('abc'), 3);
    });

    test('한글 등 전각 문자는 2칸', () {
      expect(visibleWidth('러너'), 4);
      expect(visibleWidth('a러너b'), 6);
    });

    test('빈 문자열은 0', () => expect(visibleWidth(''), 0));
  });

  group('clipToWidth', () {
    test('가시 폭을 넘지 않게 자른다', () {
      expect(clipToWidth('abcdef', 3), 'abc');
      expect(visibleWidth(clipToWidth('abcdef', 3)), 3);
    });

    test('폭이 충분하면 그대로 둔다', () {
      expect(clipToWidth('abc', 10), 'abc');
    });

    test('maxWidth가 0 이하면 빈 문자열', () {
      expect(clipToWidth('abc', 0), '');
      expect(clipToWidth('abc', -5), '');
    });

    test('SGR은 폭 0으로 통과 — 색이 붙어도 글자 수가 줄지 않는다', () {
      final clipped = clipToWidth(_styled('abcdef'), 3);
      expect(visibleWidth(clipped), 3);
      expect(clipped, contains('abc'));
      expect(clipped, contains('\x1b[38;5;45m'));
    });

    test('실제로 잘랐으면 reset을 붙여 스타일이 다음 줄로 새지 않게 한다', () {
      // 색을 연 채로 끊기면 그 뒤 화면 전체가 그 색으로 물든다.
      final clipped = clipToWidth('\x1b[38;5;45mabcdef', 3);
      expect(clipped, endsWith('\x1b[0m'));
    });

    test('전각 문자가 경계에 걸리면 통째로 버린다', () {
      // 반 칸만 그리면 그 뒤 모든 칸이 한 칸씩 밀린다.
      expect(clipToWidth('러너', 3), '러');
      expect(visibleWidth(clipToWidth('러너', 3)), 2);
      expect(clipToWidth('러너', 1), '');
    });
  });

  group('Layout 세로 예산', () {
    /// 뷰가 실제로 그리는 줄 수 — 고정 6줄(헤더·테이블 헤더/구분선·로컬·구분선·
    /// 푸터) + 빈 줄 + 테이블 행 + 로그.
    int framedLines(Layout l) =>
        6 + (l.showSpacers ? 3 : 0) + l.tableRows + l.logLines;

    test('어떤 높이에서도 프레임이 터미널을 넘지 않는다', () {
      for (var h = 7; h <= 120; h++) {
        final l = Layout.forTerminal(100, h);
        expect(framedLines(l), lessThanOrEqualTo(h),
            reason: '높이 $h에서 ${framedLines(l)}줄을 그린다 — 한 줄만 넘쳐도 '
                '터미널이 스크롤해 이후 렌더가 전부 어긋난다');
      }
    });

    test('넉넉하면 빈 줄과 로그를 모두 살린다', () {
      final l = Layout.forTerminal(120, 40);
      expect(l.showSpacers, isTrue);
      expect(l.logLines, 6);
      expect(l.tableRows, greaterThan(10));
    });

    test('좁아지면 로그가 먼저 자리를 내준다 — 테이블은 최소 1행을 지킨다 (DDR-1)', () {
      for (var h = 7; h <= 30; h++) {
        final l = Layout.forTerminal(100, h);
        expect(l.tableRows, greaterThanOrEqualTo(1),
            reason: '높이 $h에서 테이블 행이 사라졌다 — 러너 목록이 이 화면의 주제다');
        expect(l.logLines, lessThanOrEqualTo(l.tableRows),
            reason: '높이 $h에서 보조 패널인 로그가 러너 목록보다 커졌다');
      }
      expect(Layout.forTerminal(100, 11).logLines, 0);
    });

    test('여백은 넣을 자리가 없을 때만 버린다', () {
      expect(Layout.forTerminal(100, 9).showSpacers, isFalse);
      expect(Layout.forTerminal(100, 10).showSpacers, isTrue);
      expect(Layout.forTerminal(100, 40).showSpacers, isTrue);
    });

    test('높이를 키우면 테이블·로그가 줄지 않는다 (단조성)', () {
      // 여백을 한꺼번에 켜고 끄면 창을 한 줄 키웠는데 목록이 세 줄 짧아지는
      // 역전이 생긴다 — 확대·축소를 오갈 때 가장 눈에 띄는 깨짐이다.
      var prevRows = 0;
      var prevLog = 0;
      for (var h = 1; h <= 200; h++) {
        final l = Layout.forTerminal(100, h);
        expect(l.tableRows, greaterThanOrEqualTo(prevRows),
            reason: '높이 $h에서 테이블 행이 $prevRows → ${l.tableRows}로 오히려 줄었다');
        expect(l.logLines, greaterThanOrEqualTo(prevLog),
            reason: '높이 $h에서 로그 줄이 $prevLog → ${l.logLines}로 오히려 줄었다');
        prevRows = l.tableRows;
        prevLog = l.logLines;
      }
    });

    test('폭을 키워도 테이블 열이 좁아지지 않는다 (단조성)', () {
      var prevName = 0;
      var prevLabels = 0;
      for (var w = 1; w <= 400; w++) {
        final l = Layout.forTerminal(w, 40);
        expect(l.nameColumnWidth, greaterThanOrEqualTo(prevName),
            reason: '폭 $w에서 NAME 열이 오히려 좁아졌다');
        expect(l.labelColumnWidth, greaterThanOrEqualTo(prevLabels),
            reason: '폭 $w에서 LABELS 열이 오히려 좁아졌다');
        prevName = l.nameColumnWidth;
        prevLabels = l.labelColumnWidth;
      }
    });
  });

  group('Layout 가로 예산', () {
    /// 테이블 한 줄의 폭 — 커서 거터 2 + 구분자 4x3 + ST 5 + JOB 5 + OS 6.
    int rowWidth(Layout l) => 30 + l.nameColumnWidth + l.labelColumnWidth;

    test('열 폭 합계가 한 줄 예산을 넘지 않는다', () {
      // 넘치면 모든 데이터 행이 래핑돼 아래 내용이 통째로 밀려 내려간다.
      for (var w = 45; w <= 300; w++) {
        final l = Layout.forTerminal(w, 40);
        expect(rowWidth(l), lessThanOrEqualTo(l.contentWidth),
            reason: '폭 $w에서 테이블 행이 ${rowWidth(l)}칸 — 예산 ${l.contentWidth}칸을 넘는다');
      }
    });

    test('LABELS가 남는 폭을 흡수한다', () {
      expect(Layout.forTerminal(200, 40).labelColumnWidth,
          greaterThan(Layout.forTerminal(100, 40).labelColumnWidth));
    });

    test('LABELS 최소 폭을 못 채우면 NAME을 줄여 확보한다', () {
      // 폭 76 미만에서 무조건 래핑되던 게 원래 버그다.
      final narrow = Layout.forTerminal(60, 40);
      expect(narrow.nameColumnWidth, lessThan(26));
      expect(narrow.labelColumnWidth, greaterThanOrEqualTo(8));
    });

    test('NAME은 10칸 아래로 내려가지 않는다', () {
      for (var w = 20; w <= 60; w++) {
        expect(Layout.forTerminal(w, 40).nameColumnWidth,
            greaterThanOrEqualTo(10));
      }
    });

    test('마지막 칸은 비워 둔다 (DDR-3)', () {
      // 마지막 칸까지 채우면 터미널이 pending-wrap 상태가 돼 다음 쓰기가 샌다.
      expect(Layout.forTerminal(80, 24).contentWidth, 79);
    });
  });

  group('Layout 방어', () {
    test('0·음수 크기에서도 계산이 무너지지 않는다', () {
      // 터미널이 아닌 곳(파이프·CI)에서 0이 들어올 수 있다.
      for (final (w, h) in const [(0, 0), (-1, -1), (1, 1), (2, 3)]) {
        final l = Layout.forTerminal(w, h);
        expect(l.contentWidth, greaterThanOrEqualTo(1));
        expect(l.tableRows, greaterThanOrEqualTo(1));
        expect(l.logLines, greaterThanOrEqualTo(0));
        expect(l.pickerRows, greaterThanOrEqualTo(1));
        expect(l.nameColumnWidth, greaterThanOrEqualTo(10));
        expect(l.labelColumnWidth, greaterThanOrEqualTo(0));
      }
    });
  });

  group('fitFrame', () {
    test('높이를 넘는 줄은 버린다', () {
      final content = List.generate(20, (i) => 'line $i').join('\n');
      final fitted = fitFrame(content, Layout.forTerminal(80, 10));
      expect(fitted.split('\n').length, 10);
      expect(fitted.split('\n').first, 'line 0');
    });

    test('폭을 넘는 줄은 자른다', () {
      final fitted = fitFrame('x' * 200, Layout.forTerminal(40, 10));
      expect(visibleWidth(fitted), 39);
    });

    test('이미 맞는 프레임은 건드리지 않는다', () {
      const content = 'a\nb\nc';
      expect(fitFrame(content, Layout.forTerminal(80, 24)), content);
    });

    test('뷰가 계산을 놓쳐도 계약을 지킨다 — 마지막 안전망', () {
      // 어떤 뷰가 자기 몫을 잘못 계산해도 화면은 깨지지 않아야 한다.
      final broken = List.generate(500, (i) => 'x' * 500).join('\n');
      for (final (w, h) in const [(20, 8), (80, 24), (300, 100)]) {
        final l = Layout.forTerminal(w, h);
        final lines = fitFrame(broken, l).split('\n');
        expect(lines.length, lessThanOrEqualTo(h));
        for (final line in lines) {
          expect(visibleWidth(line), lessThanOrEqualTo(w - 1));
        }
      }
    });
  });
}
