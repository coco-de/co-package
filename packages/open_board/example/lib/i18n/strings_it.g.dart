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
class TranslationsIt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsIt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.it,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <it>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsIt _root = this; // ignore: unused_field

	@override 
	TranslationsIt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsIt(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$it app = _Translations$app$it._(_root);
	@override late final _Translations$common$it common = _Translations$common$it._(_root);
	@override late final _Translations$home$it home = _Translations$home$it._(_root);
	@override late final _Translations$tools$it tools = _Translations$tools$it._(_root);
	@override late final _Translations$link$it link = _Translations$link$it._(_root);
	@override late final _Translations$drawing$it drawing = _Translations$drawing$it._(_root);
	@override late final _Translations$split$it split = _Translations$split$it._(_root);
	@override late final _Translations$epub$it epub = _Translations$epub$it._(_root);
}

// Path: app
class _Translations$app$it extends Translations$app$ko {
	_Translations$app$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo di Open Board';
}

// Path: common
class _Translations$common$it extends Translations$common$ko {
	_Translations$common$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get undo => 'Annulla';
	@override String get redo => 'Ripeti';
	@override String get clear => 'Cancella tutto';
	@override String get previousPage => 'Pagina precedente';
	@override String get nextPage => 'Pagina successiva';
	@override String get loading => 'Caricamento…';
}

// Path: home
class _Translations$home$it extends Translations$home$ko {
	_Translations$home$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$it board = _Translations$home$board$it._(_root);
	@override late final _Translations$home$split$it split = _Translations$home$split$it._(_root);
	@override late final _Translations$home$epub$it epub = _Translations$home$epub$it._(_root);
}

// Path: tools
class _Translations$tools$it extends Translations$tools$ko {
	_Translations$tools$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get pen => 'Penna';
	@override String get pencil => 'Matita';
	@override String get marker => 'Pennarello';
	@override String get highlighter => 'Evidenziatore';
	@override String get fixedPen => 'Penna fissa';
	@override String get uniformPen => 'Penna uniforme';
	@override String get eraser => 'Gomma';
	@override String get text => 'Testo';
	@override String get shape => 'Forma';
	@override String get lasso => 'Lazo';
	@override String get image => 'Immagine';
}

// Path: link
class _Translations$link$it extends Translations$link$ko {
	_Translations$link$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get add => 'Aggiungi link';
	@override String get edit => 'Modifica link';
	@override String get remove => 'Rimuovi link';
	@override String get done => 'Fine';
	@override String get dialogTitle => 'Link';
	@override String get external => 'URL esterno';
	@override String get internal => 'Pagina interna';
	@override String get pageNumber => 'Numero di pagina';
	@override String get url => 'URL';
	@override String get cancel => 'Annulla';
	@override String get confirm => 'OK';
}

// Path: drawing
class _Translations$drawing$it extends Translations$drawing$ko {
	_Translations$drawing$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get startRecording => 'Avvia registrazione';
	@override String get stopRecording => 'Interrompi registrazione';
	@override String get replay => 'Riproduci';
	@override String get stopReplay => 'Interrompi riproduzione';
	@override String recording({required Object count}) => 'Registrazione · eventi: ${count}';
	@override String replaying({required Object index, required Object total}) => 'Riproduzione · ${index}/${total}';
	@override String ready({required Object count}) => 'Pronto per la riproduzione · eventi: ${count}';
	@override String get noRecording => 'Nessuna registrazione';
	@override String page({required Object number}) => 'Pagina ${number}';
	@override late final _Translations$drawing$features$it features = _Translations$drawing$features$it._(_root);
	@override late final _Translations$drawing$recordingGuide$it recordingGuide = _Translations$drawing$recordingGuide$it._(_root);
	@override late final _Translations$drawing$multiPage$it multiPage = _Translations$drawing$multiPage$it._(_root);
}

// Path: split
class _Translations$split$it extends Translations$split$ko {
	_Translations$split$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Schermo diviso — un unico pannello strumenti mobile';
}

// Path: epub
class _Translations$epub$it extends Translations$epub$ko {
	_Translations$epub$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get readingMode => 'Modalità lettura';
	@override String get annotationMode => 'Modalità annotazione';
	@override String get info => 'Le note vengono salvate per capitolo (spineHref) — open_epub 1.0 EpubReader con EpubViewController.';
	@override String get webNote => 'Sul web, le note restano solo per questa sessione.';
	@override String sample({required Object title}) => 'Esempio: ${title}';
}

// Path: home.board
class _Translations$home$board$it extends Translations$home$board$ko {
	_Translations$home$board$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo lavagna';
	@override String get description => 'Otto strumenti di scrittura, più pagine, registrazione e riproduzione';
}

// Path: home.split
class _Translations$home$split$it extends Translations$home$split$ko {
	_Translations$home$split$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo schermo diviso';
	@override String get description => 'Due aree di scrittura affiancate con un unico pannello strumenti mobile';
}

// Path: home.epub
class _Translations$home$epub$it extends Translations$home$epub$ko {
	_Translations$home$epub$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo annotazioni EPUB';
	@override String get description => 'Scrittura a mano collegata alle pagine sul lettore open_epub (passa dalla lettura alla scrittura)';
}

// Path: drawing.features
class _Translations$drawing$features$it extends Translations$drawing$features$ko {
	_Translations$drawing$features$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Funzionalità';
	@override List<String> get items => [
		'Strumenti di scrittura: penna, matita, pennarello e penna fissa',
		'Sei colori predefiniti',
		'Spessore del tratto regolabile (0,5–10,0)',
		'Gomma per cancellare i tratti',
		'Riconoscimento delle forme (cerchio, rettangolo, linea)',
		'Selezione a lazo per spostare i tratti',
		'Strumento testo per aggiungere note',
		'Annulla e ripeti',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$it extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Registrazione e riproduzione';
	@override List<String> get items => [
		'Premi il pulsante rosso per avviare la registrazione',
		'Scrivi, cambia pagina, ingrandisci e riduci: tutto viene registrato',
		'Premi stop per terminare la registrazione',
		'Premi play per riprodurre l’intera sessione',
		'Vengono registrati tratti, cambi di pagina e cambi di visualizzazione',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$it extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Più pagine';
	@override List<String> get items => [
		'Passa da una pagina all’altra con la barra delle pagine qui sopra',
		'Ogni pagina ha i propri tratti e la propria cronologia di annullamento',
		'ScribbleBookController gestisce tutte le pagine',
		'ScribbleCacheManager si occupa di cache e salvataggio',
		'Prova a scrivere su più pagine e a passare dall’una all’altra',
	];
	@override String get tip => 'Suggerimento: scrivi su questa pagina, poi su un’altra e torna qui. I tuoi tratti sono ancora qui.';
}

/// The flat map containing all translations for locale <it>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsIt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Demo di Open Board',
			'common.undo' => 'Annulla',
			'common.redo' => 'Ripeti',
			'common.clear' => 'Cancella tutto',
			'common.previousPage' => 'Pagina precedente',
			'common.nextPage' => 'Pagina successiva',
			'common.loading' => 'Caricamento…',
			'home.board.title' => 'Demo lavagna',
			'home.board.description' => 'Otto strumenti di scrittura, più pagine, registrazione e riproduzione',
			'home.split.title' => 'Demo schermo diviso',
			'home.split.description' => 'Due aree di scrittura affiancate con un unico pannello strumenti mobile',
			'home.epub.title' => 'Demo annotazioni EPUB',
			'home.epub.description' => 'Scrittura a mano collegata alle pagine sul lettore open_epub (passa dalla lettura alla scrittura)',
			'tools.pen' => 'Penna',
			'tools.pencil' => 'Matita',
			'tools.marker' => 'Pennarello',
			'tools.highlighter' => 'Evidenziatore',
			'tools.fixedPen' => 'Penna fissa',
			'tools.uniformPen' => 'Penna uniforme',
			'tools.eraser' => 'Gomma',
			'tools.text' => 'Testo',
			'tools.shape' => 'Forma',
			'tools.lasso' => 'Lazo',
			'tools.image' => 'Immagine',
			'link.add' => 'Aggiungi link',
			'link.edit' => 'Modifica link',
			'link.remove' => 'Rimuovi link',
			'link.done' => 'Fine',
			'link.dialogTitle' => 'Link',
			'link.external' => 'URL esterno',
			'link.internal' => 'Pagina interna',
			'link.pageNumber' => 'Numero di pagina',
			'link.url' => 'URL',
			'link.cancel' => 'Annulla',
			'link.confirm' => 'OK',
			'drawing.startRecording' => 'Avvia registrazione',
			'drawing.stopRecording' => 'Interrompi registrazione',
			'drawing.replay' => 'Riproduci',
			'drawing.stopReplay' => 'Interrompi riproduzione',
			'drawing.recording' => ({required Object count}) => 'Registrazione · eventi: ${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => 'Riproduzione · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => 'Pronto per la riproduzione · eventi: ${count}',
			'drawing.noRecording' => 'Nessuna registrazione',
			'drawing.page' => ({required Object number}) => 'Pagina ${number}',
			'drawing.features.title' => 'Funzionalità',
			'drawing.features.items.0' => 'Strumenti di scrittura: penna, matita, pennarello e penna fissa',
			'drawing.features.items.1' => 'Sei colori predefiniti',
			'drawing.features.items.2' => 'Spessore del tratto regolabile (0,5–10,0)',
			'drawing.features.items.3' => 'Gomma per cancellare i tratti',
			'drawing.features.items.4' => 'Riconoscimento delle forme (cerchio, rettangolo, linea)',
			'drawing.features.items.5' => 'Selezione a lazo per spostare i tratti',
			'drawing.features.items.6' => 'Strumento testo per aggiungere note',
			'drawing.features.items.7' => 'Annulla e ripeti',
			'drawing.recordingGuide.title' => 'Registrazione e riproduzione',
			'drawing.recordingGuide.items.0' => 'Premi il pulsante rosso per avviare la registrazione',
			'drawing.recordingGuide.items.1' => 'Scrivi, cambia pagina, ingrandisci e riduci: tutto viene registrato',
			'drawing.recordingGuide.items.2' => 'Premi stop per terminare la registrazione',
			'drawing.recordingGuide.items.3' => 'Premi play per riprodurre l’intera sessione',
			'drawing.recordingGuide.items.4' => 'Vengono registrati tratti, cambi di pagina e cambi di visualizzazione',
			'drawing.multiPage.title' => 'Più pagine',
			'drawing.multiPage.items.0' => 'Passa da una pagina all’altra con la barra delle pagine qui sopra',
			'drawing.multiPage.items.1' => 'Ogni pagina ha i propri tratti e la propria cronologia di annullamento',
			'drawing.multiPage.items.2' => 'ScribbleBookController gestisce tutte le pagine',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager si occupa di cache e salvataggio',
			'drawing.multiPage.items.4' => 'Prova a scrivere su più pagine e a passare dall’una all’altra',
			'drawing.multiPage.tip' => 'Suggerimento: scrivi su questa pagina, poi su un’altra e torna qui. I tuoi tratti sono ancora qui.',
			'split.title' => 'Schermo diviso — un unico pannello strumenti mobile',
			'epub.readingMode' => 'Modalità lettura',
			'epub.annotationMode' => 'Modalità annotazione',
			'epub.info' => 'Le note vengono salvate per capitolo (spineHref) — open_epub 1.0 EpubReader con EpubViewController.',
			'epub.webNote' => 'Sul web, le note restano solo per questa sessione.',
			'epub.sample' => ({required Object title}) => 'Esempio: ${title}',
			_ => null,
		};
	}
}
