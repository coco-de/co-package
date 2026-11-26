import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:open_note/src/note/io/pdf/note_pdf_deflate.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_image.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_output.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_syntax.dart';
import 'package:open_note/src/note/io/pdf/note_vector_path.dart';
import 'package:open_note/src/note/io/pdf/note_vector_segment.dart';

export 'package:open_note/src/note/io/pdf/note_pdf_output.dart'
    show NotePdfCompressor;

part 'note_pdf_content.dart';
part 'note_pdf_page.dart';

/// A small, self-contained PDF 1.4 writer: pages of vector paths and image
/// XObjects (with soft masks), opacity through `ExtGState`, transparency
/// groups and clipping. No dependency.
///
/// ```dart
/// final writer = NotePdfWriter();
/// final page = writer.addPage(595, 842);
/// page
///   ..setFillColor(const Color(0xFF2196F3))
///   ..rectangle(const Rect.fromLTWH(40, 40, 100, 60))
///   ..fill();
/// final bytes = writer.save();
/// ```
///
/// Streams are `FlateDecode` compressed where `dart:io` is available and stored
/// raw elsewhere (or with [noCompression]). The output is deterministic: no
/// timestamps unless [creationDate] is given.
class NotePdfWriter {
  /// An empty document.
  NotePdfWriter({
    this.compressor = notePdfDeflate,
    this.producer = 'open_note',
    this.title,
    this.creationDate,
  });

  /// A [compressor] that keeps every stream readable (uncompressed).
  static Uint8List? noCompression(Uint8List bytes) => null;

  /// How stream data is compressed.
  final NotePdfCompressor compressor;

  /// The `/Producer` entry of the document information.
  final String producer;

  /// The document title, if any.
  final String? title;

  /// The document creation date, if any.
  final DateTime? creationDate;

  static const int _catalog = 1;
  static const int _pageTree = 2;
  static const int _info = 3;

  final _Resources _resources = _Resources();
  final List<NotePdfPage> _pages = [];

  /// Number of pages added so far.
  int get pageCount => _pages.length;

  /// Adds a page of `width x height` points and returns its drawing surface.
  /// Throws [ArgumentError] unless both are positive and finite.
  NotePdfPage addPage(double width, double height) {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      throw ArgumentError('a page needs a positive size: $width x $height');
    }
    final page = NotePdfPage._(width, height, _resources);
    _pages.add(page);

    return page;
  }

  /// The PDF file. Throws [StateError] when there is no page or a page has an
  /// unclosed save, group or path. Can be called again after adding pages.
  Uint8List save() {
    _checkPages();
    final numbers = _ObjectNumbers(_resources, _pages.length);
    final output = NotePdfOutput(compressor)..header();
    _writeDocument(output, numbers);
    _writeGraphicsStates(output, numbers);
    _writeImages(output, numbers);
    _writeGroups(output, numbers);
    _writePages(output, numbers);

    return output.finish(root: _catalog, info: _info);
  }

  void _checkPages() {
    if (_pages.isEmpty) throw StateError('a PDF needs at least one page');
    for (var i = 0; i < _pages.length; i++) {
      if (!_pages[i]._isComplete) {
        throw StateError('page ${i + 1} has an unclosed save, group or path');
      }
    }
  }

  void _writeDocument(NotePdfOutput output, _ObjectNumbers numbers) {
    final kids = numbers.pages.map((number) => '$number 0 R').join(' ');
    final date = creationDate;
    output
      ..object(_catalog, '<< /Type /Catalog /Pages $_pageTree 0 R >>')
      ..object(
        _pageTree,
        '<< /Type /Pages /Kids [$kids] /Count ${_pages.length} >>',
      )
      ..object(
        _info,
        '<< /Producer ${notePdfTextString(producer)}'
        '${title == null ? '' : ' /Title ${notePdfTextString(title!)}'}'
        '${date == null ? '' : ' /CreationDate ${notePdfDate(date)}'} >>',
      );
  }

  void _writeGraphicsStates(NotePdfOutput output, _ObjectNumbers numbers) {
    for (var i = 0; i < _resources.graphicsStates.length; i++) {
      final alpha = _resources.graphicsStates[i];
      output.object(
        numbers.graphicsStates[i],
        '<< /Type /ExtGState /ca ${notePdfNumber(alpha.fill)} '
        '/CA ${notePdfNumber(alpha.stroke)} >>',
      );
    }
  }

  void _writeImages(NotePdfOutput output, _ObjectNumbers numbers) {
    for (var i = 0; i < _resources.images.length; i++) {
      final image = _resources.images[i];
      final size =
          '/Type /XObject /Subtype /Image /Width ${image.width} '
          '/Height ${image.height} /BitsPerComponent 8';
      final mask = numbers.masks[i];
      if (mask != null) {
        output.stream(mask, '$size /ColorSpace /DeviceGray', image.softMask!);
      }
      final maskEntry = mask == null ? '' : ' /SMask $mask 0 R';
      output.stream(
        numbers.images[i],
        '$size /ColorSpace /DeviceRGB$maskEntry',
        image.rgb,
      );
    }
  }

  void _writeGroups(NotePdfOutput output, _ObjectNumbers numbers) {
    for (var i = 0; i < _resources.groups.length; i++) {
      final group = _resources.groups[i];
      output.stream(
        numbers.groups[i],
        '/Type /XObject /Subtype /Form /FormType 1 '
        '/BBox [0 0 ${notePdfNumbers([group.width, group.height])}] '
        '/Group << /Type /Group /S /Transparency /CS /DeviceRGB >> '
        '/Resources ${_resourceDictionary(group.content, numbers)}',
        latin1.encode(group.content.operators.toString()),
      );
    }
  }

  void _writePages(NotePdfOutput output, _ObjectNumbers numbers) {
    for (var i = 0; i < _pages.length; i++) {
      final page = _pages[i];
      final box = notePdfNumbers([page.width, page.height]);
      output
        ..object(
          numbers.pages[i],
          '<< /Type /Page /Parent $_pageTree 0 R /MediaBox [0 0 $box] '
          '/Group << /Type /Group /S /Transparency /CS /DeviceRGB >> '
          '/Resources ${_resourceDictionary(page._content, numbers)} '
          '/Contents ${numbers.contents[i]} 0 R >>',
        )
        ..stream(
          numbers.contents[i],
          '',
          latin1.encode(
            // Flip to the note layer's top-left, y-down page coordinates.
            '1 0 0 -1 0 ${notePdfNumber(page.height)} cm\n'
            '${page._content.operators}',
          ),
        );
    }
  }

  String _resourceDictionary(_ContentStream content, _ObjectNumbers numbers) {
    String entries(String prefix, Set<int> used, List<int> objects) => [
      for (final index in used.toList()..sort())
        '/$prefix${index + 1} ${objects[index]} 0 R',
    ].join(' ');

    final states = entries(
      'GS',
      content.graphicsStates,
      numbers.graphicsStates,
    );
    final xObjects = [
      entries('Im', content.images, numbers.images),
      entries('Fm', content.groups, numbers.groups),
    ].where((part) => part.isNotEmpty).join(' ');

    return '<< /ProcSet [/PDF /ImageB /ImageC]'
        '${states.isEmpty ? '' : ' /ExtGState << $states >>'}'
        '${xObjects.isEmpty ? '' : ' /XObject << $xObjects >>'} >>';
  }
}

/// The object number of every object of a document, assigned before writing so
/// that references can point forward.
class _ObjectNumbers {
  _ObjectNumbers(_Resources resources, int pageCount) {
    // 1 to 3 are the catalog, the page tree and the document information.
    var next = 4;
    for (var i = 0; i < resources.graphicsStates.length; i++) {
      graphicsStates.add(next++);
    }
    for (final image in resources.images) {
      masks.add(image.hasAlpha ? next++ : null);
      images.add(next++);
    }
    for (var i = 0; i < resources.groups.length; i++) {
      groups.add(next++);
    }
    for (var i = 0; i < pageCount; i++) {
      pages.add(next++);
      contents.add(next++);
    }
  }

  final List<int> graphicsStates = [];
  final List<int?> masks = [];
  final List<int> images = [];
  final List<int> groups = [];
  final List<int> pages = [];
  final List<int> contents = [];
}
