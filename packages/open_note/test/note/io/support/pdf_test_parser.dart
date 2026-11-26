// A small, strict, test-only PDF parser: it accepts exactly the structure a
// conforming PDF 1.4 file written by `NotePdfWriter` must have, and fails the
// test on anything else.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// One indirect object.
class PdfTestObject {
  PdfTestObject(this.number, this.body, this.data);

  final int number;

  /// The dictionary (or other value) text.
  final String body;

  /// Decoded stream data, or `null` for a non-stream object.
  final Uint8List? data;

  String get text => latin1.decode(data!);

  bool has(String entry) => body.contains(entry);

  /// The object number referenced by `/key N 0 R`.
  int ref(String key) {
    final match = RegExp('/$key (\\d+) 0 R').firstMatch(body);
    expect(match, isNotNull, reason: 'object $number has no /$key reference');

    return int.parse(match!.group(1)!);
  }

  /// Named references of a resource category, e.g. `XObject`.
  Map<String, int> resources(String category) {
    final block = RegExp('/$category << ([^>]*)>>').firstMatch(body);
    if (block == null) return {};

    return {
      for (final match in RegExp(
        r'/(\w+) (\d+) 0 R',
      ).allMatches(block.group(1)!))
        match.group(1)!: int.parse(match.group(2)!),
    };
  }

  List<double> numberArray(String key) {
    final match = RegExp('/$key \\[([^\\]]*)\\]').firstMatch(body);
    expect(match, isNotNull, reason: 'object $number has no /$key array');

    return match!.group(1)!.trim().split(' ').map(double.parse).toList();
  }
}

/// A content stream operator with its operands.
typedef PdfTestOperator = ({List<String> operands, String name});

/// A parsed and structurally verified file.
class PdfTestDocument {
  PdfTestDocument._(this.objects, this.rootNumber, this.infoNumber);

  /// Parses [bytes], verifying the header, the cross-reference table, every
  /// object offset, every stream length and the trailer.
  factory PdfTestDocument.parse(Uint8List bytes) {
    // latin1 maps bytes to characters 1:1, so string indices are offsets.
    final source = latin1.decode(bytes);
    expect(source, startsWith('%PDF-1.4\n'));
    expect(bytes.sublist(9, 15), [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);
    expect(source, endsWith('\n%%EOF\n'));

    final startXrefAt = source.lastIndexOf('startxref\n');
    final xrefOffset = int.parse(
      source.substring(startXrefAt + 'startxref\n'.length).split('\n').first,
    );
    expect(source.substring(xrefOffset), startsWith('xref\n0 '));

    var cursor = xrefOffset + 'xref\n'.length;
    final countLine = source.substring(cursor, source.indexOf('\n', cursor));
    final size = int.parse(countLine.split(' ')[1]);
    cursor += countLine.length + 1;

    final offsets = <int, int>{};
    for (var number = 0; number < size; number++) {
      final entry = source.substring(cursor, cursor + 20);
      cursor += 20;
      final match = RegExp(r'^(\d{10}) (\d{5}) ([nf]) \n$').firstMatch(entry);
      expect(match, isNotNull, reason: 'bad xref entry $number: "$entry"');
      if (number == 0) {
        expect(entry, '0000000000 65535 f \n');
      } else {
        expect(match!.group(3), 'n');
        offsets[number] = int.parse(match.group(1)!);
      }
    }

    final trailer = source.substring(cursor);
    expect(trailer, startsWith('trailer\n<< /Size $size '));
    final root = int.parse(
      RegExp(r'/Root (\d+) 0 R').firstMatch(trailer)!.group(1)!,
    );
    final info = int.parse(
      RegExp(r'/Info (\d+) 0 R').firstMatch(trailer)!.group(1)!,
    );

    final objects = <int, PdfTestObject>{
      for (final entry in offsets.entries)
        entry.key: _object(bytes, source, entry.key, entry.value),
    };
    final document = PdfTestDocument._(objects, root, info);
    document._checkReferences();

    return document;
  }

  final Map<int, PdfTestObject> objects;
  final int rootNumber;
  final int infoNumber;

  PdfTestObject operator [](int number) => objects[number]!;

  PdfTestObject get catalog => this[rootNumber];

  PdfTestObject get info => this[infoNumber];

  /// Pages in tree order, with the tree verified.
  List<PdfTestObject> get pages {
    expect(catalog.body, contains('/Type /Catalog'));
    final treeNumber = catalog.ref('Pages');
    final tree = this[treeNumber];
    expect(tree.body, contains('/Type /Pages'));
    final kids = RegExp(r'/Kids \[([^\]]*)\]').firstMatch(tree.body)!;
    final numbers = [
      for (final match in RegExp(r'(\d+) 0 R').allMatches(kids.group(1)!))
        int.parse(match.group(1)!),
    ];
    expect(tree.body, contains('/Count ${numbers.length} '));

    final kidPages = [for (final number in numbers) this[number]];
    for (final page in kidPages) {
      expect(page.body, contains('/Type /Page '));
      expect(page.ref('Parent'), treeNumber);
    }

    return kidPages;
  }

  /// The decoded content stream of [page].
  String contentOf(PdfTestObject page) => this[page.ref('Contents')].text;

  /// The XObjects of [owner] (a page or form) that are images.
  Map<String, PdfTestObject> imagesOf(PdfTestObject owner) => {
    for (final entry in owner.resources('XObject').entries)
      if (this[entry.value].has('/Subtype /Image'))
        entry.key: this[entry.value],
  };

  /// The XObjects of [owner] that are forms (transparency groups).
  Map<String, PdfTestObject> formsOf(PdfTestObject owner) => {
    for (final entry in owner.resources('XObject').entries)
      if (this[entry.value].has('/Subtype /Form')) entry.key: this[entry.value],
  };

  void _checkReferences() {
    for (final object in objects.values) {
      for (final match in RegExp(r'(\d+) 0 R').allMatches(object.body)) {
        final target = int.parse(match.group(1)!);
        expect(
          objects.containsKey(target),
          isTrue,
          reason: 'object ${object.number} references missing $target',
        );
      }
    }
  }

  static PdfTestObject _object(
    Uint8List bytes,
    String source,
    int number,
    int offset,
  ) {
    final header = '$number 0 obj\n';
    expect(
      source.substring(offset, offset + header.length),
      header,
      reason: 'xref offset of $number does not point at its object',
    );
    final start = offset + header.length;
    final end = source.indexOf('endobj', start);
    const marker = '>>\nstream\n';
    final streamAt = source.indexOf(marker, start);
    if (streamAt < 0 || streamAt > end) {
      return PdfTestObject(number, source.substring(start, end).trim(), null);
    }
    final dictionary = source.substring(start, streamAt + 2);
    final length = int.parse(
      RegExp(r'/Length (\d+) >>$').firstMatch(dictionary)!.group(1)!,
    );
    final dataStart = streamAt + marker.length;
    expect(
      source.substring(dataStart + length),
      startsWith('\nendstream\nendobj\n'),
      reason: 'object $number: /Length $length does not match the stream',
    );
    var data = bytes.sublist(dataStart, dataStart + length);
    if (dictionary.contains('/Filter /FlateDecode')) {
      data = Uint8List.fromList(zlib.decode(data));
    }

    return PdfTestObject(number, dictionary, data);
  }
}

const _pathStart = {'m', 're'};
const _pathBuild = {'l', 'c', 'h'};
const _pathPaint = {'f', 'f*', 'S', 'B', 'B*', 'n'};
const _stateOps = {
  'q',
  'Q',
  'cm',
  'w',
  'J',
  'j',
  'M',
  'd',
  'gs',
  'rg',
  'RG',
  'Do',
};

/// Splits a content stream into operators and verifies its grammar: only known
/// operators, balanced `q`/`Q`, no state change inside a path, no painting
/// without a path, and every `gs`/`Do` name present in [owner]'s resources.
List<PdfTestOperator> pdfOperators(String content, [PdfTestObject? owner]) {
  final operators = <PdfTestOperator>[];
  var operands = <String>[];
  var depth = 0;
  var inPath = false;
  for (final token in content.split(RegExp(r'\s+'))) {
    if (token.isEmpty) continue;
    final isOperator = RegExp(r'^[A-Za-z]+\*?$').hasMatch(token);
    if (!isOperator) {
      operands.add(token);
      continue;
    }
    if (_pathStart.contains(token)) {
      inPath = true;
    } else if (_pathBuild.contains(token)) {
      expect(inPath, isTrue, reason: '$token without a current point');
    } else if (token == 'W' || token == 'W*') {
      expect(inPath, isTrue, reason: 'clip without a path');
    } else if (_pathPaint.contains(token)) {
      expect(inPath, isTrue, reason: '$token without a path');
      inPath = false;
    } else {
      expect(_stateOps, contains(token), reason: 'unknown operator $token');
      expect(inPath, isFalse, reason: '$token inside a path');
    }
    if (token == 'q') depth++;
    if (token == 'Q') {
      depth--;
      expect(depth, greaterThanOrEqualTo(0), reason: 'Q without q');
    }
    if (owner != null && token == 'gs') {
      expect(
        owner.resources('ExtGState').keys,
        contains(operands.single.substring(1)),
      );
    }
    if (owner != null && token == 'Do') {
      expect(
        owner.resources('XObject').keys,
        contains(operands.single.substring(1)),
      );
    }
    operators.add((operands: operands, name: token));
    operands = [];
  }
  expect(depth, 0, reason: 'unbalanced q/Q');
  expect(inPath, isFalse, reason: 'unpainted path at the end');
  expect(operands, isEmpty, reason: 'trailing operands');

  return operators;
}

/// Operator names only.
List<String> pdfOperatorNames(String content, [PdfTestObject? owner]) => [
  for (final operator in pdfOperators(content, owner)) operator.name,
];
