import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';

const String _usage = '''
Usage:
  dart run co_faker:coverage [--input plan.json] [--format markdown|json] [--strict]
      Reports which fields of a planned entity list the domain packs cover.
  dart run co_faker:coverage --languages [--format markdown|json]
      Prints the table of supported languages: what each has, computed from
      the registries.
  dart run co_faker:coverage --language <code> [--strict] [--format markdown|json]
      Runs the language gate on one language (ko, en, zh, ja, de, fr, ru, it,
      pt): the texts are written in the language (no Hangul, its writing
      system, few texts like English), every list lines up with English, and
      nothing is left unregistered. --strict exits with 1 when it fails.
''';

/// Prints a Markdown or JSON coverage report: for a planned entity list, for
/// the supported languages, or for the gate of one language.
Future<void> main(List<String> args) async {
  try {
    String? inputPath;
    String? language;
    var languages = false;
    var format = 'markdown';
    var strict = false;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--input':
          if (++i >= args.length) {
            throw const FormatException('--input needs a path');
          }
          inputPath = args[i];
        case '--format':
          if (++i >= args.length) {
            throw const FormatException('--format needs a value');
          }
          format = args[i];
        case '--strict':
          strict = true;
        case '--languages':
          languages = true;
        case '--language':
          if (++i >= args.length) {
            throw const FormatException('--language needs a language code');
          }
          language = args[i];
        case '--help':
          stdout.write(_usage);
          return;
        default:
          throw FormatException('Unknown option: ${args[i]}');
      }
    }
    if (format != 'markdown' && format != 'json') {
      throw FormatException('Unknown format: $format');
    }
    if (languages || language != null) {
      if (languages && language != null) {
        throw const FormatException(
          '--languages and --language are separate reports: pick one',
        );
      }
      if (inputPath != null) {
        throw const FormatException(
          '--input is for the entity plan, not for --language and --languages',
        );
      }
      if (languages) {
        if (strict) {
          throw const FormatException(
            '--strict needs --language: it decides the gate of one language',
          );
        }
        _languages(format);
      } else {
        _language(language!, format, strict);
      }
      return;
    }
    final source = inputPath == null
        ? await stdin.transform(utf8.decoder).join()
        : await File(inputPath).readAsString();
    final data = jsonDecode(source);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Input must be a JSON object');
    }
    final requestedDomains = data['domains'];
    final domains = requestedDomains == null
        ? CoFakerDomains.all
        : _domainList(requestedDomains);
    final requestedEntities = data['entities'];
    if (requestedEntities is! List) {
      throw const FormatException('entities must be an array');
    }
    final entities = requestedEntities.map(_entity).toList();
    final report = CoFakerCoverage(CoFaker(domains: domains)).check(entities);
    stdout.writeln(
      format == 'json'
          ? jsonEncode(<String, Object>{
              'complete': report.complete,
              'rows': report.toJson(),
            })
          : report.toMarkdown(),
    );
    if (strict && !report.complete) exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('coverage: ${error.message}');
    exitCode = 2;
  } on FileSystemException catch (error) {
    stderr.writeln('coverage: $error');
    exitCode = 2;
  }
}

/// Prints the table of supported languages.
void _languages(String format) {
  final rows = CoLanguageCoverage.support();
  stdout.writeln(
    format == 'json'
        ? const JsonEncoder.withIndent(
            '  ',
          ).convert(<Object?>[for (final row in rows) row.toJson()])
        : CoLanguageCoverage.supportMarkdown(rows),
  );
}

/// Runs the gate on one language and prints its report.
void _language(String tag, String format, bool strict) {
  final resolved = CoFakerLanguages.resolve(tag);
  if (!resolved.supported) {
    throw FormatException(
      'Unknown language: $tag; supported: '
      '${CoFakerLanguages.all.map((language) => language.code).join(', ')}',
    );
  }
  final report = CoLanguageCoverage().checkRegistered(resolved.language.code);
  stdout.writeln(
    format == 'json'
        ? const JsonEncoder.withIndent('  ').convert(report.toJson())
        : report.toMarkdown(),
  );
  if (strict && !report.passed) exitCode = 1;
}

List<CoFakerDomain> _domainList(Object? value) {
  if (value is! List) throw const FormatException('domains must be an array');
  final builtins = <String, CoFakerDomain>{
    for (final domain in CoFakerDomains.all) domain.name: domain,
  };
  return value.map((name) {
    final domain = builtins[name];
    if (domain == null) throw FormatException('Unknown domain: $name');
    return domain;
  }).toList();
}

CoCoverageEntity _entity(Object? value) {
  if (value is String) return CoCoverageEntity(value);
  if (value is! Map<String, dynamic> || value['name'] is! String) {
    throw const FormatException('Each entity needs a name');
  }
  return CoCoverageEntity(
    value['name'] as String,
    fields: _strings(value['fields'], 'fields'),
    roles: _strings(value['roles'], 'roles'),
    enums: _enums(value['enums']),
  );
}

Map<String, String> _strings(Object? value, String label) {
  if (value == null) return const <String, String>{};
  if (value is! Map<String, dynamic> ||
      value.values.any((element) => element is! String)) {
    throw FormatException('$label must be a string map');
  }
  return value.cast<String, String>();
}

Map<String, List<String>> _enums(Object? value) {
  if (value == null) return const <String, List<String>>{};
  if (value is! Map<String, dynamic>) {
    throw const FormatException('enums must be a string list map');
  }
  final result = <String, List<String>>{};
  for (final entry in value.entries) {
    if (entry.value is! List ||
        (entry.value as List).any((element) => element is! String)) {
      throw const FormatException('enums must be a string list map');
    }
    result[entry.key] = (entry.value as List).cast<String>();
  }
  return result;
}
