import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';

/// Exports component copy for a design script without Flutter or a network.
void main(List<String> args) {
  if (args.length == 1 && args.single == '--help') {
    stdout.writeln('Usage: dart run co_faker:ui_copy [--locale ko|en]');
    return;
  }
  var locale = 'en';
  if (args.isNotEmpty) {
    if (args.length != 2 || args.first != '--locale' || args.last.isEmpty) {
      stderr.writeln('Usage: dart run co_faker:ui_copy [--locale ko|en]');
      exitCode = 64;
      return;
    }
    locale = args.last;
  }
  final faker = CoFaker(locale: locale);
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'source': CoFakerUi.sourceUrl,
      'decisions': CoFakerUi.decisionsUrl,
      'revision': CoFakerUi.revision,
      'locale': faker.locale,
      'language': faker.ui.language,
      'texts': {for (final key in CoFakerUi.keys) key: faker.ui.list(key)},
    }),
  );
}
