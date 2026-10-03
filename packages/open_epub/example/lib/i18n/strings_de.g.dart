///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsDe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$de app = _Translations$app$de._(_root);
	@override late final _Translations$common$de common = _Translations$common$de._(_root);
	@override late final _Translations$home$de home = _Translations$home$de._(_root);
	@override late final _Translations$samples$de samples = _Translations$samples$de._(_root);
	@override late final _Translations$reader$de reader = _Translations$reader$de._(_root);
	@override late final _Translations$core$de core = _Translations$core$de._(_root);
	@override late final _Translations$highlight$de highlight = _Translations$highlight$de._(_root);
	@override late final _Translations$fixedLayout$de fixedLayout = _Translations$fixedLayout$de._(_root);
	@override late final _Translations$epubReader$de epubReader = _Translations$epubReader$de._(_root);
}

// Path: app
class _Translations$app$de extends Translations$app$ko {
	_Translations$app$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'open_epub Demo';
}

// Path: common
class _Translations$common$de extends Translations$common$ko {
	_Translations$common$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get previousPage => 'Vorherige Seite';
	@override String get nextPage => 'Nächste Seite';
	@override String get cancel => 'Abbrechen';
	@override String get save => 'Speichern';
	@override String get close => 'Schließen';
}

// Path: home
class _Translations$home$de extends Translations$home$ko {
	_Translations$home$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$de library = _Translations$home$library$de._(_root);
	@override late final _Translations$home$core$de core = _Translations$home$core$de._(_root);
	@override late final _Translations$home$highlight$de highlight = _Translations$home$highlight$de._(_root);
	@override late final _Translations$home$fixedLayout$de fixedLayout = _Translations$home$fixedLayout$de._(_root);
}

// Path: samples
class _Translations$samples$de extends Translations$samples$ko {
	_Translations$samples$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$de nohoechan = _Translations$samples$nohoechan$de._(_root);
	@override late final _Translations$samples$wasteland$de wasteland = _Translations$samples$wasteland$de._(_root);
	@override late final _Translations$samples$arabicRtl$de arabicRtl = _Translations$samples$arabicRtl$de._(_root);
	@override late final _Translations$samples$mathml$de mathml = _Translations$samples$mathml$de._(_root);
	@override late final _Translations$samples$vertical$de vertical = _Translations$samples$vertical$de._(_root);
	@override late final _Translations$samples$mediaOverlay$de mediaOverlay = _Translations$samples$mediaOverlay$de._(_root);
	@override late final _Translations$samples$accessible$de accessible = _Translations$samples$accessible$de._(_root);
	@override late final _Translations$samples$cfi$de cfi = _Translations$samples$cfi$de._(_root);
	@override late final _Translations$samples$fixedA4$de fixedA4 = _Translations$samples$fixedA4$de._(_root);
}

// Path: reader
class _Translations$reader$de extends Translations$reader$ko {
	_Translations$reader$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => 'Dieses Buch hat kein Media Overlay';
	@override String get mediaOverlayLoadFailed => 'Media Overlay (SMIL) konnte nicht geladen werden';
	@override String audioFailed({required Object error}) => 'Audiowiedergabe fehlgeschlagen (möglicherweise eine Einschränkung des Simulators): ${error}';
	@override String localFixture({required Object asset}) => 'Dieses Beispiel (${asset}) ist eine lokale Testdatei, die nicht im Repository liegt (wegen Größe oder Lizenz per .gitignore ausgeschlossen).\nZum Öffnen die EPUB-Datei in der lokalen Arbeitskopie unter packages/open_epub/example/assets/ ablegen und die App neu starten.';
	@override String get mode => 'Modus';
	@override String get swipe => 'Wischen';
	@override String get scroll => 'Scrollen';
	@override String get vertical => 'Vertikal';
	@override String get fontSmaller => 'Schrift kleiner';
	@override String get fontLarger => 'Schrift größer';
	@override String get verticalScroll => 'Vertikal scrollen';
	@override String get rtlDirection => 'Blätterrichtung RTL';
	@override String get verticalWriting => 'Vertikale Schrift';
	@override String get narration => 'Vorlesen (Media Overlay)';
}

// Path: core
class _Translations$core$de extends Translations$core$ko {
	_Translations$core$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · Korrekturen: ${count}';
	@override String get recordHighlight => 'recordHighlight() — toolUse-Ereignis';
	@override String get recordBookmark => 'recordBookmark() — toolUse-Ereignis';
	@override String assetLoadFailed({required Object error}) => 'Asset konnte nicht geladen werden: ${error}';
	@override String get positionTokenTitle => 'BookPosition-v1-Token';
	@override String get eventLog => 'Ereignisprotokoll';
	@override String get positionToken => 'Positions-Token';
	@override String get waitingForEvents => 'Warte auf Ereignisse …';
}

// Path: highlight
class _Translations$highlight$de extends Translations$highlight$ko {
	_Translations$highlight$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get list => 'Markierungen';
	@override String get action => 'Markieren';
	@override String openFailed({required Object error}) => 'Das Buch kann nicht geöffnet werden: ${error}';
	@override String get selectFirst => 'Bitte zuerst Text auswählen.';
	@override String saved({required Object color}) => 'Markierung gespeichert (${color})';
	@override String get deleted => 'Markierung gelöscht';
	@override String get noteSaved => 'Notiz gespeichert';
	@override String get hintSelected => '„Markieren“ drücken, um die Auswahl einzufärben';
	@override String get hintIdle => 'Text auswählen, dann erscheint die Schaltfläche „Markieren“';
	@override String get previousChapter => 'Vorheriges Kapitel';
	@override String get nextChapter => 'Nächstes Kapitel';
	@override String get note => 'Notiz';
	@override String get noteHint => 'Notiz eingeben';
	@override String get noteOptional => 'Notiz (optional)';
	@override String colorLabel({required Object color}) => 'Farbe: ${color}';
	@override String count({required Object count}) => 'Markierungen: ${count}';
	@override String get empty => 'Noch keine Markierungen.';
	@override String noteLine({required Object note}) => 'Notiz: ${note}';
	@override String get menu => 'Markierungsmenü';
	@override String get editNote => 'Notiz bearbeiten';
	@override String get delete => 'Löschen';
	@override late final _Translations$highlight$colors$de colors = _Translations$highlight$colors$de._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$de extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => 'Seite ${index}/${total}';
}

// Path: epubReader
class _Translations$epubReader$de extends Translations$epubReader$ko {
	_Translations$epubReader$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => 'Die Datei ist zu groß zum Öffnen.';
	@override String get networkFailure => 'Das Buch konnte wegen eines Netzwerkfehlers nicht geladen werden.';
	@override String get corruptedFile => 'Dieses EPUB ist beschädigt oder ungültig.';
	@override String get openFailed => 'Beim Öffnen des Buches ist ein Fehler aufgetreten.';
	@override String get positionRestoreFailed => 'Die letzte Position wurde nicht gefunden, daher beginnt das Buch von vorn';
	@override String get emptyBook => 'Dieses Buch enthält nichts zum Anzeigen.';
	@override String get emptyPage => 'Diese Seite enthält nichts zum Anzeigen.';
	@override String get chapterLoadFailed => 'Der Text konnte nicht geladen werden.';
	@override String get pageLoadFailed => 'Die Seite konnte nicht geladen werden.';
	@override String get formula => 'Formel';
}

// Path: home.library
class _Translations$home$library$de extends Translations$home$library$ko {
	_Translations$home$library$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'EPUB3-Beispielbibliothek';
	@override String get description => 'Prüft RTL, MathML, vertikale Schrift, Media Overlay und CFI';
}

// Path: home.core
class _Translations$home$core$de extends Translations$home$core$ko {
	_Translations$home$core$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => '1.0-Core-Demo';
}

// Path: home.highlight
class _Translations$home$highlight$de extends Translations$home$highlight$ko {
	_Translations$home$highlight$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Markierungsdemo';
	@override String get description => 'Text auswählen → Farbe → Markierung + Notiz';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$de extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fixed-Layout-A4-Demo';
	@override String get description => 'Stellt ein vorpaginiertes Buch im A4-Format (794×1123) dar';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$de extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Echtes EPUB2 mit Umbruch · 22 MB groß';
	@override String get tag => 'EPUB2 · große Datei';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$de extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · EPUB3-Grundlagen (nav, CSS)';
	@override String get tag => 'EPUB3-Grundlagen';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$de extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Arabisch · page-progression-direction=rtl';
	@override String get tag => 'RTL-Blättern (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$de extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '71 MathML-Formeln · TeX-Umwandlung und Ersatzdarstellung';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$de extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Japanische vertikale Schrift (vertical-rl) + RTL';
	@override String get tag => 'Vertikale Schrift (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$de extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'SMIL-Vorlesen mit synchroner Audio-Markierung';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$de extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · Landmarks und verschachteltes Inhaltsverzeichnis';
	@override String get tag => 'Umfassendes EPUB3 (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$de extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · page-list mit 7 Einträgen';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$de extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Vorpaginiertes festes Layout · A4 (794×1123), 3 Seiten';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$de extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get yellow => 'Gelb';
	@override String get green => 'Grün';
	@override String get blue => 'Blau';
	@override String get pink => 'Rosa';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'open_epub Demo',
			'common.previousPage' => 'Vorherige Seite',
			'common.nextPage' => 'Nächste Seite',
			'common.cancel' => 'Abbrechen',
			'common.save' => 'Speichern',
			'common.close' => 'Schließen',
			'home.library.title' => 'EPUB3-Beispielbibliothek',
			'home.library.description' => 'Prüft RTL, MathML, vertikale Schrift, Media Overlay und CFI',
			'home.core.title' => '1.0-Core-Demo',
			'home.highlight.title' => 'Markierungsdemo',
			'home.highlight.description' => 'Text auswählen → Farbe → Markierung + Notiz',
			'home.fixedLayout.title' => 'Fixed-Layout-A4-Demo',
			'home.fixedLayout.description' => 'Stellt ein vorpaginiertes Buch im A4-Format (794×1123) dar',
			'samples.nohoechan.subtitle' => 'Echtes EPUB2 mit Umbruch · 22 MB groß',
			'samples.nohoechan.tag' => 'EPUB2 · große Datei',
			'samples.wasteland.subtitle' => 'T.S. Eliot · EPUB3-Grundlagen (nav, CSS)',
			'samples.wasteland.tag' => 'EPUB3-Grundlagen',
			'samples.arabicRtl.subtitle' => 'Arabisch · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'RTL-Blättern (E14)',
			'samples.mathml.subtitle' => '71 MathML-Formeln · TeX-Umwandlung und Ersatzdarstellung',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => 'Japanische vertikale Schrift (vertical-rl) + RTL',
			'samples.vertical.tag' => 'Vertikale Schrift (E15)',
			'samples.mediaOverlay.subtitle' => 'SMIL-Vorlesen mit synchroner Audio-Markierung',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · Landmarks und verschachteltes Inhaltsverzeichnis',
			'samples.accessible.tag' => 'Umfassendes EPUB3 (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list mit 7 Einträgen',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'Vorpaginiertes festes Layout · A4 (794×1123), 3 Seiten',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => 'Dieses Buch hat kein Media Overlay',
			'reader.mediaOverlayLoadFailed' => 'Media Overlay (SMIL) konnte nicht geladen werden',
			'reader.audioFailed' => ({required Object error}) => 'Audiowiedergabe fehlgeschlagen (möglicherweise eine Einschränkung des Simulators): ${error}',
			'reader.localFixture' => ({required Object asset}) => 'Dieses Beispiel (${asset}) ist eine lokale Testdatei, die nicht im Repository liegt (wegen Größe oder Lizenz per .gitignore ausgeschlossen).\nZum Öffnen die EPUB-Datei in der lokalen Arbeitskopie unter packages/open_epub/example/assets/ ablegen und die App neu starten.',
			'reader.mode' => 'Modus',
			'reader.swipe' => 'Wischen',
			'reader.scroll' => 'Scrollen',
			'reader.vertical' => 'Vertikal',
			'reader.fontSmaller' => 'Schrift kleiner',
			'reader.fontLarger' => 'Schrift größer',
			'reader.verticalScroll' => 'Vertikal scrollen',
			'reader.rtlDirection' => 'Blätterrichtung RTL',
			'reader.verticalWriting' => 'Vertikale Schrift',
			'reader.narration' => 'Vorlesen (Media Overlay)',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · Korrekturen: ${count}',
			'core.recordHighlight' => 'recordHighlight() — toolUse-Ereignis',
			'core.recordBookmark' => 'recordBookmark() — toolUse-Ereignis',
			'core.assetLoadFailed' => ({required Object error}) => 'Asset konnte nicht geladen werden: ${error}',
			'core.positionTokenTitle' => 'BookPosition-v1-Token',
			'core.eventLog' => 'Ereignisprotokoll',
			'core.positionToken' => 'Positions-Token',
			'core.waitingForEvents' => 'Warte auf Ereignisse …',
			'highlight.list' => 'Markierungen',
			'highlight.action' => 'Markieren',
			'highlight.openFailed' => ({required Object error}) => 'Das Buch kann nicht geöffnet werden: ${error}',
			'highlight.selectFirst' => 'Bitte zuerst Text auswählen.',
			'highlight.saved' => ({required Object color}) => 'Markierung gespeichert (${color})',
			'highlight.deleted' => 'Markierung gelöscht',
			'highlight.noteSaved' => 'Notiz gespeichert',
			'highlight.hintSelected' => '„Markieren“ drücken, um die Auswahl einzufärben',
			'highlight.hintIdle' => 'Text auswählen, dann erscheint die Schaltfläche „Markieren“',
			'highlight.previousChapter' => 'Vorheriges Kapitel',
			'highlight.nextChapter' => 'Nächstes Kapitel',
			'highlight.note' => 'Notiz',
			'highlight.noteHint' => 'Notiz eingeben',
			'highlight.noteOptional' => 'Notiz (optional)',
			'highlight.colorLabel' => ({required Object color}) => 'Farbe: ${color}',
			'highlight.count' => ({required Object count}) => 'Markierungen: ${count}',
			'highlight.empty' => 'Noch keine Markierungen.',
			'highlight.noteLine' => ({required Object note}) => 'Notiz: ${note}',
			'highlight.menu' => 'Markierungsmenü',
			'highlight.editNote' => 'Notiz bearbeiten',
			'highlight.delete' => 'Löschen',
			'highlight.colors.yellow' => 'Gelb',
			'highlight.colors.green' => 'Grün',
			'highlight.colors.blue' => 'Blau',
			'highlight.colors.pink' => 'Rosa',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => 'Seite ${index}/${total}',
			'epubReader.fileTooLarge' => 'Die Datei ist zu groß zum Öffnen.',
			'epubReader.networkFailure' => 'Das Buch konnte wegen eines Netzwerkfehlers nicht geladen werden.',
			'epubReader.corruptedFile' => 'Dieses EPUB ist beschädigt oder ungültig.',
			'epubReader.openFailed' => 'Beim Öffnen des Buches ist ein Fehler aufgetreten.',
			'epubReader.positionRestoreFailed' => 'Die letzte Position wurde nicht gefunden, daher beginnt das Buch von vorn',
			'epubReader.emptyBook' => 'Dieses Buch enthält nichts zum Anzeigen.',
			'epubReader.emptyPage' => 'Diese Seite enthält nichts zum Anzeigen.',
			'epubReader.chapterLoadFailed' => 'Der Text konnte nicht geladen werden.',
			'epubReader.pageLoadFailed' => 'Die Seite konnte nicht geladen werden.',
			'epubReader.formula' => 'Formel',
			_ => null,
		};
	}
}
