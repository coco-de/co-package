/// 터미널 크기가 바뀌어도(확대·축소·창 리사이즈) 프레임이 화면을 넘지 않도록
/// 세로·가로 예산을 계산하고 줄을 잘라내는 계층.
///
/// dart_tui의 `AnsiRenderer`는 프레임을 절대 좌표(`ESC [row;1H`)로 그린다.
/// 프레임이 터미널보다 한 줄이라도 크면 터미널이 스크롤해 1행이 더 이상 화면
/// 맨 위가 아니게 되고, 그 뒤 모든 행 쓰기가 한 줄씩 어긋난다 — 한 번 밀리면
/// 다음 리사이즈까지 복구되지 않는다. 폭도 마찬가지로, 넘치는 줄은 래핑돼
/// 아래 내용을 통째로 밀어 내린다.
///
/// 그래서 이 파일의 계약은 셋이다.
///
/// 1. 뷰가 내보내는 프레임은 어떤 크기에서도 `height`줄을 넘지 않는다.
/// 2. 각 줄은 `width - 1`칸을 넘지 않는다 (마지막 칸은 pending wrap 때문에 비운다).
/// 3. 높이를 키우면 테이블 행 수와 로그 줄 수가 절대 줄어들지 않는다(단조성).
///    확대·축소를 오가는 도중 목록이 늘었다 줄었다 하는 것도 "깨짐"으로 보인다.
///
/// [Layout]이 각 패널의 몫을 정하고, [fitFrame]이 마지막 안전망으로 1·2를
/// 강제한다.
library;

/// 한 프레임의 세로·가로 예산.
final class Layout {
  const Layout._({
    required this.width,
    required this.height,
    required this.tableRows,
    required this.logLines,
    required this.showSpacers,
    required this.nameColumnWidth,
    required this.labelColumnWidth,
  });

  /// 터미널 [width]x[height]에 맞는 예산을 계산한다.
  factory Layout.forTerminal(int width, int height) {
    // 터미널이 아닌 곳(파이프·테스트)에서 0이 들어와도 계산이 무너지지 않게.
    final w = width < 1 ? 1 : width;
    final h = height < 1 ? 1 : height;
    final content = w - 1 < 1 ? 1 : w - 1;

    // ── 세로 ──────────────────────────────────────────────────────────────
    // 가변 공간은 테이블 우선으로 나눈다. 로그는 보조 패널이라 최대
    // [_maxLogLines]줄, 그리고 가변 공간의 1/3을 넘지 않는다 — 좁아질수록
    // 로그가 먼저 자리를 내주고 러너 목록이 남는다.
    var showSpacers = true;
    var flexible = h - _fixedChrome - _spacerLines;
    if (flexible < _minTableRows) {
      // 여백을 넣을 수 없을 만큼 짧다. 이때 내용을 여백 자리까지 넓히지는
      // 않는다 — 넓혔다가 여백이 켜지는 높이에서 도로 줄어들면, 창을 키웠는데
      // 목록이 짧아지는 역전이 생긴다 (확대·축소를 오갈 때 가장 눈에 띄는
      // 종류의 깨짐이다).
      showSpacers = false;
      flexible = _minTableRows;
    }

    final logLines = (flexible ~/ 3).clamp(0, _maxLogLines);
    final rows = flexible - logLines;
    final tableRows = rows < _minTableRows ? _minTableRows : rows;

    // ── 가로 ──────────────────────────────────────────────────────────────
    // NAME과 LABELS만 가변이다. LABELS가 남는 폭을 흡수하고, 그것만으로
    // 최소 폭을 못 채우면 NAME을 [_minNameWidth]까지 줄여 확보한다 — 러너
    // 이름은 앞부분만 봐도 구분되지만, 라벨은 서너 글자로는 못 읽는다.
    var name = _maxNameWidth;
    var labels = content - _fixedColumns - name;
    if (labels < _minLabelWidth) {
      name = (name - (_minLabelWidth - labels))
          .clamp(_minNameWidth, _maxNameWidth);
      labels = content - _fixedColumns - name;
    }

    return Layout._(
      width: w,
      height: h,
      tableRows: tableRows,
      logLines: logLines,
      showSpacers: showSpacers,
      nameColumnWidth: name,
      labelColumnWidth: labels.clamp(0, _maxLabelWidth),
    );
  }

  /// 테이블 밖 고정 줄 수 — 헤더 1 + 테이블 헤더·구분선 2 + 로컬 줄 1 +
  /// 구분선 1 + 푸터 1. 어떤 크기에서도 살아남는 뼈대다.
  static const _fixedChrome = 6;

  /// 헤더 뒤·테이블 뒤·푸터 앞의 빈 줄.
  static const _spacerLines = 3;

  static const _maxLogLines = 6;
  static const _minTableRows = 1;

  /// 커서 거터 2 + 구분자 4x3 + ST 5 + JOB 5 + OS 6.
  static const _fixedColumns = 30;
  static const _maxNameWidth = 26;
  static const _minNameWidth = 10;
  static const _minLabelWidth = 8;
  static const _maxLabelWidth = 120;

  final int width;
  final int height;

  /// 표에 그릴 데이터 행 수 (헤더·구분선 제외).
  final int tableRows;

  /// 로그 패널에 그릴 줄 수. 0이면 로그 패널을 아예 그리지 않는다.
  final int logLines;

  /// 여백(빈 줄)을 넣을 수 있는지.
  final bool showSpacers;

  final int nameColumnWidth;
  final int labelColumnWidth;

  /// 줄 하나가 쓸 수 있는 칸 수. 마지막 칸은 비워 둔다 — 거기까지 채우면
  /// 터미널이 pending-wrap 상태가 되어, 다음 쓰기가 의도치 않게 다음 줄로
  /// 넘어가거나 지워진다 (dart_tui 렌더러가 EL 처리에서 같은 이유를 든다).
  int get contentWidth => width - 1 < 1 ? 1 : width - 1;

  /// [s]를 이 프레임의 한 줄 폭([contentWidth])으로 자른다.
  String clip(String s) => clipToWidth(s, contentWidth);

  /// 라벨 피커 화면의 항목 행 수.
  ///
  /// 피커 밖 고정 줄 — 제목 1 + read-only 안내 1 + 빈 줄 1 + 빈 줄 1 +
  /// 선택 수 1 + 빈 줄 1 + 구분선 1 + 푸터 1.
  int get pickerRows {
    const chrome = 8;
    final rows = height - chrome;
    return rows < 1 ? 1 : rows;
  }
}

/// 프레임을 터미널에 강제로 맞춘다 — 각 줄을 [layout]의 폭으로 자르고,
/// [Layout.height]줄을 넘는 줄은 버린다.
///
/// 각 뷰가 이미 자기 몫을 지켜 그리지만, 이 함수는 그와 무관하게 계약을
/// 보장하는 마지막 안전망이다. 뷰 하나가 계산을 놓쳐도 화면은 깨지지 않는다.
String fitFrame(String content, Layout layout) {
  final lines = content.split('\n');
  final count = lines.length < layout.height ? lines.length : layout.height;
  final b = StringBuffer();
  for (var i = 0; i < count; i++) {
    if (i > 0) b.write('\n');
    b.write(clipToWidth(lines[i], layout.contentWidth));
  }
  return b.toString();
}

/// [s]가 화면에서 차지하는 칸 수. ANSI 이스케이프는 0칸, 전각 문자는 2칸이다.
int visibleWidth(String s) {
  final runes = s.runes.toList(growable: false);
  var width = 0;
  var i = 0;
  while (i < runes.length) {
    final skip = _escapeEnd(runes, i);
    if (skip > i) {
      i = skip;
      continue;
    }
    width += runeWidth(runes[i]);
    i++;
  }
  return width;
}

/// [s]를 가시 폭 [maxWidth]까지 자른다.
///
/// ANSI 이스케이프는 폭 0으로 통과시켜 색이 중간에서 끊기지 않게 하고, 실제로
/// 잘라낸 경우에만 reset을 붙여 스타일이 다음 줄로 새지 않게 한다. 전각 문자가
/// 경계에 걸리면 그 글자는 통째로 버린다 — 반 칸만 그리면 그 뒤가 한 칸씩
/// 밀린다.
String clipToWidth(String s, int maxWidth) {
  if (maxWidth <= 0) return '';
  final runes = s.runes.toList(growable: false);
  final b = StringBuffer();
  var width = 0;
  var styled = false;
  var i = 0;
  while (i < runes.length) {
    final skip = _escapeEnd(runes, i);
    if (skip > i) {
      for (var j = i; j < skip; j++) {
        b.writeCharCode(runes[j]);
      }
      styled = true;
      i = skip;
      continue;
    }
    final w = runeWidth(runes[i]);
    if (width + w > maxWidth) {
      if (styled) b.write('\x1b[0m');
      return b.toString();
    }
    b.writeCharCode(runes[i]);
    width += w;
    i++;
  }
  return b.toString();
}

/// 한 문자가 차지하는 칸 수 — 한글·CJK·이모지 등 전각은 2.
int runeWidth(int code) {
  if (code >= 0x1100 &&
      (code <= 0x11ff ||
          (code >= 0x2e80 && code <= 0x9fff) ||
          (code >= 0xac00 && code <= 0xd7af) ||
          (code >= 0xf900 && code <= 0xfaff) ||
          (code >= 0xfe30 && code <= 0xfe4f) ||
          (code >= 0xff00 && code <= 0xff60) ||
          (code >= 0x1f300 && code <= 0x1f9ff))) {
    return 2;
  }
  return 1;
}

/// [i]에서 시작하는 CSI 이스케이프(`ESC [ … 종료바이트`)의 끝(exclusive).
/// 이스케이프가 아니면 [i]를 그대로 돌려준다.
int _escapeEnd(List<int> runes, int i) {
  if (runes[i] != 0x1b) return i;
  if (i + 1 >= runes.length || runes[i + 1] != 0x5b) return i; // '['
  var j = i + 2;
  while (j < runes.length && runes[j] >= 0x30 && runes[j] <= 0x3f) {
    j++; // 파라미터 바이트
  }
  while (j < runes.length && runes[j] >= 0x20 && runes[j] <= 0x2f) {
    j++; // 중간 바이트
  }
  if (j < runes.length && runes[j] >= 0x40 && runes[j] <= 0x7e) {
    return j + 1; // 종료 바이트
  }
  return i;
}
