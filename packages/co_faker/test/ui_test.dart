import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  test('Korean examples follow final approved copy, including follow-ups', () {
    for (final locale in ['ko', 'ko_KR', 'ko-KR']) {
      final ui = CoFaker(locale: locale).ui;
      expect(ui.text('textField.placeholder'), '이메일을 입력해 주세요');
      expect(ui.text('textField.value'), 'hello@cocode.im');
      expect(ui.text('phoneInput.placeholder'), '전화번호');
      expect(ui.text('itemPicker.placeholder'), '검색');
      expect(ui.text('itemPicker.empty'), '항목이 없어요.');
      expect(ui.text('toast.message'), '저장했어요');
      expect(ui.text('commandSearch.hint'), '명령어나 검색어를 입력해 주세요');
      expect(ui.text('avatar.initials'), '코드');
      expect(ui.list('itemPicker.options'), ['김코드', '이코드', '박코드']);
      expect(ui.text('footer.businessInfo'), contains('000-00-00000'));
      expect(ui.text('footer.copyright'), '© 2026 코코드. All rights reserved.');
      expect('${ui.text('stat.value')} ${ui.text('stat.unit')}', '1,248만 원');
      expect(ui.text('timePicker.value'), '오후 02:30');
    }
  });

  test('every English/Korean key is aligned and immutable', () {
    final en = CoFaker().ui;
    final ko = CoFaker.forLanguage('ko').ui;
    expect(CoFakerUi.keys.length, greaterThan(200));
    for (final key in CoFakerUi.keys) {
      final english = en.list(key);
      final korean = ko.list(key);
      expect(english, isNotEmpty, reason: key);
      expect(korean.length, english.length, reason: key);
      if (!key.startsWith('autocomplete.')) {
        expect(
          english.every((text) => text.trim().isNotEmpty),
          isTrue,
          reason: key,
        );
        expect(
          korean.every((text) => text.trim().isNotEmpty),
          isTrue,
          reason: key,
        );
      }
      expect(() => korean.add('changed'), throwsUnsupportedError, reason: key);
      expect(() => english[0] = 'changed', throwsUnsupportedError, reason: key);
    }
  });

  test('Autocomplete fragments reconstruct rows around the shared query', () {
    final ui = CoFaker(locale: 'ko').ui;
    final before = ui.list('autocomplete.before');
    final match = ui.list('autocomplete.match');
    final after = ui.list('autocomplete.after');
    expect(
      match.every((text) => text == ui.text('autocomplete.query')),
      isTrue,
    );
    expect(
      [
        for (var i = 0; i < match.length; i++)
          '${before[i]}${match[i]}${after[i]}',
      ],
      ['과자', '사과잼', '사과'],
    );
  });

  test(
    'same seed picks corresponding rows; deterministic reads draw nothing',
    () {
      final en = CoFaker(seed: 6010);
      final ko = CoFaker(locale: 'ko', seed: 6010);
      final control = CoFaker(seed: 6010);
      for (final key in CoFakerUi.keys) {
        en.ui.list(key);
        en.ui.pickBalanced(key, 42);
        if (en.ui.list(key).length == 1) en.ui.text(key);
      }
      expect(en.random.int(max: 1000000), control.random.int(max: 1000000));
      // Use fresh streams for the bilingual row comparison.
      final fresh = CoFaker(seed: 6010);
      for (var i = 0; i < 100; i++) {
        final index = fresh.ui
            .list('itemPicker.options')
            .indexOf(fresh.ui.pick('itemPicker.options'));
        expect(
          ko.ui.pick('itemPicker.options'),
          ko.ui.list('itemPicker.options')[index],
        );
      }
    },
  );

  test('localized and derived views preserve the copy language', () {
    final base = CoFaker(seed: 12);
    final ko = base.localized('ko').derive('preview');
    expect(ko.ui.language, 'ko');
    expect(ko.ui.text('card.header'), '프로젝트 요약');
    expect(base.ui.text('card.header'), 'Project summary');
    for (final locale in ['ja', 'zh_TW', 'xx']) {
      final fallback = CoFaker(locale: locale).ui;
      expect(fallback.language, 'en');
      expect(fallback.text('card.header'), base.ui.text('card.header'));
    }
  });

  test('literal keys/codes remain and system prompts are excluded', () {
    final ui = CoFaker(locale: 'ko').ui;
    expect(ui.text('commandItem.shortcut'), 'Ctrl+P');
    expect(ui.text('menuItem.shortcut'), 'F2');
    expect(ui.text('treeItem.label'), 'button.dart');
    expect(ui.text('mockupBrowser.address'), 'example.com');
    expect(ui.text('textArea.counter'), '0 / 200');
    expect(
      CoFakerUi.keys.any((key) => key.startsWith('permissionAlert.')),
      isFalse,
    );
    expect(() => ui.text('missing'), throwsArgumentError);
    expect(() => ui.text('filter.labels'), throwsStateError);
  });

  test(
    'CLI exports the same Korean catalog and rejects malformed arguments',
    () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/ui_copy.dart',
        '--locale',
        'ko',
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      expect(json['revision'], CoFakerUi.revision);
      expect(json['source'], CoFakerUi.sourceUrl);
      expect(json['decisions'], CoFakerUi.decisionsUrl);
      expect(json['language'], 'ko');
      final texts = json['texts'] as Map<String, dynamic>;
      expect(texts.keys, CoFakerUi.keys);
      for (final key in CoFakerUi.keys) {
        expect(texts[key], CoFaker(locale: 'ko').ui.list(key), reason: key);
      }
      final bad = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/ui_copy.dart',
        '--locale',
      ]);
      expect(bad.exitCode, 64);
      expect(bad.stdout, isEmpty);
    },
  );
}
