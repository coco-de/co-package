// Internal to the PDF writer: byte-level serialisation of numbered objects, the
// cross-reference table and the trailer. Not exported from the module barrel.
import 'dart:convert';
import 'dart:typed_data';

/// Compresses stream data for the `FlateDecode` filter, or returns `null` to
/// store it as is.
typedef NotePdfCompressor = Uint8List? Function(Uint8List bytes);

/// Writes a PDF file, remembering the byte offset of each object.
class NotePdfOutput {
  /// A writer compressing stream data with [compressor].
  NotePdfOutput(this.compressor);

  /// Compresses stream data.
  final NotePdfCompressor compressor;

  final BytesBuilder _bytes = BytesBuilder();
  final Map<int, int> _offsets = {};

  /// The version header, followed by a comment of high bytes so tools treat the
  /// file as binary.
  void header() {
    _text('%PDF-1.4\n');
    _bytes.add(const [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);
  }

  /// Writes object [number] with the [body] (a dictionary, array…).
  void object(int number, String body) {
    _begin(number);
    _text('$body\nendobj\n');
  }

  /// Writes object [number] as a stream of [data] whose dictionary holds
  /// [entries] plus the filter and the exact `/Length`.
  void stream(int number, String entries, Uint8List data) {
    final compressed = compressor(data);
    final payload = compressed ?? data;
    final filter = compressed == null ? '' : ' /Filter /FlateDecode';
    _begin(number);
    _text('<< $entries$filter /Length ${payload.length} >>\nstream\n');
    _bytes.add(payload);
    _text('\nendstream\nendobj\n');
  }

  /// Appends the cross-reference table and trailer and returns the file.
  /// Object numbers must be exactly 1 to the highest number written.
  Uint8List finish({required int root, required int info}) {
    final size = _offsets.length + 1;
    final startXref = _bytes.length;
    _text('xref\n0 $size\n0000000000 65535 f \n');
    for (var number = 1; number < size; number++) {
      final offset = _offsets[number];
      if (offset == null) throw StateError('object $number is missing');
      _text('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    _text(
      'trailer\n<< /Size $size /Root $root 0 R /Info $info 0 R >>\n'
      'startxref\n$startXref\n%%EOF\n',
    );

    return _bytes.takeBytes();
  }

  void _begin(int number) {
    if (_offsets.containsKey(number)) {
      throw StateError('object $number written twice');
    }
    _offsets[number] = _bytes.length;
    _text('$number 0 obj\n');
  }

  void _text(String text) => _bytes.add(latin1.encode(text));
}
