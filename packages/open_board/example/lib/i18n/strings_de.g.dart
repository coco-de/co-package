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
	@override late final _Translations$tools$de tools = _Translations$tools$de._(_root);
	@override late final _Translations$link$de link = _Translations$link$de._(_root);
	@override late final _Translations$drawing$de drawing = _Translations$drawing$de._(_root);
	@override late final _Translations$split$de split = _Translations$split$de._(_root);
	@override late final _Translations$epub$de epub = _Translations$epub$de._(_root);
}

// Path: app
class _Translations$app$de extends Translations$app$ko {
	_Translations$app$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Open Board Demo';
}

// Path: common
class _Translations$common$de extends Translations$common$ko {
	_Translations$common$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get undo => 'Rückgängig';
	@override String get redo => 'Wiederholen';
	@override String get clear => 'Alles löschen';
	@override String get previousPage => 'Vorherige Seite';
	@override String get nextPage => 'Nächste Seite';
	@override String get loading => 'Wird geladen …';
}

// Path: home
class _Translations$home$de extends Translations$home$ko {
	_Translations$home$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$de board = _Translations$home$board$de._(_root);
	@override late final _Translations$home$split$de split = _Translations$home$split$de._(_root);
	@override late final _Translations$home$epub$de epub = _Translations$home$epub$de._(_root);
}

// Path: tools
class _Translations$tools$de extends Translations$tools$ko {
	_Translations$tools$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get pen => 'Stift';
	@override String get pencil => 'Bleistift';
	@override String get marker => 'Marker';
	@override String get highlighter => 'Textmarker';
	@override String get fixedPen => 'Fester Stift';
	@override String get uniformPen => 'Gleichmäßiger Stift';
	@override String get eraser => 'Radierer';
	@override String get text => 'Text';
	@override String get shape => 'Form';
	@override String get lasso => 'Lasso';
	@override String get image => 'Bild';
}

// Path: link
class _Translations$link$de extends Translations$link$ko {
	_Translations$link$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get add => 'Link hinzufügen';
	@override String get edit => 'Link bearbeiten';
	@override String get remove => 'Link entfernen';
	@override String get done => 'Fertig';
	@override String get dialogTitle => 'Link';
	@override String get external => 'Externe URL';
	@override String get internal => 'Interne Seite';
	@override String get pageNumber => 'Seitenzahl';
	@override String get url => 'URL';
	@override String get cancel => 'Abbrechen';
	@override String get confirm => 'OK';
}

// Path: drawing
class _Translations$drawing$de extends Translations$drawing$ko {
	_Translations$drawing$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get startRecording => 'Aufnahme starten';
	@override String get stopRecording => 'Aufnahme beenden';
	@override String get replay => 'Wiedergeben';
	@override String get stopReplay => 'Wiedergabe beenden';
	@override String recording({required Object count}) => 'Aufnahme · Ereignisse: ${count}';
	@override String replaying({required Object index, required Object total}) => 'Wiedergabe · ${index}/${total}';
	@override String ready({required Object count}) => 'Bereit zur Wiedergabe · Ereignisse: ${count}';
	@override String get noRecording => 'Keine Aufnahme';
	@override String page({required Object number}) => 'Seite ${number}';
	@override late final _Translations$drawing$features$de features = _Translations$drawing$features$de._(_root);
	@override late final _Translations$drawing$recordingGuide$de recordingGuide = _Translations$drawing$recordingGuide$de._(_root);
	@override late final _Translations$drawing$multiPage$de multiPage = _Translations$drawing$multiPage$de._(_root);
}

// Path: split
class _Translations$split$de extends Translations$split$ko {
	_Translations$split$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Geteilte Zeichenfläche – ein schwebendes Werkzeugfeld';
}

// Path: epub
class _Translations$epub$de extends Translations$epub$ko {
	_Translations$epub$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get readingMode => 'Lesemodus';
	@override String get annotationMode => 'Anmerkungsmodus';
	@override String get info => 'Notizen werden pro Kapitel (spineHref) gespeichert – open_epub 1.0 EpubReader mit EpubViewController.';
	@override String get webNote => 'Im Web bleiben Notizen nur während dieser Sitzung erhalten.';
	@override String sample({required Object title}) => 'Beispiel: ${title}';
}

// Path: home.board
class _Translations$home$board$de extends Translations$home$board$ko {
	_Translations$home$board$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Board-Demo';
	@override String get description => 'Acht Zeichenwerkzeuge, mehrere Seiten, Aufnahme und Wiedergabe';
}

// Path: home.split
class _Translations$home$split$de extends Translations$home$split$ko {
	_Translations$home$split$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo: geteilte Zeichenfläche';
	@override String get description => 'Zwei Zeichenflächen nebeneinander mit einem schwebenden Werkzeugfeld';
}

// Path: home.epub
class _Translations$home$epub$de extends Translations$home$epub$ko {
	_Translations$home$epub$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'EPUB-Anmerkungsdemo';
	@override String get description => 'Seitenbezogene Handschrift über dem open_epub-Reader (zwischen Lesen und Schreiben wechseln)';
}

// Path: drawing.features
class _Translations$drawing$features$de extends Translations$drawing$features$ko {
	_Translations$drawing$features$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Funktionen';
	@override List<String> get items => [
		'Zeichenwerkzeuge Stift, Bleistift, Marker und fester Stift',
		'Sechs voreingestellte Farben',
		'Einstellbare Strichstärke (0,5–10,0)',
		'Radierer zum Entfernen von Strichen',
		'Formerkennung (Kreis, Rechteck, Linie)',
		'Lasso-Auswahl zum Verschieben von Strichen',
		'Textwerkzeug für Textnotizen',
		'Rückgängig und Wiederholen',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$de extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Aufnahme & Wiedergabe';
	@override List<String> get items => [
		'Rote Aufnahmetaste drücken, um die Aufnahme zu starten',
		'Zeichnen, Seiten wechseln, vergrößern und verkleinern – alles wird aufgezeichnet',
		'Stopp drücken, um die Aufnahme zu beenden',
		'Wiedergabe drücken, um die ganze Sitzung abzuspielen',
		'Striche, Seitenwechsel und Ansichtsänderungen werden aufgezeichnet',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$de extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mehrere Seiten';
	@override List<String> get items => [
		'Mit der Seitenleiste oben zwischen den Seiten wechseln',
		'Jede Seite hat eigene Striche und einen eigenen Rückgängig-Verlauf',
		'ScribbleBookController verwaltet alle Seiten',
		'ScribbleCacheManager übernimmt Zwischenspeicherung und Speicherung',
		'Auf verschiedenen Seiten zeichnen und zwischen ihnen wechseln',
	];
	@override String get tip => 'Tipp: Auf dieser Seite zeichnen, dann auf einer anderen Seite zeichnen und zurückkehren. Die Striche sind noch da.';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Open Board Demo',
			'common.undo' => 'Rückgängig',
			'common.redo' => 'Wiederholen',
			'common.clear' => 'Alles löschen',
			'common.previousPage' => 'Vorherige Seite',
			'common.nextPage' => 'Nächste Seite',
			'common.loading' => 'Wird geladen …',
			'home.board.title' => 'Board-Demo',
			'home.board.description' => 'Acht Zeichenwerkzeuge, mehrere Seiten, Aufnahme und Wiedergabe',
			'home.split.title' => 'Demo: geteilte Zeichenfläche',
			'home.split.description' => 'Zwei Zeichenflächen nebeneinander mit einem schwebenden Werkzeugfeld',
			'home.epub.title' => 'EPUB-Anmerkungsdemo',
			'home.epub.description' => 'Seitenbezogene Handschrift über dem open_epub-Reader (zwischen Lesen und Schreiben wechseln)',
			'tools.pen' => 'Stift',
			'tools.pencil' => 'Bleistift',
			'tools.marker' => 'Marker',
			'tools.highlighter' => 'Textmarker',
			'tools.fixedPen' => 'Fester Stift',
			'tools.uniformPen' => 'Gleichmäßiger Stift',
			'tools.eraser' => 'Radierer',
			'tools.text' => 'Text',
			'tools.shape' => 'Form',
			'tools.lasso' => 'Lasso',
			'tools.image' => 'Bild',
			'link.add' => 'Link hinzufügen',
			'link.edit' => 'Link bearbeiten',
			'link.remove' => 'Link entfernen',
			'link.done' => 'Fertig',
			'link.dialogTitle' => 'Link',
			'link.external' => 'Externe URL',
			'link.internal' => 'Interne Seite',
			'link.pageNumber' => 'Seitenzahl',
			'link.url' => 'URL',
			'link.cancel' => 'Abbrechen',
			'link.confirm' => 'OK',
			'drawing.startRecording' => 'Aufnahme starten',
			'drawing.stopRecording' => 'Aufnahme beenden',
			'drawing.replay' => 'Wiedergeben',
			'drawing.stopReplay' => 'Wiedergabe beenden',
			'drawing.recording' => ({required Object count}) => 'Aufnahme · Ereignisse: ${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => 'Wiedergabe · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => 'Bereit zur Wiedergabe · Ereignisse: ${count}',
			'drawing.noRecording' => 'Keine Aufnahme',
			'drawing.page' => ({required Object number}) => 'Seite ${number}',
			'drawing.features.title' => 'Funktionen',
			'drawing.features.items.0' => 'Zeichenwerkzeuge Stift, Bleistift, Marker und fester Stift',
			'drawing.features.items.1' => 'Sechs voreingestellte Farben',
			'drawing.features.items.2' => 'Einstellbare Strichstärke (0,5–10,0)',
			'drawing.features.items.3' => 'Radierer zum Entfernen von Strichen',
			'drawing.features.items.4' => 'Formerkennung (Kreis, Rechteck, Linie)',
			'drawing.features.items.5' => 'Lasso-Auswahl zum Verschieben von Strichen',
			'drawing.features.items.6' => 'Textwerkzeug für Textnotizen',
			'drawing.features.items.7' => 'Rückgängig und Wiederholen',
			'drawing.recordingGuide.title' => 'Aufnahme & Wiedergabe',
			'drawing.recordingGuide.items.0' => 'Rote Aufnahmetaste drücken, um die Aufnahme zu starten',
			'drawing.recordingGuide.items.1' => 'Zeichnen, Seiten wechseln, vergrößern und verkleinern – alles wird aufgezeichnet',
			'drawing.recordingGuide.items.2' => 'Stopp drücken, um die Aufnahme zu beenden',
			'drawing.recordingGuide.items.3' => 'Wiedergabe drücken, um die ganze Sitzung abzuspielen',
			'drawing.recordingGuide.items.4' => 'Striche, Seitenwechsel und Ansichtsänderungen werden aufgezeichnet',
			'drawing.multiPage.title' => 'Mehrere Seiten',
			'drawing.multiPage.items.0' => 'Mit der Seitenleiste oben zwischen den Seiten wechseln',
			'drawing.multiPage.items.1' => 'Jede Seite hat eigene Striche und einen eigenen Rückgängig-Verlauf',
			'drawing.multiPage.items.2' => 'ScribbleBookController verwaltet alle Seiten',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager übernimmt Zwischenspeicherung und Speicherung',
			'drawing.multiPage.items.4' => 'Auf verschiedenen Seiten zeichnen und zwischen ihnen wechseln',
			'drawing.multiPage.tip' => 'Tipp: Auf dieser Seite zeichnen, dann auf einer anderen Seite zeichnen und zurückkehren. Die Striche sind noch da.',
			'split.title' => 'Geteilte Zeichenfläche – ein schwebendes Werkzeugfeld',
			'epub.readingMode' => 'Lesemodus',
			'epub.annotationMode' => 'Anmerkungsmodus',
			'epub.info' => 'Notizen werden pro Kapitel (spineHref) gespeichert – open_epub 1.0 EpubReader mit EpubViewController.',
			'epub.webNote' => 'Im Web bleiben Notizen nur während dieser Sitzung erhalten.',
			'epub.sample' => ({required Object title}) => 'Beispiel: ${title}',
			_ => null,
		};
	}
}
