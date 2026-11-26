import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/template/template.dart';

void main() {
  const a4 = NotePageSize.a4;

  group('NotePaperKind', () {
    test('knows which kinds draw ruling', () {
      expect(NotePaperKind.values.where((k) => k.isRuled), [
        NotePaperKind.lined,
        NotePaperKind.grid,
        NotePaperKind.dotted,
        NotePaperKind.cornell,
        NotePaperKind.music,
      ]);
      expect(NotePaperKind.values.map((k) => k.name), [
        'blank',
        'lined',
        'grid',
        'dotted',
        'cornell',
        'music',
        'image',
      ]);
    });

    test('image fits map onto BoxFit', () {
      expect(NotePaperImageFit.values.map((f) => f.boxFit), [
        BoxFit.contain,
        BoxFit.cover,
        BoxFit.fill,
      ]);
    });
  });

  group('NotePaperTemplate defaults', () {
    test('line spacing depends on the kind', () {
      final spacings = {
        NotePaperTemplate.lined(): 28,
        NotePaperTemplate.grid(): 24,
        NotePaperTemplate.dotted(): 24,
        NotePaperTemplate.cornell(): 28,
        NotePaperTemplate.music(): 10,
      };
      for (final MapEntry(key: paper, value: spacing) in spacings.entries) {
        expect(paper.lineSpacing, spacing, reason: paper.kind.name);
        expect(paper.lineWidth, 0.6);
        expect(paper.backgroundColor, const Color(0xFFFFFFFF));
        expect(paper.showMarginLine, isFalse);
        expect(paper.imageSource, isNull);
        expect(paper.imageOpacity, 1);
      }
      for (final kind in NotePaperKind.values) {
        expect(
          NotePaperTemplate(id: 'x', kind: kind).lineSpacing,
          NotePaperTemplate.defaultLineSpacing(kind),
        );
      }
    });

    test('presets carry built-in ids and English names', () {
      expect(NotePaperTemplate.blank().id, NotePaperCatalog.blankId);
      expect(NotePaperTemplate.lined().id, NotePaperCatalog.linedId);
      expect(NotePaperTemplate.grid().id, NotePaperCatalog.gridId);
      expect(NotePaperTemplate.dotted().id, NotePaperCatalog.dottedId);
      expect(NotePaperTemplate.cornell().id, NotePaperCatalog.cornellId);
      expect(NotePaperTemplate.music().id, NotePaperCatalog.musicId);
      expect(NotePaperTemplate.cornell().name, 'Cornell');
      expect(NotePaperTemplate.grid(id: 'mine', name: 'Mine').id, 'mine');
      expect(NotePaperTemplate.grid(id: 'mine', name: 'Mine').name, 'Mine');
    });

    test('an image paper takes the picture and fit', () {
      final paper = NotePaperTemplate.image(
        id: 'photo',
        imageSource: '/tmp/a.png',
        imageFit: NotePaperImageFit.cover,
        imageOpacity: 0.5,
      );
      expect(paper.kind, NotePaperKind.image);
      expect(paper.name, 'Image');
      expect(paper.imageSource, '/tmp/a.png');
      expect(paper.imageFit, NotePaperImageFit.cover);
      expect(paper.imageOpacity, 0.5);
      expect(paper.margins, EdgeInsets.zero);
    });

    test('Cornell margins are proportional to the page', () {
      final margins = NotePaperTemplate.cornell().margins;
      expect(margins.left, (595 * 0.28).roundToDouble());
      expect(margins.top, (842 * 0.08).roundToDouble());
      expect(margins.bottom, (842 * 0.18).roundToDouble());
    });

    test('the writable area is the page minus the margins', () {
      final paper = NotePaperTemplate.lined();
      expect(
        paper.writableArea,
        const Rect.fromLTRB(40, 56, 595 - 24, 842 - 32),
      );
    });
  });

  group('NotePaperTemplate ranges', () {
    test('line spacing is clamped to 6 – 120', () {
      expect(NotePaperTemplate.lined(lineSpacing: 1).lineSpacing, 6);
      expect(NotePaperTemplate.lined(lineSpacing: 999).lineSpacing, 120);
      expect(NotePaperTemplate.lined(lineSpacing: double.nan).lineSpacing, 28);
      expect(
        NotePaperTemplate.lined().copyWith(lineSpacing: -4).lineSpacing,
        6,
      );
    });

    test('line width is clamped to 0.25 – 4', () {
      expect(NotePaperTemplate.grid(lineWidth: 0).lineWidth, 0.25);
      expect(NotePaperTemplate.grid(lineWidth: 40).lineWidth, 4);
      expect(NotePaperTemplate.grid(lineWidth: double.infinity).lineWidth, 0.6);
    });

    test('image opacity and margins are kept usable', () {
      final paper = NotePaperTemplate(
        id: 'x',
        size: const NotePageSize(100, 200),
        margins: const EdgeInsets.fromLTRB(-5, double.nan, 500, 90),
        imageOpacity: 7,
      );
      expect(paper.imageOpacity, 1);
      expect(paper.margins, const EdgeInsets.fromLTRB(0, 0, 100, 90));
      final crowded = paper.copyWith(
        margins: const EdgeInsets.fromLTRB(80, 150, 120, 100),
      );
      expect(crowded.margins.horizontal, closeTo(100, 1e-9));
      expect(crowded.margins.vertical, closeTo(200, 1e-9));
      expect(crowded.margins.left / crowded.margins.right, closeTo(0.8, 1e-9));
    });
  });

  group('NotePaperTemplate values', () {
    final custom = NotePaperTemplate(
      id: 'custom',
      name: 'My paper',
      kind: NotePaperKind.cornell,
      size: const NotePageSize(612, 792),
      lineSpacing: 20 + 1 / 3,
      lineWidth: 1.1,
      lineColor: const Color(0xFF112233),
      backgroundColor: const Color(0xFFFFF8E1),
      accentColor: const Color(0x80FF0000),
      margins: const EdgeInsets.fromLTRB(150.5, 60, 20, 100),
      showMarginLine: true,
      imageSource: 'file:///a.png',
      imageFit: NotePaperImageFit.fill,
      imageOpacity: 0.25,
    );

    test('JSON round trip', () {
      final papers = [
        custom,
        ...NotePaperCatalog.builtInTemplates(),
        NotePaperTemplate.image(id: 'i', imageSource: 's'),
        NotePaperTemplate.lined(size: const NotePageSize(300, 100)),
      ];
      for (final paper in papers) {
        final read = NotePaperTemplate.fromJson(
          NoteJson.decodeMap(NoteJson.encode(paper.toJson())),
        );
        expect(read, paper, reason: paper.id);
        expect(read.hashCode, paper.hashCode);
      }
    });

    test('margins that fill the page survive a round trip', () {
      final paper = custom.copyWith(
        margins: const EdgeInsets.fromLTRB(1000, 700, 333, 900),
      );
      expect(NotePaperTemplate.fromJson(paper.toJson()), paper);
    });

    test('fromJson never throws on malformed input', () {
      for (final bad in <Object?>[null, 42, 'x', <Object?>[], true]) {
        expect(
          NotePaperTemplate.fromJson(bad),
          NotePaperTemplate.blank(),
          reason: '$bad',
        );
      }
      final odd = NotePaperTemplate.fromJson({
        'id': 7,
        'kind': 'hologram',
        'size': {'w': -4, 'h': 'x'},
        'lineSpacing': 'wide',
        'lineColor': 'red',
        'margins': [1, 2],
        'showMarginLine': 'yes',
        'imageFit': 'stretch',
        'imageOpacity': 'half',
      });
      expect(odd.kind, NotePaperKind.blank);
      expect(odd.id, '');
      expect(odd.size, a4);
      expect(odd.margins, EdgeInsets.zero);
      expect(odd.imageFit, NotePaperImageFit.contain);
      expect(odd.imageOpacity, 1);
    });

    test('fromJson fills missing fields with the kind defaults', () {
      final read = NotePaperTemplate.fromJson({'id': 'm', 'kind': 'music'});
      expect(read.lineSpacing, 10);
      expect(read.lineColor, const Color(0xFF616161));
      expect(read.margins, const EdgeInsets.fromLTRB(40, 56, 40, 40));
      final partial = NotePaperTemplate.fromJson({
        'id': 'p',
        'kind': 'lined',
        'margins': {'left': 90},
      });
      expect(partial.margins, const EdgeInsets.fromLTRB(90, 56, 24, 32));
    });

    test('fromJson limits absurd page sizes', () {
      final huge = NotePaperTemplate.fromJson({
        'id': 'h',
        'size': {'w': 1e300, 'h': 1e-300},
      });
      expect(huge.size.width, NotePaperTemplate.maxPageSide);
      expect(huge.size.height, 1);
    });

    test('copyWith keeps and clears', () {
      expect(custom.copyWith(), custom);
      expect(custom.copyWith(clearImageSource: true).imageSource, isNull);
      final changed = custom.copyWith(
        name: 'Other',
        showMarginLine: false,
        kind: NotePaperKind.grid,
      );
      expect(changed.name, 'Other');
      expect(changed.kind, NotePaperKind.grid);
      expect(changed.lineSpacing, custom.lineSpacing);
      expect(changed, isNot(custom));
    });

    test('fitted scales the margins with the page', () {
      final paper = NotePaperTemplate.cornell();
      expect(paper.fitted(a4), same(paper));
      final half = paper.fitted(const NotePageSize(297.5, 421));
      expect(half.size, const NotePageSize(297.5, 421));
      expect(half.margins.left, closeTo(paper.margins.left / 2, 1e-9));
      expect(half.margins.top, closeTo(paper.margins.top / 2, 1e-9));
      expect(half.margins.right, closeTo(paper.margins.right / 2, 1e-9));
      expect(half.margins.bottom, closeTo(paper.margins.bottom / 2, 1e-9));
      expect(half.lineSpacing, paper.lineSpacing);
      expect(half.lineWidth, paper.lineWidth);
      final landscape = paper.fitted(a4.rotated);
      expect(
        landscape.margins.left,
        closeTo(paper.margins.left * 842 / 595, 1e-9),
      );
    });

    test('colours are stored with 8 bits per channel', () {
      final paper = NotePaperTemplate(
        id: 'c',
        lineColor: const Color.from(
          alpha: 0.5,
          red: 0.1234,
          green: 0.5,
          blue: 0.9,
        ),
      );
      expect(paper.lineColor, Color(paper.lineColor.toARGB32()));
      expect(NotePaperTemplate.fromJson(paper.toJson()), paper);
    });

    test('toString names the paper', () {
      expect(custom.toString(), contains('custom'));
    });
  });
}
