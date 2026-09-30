import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';

/// Prints a Markdown or JSON coverage report for a planned entity list.
Future<void> main(List<String> args) async {
  try {
    String? inputPath;
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
        case '--help':
          stdout.writeln(
            'Usage: dart run co_faker:coverage [--input plan.json] '
            '[--format markdown|json] [--strict]',
          );
          return;
        default:
          throw FormatException('Unknown option: ${args[i]}');
      }
    }
    if (format != 'markdown' && format != 'json') {
      throw FormatException('Unknown format: $format');
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
