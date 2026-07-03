// Data — open_epub 1.0
// Story: S1.5-3 (시각 선택 → locator), S1.5-4 (하이라이트 주입),
//        S1.5-5 (spine 평문 추출) — E1.5
//
// 검색·선택·하이라이트가 공유하는 단일 char-offset 공간을 정의한다:
//   "body 영역에서 태그 밖에 있는 텍스트 노드를 원본 순서대로 이은 평문".
// 이 오프셋은 XHTML 원본 위치로 결정적으로 역매핑되므로(injectHighlights),
// 글자 크기·줄간격이 바뀌어도(=재렌더) 불변이다 → 하이라이트가
// repagination을 가로질러 보존된다(S1.5-7).
//
// Pure Dart (Flutter 비의존). flutter_html이 본문을 렌더하는 방식과 동일한
// "태그 밖 텍스트"를 평문으로 본다. 엔티티(&amp; 등)는 디코드하지 않고 원본
// 문자 기준으로 센다 — 오프셋↔원본 역매핑을 1:1로 유지하기 위함.

import '../../domain/entity/epub_highlight.dart';
import '../../domain/entity/epub_selection.dart';

/// body 텍스트 노드의 원본 [start,end) 구간.
class _Run {
  const _Run(this.start, this.end);
  final int start;
  final int end;
  int get length => end - start;
}

/// XHTML 본문에서 평문을 추출하고, 선택→locator 변환·하이라이트 주입을
/// 동일 오프셋 공간 위에서 수행하는 유틸.
class SpineTextExtractor {
  const SpineTextExtractor();

  /// body 텍스트 노드(태그 밖)를 순서대로 이은 평문.
  String extractPlainText(String xhtml) {
    final runs = _runs(xhtml);
    final buffer = StringBuffer();
    for (final run in runs) {
      buffer.write(xhtml.substring(run.start, run.end));
    }
    return buffer.toString();
  }

  /// canonical charOffset(=[extractPlainText] 공간, raw) ↔ 디코드된 평문 offset
  /// 매핑을 반환한다. 디코드된 평문은 DOM 텍스트 노드(엔티티 디코드)와 같은
  /// 공간이므로, CFI 매퍼(S12.2)가 charOffset을 CFI(:offset, 디코드 공간)와
  /// 브리지하는 데 쓴다. (open-epub CFI, ADR-010)
  PlainTextDecodeMapping decodePlainText(String xhtml) {
    final mapped = _decodeEntities(extractPlainText(xhtml));
    return PlainTextDecodeMapping._(
      mapped.text,
      mapped.rawStarts,
      mapped.rawEnds,
    );
  }

  /// [selectedText]를 평문에서 찾아 [EpubSelection]으로 변환한다.
  ///
  /// [occurrence]번째 일치(0-based)를 사용한다. 정확 일치가 없으면 렌더 규칙
  /// (HTML 공백 접기 + 엔티티 디코드)을 반영한 **정규화 매칭**으로 폴백한다 —
  /// SelectionArea가 반환하는 선택 평문은 렌더된 텍스트라 원본의 소스 개행·
  /// 들여쓰기·`&amp;` 같은 엔티티와 문자 단위로 다르기 때문(open-epub#62).
  /// 반환 offset은 항상 원본 평문 공간이므로 [injectHighlights]와 호환된다.
  /// 그래도 없으면 null. (여러 문단에 걸친 선택 등 본문과 일치하지 않으면
  /// null — 호스트는 목록에 유지하되 본문 표시는 생략, BDD @edge와 동일.)
  EpubSelection? resolveSelection({
    required String spineHref,
    required String xhtml,
    required String selectedText,
    int occurrence = 0,
  }) {
    final plain = extractPlainText(xhtml);
    var needle = selectedText;
    var idx = _nthIndexOf(plain, needle, occurrence);
    if (idx < 0) {
      needle = selectedText.trim();
      if (needle.isEmpty) return null;
      idx = _nthIndexOf(plain, needle, occurrence);
    }
    if (idx >= 0) {
      return EpubSelection(
        spineHref: spineHref,
        start: idx,
        end: idx + needle.length,
        selectedText: needle,
      );
    }
    return _resolveNormalized(
      spineHref: spineHref,
      plain: plain,
      selectedText: selectedText,
      occurrence: occurrence,
    );
  }

  /// 정규화 공간(엔티티 디코드 + 공백 접기)에서 매칭하고 원본 offset으로
  /// 역매핑한다. (open-epub#62)
  EpubSelection? _resolveNormalized({
    required String spineHref,
    required String plain,
    required String selectedText,
    required int occurrence,
  }) {
    // 검색어(렌더된 텍스트)는 공백 접기만 적용 — 엔티티는 이미 디코드된
    // 상태이며, 본문에 리터럴로 보이는 "&amp;" 텍스트와의 매칭을 지키기 위해
    // 검색어 쪽은 디코드하지 않는다.
    final needle =
        _collapseWhitespace(_MappedText.identity(selectedText)).text.trim();
    if (needle.isEmpty) return null;

    final normalized = _collapseWhitespace(_decodeEntities(plain));
    final idx = _nthIndexOf(normalized.text, needle, occurrence);
    if (idx < 0) return null;

    final rawStart = normalized.rawStarts[idx];
    final rawEnd = normalized.rawEnds[idx + needle.length - 1];
    return EpubSelection(
      spineHref: spineHref,
      start: rawStart,
      end: rawEnd,
      selectedText: needle,
    );
  }

  /// HTML 공백 접기에서 하나로 접히는 문자인지. `&nbsp;`(U+00A0)는 표준상
  /// 접히지 않지만, 렌더러/플랫폼별 선택 평문 차이를 흡수하기 위해 포함한다.
  static bool _isCollapsibleWhitespace(int code) =>
      code == 0x20 || // space
      code == 0x09 || // tab
      code == 0x0A || // LF
      code == 0x0B || // VT
      code == 0x0C || // FF
      code == 0x0D || // CR
      code == 0xA0; // NBSP

  static const Map<String, String> _namedEntities = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
  };

  /// [plain]의 문자 참조(named/numeric)를 디코드한 매핑 텍스트를 만든다.
  /// 디코드된 문자는 엔티티 원본 구간 전체(`&...;`)로 역매핑된다.
  _MappedText _decodeEntities(String plain) {
    final buffer = StringBuffer();
    final starts = <int>[];
    final ends = <int>[];
    var i = 0;
    while (i < plain.length) {
      final decoded = plain.codeUnitAt(i) == 0x26 ? _entityAt(plain, i) : null;
      if (decoded == null) {
        starts.add(i);
        ends.add(i + 1);
        buffer.write(plain[i]);
        i++;
        continue;
      }
      final (value, rawLength) = decoded;
      for (var unit = 0; unit < value.length; unit++) {
        starts.add(i);
        ends.add(i + rawLength);
      }
      buffer.write(value);
      i += rawLength;
    }
    return _MappedText(buffer.toString(), starts, ends);
  }

  /// [pos]('&')에서 시작하는 문자 참조를 파싱한다. (디코드 문자열, 원본 길이)
  /// 를 반환하고, 유효한 참조가 아니면 null.
  (String, int)? _entityAt(String plain, int pos) {
    final semi = plain.indexOf(';', pos + 1);
    // 엔티티 이름/숫자 참조는 짧다 — 멀리 있는 ';'는 참조 아님으로 간주.
    if (semi < 0 || semi - pos > 10) return null;
    final body = plain.substring(pos + 1, semi);
    if (body.isEmpty) return null;
    final rawLength = semi - pos + 1;
    if (body.startsWith('#')) {
      final digits = body.substring(1);
      final code = digits.startsWith('x') || digits.startsWith('X')
          ? int.tryParse(digits.substring(1), radix: 16)
          : int.tryParse(digits);
      if (code == null || code <= 0 || code > 0x10FFFF) return null;
      return (String.fromCharCode(code), rawLength);
    }
    final named = _namedEntities[body];
    return named == null ? null : (named, rawLength);
  }

  /// 연속 공백을 단일 스페이스로 접는다. 선두 공백 run은 제거한다(트림과
  /// 매칭 안정성 — 후미는 남아도 indexOf 매칭에 영향 없음).
  _MappedText _collapseWhitespace(_MappedText source) {
    final text = source.text;
    final buffer = StringBuffer();
    final starts = <int>[];
    final ends = <int>[];
    var i = 0;
    while (i < text.length) {
      if (!_isCollapsibleWhitespace(text.codeUnitAt(i))) {
        starts.add(source.rawStarts[i]);
        ends.add(source.rawEnds[i]);
        buffer.write(text[i]);
        i++;
        continue;
      }
      final runStart = i;
      do {
        i++;
      } while (i < text.length && _isCollapsibleWhitespace(text.codeUnitAt(i)));
      if (buffer.isEmpty) continue; // 선두 공백 run 제거
      starts.add(source.rawStarts[runStart]);
      ends.add(source.rawEnds[i - 1]);
      buffer.write(' ');
    }
    return _MappedText(buffer.toString(), starts, ends);
  }

  /// 하이라이트 탭 라우팅용 링크 스킴. [injectHighlights]가 `tappable: true`로
  /// 주입한 `<a href>`의 prefix이며, flutter_html `onLinkTap`이 이 스킴으로
  /// 시작하는 url을 하이라이트 탭으로 식별한다. (S7.3)
  static const String highlightLinkScheme = 'openepub-hl:';

  /// onLinkTap이 받은 [href]가 하이라이트 링크면 그 id를, 아니면 null. (S7.3)
  static String? highlightIdFromHref(String href) =>
      href.startsWith(highlightLinkScheme)
          ? href.substring(highlightLinkScheme.length)
          : null;

  /// [highlights]를 평문 오프셋 기준으로 [xhtml] 원본에 배경색으로 주입한다.
  /// 태그를 파손하지 않으며, 여러 텍스트 노드에 걸친 하이라이트는 노드별로
  /// 분할해 감싼다. 범위를 벗어나거나 빈 하이라이트는 건너뛴다.
  ///
  /// [tappable]이 true면 `<span>` 대신 `<a href="openepub-hl:ID">`로 감싸
  /// flutter_html `onLinkTap`으로 탭을 받을 수 있게 한다(밑줄/링크색은
  /// 제거). (S7.3)
  String injectHighlights(
    String xhtml,
    Iterable<EpubHighlight> highlights, {
    bool tappable = false,
  }) {
    final runs = _runs(xhtml);
    if (runs.isEmpty) return xhtml;
    final plainLength = runs.fold<int>(0, (sum, r) => sum + r.length);

    // (원본 위치, 삽입 문자열, 우선순위) — 같은 위치에서 close(0) → open(1)
    // 순으로 적용해 인접 하이라이트가 깔끔히 닫히고 열리게 한다.
    final inserts = <_Insert>[];
    for (final h in highlights) {
      final start = h.start;
      final end = h.end;
      if (end <= start) continue;
      if (start >= plainLength) continue;
      final clampedEnd = end > plainLength ? plainLength : end;
      final color = _cssHex(h.colorArgb);
      final (open, close) = tappable
          ? (
              '<a href="$highlightLinkScheme${h.id}" '
                  'style="background-color:$color;color:inherit;'
                  'text-decoration:none;">',
              '</a>',
            )
          : ('<span style="background-color:$color;">', '</span>');
      _emitSpansForRange(runs, start, clampedEnd, open, close, inserts);
    }
    if (inserts.isEmpty) return xhtml;

    inserts.sort((a, b) {
      final byPos = a.pos.compareTo(b.pos);
      return byPos != 0 ? byPos : a.priority.compareTo(b.priority);
    });

    final buffer = StringBuffer();
    var cursor = 0;
    for (final ins in inserts) {
      if (ins.pos > cursor) buffer.write(xhtml.substring(cursor, ins.pos));
      buffer.write(ins.text);
      cursor = ins.pos;
    }
    buffer.write(xhtml.substring(cursor));
    return buffer.toString();
  }

  /// 평문 구간 [start,end)를 run 단위로 분할해 각 조각을 감싸는 open/close
  /// 삽입을 생성한다.
  void _emitSpansForRange(
    List<_Run> runs,
    int start,
    int end,
    String open,
    String close,
    List<_Insert> inserts,
  ) {
    var plainCursor = 0;
    for (final run in runs) {
      final runStartPlain = plainCursor;
      final runEndPlain = plainCursor + run.length;
      plainCursor = runEndPlain;
      if (runEndPlain <= start) continue; // 아직 구간 이전
      if (runStartPlain >= end) break; // 구간 이후
      final sliceStartPlain = start > runStartPlain ? start : runStartPlain;
      final sliceEndPlain = end < runEndPlain ? end : runEndPlain;
      final srcOpen = run.start + (sliceStartPlain - runStartPlain);
      final srcClose = run.start + (sliceEndPlain - runStartPlain);
      inserts.add(_Insert(srcOpen, open, 1));
      inserts.add(_Insert(srcClose, close, 0));
    }
  }

  /// body 영역에서 태그 밖 텍스트 run들을 추출. script/style 요소 내용은 제외.
  List<_Run> _runs(String xhtml) {
    final contentStart = _bodyContentStart(xhtml);
    final contentEnd = _bodyContentEnd(xhtml);
    final runs = <_Run>[];
    var i = contentStart;
    int? runStart;
    while (i < contentEnd) {
      if (xhtml.codeUnitAt(i) == 0x3C) {
        // '<'
        if (runStart != null) {
          runs.add(_Run(runStart, i));
          runStart = null;
        }
        final skipTo = _skipRawElement(xhtml, i, 'script') ??
            _skipRawElement(xhtml, i, 'style');
        if (skipTo != null) {
          i = skipTo;
          continue;
        }
        final gt = xhtml.indexOf('>', i);
        if (gt < 0) break;
        i = gt + 1;
      } else {
        runStart ??= i;
        i++;
      }
    }
    if (runStart != null) runs.add(_Run(runStart, contentEnd));
    return runs;
  }

  /// [pos]가 `<script`/`<style` 여는 태그면 닫는 태그 다음 위치를 반환, 아니면 null.
  int? _skipRawElement(String xhtml, int pos, String tag) {
    if (!_startsWithTag(xhtml, pos, tag)) return null;
    final close = xhtml.toLowerCase().indexOf('</$tag', pos);
    if (close < 0) return xhtml.length;
    final gt = xhtml.indexOf('>', close);
    return gt < 0 ? xhtml.length : gt + 1;
  }

  bool _startsWithTag(String xhtml, int pos, String tag) {
    final after = pos + 1 + tag.length;
    if (after > xhtml.length) return false;
    if (!xhtml.substring(pos + 1, after).toLowerCase().startsWith(tag)) {
      return false;
    }
    // 태그명 경계: 다음 문자가 공백/>/ 슬래시 여야 함 (<style> vs <styleX>)
    final next = after < xhtml.length ? xhtml[after] : '>';
    return next == '>' ||
        next == ' ' ||
        next == '\t' ||
        next == '\n' ||
        next == '\r' ||
        next == '/';
  }

  int _bodyContentStart(String xhtml) {
    final lower = xhtml.toLowerCase();
    final body = lower.indexOf('<body');
    if (body < 0) return 0;
    final gt = xhtml.indexOf('>', body);
    return gt < 0 ? 0 : gt + 1;
  }

  int _bodyContentEnd(String xhtml) {
    final lower = xhtml.toLowerCase();
    final body = lower.indexOf('</body');
    return body < 0 ? xhtml.length : body;
  }

  int _nthIndexOf(String haystack, String needle, int n) {
    if (needle.isEmpty) return -1;
    var from = 0;
    var count = 0;
    while (true) {
      final idx = haystack.indexOf(needle, from);
      if (idx < 0) return -1;
      if (count == n) return idx;
      count++;
      from = idx + 1;
    }
  }

  static String _cssHex(int argb) {
    final rgb = argb & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _Insert {
  const _Insert(this.pos, this.text, this.priority);
  final int pos;
  final String text;
  final int priority;
}

/// 문자 단위 원본 구간 매핑을 가진 텍스트 — 정규화 매칭의 역매핑용.
/// [rawStarts]/[rawEnds]는 [text]의 각 code unit이 유래한 원본 [start,end).
/// [SpineTextExtractor.decodePlainText]의 결과 — 디코드된 body 평문 + raw
/// charOffset(extractPlainText 공간) ↔ 디코드 offset 양방향 변환. (S12.2 CFI)
class PlainTextDecodeMapping {
  const PlainTextDecodeMapping._(this.decoded, this._rawStarts, this._rawEnds);

  /// 엔티티가 디코드된 body 평문. DOM 텍스트 노드 concat과 동일 공간.
  final String decoded;
  final List<int> _rawStarts;
  final List<int> _rawEnds;

  /// 디코드 offset → raw charOffset. 경계 밖은 clamp.
  int decodedToRaw(int decodedOffset) {
    if (decodedOffset <= 0) return 0;
    if (decodedOffset >= decoded.length) {
      return _rawEnds.isEmpty ? 0 : _rawEnds.last;
    }
    return _rawStarts[decodedOffset];
  }

  /// raw charOffset → 디코드 offset. rawStarts는 비감소이므로 이진 탐색으로
  /// rawStarts[j] < rawOffset 인 디코드 char 개수를 구한다(=그 앞 문자 수).
  int rawToDecoded(int rawOffset) {
    if (rawOffset <= 0) return 0;
    var lo = 0;
    var hi = decoded.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_rawStarts[mid] < rawOffset) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

class _MappedText {
  const _MappedText(this.text, this.rawStarts, this.rawEnds);

  /// 원본 그대로(1:1 매핑) — 검색어처럼 역매핑이 자기 자신인 텍스트.
  factory _MappedText.identity(String text) => _MappedText(
        text,
        List<int>.generate(text.length, (i) => i),
        List<int>.generate(text.length, (i) => i + 1),
      );

  final String text;
  final List<int> rawStarts;
  final List<int> rawEnds;
}
