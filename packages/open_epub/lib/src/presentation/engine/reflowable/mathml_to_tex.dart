// Presentation Engine — open_epub 1.0
// Story: S14.2 (#106) — MathML 자체 폴백 (gap #5)
//
// fwfh는 `<math>`(MathML)를 렌더하지 않는다. 이 변환기는 MathML presentation
// 트리를 LaTeX(TeX) 문자열로 바꿔 flutter_math_fork(Math.tex)로 렌더할 수 있게
// 한다. 변환 우선순위:
//   1. <annotation encoding="application/x-tex"> — 생성기가 심은 원본 TeX(최상)
//   2. math[alttext] — LaTeX 원본이 흔함
//   3. presentation MathML 트리 재귀 변환(근사)
//
// 변환 결과가 비면 null을 반환한다(호출자가 never-empty placeholder로 폴백,
// ADR-009). 근사 변환이 잘못된 TeX를 만들면 Math.tex의 onErrorFallback이
// placeholder로 폴백하므로 공백은 발생하지 않는다.

import 'package:html/dom.dart' as dom;

/// MathML `<math>` 요소를 TeX로 변환한다. 의미 있는 수식을 만들지 못하면 null.
String? mathmlToTex(dom.Element math) {
  // 1) TeX annotation이 있으면 그대로 사용(가장 신뢰도 높음).
  final annotation = _findTexAnnotation(math);
  if (annotation != null) {
    final trimmed = annotation.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }

  // 2) presentation 트리 변환.
  final converted = _convertChildren(math).trim();
  if (converted.isNotEmpty) return converted;

  // 3) alttext 폴백(LaTeX 원본이 흔함).
  final alt = math.attributes['alttext']?.trim();
  if (alt != null && alt.isNotEmpty) return alt;

  return null;
}

/// `<semantics>` 안의 `<annotation encoding="application/x-tex">` 텍스트.
String? _findTexAnnotation(dom.Element root) {
  for (final el in root.querySelectorAll('annotation')) {
    final enc = el.attributes['encoding']?.toLowerCase() ?? '';
    if (enc.contains('x-tex') || enc.contains('tex')) {
      return el.text;
    }
  }
  return null;
}

/// 요소의 로컬 이름(네임스페이스 접두사 `m:` 등 제거, 소문자).
String _localName(dom.Element el) {
  final name = el.localName ?? '';
  final colon = name.indexOf(':');
  return (colon >= 0 ? name.substring(colon + 1) : name).toLowerCase();
}

/// presentation 자식 노드들을 순서대로 변환해 공백으로 잇는다(juxtaposition).
String _convertChildren(dom.Element parent) {
  final parts = <String>[];
  for (final node in parent.nodes) {
    final tex = _convertNode(node);
    if (tex.isNotEmpty) parts.add(tex);
  }
  return parts.join(' ');
}

/// presentation 자식 요소만(텍스트 노드 무시) 변환한 리스트 — 위치 인자용.
List<String> _convertElementChildren(dom.Element parent) {
  final parts = <String>[];
  for (final child in parent.children) {
    final tex = _convertElement(child);
    if (tex.isNotEmpty) parts.add(tex);
  }
  return parts;
}

String _convertNode(dom.Node node) {
  if (node is dom.Element) return _convertElement(node);
  if (node is dom.Text) {
    // mrow 등에 직접 놓인 텍스트는 드물다. 공백만이면 무시.
    final t = node.text.trim();
    return t.isEmpty ? '' : _mapText(t);
  }
  return '';
}

String _convertElement(dom.Element el) {
  switch (_localName(el)) {
    case 'mi':
      return _mapSymbol(el.text.trim());
    case 'mn':
      return _escapeLiteral(el.text.trim());
    case 'mo':
      return _mapOperator(el.text.trim());
    case 'mtext':
      final t = el.text;
      return t.trim().isEmpty ? '' : '\\text{${_escapeText(t)}}';
    case 'mspace':
      return '\\;';
    case 'mrow':
    case 'mstyle':
    case 'mpadded':
    case 'mphantom':
      return _convertChildren(el);
    case 'semantics':
      // 첫 presentation 자식만(annotation은 상위에서 처리).
      final children = _convertElementChildren(el);
      return children.isEmpty ? '' : children.first;
    case 'mfrac':
      final c = _convertElementChildren(el);
      if (c.length >= 2) return '\\frac{${c[0]}}{${c[1]}}';
      return _wrapGroup(c);
    case 'msqrt':
      return '\\sqrt{${_convertChildren(el)}}';
    case 'mroot':
      final c = _convertElementChildren(el);
      if (c.length >= 2) return '\\sqrt[${c[1]}]{${c[0]}}';
      return '\\sqrt{${c.isEmpty ? '' : c[0]}}';
    case 'msup':
      final c = _convertElementChildren(el);
      if (c.length >= 2) return '{${c[0]}}^{${c[1]}}';
      return _wrapGroup(c);
    case 'msub':
      final c = _convertElementChildren(el);
      if (c.length >= 2) return '{${c[0]}}_{${c[1]}}';
      return _wrapGroup(c);
    case 'msubsup':
      final c = _convertElementChildren(el);
      if (c.length >= 3) return '{${c[0]}}_{${c[1]}}^{${c[2]}}';
      return _wrapGroup(c);
    case 'munderover':
      final c = _convertElementChildren(el);
      if (c.length >= 3) return '${c[0]}_{${c[1]}}^{${c[2]}}';
      return _wrapGroup(c);
    case 'munder':
      final c = _convertElementChildren(el);
      if (c.length >= 2) return '\\underset{${c[1]}}{${c[0]}}';
      return _wrapGroup(c);
    case 'mover':
      final c = _convertElementChildren(el);
      if (c.length >= 2) return '\\overset{${c[1]}}{${c[0]}}';
      return _wrapGroup(c);
    case 'mfenced':
      return _convertFenced(el);
    case 'mtable':
      return _convertTable(el);
    case 'math':
      return _convertChildren(el);
    default:
      // 알 수 없는 요소는 자식을 최선으로 변환(mrow 취급).
      return _convertChildren(el);
  }
}

/// mfenced → `\left<open> c0 sep c1 ... \right<close>`.
String _convertFenced(dom.Element el) {
  final open = el.attributes['open'] ?? '(';
  final close = el.attributes['close'] ?? ')';
  final sepAttr = el.attributes['separators'] ?? ',';
  final seps = sepAttr.replaceAll(' ', '').split('');
  final children = _convertElementChildren(el);
  final buf = StringBuffer('\\left${_mapDelimiter(open)} ');
  for (var i = 0; i < children.length; i++) {
    if (i > 0) {
      final sep = seps.isEmpty ? ',' : seps[(i - 1).clamp(0, seps.length - 1)];
      buf.write('$sep ');
    }
    buf.write(children[i]);
  }
  buf.write(' \\right${_mapDelimiter(close)}');
  return buf.toString();
}

/// mtable → \begin{matrix} ... \end{matrix}.
String _convertTable(dom.Element el) {
  final rows = <String>[];
  for (final tr in el.children.where((c) => _localName(c) == 'mtr')) {
    final cells = <String>[];
    for (final td in tr.children.where((c) => _localName(c) == 'mtd')) {
      cells.add(_convertChildren(td));
    }
    rows.add(cells.join(' & '));
  }
  if (rows.isEmpty) return '';
  return '\\begin{matrix} ${rows.join(' \\\\ ')} \\end{matrix}';
}

String _wrapGroup(List<String> parts) => parts.join(' ');

String _mapDelimiter(String d) {
  switch (d) {
    case '{':
      return '\\{';
    case '}':
      return '\\}';
    case '|':
      return '|';
    case '':
      return '.';
    default:
      return d;
  }
}

/// mi 내용 → 심볼(그리스 문자 등) 매핑, 아니면 리터럴 이스케이프.
String _mapSymbol(String s) {
  if (s.isEmpty) return '';
  if (s.length == 1) {
    final mapped = _symbolMap[s];
    if (mapped != null) return mapped;
  }
  return _escapeLiteral(s);
}

/// mo 내용 → 연산자 매핑. 보이지 않는 연산자(InvisibleTimes 등)는 제거.
String _mapOperator(String s) {
  if (s.isEmpty) return '';
  if (_invisible.contains(s)) return '';
  if (s.length == 1) {
    final mapped = _symbolMap[s];
    if (mapped != null) return mapped;
  }
  final mappedMulti = _symbolMap[s];
  if (mappedMulti != null) return mappedMulti;
  return _escapeLiteral(s);
}

/// mrow에 직접 놓인 텍스트 매핑.
String _mapText(String s) => _symbolMap[s] ?? _escapeLiteral(s);

/// TeX 리터럴에서 특수문자 이스케이프( \text{} 밖 — 수식 모드 ).
String _escapeLiteral(String s) {
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    switch (ch) {
      case '{':
      case '}':
      case '%':
      case '&':
      case '#':
      case r'$':
        buf.write('\\$ch');
      case '_':
        buf.write(r'\_');
      case '^':
        buf.write(r'\char94 ');
      case '~':
        buf.write(r'\sim ');
      case r'\':
        buf.write(r'\backslash ');
      default:
        buf.write(_symbolMap[ch] ?? ch);
    }
  }
  return buf.toString();
}

/// \text{} 안 텍스트 이스케이프.
String _escapeText(String s) => s
    .replaceAll(r'\', r'\backslash ')
    .replaceAll('{', r'\{')
    .replaceAll('}', r'\}')
    .replaceAll(r'$', r'\$')
    .replaceAll('&', r'\&')
    .replaceAll('%', r'\%')
    .replaceAll('#', r'\#')
    .replaceAll('_', r'\_');

/// 보이지 않는 MathML 연산자(제어 문자) — 제거 대상.
const Set<String> _invisible = {
  '⁡', // FunctionApplication
  '⁢', // InvisibleTimes
  '⁣', // InvisibleComma
  '⁤', // InvisiblePlus
};

/// 유니코드 수학 기호 → TeX 매핑(대표적인 것만; 미등록은 원문 통과).
const Map<String, String> _symbolMap = {
  // 연산자
  '×': r'\times',
  '⋅': r'\cdot',
  '·': r'\cdot',
  '÷': r'\div',
  '−': '-',
  '±': r'\pm',
  '∓': r'\mp',
  '≤': r'\leq',
  '≥': r'\geq',
  '≠': r'\neq',
  '≈': r'\approx',
  '≡': r'\equiv',
  '∼': r'\sim',
  '∞': r'\infty',
  '∂': r'\partial',
  '∇': r'\nabla',
  '∑': r'\sum',
  '∏': r'\prod',
  '∫': r'\int',
  '√': r'\sqrt',
  '∘': r'\circ',
  '…': r'\ldots',
  '⋯': r'\cdots',
  '→': r'\rightarrow',
  '←': r'\leftarrow',
  '↔': r'\leftrightarrow',
  '⇒': r'\Rightarrow',
  '⇐': r'\Leftarrow',
  '⇔': r'\Leftrightarrow',
  '∈': r'\in',
  '∉': r'\notin',
  '⊂': r'\subset',
  '⊆': r'\subseteq',
  '⊃': r'\supset',
  '∪': r'\cup',
  '∩': r'\cap',
  '∀': r'\forall',
  '∃': r'\exists',
  '∅': r'\emptyset',
  '¬': r'\neg',
  '∧': r'\wedge',
  '∨': r'\vee',
  '⟨': r'\langle',
  '⟩': r'\rangle',
  '′': "'",
  // 소문자 그리스
  'α': r'\alpha',
  'β': r'\beta',
  'γ': r'\gamma',
  'δ': r'\delta',
  'ε': r'\epsilon',
  'ζ': r'\zeta',
  'η': r'\eta',
  'θ': r'\theta',
  'ι': r'\iota',
  'κ': r'\kappa',
  'λ': r'\lambda',
  'μ': r'\mu',
  'ν': r'\nu',
  'ξ': r'\xi',
  'π': r'\pi',
  'ρ': r'\rho',
  'σ': r'\sigma',
  'τ': r'\tau',
  'υ': r'\upsilon',
  'φ': r'\phi',
  'χ': r'\chi',
  'ψ': r'\psi',
  'ω': r'\omega',
  // 대문자 그리스
  'Γ': r'\Gamma',
  'Δ': r'\Delta',
  'Θ': r'\Theta',
  'Λ': r'\Lambda',
  'Ξ': r'\Xi',
  'Π': r'\Pi',
  'Σ': r'\Sigma',
  'Φ': r'\Phi',
  'Ψ': r'\Psi',
  'Ω': r'\Omega',
};
