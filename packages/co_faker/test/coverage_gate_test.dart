import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

/// Runs `dart run co_faker:coverage` with [args] in the package.
Future<ProcessResult> _coverage(List<String> args) => Process.run(
  Platform.resolvedExecutable,
  <String>['run', 'co_faker:coverage', ...args],
  workingDirectory: Directory.current.path,
);

void main() {
  final coverage = CoLanguageCoverage();

  // The pull request of a language is checked by this test: a language that
  // has domain text has to pass `dart run co_faker:coverage --language <code>
  // --strict`, and a language that has none has to be a stub that nothing is
  // written in yet. The languages are read from CoFakerLanguages and the
  // registries, so a language that is filled is checked without an edit here.
  group('the language gate', () {
    for (final language in CoFakerLanguages.all) {
      final data = CoLanguageData.registered(language.code);
      if (data.bundle.isNotEmpty) {
        test('${language.code} has domain text and passes the gate', () {
          final report = coverage.check(data);
          expect(report.level, CoLanguageLevel.localized);
          expect(report.passed, isTrue, reason: report.toMarkdown(limit: 60));
        });
      } else {
        test('${language.code} has no domain text and is planned', () {
          // A language without a bundle has no clinic or SaaS data either:
          // the three are filled in one pull request.
          expect(data.clinic, isNull, reason: 'clinic data without a bundle');
          expect(data.saas, isNull, reason: 'SaaS data without a bundle');
          expect(
            data.level,
            anyOf(CoLanguageLevel.planned, CoLanguageLevel.base),
          );
          final report = coverage.check(data);
          expect(report.passed, isFalse);
          expect(report.issues.single.check, CoLanguageCheck.planned);
        });
      }
    }

    test('English is the reference and Korean passes against it', () {
      final english = coverage.checkRegistered('en');
      expect(english.reference, isTrue);
      expect(english.passed, isTrue, reason: english.toMarkdown());
      expect(english.stats['generatorCalls'], greaterThan(600));
      final korean = coverage.checkRegistered('ko');
      expect(korean.passed, isTrue, reason: korean.toMarkdown());
      // The Korean measure that the thresholds rest on: every Korean text
      // that equals English is listed in allowSameAsEnglish, and none else.
      expect(korean.stats['sameAsEnglish'], 0);
      expect(korean.stats['allowedSameAsEnglish'], greaterThanOrEqualTo(25));
      expect(korean.stats['scriptRatio'], greaterThanOrEqualTo(0.99));
    });

    test('the gate is quick enough to run on every language', () {
      final watch = Stopwatch()..start();
      coverage.checkRegistered('ko');
      expect(watch.elapsed, lessThan(const Duration(seconds: 20)));
    });

    test('every language that CoFakerLanguages supports is in the table', () {
      final table = CoLanguageCoverage.support();
      expect(
        table.map((row) => row.code),
        CoFakerLanguages.all.map((language) => language.code),
      );
      for (final row in table) {
        expect(
          row.level,
          row.clinic && row.saas && row.bundleKeys > 0
              ? CoLanguageLevel.localized
              : isNot(CoLanguageLevel.localized),
          reason: row.code,
        );
      }
    });

    test('every language with a registered bundle is a supported language', () {
      // The gate and the safety scan read CoFakerLanguages: a bundle for a
      // language that is not listed there would never be checked.
      final supported = <String>{
        for (final language in CoFakerLanguages.all) language.code,
      };
      expect(
        CoL10nRegistry.bundles.keys.toSet().difference(supported),
        isEmpty,
      );
    });
  });

  // Each test starts its processes together: a `dart run` compiles the tool
  // before it runs, and they would otherwise wait for one another.
  group('dart run co_faker:coverage', () {
    test('--languages prints the table of languages', () async {
      final results = await Future.wait(<Future<ProcessResult>>[
        _coverage(<String>['--languages']),
        _coverage(<String>['--languages', '--format', 'json']),
      ]);
      final result = results[0];
      expect(result.exitCode, 0, reason: '${result.stderr}');
      final out = result.stdout as String;
      expect(out, startsWith('| Language | Script |'));
      for (final language in CoFakerLanguages.all) {
        expect(out, contains('| `${language.code}` '));
      }
      expect(out, contains('| localized |'));
      final json = results[1];
      expect(json.exitCode, 0, reason: '${json.stderr}');
      final rows = (jsonDecode(json.stdout as String) as List)
          .cast<Map<String, Object?>>();
      expect(
        rows.map((row) => row['language']),
        CoFakerLanguages.all.map((language) => language.code),
      );
      expect(rows.first['level'], 'localized');
      expect(
        rows.first.keys,
        containsAll(<String>['clinic', 'saas', 'script']),
      );
    });

    test('--language --strict passes a finished language', () async {
      final results = await Future.wait(<Future<ProcessResult>>[
        _coverage(<String>['--language', 'ko', '--strict']),
        _coverage(<String>['--language', 'en', '--strict', '--format', 'json']),
      ]);
      final result = results[0];
      expect(result.exitCode, 0, reason: '${result.stderr}${result.stdout}');
      expect(result.stdout, contains('Result: **PASS**'));
      final json = results[1];
      expect(json.exitCode, 0, reason: '${json.stderr}');
      final report = jsonDecode(json.stdout as String) as Map<String, Object?>;
      expect(report['passed'], isTrue);
      expect(report['reference'], isTrue);
    });

    // A supported language whose data is not written yet, while one is left.
    final pending = <String>[
      for (final language in CoFakerLanguages.all)
        if (CoLanguageData.registered(language.code).level ==
            CoLanguageLevel.planned)
          language.code,
    ];
    test('--language --strict fails a language without data', () async {
      final code = pending.last;
      final results = await Future.wait(<Future<ProcessResult>>[
        _coverage(<String>['--language', code, '--strict']),
        _coverage(<String>['--language', code]),
        _coverage(<String>['--language', code, '--strict', '--format', 'json']),
      ]);
      final strict = results[0];
      expect(strict.exitCode, 1);
      expect(strict.stdout, contains('planned'));
      expect(strict.stdout, contains('Result: **FAIL**'));
      // Without --strict the report is information and the exit code is 0.
      final info = results[1];
      expect(info.exitCode, 0);
      expect(info.stdout, contains('Result: **FAIL**'));
      // A tool reads the same verdict as JSON, issue by issue.
      final json = results[2];
      expect(json.exitCode, 1);
      final report = jsonDecode(json.stdout as String) as Map<String, Object?>;
      expect(report['passed'], isFalse);
      expect(report['level'], 'planned');
      final issues = (report['issues']! as List).cast<Map<String, Object?>>();
      expect(issues.single['check'], 'planned');
      expect(issues.single['where'], code);
    }, skip: pending.isEmpty ? 'every supported language is localized' : false);

    test('rejects what it cannot read with exit code 2', () async {
      final invalid = <List<String>>[
        <String>['--language', 'xx'],
        // Traditional Chinese is not a supported language.
        <String>['--language', 'zh_TW'],
        <String>['--languages', '--strict'],
        <String>['--languages', '--language', 'ko'],
        <String>['--language', 'ko', '--input', 'plan.json'],
        <String>['--language'],
        <String>['--language', 'ko', '--format', 'xml'],
      ];
      final results = await Future.wait(<Future<ProcessResult>>[
        for (final args in invalid) _coverage(args),
      ]);
      for (var i = 0; i < invalid.length; i++) {
        expect(results[i].exitCode, 2, reason: invalid[i].join(' '));
      }
      expect(results[0].stderr, contains('Unknown language: xx'));
    });
  }, timeout: const Timeout.factor(3));
}
