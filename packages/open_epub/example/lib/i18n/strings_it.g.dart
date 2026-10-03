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
	@override late final _Translations$samples$it samples = _Translations$samples$it._(_root);
	@override late final _Translations$reader$it reader = _Translations$reader$it._(_root);
	@override late final _Translations$core$it core = _Translations$core$it._(_root);
	@override late final _Translations$highlight$it highlight = _Translations$highlight$it._(_root);
	@override late final _Translations$fixedLayout$it fixedLayout = _Translations$fixedLayout$it._(_root);
	@override late final _Translations$epubReader$it epubReader = _Translations$epubReader$it._(_root);
}

// Path: app
class _Translations$app$it extends Translations$app$ko {
	_Translations$app$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo di open_epub';
}

// Path: common
class _Translations$common$it extends Translations$common$ko {
	_Translations$common$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get previousPage => 'Pagina precedente';
	@override String get nextPage => 'Pagina successiva';
	@override String get cancel => 'Annulla';
	@override String get save => 'Salva';
	@override String get close => 'Chiudi';
}

// Path: home
class _Translations$home$it extends Translations$home$ko {
	_Translations$home$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$it library = _Translations$home$library$it._(_root);
	@override late final _Translations$home$core$it core = _Translations$home$core$it._(_root);
	@override late final _Translations$home$highlight$it highlight = _Translations$home$highlight$it._(_root);
	@override late final _Translations$home$fixedLayout$it fixedLayout = _Translations$home$fixedLayout$it._(_root);
}

// Path: samples
class _Translations$samples$it extends Translations$samples$ko {
	_Translations$samples$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$it nohoechan = _Translations$samples$nohoechan$it._(_root);
	@override late final _Translations$samples$wasteland$it wasteland = _Translations$samples$wasteland$it._(_root);
	@override late final _Translations$samples$arabicRtl$it arabicRtl = _Translations$samples$arabicRtl$it._(_root);
	@override late final _Translations$samples$mathml$it mathml = _Translations$samples$mathml$it._(_root);
	@override late final _Translations$samples$vertical$it vertical = _Translations$samples$vertical$it._(_root);
	@override late final _Translations$samples$mediaOverlay$it mediaOverlay = _Translations$samples$mediaOverlay$it._(_root);
	@override late final _Translations$samples$accessible$it accessible = _Translations$samples$accessible$it._(_root);
	@override late final _Translations$samples$cfi$it cfi = _Translations$samples$cfi$it._(_root);
	@override late final _Translations$samples$fixedA4$it fixedA4 = _Translations$samples$fixedA4$it._(_root);
}

// Path: reader
class _Translations$reader$it extends Translations$reader$ko {
	_Translations$reader$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => 'Questo libro non ha un Media Overlay';
	@override String get mediaOverlayLoadFailed => 'Caricamento del Media Overlay (SMIL) non riuscito';
	@override String audioFailed({required Object error}) => 'Riproduzione audio non riuscita (forse un limite del simulatore): ${error}';
	@override String localFixture({required Object asset}) => 'Questo esempio (${asset}) è un file di test locale non incluso nel repository (escluso da .gitignore per dimensioni o licenza).\nPer aprirlo, metti il file EPUB in packages/open_epub/example/assets/ nella tua copia locale e riavvia l’app.';
	@override String get mode => 'Modalità';
	@override String get swipe => 'pagine';
	@override String get scroll => 'scorrimento';
	@override String get vertical => 'Verticale';
	@override String get fontSmaller => 'Testo più piccolo';
	@override String get fontLarger => 'Testo più grande';
	@override String get verticalScroll => 'Scorrimento verticale';
	@override String get rtlDirection => 'Direzione pagine RTL';
	@override String get verticalWriting => 'Scrittura verticale';
	@override String get narration => 'Narrazione (Media Overlay)';
}

// Path: core
class _Translations$core$it extends Translations$core$ko {
	_Translations$core$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · correzioni: ${count}';
	@override String get recordHighlight => 'recordHighlight() — evento toolUse';
	@override String get recordBookmark => 'recordBookmark() — evento toolUse';
	@override String assetLoadFailed({required Object error}) => 'Caricamento dell’asset non riuscito: ${error}';
	@override String get positionTokenTitle => 'Token BookPosition v1';
	@override String get eventLog => 'Registro eventi';
	@override String get positionToken => 'Token di posizione';
	@override String get waitingForEvents => 'In attesa di eventi…';
}

// Path: highlight
class _Translations$highlight$it extends Translations$highlight$ko {
	_Translations$highlight$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get list => 'Evidenziazioni';
	@override String get action => 'Evidenzia';
	@override String openFailed({required Object error}) => 'Impossibile aprire il libro: ${error}';
	@override String get selectFirst => 'Seleziona prima del testo.';
	@override String saved({required Object color}) => 'Evidenziazione salvata (${color})';
	@override String get deleted => 'Evidenziazione eliminata';
	@override String get noteSaved => 'Nota salvata';
	@override String get hintSelected => 'Premi «Evidenzia» per colorare la selezione';
	@override String get hintIdle => 'Seleziona del testo per vedere il pulsante Evidenzia';
	@override String get previousChapter => 'Capitolo precedente';
	@override String get nextChapter => 'Capitolo successivo';
	@override String get note => 'Nota';
	@override String get noteHint => 'Scrivi una nota';
	@override String get noteOptional => 'Nota (facoltativa)';
	@override String colorLabel({required Object color}) => 'Colore: ${color}';
	@override String count({required Object count}) => 'Evidenziazioni: ${count}';
	@override String get empty => 'Nessuna evidenziazione salvata.';
	@override String noteLine({required Object note}) => 'Nota: ${note}';
	@override String get menu => 'Menu evidenziazione';
	@override String get editNote => 'Modifica nota';
	@override String get delete => 'Elimina';
	@override late final _Translations$highlight$colors$it colors = _Translations$highlight$colors$it._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$it extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => 'pagina ${index}/${total}';
}

// Path: epubReader
class _Translations$epubReader$it extends Translations$epubReader$ko {
	_Translations$epubReader$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => 'Il file è troppo grande per essere aperto.';
	@override String get networkFailure => 'Impossibile scaricare il libro a causa di un errore di rete.';
	@override String get corruptedFile => 'Questo EPUB è danneggiato o non valido.';
	@override String get openFailed => 'Si è verificato un errore durante l’apertura del libro.';
	@override String get positionRestoreFailed => 'Impossibile trovare l’ultima posizione: il libro riparte dall’inizio';
	@override String get emptyBook => 'Questo libro non ha contenuti da mostrare.';
	@override String get emptyPage => 'Questa pagina non ha contenuti da mostrare.';
	@override String get chapterLoadFailed => 'Impossibile caricare il testo.';
	@override String get pageLoadFailed => 'Impossibile caricare la pagina.';
	@override String get formula => 'Formula';
}

// Path: home.library
class _Translations$home$library$it extends Translations$home$library$ko {
	_Translations$home$library$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Libreria di esempi EPUB3';
	@override String get description => 'Verifica RTL, MathML, scrittura verticale, Media Overlay e CFI';
}

// Path: home.core
class _Translations$home$core$it extends Translations$home$core$ko {
	_Translations$home$core$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo del core 1.0';
}

// Path: home.highlight
class _Translations$home$highlight$it extends Translations$home$highlight$ko {
	_Translations$home$highlight$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo evidenziazione';
	@override String get description => 'Selezione del testo → colore → evidenziazione + nota';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$it extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo Fixed Layout A4';
	@override String get description => 'Mostra un libro preimpaginato in formato A4 (794×1123)';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$it extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB2 reale con testo adattabile · 22 MB';
	@override String get tag => 'EPUB2 · file grande';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$it extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · basi di EPUB3 (nav, CSS)';
	@override String get tag => 'Basi di EPUB3';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$it extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Arabo · page-progression-direction=rtl';
	@override String get tag => 'Pagine da destra a sinistra (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$it extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '71 formule MathML · conversione in TeX e ripiego';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$it extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Scrittura verticale giapponese (vertical-rl) + RTL';
	@override String get tag => 'Scrittura verticale (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$it extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Narrazione SMIL con evidenziazione sincronizzata all’audio';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$it extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · punti di riferimento e indice annidato';
	@override String get tag => 'EPUB3 completo (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$it extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · page-list di 7 voci';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$it extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Layout fisso preimpaginato · A4 (794×1123), 3 pagine';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$it extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get yellow => 'Giallo';
	@override String get green => 'Verde';
	@override String get blue => 'Blu';
	@override String get pink => 'Rosa';
}

/// The flat map containing all translations for locale <it>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsIt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Demo di open_epub',
			'common.previousPage' => 'Pagina precedente',
			'common.nextPage' => 'Pagina successiva',
			'common.cancel' => 'Annulla',
			'common.save' => 'Salva',
			'common.close' => 'Chiudi',
			'home.library.title' => 'Libreria di esempi EPUB3',
			'home.library.description' => 'Verifica RTL, MathML, scrittura verticale, Media Overlay e CFI',
			'home.core.title' => 'Demo del core 1.0',
			'home.highlight.title' => 'Demo evidenziazione',
			'home.highlight.description' => 'Selezione del testo → colore → evidenziazione + nota',
			'home.fixedLayout.title' => 'Demo Fixed Layout A4',
			'home.fixedLayout.description' => 'Mostra un libro preimpaginato in formato A4 (794×1123)',
			'samples.nohoechan.subtitle' => 'EPUB2 reale con testo adattabile · 22 MB',
			'samples.nohoechan.tag' => 'EPUB2 · file grande',
			'samples.wasteland.subtitle' => 'T.S. Eliot · basi di EPUB3 (nav, CSS)',
			'samples.wasteland.tag' => 'Basi di EPUB3',
			'samples.arabicRtl.subtitle' => 'Arabo · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'Pagine da destra a sinistra (E14)',
			'samples.mathml.subtitle' => '71 formule MathML · conversione in TeX e ripiego',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => 'Scrittura verticale giapponese (vertical-rl) + RTL',
			'samples.vertical.tag' => 'Scrittura verticale (E15)',
			'samples.mediaOverlay.subtitle' => 'Narrazione SMIL con evidenziazione sincronizzata all’audio',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · punti di riferimento e indice annidato',
			'samples.accessible.tag' => 'EPUB3 completo (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list di 7 voci',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'Layout fisso preimpaginato · A4 (794×1123), 3 pagine',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => 'Questo libro non ha un Media Overlay',
			'reader.mediaOverlayLoadFailed' => 'Caricamento del Media Overlay (SMIL) non riuscito',
			'reader.audioFailed' => ({required Object error}) => 'Riproduzione audio non riuscita (forse un limite del simulatore): ${error}',
			'reader.localFixture' => ({required Object asset}) => 'Questo esempio (${asset}) è un file di test locale non incluso nel repository (escluso da .gitignore per dimensioni o licenza).\nPer aprirlo, metti il file EPUB in packages/open_epub/example/assets/ nella tua copia locale e riavvia l’app.',
			'reader.mode' => 'Modalità',
			'reader.swipe' => 'pagine',
			'reader.scroll' => 'scorrimento',
			'reader.vertical' => 'Verticale',
			'reader.fontSmaller' => 'Testo più piccolo',
			'reader.fontLarger' => 'Testo più grande',
			'reader.verticalScroll' => 'Scorrimento verticale',
			'reader.rtlDirection' => 'Direzione pagine RTL',
			'reader.verticalWriting' => 'Scrittura verticale',
			'reader.narration' => 'Narrazione (Media Overlay)',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · correzioni: ${count}',
			'core.recordHighlight' => 'recordHighlight() — evento toolUse',
			'core.recordBookmark' => 'recordBookmark() — evento toolUse',
			'core.assetLoadFailed' => ({required Object error}) => 'Caricamento dell’asset non riuscito: ${error}',
			'core.positionTokenTitle' => 'Token BookPosition v1',
			'core.eventLog' => 'Registro eventi',
			'core.positionToken' => 'Token di posizione',
			'core.waitingForEvents' => 'In attesa di eventi…',
			'highlight.list' => 'Evidenziazioni',
			'highlight.action' => 'Evidenzia',
			'highlight.openFailed' => ({required Object error}) => 'Impossibile aprire il libro: ${error}',
			'highlight.selectFirst' => 'Seleziona prima del testo.',
			'highlight.saved' => ({required Object color}) => 'Evidenziazione salvata (${color})',
			'highlight.deleted' => 'Evidenziazione eliminata',
			'highlight.noteSaved' => 'Nota salvata',
			'highlight.hintSelected' => 'Premi «Evidenzia» per colorare la selezione',
			'highlight.hintIdle' => 'Seleziona del testo per vedere il pulsante Evidenzia',
			'highlight.previousChapter' => 'Capitolo precedente',
			'highlight.nextChapter' => 'Capitolo successivo',
			'highlight.note' => 'Nota',
			'highlight.noteHint' => 'Scrivi una nota',
			'highlight.noteOptional' => 'Nota (facoltativa)',
			'highlight.colorLabel' => ({required Object color}) => 'Colore: ${color}',
			'highlight.count' => ({required Object count}) => 'Evidenziazioni: ${count}',
			'highlight.empty' => 'Nessuna evidenziazione salvata.',
			'highlight.noteLine' => ({required Object note}) => 'Nota: ${note}',
			'highlight.menu' => 'Menu evidenziazione',
			'highlight.editNote' => 'Modifica nota',
			'highlight.delete' => 'Elimina',
			'highlight.colors.yellow' => 'Giallo',
			'highlight.colors.green' => 'Verde',
			'highlight.colors.blue' => 'Blu',
			'highlight.colors.pink' => 'Rosa',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => 'pagina ${index}/${total}',
			'epubReader.fileTooLarge' => 'Il file è troppo grande per essere aperto.',
			'epubReader.networkFailure' => 'Impossibile scaricare il libro a causa di un errore di rete.',
			'epubReader.corruptedFile' => 'Questo EPUB è danneggiato o non valido.',
			'epubReader.openFailed' => 'Si è verificato un errore durante l’apertura del libro.',
			'epubReader.positionRestoreFailed' => 'Impossibile trovare l’ultima posizione: il libro riparte dall’inizio',
			'epubReader.emptyBook' => 'Questo libro non ha contenuti da mostrare.',
			'epubReader.emptyPage' => 'Questa pagina non ha contenuti da mostrare.',
			'epubReader.chapterLoadFailed' => 'Impossibile caricare il testo.',
			'epubReader.pageLoadFailed' => 'Impossibile caricare la pagina.',
			'epubReader.formula' => 'Formula',
			_ => null,
		};
	}
}
