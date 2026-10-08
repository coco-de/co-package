import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm2/xterm.dart';

import 'desktop_text_input_double.dart';
import 'hangul_two_set_composer.dart';

// Cocode AC-16 말뭉치: 물리 키·한글 입력원 시작 위치·PTY가 받을 최종 텍스트.
const _trials = [
  ('t1-single-syllable', ['g', 'k', 's'], 0, '한'),
  (
    't2-lumide-64-string',
    ['g', 'k', 's', 'r', 'm', 'f', 'x', 'p', 't', 'm', 'x', 'm'],
    0,
    '한글테스트'
  ),
  ('t3-jongseong-migration', ['r', 'k', 's', 'k'], 0, '가나'),
  ('t4-compound-jongseong', ['e', 'k', 'f', 'r'], 0, '닭'),
  ('t5-backspace-in-composition', ['g', 'k', 's', '<backspace>'], 0, '하'),
  (
    't6-mixed-latin-hangul',
    ['e', 'c', 'h', 'o', ' ', 'g', 'k', 's'],
    5,
    'echo 한'
  ),
  ('t7-escape-cancels-composition', ['g', 'k', '<escape>'], 0, ''),
];

void main() {
  group('HangulTwoSetComposer', () {
    test('marks syllables and commits when the next jamo cannot join', () {
      final composer = HangulTwoSetComposer();
      final steps = <String>[];
      var committed = '';
      for (final jamo in 'ㅎㅏㄴㄱㅡㄹㅌㅔㅅㅡㅌㅡ'.split('')) {
        committed += composer.input(jamo);
        steps.add(committed + composer.marked);
      }
      expect(steps, [
        'ㅎ', '하', '한', '한ㄱ', '한그', '한글', '한긅', '한글테', '한글텟', //
        '한글테스', '한글테슽', '한글테스트',
      ]);
      expect(committed + composer.flush(), '한글테스트');
    });

    test('moves a final consonant to the next syllable', () {
      final composer = HangulTwoSetComposer();
      for (final jamo in ['ㄱ', 'ㅏ', 'ㄴ']) {
        composer.input(jamo);
      }
      expect(composer.input('ㅏ'), '가');
      expect(composer.marked, '나');
    });

    test('builds compound finals and splits them before a vowel', () {
      final composer = HangulTwoSetComposer();
      for (final jamo in ['ㄷ', 'ㅏ', 'ㄹ', 'ㄱ']) {
        composer.input(jamo);
      }
      expect(composer.marked, '닭');
      expect(composer.input('ㅣ'), '달');
      expect(composer.marked, '기');
    });

    test('backspace removes one jamo at a time', () {
      final composer = HangulTwoSetComposer();
      for (final jamo in ['ㅎ', 'ㅏ', 'ㄴ']) {
        composer.input(jamo);
      }
      composer.backspace();
      expect(composer.marked, '하');
      composer.backspace();
      expect(composer.marked, 'ㅎ');
      composer.backspace();
      expect(composer.isComposing, isFalse);
    });
  });

  testWidgets('an action ending a composition sends the syllable first',
      variant: TargetPlatformVariant.desktop(), (tester) async {
    final output = <String>[];
    final terminal = Terminal(onOutput: output.add);
    await tester.pumpWidget(MaterialApp(
      home: TerminalView(terminal, autofocus: true),
    ));
    await tester.pump();
    final input = DesktopTextInputDouble(tester)..korean = true;
    for (final key in ['g', 'k', 's']) {
      await input.press(key);
    }
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    await tester.pump();
    expect(output.join(), '한\r');
  });

  group('desktop input method composition', () {
    for (final (id, keys, koreanFrom, expected) in _trials) {
      testWidgets(id, variant: TargetPlatformVariant.desktop(), (tester) async {
        final output = <String>[];
        final terminal = Terminal(
          onOutput: output.add,
          platform: TerminalTargetPlatform.macos,
        );
        await tester.pumpWidget(MaterialApp(
          home: TerminalView(terminal, autofocus: true),
        ));
        await tester.pump();
        final input = DesktopTextInputDouble(tester);
        for (var index = 0; index < keys.length; index++) {
          input.korean = index >= koreanFrom;
          await input.press(keys[index]);
        }
        await input.commitComposition();
        final text = output.join();
        expect(text.runes.where((r) => r >= 0x3131 && r <= 0x318E), isEmpty,
            reason:
                'compatibility jamo reached the shell: input method bypassed');
        expect(input.discardedCompositions, 0,
            reason: 'the framework replaced the editing state mid-composition');
        expect(text, expected);
      });
    }
  });
}
