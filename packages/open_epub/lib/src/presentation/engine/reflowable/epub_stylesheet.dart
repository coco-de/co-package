// Presentation Engine — open_epub 1.0
// Issue: #278 — 문서 내 <style> 선택자를 매칭해 customStylesBuilder로 넘긴다.
//
// flutter_widget_from_html_core는 CSS를 요소 style 속성과 customStylesBuilder에서만
// 읽는다. <style> 블록은 <script>와 같이 숨겨지므로, 여기서 선택자를 적용한다.
// 지원: 태그/클래스/id/`*`와 자손( )·자식(>) 조합. 속성 선택자·의사 클래스·
// @media·var()는 건너뛴다(fwfh 비지원 속성은 매칭되어도 렌더러가 무시).

import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// 문서 `<style>`에서 추출한 규칙. [stylesFor]가 fwfh `customStylesBuilder`에 연결된다.
class EpubStylesheet {
  EpubStylesheet._(this._rules, this._document);

  factory EpubStylesheet.parse(String xhtml) {
    final document = html_parser.parse(xhtml);
    final cssText = document
        .querySelectorAll('style')
        .map((el) => el.text)
        .where((text) => text.trim().isNotEmpty)
        .join('\n');
    final rules = <_Rule>[];
    if (cssText.isNotEmpty) {
      final errors = <css_parser.Message>[];
      final sheet = css_parser.parse(cssText, errors: errors);
      var order = 0;
      for (final node in sheet.topLevels) {
        if (node is css.RuleSet) {
          _collectRule(node, rules, order);
          order++;
        }
      }
    }
    return EpubStylesheet._(List<_Rule>.unmodifiable(rules), document);
  }

  final List<_Rule> _rules;
  final dom.Document _document;

  /// html/body에 실제로 적용된 writing-mode가 vertical-*인지.
  /// 미사용 클래스 선언만 있는 `<style>`은 false다.
  bool get rootIsVerticalWriting {
    final mode = rootWritingMode;
    return mode != null && _verticalWritingValue.hasMatch(mode);
  }

  /// html/body의 writing-mode가 vertical-lr인지(그 외 vertical은 rl).
  bool get rootIsVerticalLr {
    final mode = rootWritingMode;
    return mode != null &&
        RegExp(r'vertical-lr', caseSensitive: false).hasMatch(mode);
  }

  /// html/body에 적용된 writing-mode 값. 인라인 style이 스타일시트보다 우선.
  String? get rootWritingMode {
    return _writingModeOf(_document.documentElement) ??
        _writingModeOf(_document.body);
  }

  bool get isEmpty => _rules.isEmpty;

  /// [element]에 매칭되는 선언. 없으면 null. 인라인 style은 fwfh가 이후에 덮어쓴다.
  Map<String, String>? stylesFor(dom.Element element) {
    final matched = <_Rule>[];
    for (final rule in _rules) {
      if (_selectorMatches(element, rule.selector)) {
        matched.add(rule);
      }
    }
    if (matched.isEmpty) return null;
    matched.sort((a, b) {
      final spec = a.specificity.compareTo(b.specificity);
      if (spec != 0) return spec;
      return a.order.compareTo(b.order);
    });
    final out = <String, String>{};
    for (final rule in matched) {
      out.addAll(rule.declarations);
    }
    return out;
  }

  String? _writingModeOf(dom.Element? element) {
    if (element == null) return null;
    final inline = element.attributes['style'];
    if (inline != null) {
      final match = RegExp(
        r'writing-mode\s*:\s*([^;]+)',
        caseSensitive: false,
      ).firstMatch(inline);
      if (match != null) return match.group(1)!.trim();
    }
    return stylesFor(element)?['writing-mode'];
  }
}

final _verticalWritingValue = RegExp(
  r'vertical-(rl|lr)',
  caseSensitive: false,
);

/// csslib Expression.span은 숫자만 남기는 경우가 있어(`1em` → `1`),
/// 선언 원문에서 콜론 뒤를 쓴다.
String _declarationValue(css.Declaration node) {
  final raw = node.span.text;
  final colon = raw.indexOf(':');
  var value = colon >= 0 ? raw.substring(colon + 1).trim() : '';
  if (value.endsWith(';')) {
    value = value.substring(0, value.length - 1).trim();
  }
  if (value.isEmpty) {
    value = (node.expression?.span?.text ?? node.expression?.toString() ?? '')
        .trim();
  }
  if (node.important && !value.toLowerCase().contains('important')) {
    value = '$value !important';
  }
  return value;
}

void _collectRule(css.RuleSet ruleSet, List<_Rule> rules, int order) {
  final group = ruleSet.selectorGroup;
  if (group == null) return;
  final declarations = <String, String>{};
  for (final node in ruleSet.declarationGroup.declarations) {
    if (node is! css.Declaration) continue;
    final name = node.property.trim().toLowerCase();
    if (name.isEmpty) continue;
    final value = _declarationValue(node);
    if (value.isEmpty) continue;
    declarations[name] = value;
  }
  if (declarations.isEmpty) return;
  for (final selector in group.selectors) {
    if (!_selectorSupported(selector)) continue;
    rules.add(
      _Rule(
        selector: selector,
        declarations: Map<String, String>.unmodifiable(declarations),
        specificity: _specificity(selector),
        order: order,
      ),
    );
  }
}

bool _selectorSupported(css.Selector selector) {
  for (final seq in selector.simpleSelectorSequences) {
    if (seq.isCombinatorPlus || seq.isCombinatorTilde) return false;
    if (!_simpleSupported(seq.simpleSelector)) return false;
  }
  return selector.simpleSelectorSequences.isNotEmpty;
}

bool _simpleSupported(css.SimpleSelector simple) {
  return simple is css.ElementSelector ||
      simple is css.ClassSelector ||
      simple is css.IdSelector ||
      simple.isWildcard;
}

int _specificity(css.Selector selector) {
  var ids = 0;
  var classes = 0;
  var types = 0;
  for (final seq in selector.simpleSelectorSequences) {
    final simple = seq.simpleSelector;
    if (simple is css.IdSelector) {
      ids++;
    } else if (simple is css.ClassSelector) {
      classes++;
    } else if (simple is css.ElementSelector && !simple.isWildcard) {
      types++;
    }
  }
  return ids * 100 + classes * 10 + types;
}

bool _selectorMatches(dom.Element element, css.Selector selector) {
  final compounds = _compounds(selector);
  if (compounds.isEmpty) return false;
  return _matchCompound(element, compounds, compounds.length - 1);
}

class _Compound {
  _Compound(this.simples, this.combinator);
  final List<css.SimpleSelector> simples;
  final int combinator;
}

List<_Compound> _compounds(css.Selector selector) {
  final out = <_Compound>[];
  List<css.SimpleSelector>? current;
  var combinator = css_parser.TokenKind.COMBINATOR_NONE;
  for (final seq in selector.simpleSelectorSequences) {
    if (current == null) {
      current = [seq.simpleSelector];
      combinator = seq.combinator;
    } else if (seq.isCombinatorNone) {
      current.add(seq.simpleSelector);
    } else {
      out.add(_Compound(current, combinator));
      current = [seq.simpleSelector];
      combinator = seq.combinator;
    }
  }
  if (current != null) {
    out.add(_Compound(current, combinator));
  }
  return out;
}

bool _matchCompound(
  dom.Element? element,
  List<_Compound> compounds,
  int index,
) {
  if (index < 0) return true;
  if (element == null) return false;
  final compound = compounds[index];
  if (!_compoundMatches(element, compound.simples)) return false;
  if (index == 0) return true;
  final previous = compounds[index].combinator;
  if (previous == css_parser.TokenKind.COMBINATOR_GREATER) {
    return _matchCompound(_elementParent(element), compounds, index - 1);
  }
  if (previous == css_parser.TokenKind.COMBINATOR_DESCENDANT) {
    var ancestor = _elementParent(element);
    while (ancestor != null) {
      if (_matchCompound(ancestor, compounds, index - 1)) return true;
      ancestor = _elementParent(ancestor);
    }
    return false;
  }
  // COMBINATOR_NONE on a non-first compound should not happen after grouping.
  return _matchCompound(_elementParent(element), compounds, index - 1);
}

bool _compoundMatches(dom.Element element, List<css.SimpleSelector> simples) {
  for (final simple in simples) {
    if (!_simpleMatches(element, simple)) return false;
  }
  return true;
}

bool _simpleMatches(dom.Element element, css.SimpleSelector simple) {
  if (simple.isWildcard) return true;
  if (simple is css.ElementSelector) {
    return (element.localName ?? '').toLowerCase() == simple.name.toLowerCase();
  }
  if (simple is css.ClassSelector) {
    return element.classes.contains(simple.name);
  }
  if (simple is css.IdSelector) {
    return element.id == simple.name;
  }
  return false;
}

dom.Element? _elementParent(dom.Element element) {
  final parent = element.parent;
  return parent is dom.Element ? parent : null;
}

class _Rule {
  const _Rule({
    required this.selector,
    required this.declarations,
    required this.specificity,
    required this.order,
  });

  final css.Selector selector;
  final Map<String, String> declarations;
  final int specificity;
  final int order;
}
