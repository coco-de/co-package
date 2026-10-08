import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hangul_two_set_composer.dart';

/// 프레임워크 우선 키 처리·확정과 표시의 연속 갱신·조합 중 교체를 모사한다.
class DesktopTextInputDouble {
  DesktopTextInputDouble(this.tester) : _seen = tester.testTextInput.log.length;

  final WidgetTester tester;
  bool korean = false;
  int discardedCompositions = 0;
  final _composer = HangulTwoSetComposer();
  String _text = '';
  TextRange _marked = TextRange.empty;
  int _seen;

  static const _keyToJamo = {
    'r': 'ㄱ', 'R': 'ㄲ', 's': 'ㄴ', 'e': 'ㄷ', 'E': 'ㄸ', 'f': 'ㄹ', 'a': 'ㅁ', //
    'q': 'ㅂ', 'Q': 'ㅃ', 't': 'ㅅ', 'T': 'ㅆ', 'd': 'ㅇ', 'w': 'ㅈ', 'W': 'ㅉ',
    'c': 'ㅊ', 'z': 'ㅋ', 'x': 'ㅌ', 'v': 'ㅍ', 'g': 'ㅎ', 'k': 'ㅏ', 'o': 'ㅐ',
    'i': 'ㅑ', 'O': 'ㅒ', 'j': 'ㅓ', 'p': 'ㅔ', 'u': 'ㅕ', 'P': 'ㅖ', 'h': 'ㅗ',
    'y': 'ㅛ', 'n': 'ㅜ', 'b': 'ㅠ', 'm': 'ㅡ', 'l': 'ㅣ',
  };

  Future<void> press(String key) async {
    final (logical, physical, character, shift) = _describe(key);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final handled = await tester.sendKeyDownEvent(
      logical,
      physicalKey: physical,
      character: character,
    );
    _adoptFrameworkStates();
    if (!handled) {
      await _interpret(key, character);
      _adoptFrameworkStates();
    }
    await tester.sendKeyUpEvent(logical, physicalKey: physical);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
  }

  Future<void> commitComposition() async {
    if (!_composer.isComposing) return;
    await _apply(commit: _composer.flush(), marked: '');
    _adoptFrameworkStates();
    await tester.pump();
  }

  Future<void> _interpret(String key, String? character) async {
    switch (key) {
      case '<backspace>':
        if (!_composer.isComposing) return;
        _composer.backspace();
        await _apply(commit: '', marked: _composer.marked);
      case '<escape>':
        if (!_composer.isComposing) return;
        _composer.reset();
        await _apply(commit: '', marked: '');
      default:
        if (character == null) return;
        if (!korean || !_keyToJamo.containsValue(character)) {
          await _apply(commit: _composer.flush() + character, marked: '');
          return;
        }
        final committed = _composer.input(character);
        await _apply(commit: committed, marked: _composer.marked);
    }
  }

  Future<void> _apply({required String commit, required String marked}) async {
    final base = _marked.isValid && !_marked.isCollapsed
        ? _text.replaceRange(_marked.start, _marked.end, '')
        : _text;
    _text = base + commit;
    _marked = TextRange.empty;
    if (commit.isNotEmpty || marked.isEmpty) await _deliver();
    if (marked.isNotEmpty) {
      _marked =
          TextRange(start: _text.length, end: _text.length + marked.length);
      _text += marked;
      await _deliver();
    }
  }

  Future<void> _deliver() async {
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: _text,
      selection: TextSelection.collapsed(offset: _text.length),
      composing: _marked,
    ));
    await tester.idle();
  }

  void _adoptFrameworkStates() {
    final log = tester.testTextInput.log;
    String? latest;
    for (; _seen < log.length; _seen++) {
      final call = log[_seen];
      if (call.method == 'TextInput.setEditingState') {
        latest = (call.arguments as Map)['text'] as String;
      }
    }
    if (latest == null) return;
    if (_composer.isComposing) {
      _composer.reset();
      discardedCompositions++;
    }
    _text = latest;
    _marked = TextRange.empty;
  }

  (LogicalKeyboardKey, PhysicalKeyboardKey, String?, bool) _describe(
      String key) {
    switch (key) {
      case '<backspace>':
        return (
          LogicalKeyboardKey.backspace,
          PhysicalKeyboardKey.backspace,
          null,
          false
        );
      case '<escape>':
        return (
          LogicalKeyboardKey.escape,
          PhysicalKeyboardKey.escape,
          null,
          false
        );
      case ' ':
        return (
          LogicalKeyboardKey.space,
          PhysicalKeyboardKey.space,
          ' ',
          false
        );
    }
    final lower = key.toLowerCase();
    final offset = lower.codeUnitAt(0) - 'a'.codeUnitAt(0);
    return (
      LogicalKeyboardKey(0x61 + offset),
      PhysicalKeyboardKey(0x00070004 + offset),
      korean ? _keyToJamo[key] : key,
      key != lower,
    );
  }
}
