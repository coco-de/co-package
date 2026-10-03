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
class TranslationsFr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$fr app = _Translations$app$fr._(_root);
	@override late final _Translations$common$fr common = _Translations$common$fr._(_root);
	@override late final _Translations$home$fr home = _Translations$home$fr._(_root);
	@override late final _Translations$samples$fr samples = _Translations$samples$fr._(_root);
	@override late final _Translations$reader$fr reader = _Translations$reader$fr._(_root);
	@override late final _Translations$core$fr core = _Translations$core$fr._(_root);
	@override late final _Translations$highlight$fr highlight = _Translations$highlight$fr._(_root);
	@override late final _Translations$fixedLayout$fr fixedLayout = _Translations$fixedLayout$fr._(_root);
	@override late final _Translations$epubReader$fr epubReader = _Translations$epubReader$fr._(_root);
}

// Path: app
class _Translations$app$fr extends Translations$app$ko {
	_Translations$app$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Démo open_epub';
}

// Path: common
class _Translations$common$fr extends Translations$common$ko {
	_Translations$common$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get previousPage => 'Page précédente';
	@override String get nextPage => 'Page suivante';
	@override String get cancel => 'Annuler';
	@override String get save => 'Enregistrer';
	@override String get close => 'Fermer';
}

// Path: home
class _Translations$home$fr extends Translations$home$ko {
	_Translations$home$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$fr library = _Translations$home$library$fr._(_root);
	@override late final _Translations$home$core$fr core = _Translations$home$core$fr._(_root);
	@override late final _Translations$home$highlight$fr highlight = _Translations$home$highlight$fr._(_root);
	@override late final _Translations$home$fixedLayout$fr fixedLayout = _Translations$home$fixedLayout$fr._(_root);
}

// Path: samples
class _Translations$samples$fr extends Translations$samples$ko {
	_Translations$samples$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$fr nohoechan = _Translations$samples$nohoechan$fr._(_root);
	@override late final _Translations$samples$wasteland$fr wasteland = _Translations$samples$wasteland$fr._(_root);
	@override late final _Translations$samples$arabicRtl$fr arabicRtl = _Translations$samples$arabicRtl$fr._(_root);
	@override late final _Translations$samples$mathml$fr mathml = _Translations$samples$mathml$fr._(_root);
	@override late final _Translations$samples$vertical$fr vertical = _Translations$samples$vertical$fr._(_root);
	@override late final _Translations$samples$mediaOverlay$fr mediaOverlay = _Translations$samples$mediaOverlay$fr._(_root);
	@override late final _Translations$samples$accessible$fr accessible = _Translations$samples$accessible$fr._(_root);
	@override late final _Translations$samples$cfi$fr cfi = _Translations$samples$cfi$fr._(_root);
	@override late final _Translations$samples$fixedA4$fr fixedA4 = _Translations$samples$fixedA4$fr._(_root);
}

// Path: reader
class _Translations$reader$fr extends Translations$reader$ko {
	_Translations$reader$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => 'Ce livre n’a pas de Media Overlay';
	@override String get mediaOverlayLoadFailed => 'Échec du chargement du Media Overlay (SMIL)';
	@override String audioFailed({required Object error}) => 'Échec de la lecture audio (peut-être une limite du simulateur) : ${error}';
	@override String localFixture({required Object asset}) => 'Cet exemple (${asset}) est un fichier de test local qui n’est pas dans le dépôt (exclu par .gitignore pour des raisons de taille ou de licence).\nPour l’ouvrir, placez le fichier EPUB dans packages/open_epub/example/assets/ de votre copie locale, puis relancez l’application.';
	@override String get mode => 'Mode';
	@override String get swipe => 'balayage';
	@override String get scroll => 'défilement';
	@override String get vertical => 'Vertical';
	@override String get fontSmaller => 'Texte plus petit';
	@override String get fontLarger => 'Texte plus grand';
	@override String get verticalScroll => 'Défilement vertical';
	@override String get rtlDirection => 'Sens de lecture RTL';
	@override String get verticalWriting => 'Écriture verticale';
	@override String get narration => 'Lecture à voix haute (Media Overlay)';
}

// Path: core
class _Translations$core$fr extends Translations$core$ko {
	_Translations$core$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout : ${layout} · corrections : ${count}';
	@override String get recordHighlight => 'recordHighlight() — événement toolUse';
	@override String get recordBookmark => 'recordBookmark() — événement toolUse';
	@override String assetLoadFailed({required Object error}) => 'Échec du chargement de l’asset : ${error}';
	@override String get positionTokenTitle => 'Jeton BookPosition v1';
	@override String get eventLog => 'Journal des événements';
	@override String get positionToken => 'Jeton de position';
	@override String get waitingForEvents => 'En attente d’événements…';
}

// Path: highlight
class _Translations$highlight$fr extends Translations$highlight$ko {
	_Translations$highlight$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get list => 'Surlignages';
	@override String get action => 'Surligner';
	@override String openFailed({required Object error}) => 'Impossible d’ouvrir le livre : ${error}';
	@override String get selectFirst => 'Sélectionnez d’abord du texte.';
	@override String saved({required Object color}) => 'Surlignage enregistré (${color})';
	@override String get deleted => 'Surlignage supprimé';
	@override String get noteSaved => 'Note enregistrée';
	@override String get hintSelected => 'Appuyez sur « Surligner » pour colorer la sélection';
	@override String get hintIdle => 'Sélectionnez du texte pour afficher le bouton Surligner';
	@override String get previousChapter => 'Chapitre précédent';
	@override String get nextChapter => 'Chapitre suivant';
	@override String get note => 'Note';
	@override String get noteHint => 'Saisissez une note';
	@override String get noteOptional => 'Note (facultative)';
	@override String colorLabel({required Object color}) => 'Couleur : ${color}';
	@override String count({required Object count}) => 'Surlignages : ${count}';
	@override String get empty => 'Aucun surlignage pour l’instant.';
	@override String noteLine({required Object note}) => 'Note : ${note}';
	@override String get menu => 'Menu du surlignage';
	@override String get editNote => 'Modifier la note';
	@override String get delete => 'Supprimer';
	@override late final _Translations$highlight$colors$fr colors = _Translations$highlight$colors$fr._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$fr extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => 'page ${index}/${total}';
}

// Path: epubReader
class _Translations$epubReader$fr extends Translations$epubReader$ko {
	_Translations$epubReader$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => 'Ce fichier est trop volumineux pour être ouvert.';
	@override String get networkFailure => 'Le livre n’a pas pu être récupéré à cause d’une erreur réseau.';
	@override String get corruptedFile => 'Cet EPUB est endommagé ou non valide.';
	@override String get openFailed => 'Une erreur s’est produite à l’ouverture du livre.';
	@override String get positionRestoreFailed => 'Impossible de retrouver votre dernière position : le livre s’affiche depuis le début';
	@override String get emptyBook => 'Ce livre n’a rien à afficher.';
	@override String get emptyPage => 'Cette page n’a rien à afficher.';
	@override String get chapterLoadFailed => 'Impossible de charger le texte.';
	@override String get pageLoadFailed => 'Impossible de charger la page.';
	@override String get formula => 'Formule';
}

// Path: home.library
class _Translations$home$library$fr extends Translations$home$library$ko {
	_Translations$home$library$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliothèque d’exemples EPUB3';
	@override String get description => 'Vérifie RTL, MathML, écriture verticale, Media Overlay et CFI';
}

// Path: home.core
class _Translations$home$core$fr extends Translations$home$core$ko {
	_Translations$home$core$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Démo du cœur 1.0';
}

// Path: home.highlight
class _Translations$home$highlight$fr extends Translations$home$highlight$ko {
	_Translations$home$highlight$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Démo de surlignage';
	@override String get description => 'Sélection de texte → couleur → surlignage + note';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$fr extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Démo Fixed Layout A4';
	@override String get description => 'Affiche un livre prépaginé au format A4 (794×1123)';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$fr extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB2 réel en texte recomposable · 22 Mo';
	@override String get tag => 'EPUB2 · fichier volumineux';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$fr extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · bases d’EPUB3 (nav, CSS)';
	@override String get tag => 'Bases d’EPUB3';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$fr extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Arabe · page-progression-direction=rtl';
	@override String get tag => 'Pages de droite à gauche (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$fr extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '71 formules MathML · conversion TeX et repli';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$fr extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Écriture verticale japonaise (vertical-rl) + RTL';
	@override String get tag => 'Écriture verticale (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$fr extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Lecture SMIL avec surlignage synchronisé à l’audio';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$fr extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · repères (landmarks) et table des matières imbriquée';
	@override String get tag => 'EPUB3 complet (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$fr extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · page-list de 7 entrées';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$fr extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Mise en page fixe prépaginée · A4 (794×1123), 3 pages';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$fr extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get yellow => 'Jaune';
	@override String get green => 'Vert';
	@override String get blue => 'Bleu';
	@override String get pink => 'Rose';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Démo open_epub',
			'common.previousPage' => 'Page précédente',
			'common.nextPage' => 'Page suivante',
			'common.cancel' => 'Annuler',
			'common.save' => 'Enregistrer',
			'common.close' => 'Fermer',
			'home.library.title' => 'Bibliothèque d’exemples EPUB3',
			'home.library.description' => 'Vérifie RTL, MathML, écriture verticale, Media Overlay et CFI',
			'home.core.title' => 'Démo du cœur 1.0',
			'home.highlight.title' => 'Démo de surlignage',
			'home.highlight.description' => 'Sélection de texte → couleur → surlignage + note',
			'home.fixedLayout.title' => 'Démo Fixed Layout A4',
			'home.fixedLayout.description' => 'Affiche un livre prépaginé au format A4 (794×1123)',
			'samples.nohoechan.subtitle' => 'EPUB2 réel en texte recomposable · 22 Mo',
			'samples.nohoechan.tag' => 'EPUB2 · fichier volumineux',
			'samples.wasteland.subtitle' => 'T.S. Eliot · bases d’EPUB3 (nav, CSS)',
			'samples.wasteland.tag' => 'Bases d’EPUB3',
			'samples.arabicRtl.subtitle' => 'Arabe · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'Pages de droite à gauche (E14)',
			'samples.mathml.subtitle' => '71 formules MathML · conversion TeX et repli',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => 'Écriture verticale japonaise (vertical-rl) + RTL',
			'samples.vertical.tag' => 'Écriture verticale (E15)',
			'samples.mediaOverlay.subtitle' => 'Lecture SMIL avec surlignage synchronisé à l’audio',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · repères (landmarks) et table des matières imbriquée',
			'samples.accessible.tag' => 'EPUB3 complet (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list de 7 entrées',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'Mise en page fixe prépaginée · A4 (794×1123), 3 pages',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => 'Ce livre n’a pas de Media Overlay',
			'reader.mediaOverlayLoadFailed' => 'Échec du chargement du Media Overlay (SMIL)',
			'reader.audioFailed' => ({required Object error}) => 'Échec de la lecture audio (peut-être une limite du simulateur) : ${error}',
			'reader.localFixture' => ({required Object asset}) => 'Cet exemple (${asset}) est un fichier de test local qui n’est pas dans le dépôt (exclu par .gitignore pour des raisons de taille ou de licence).\nPour l’ouvrir, placez le fichier EPUB dans packages/open_epub/example/assets/ de votre copie locale, puis relancez l’application.',
			'reader.mode' => 'Mode',
			'reader.swipe' => 'balayage',
			'reader.scroll' => 'défilement',
			'reader.vertical' => 'Vertical',
			'reader.fontSmaller' => 'Texte plus petit',
			'reader.fontLarger' => 'Texte plus grand',
			'reader.verticalScroll' => 'Défilement vertical',
			'reader.rtlDirection' => 'Sens de lecture RTL',
			'reader.verticalWriting' => 'Écriture verticale',
			'reader.narration' => 'Lecture à voix haute (Media Overlay)',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout : ${layout} · corrections : ${count}',
			'core.recordHighlight' => 'recordHighlight() — événement toolUse',
			'core.recordBookmark' => 'recordBookmark() — événement toolUse',
			'core.assetLoadFailed' => ({required Object error}) => 'Échec du chargement de l’asset : ${error}',
			'core.positionTokenTitle' => 'Jeton BookPosition v1',
			'core.eventLog' => 'Journal des événements',
			'core.positionToken' => 'Jeton de position',
			'core.waitingForEvents' => 'En attente d’événements…',
			'highlight.list' => 'Surlignages',
			'highlight.action' => 'Surligner',
			'highlight.openFailed' => ({required Object error}) => 'Impossible d’ouvrir le livre : ${error}',
			'highlight.selectFirst' => 'Sélectionnez d’abord du texte.',
			'highlight.saved' => ({required Object color}) => 'Surlignage enregistré (${color})',
			'highlight.deleted' => 'Surlignage supprimé',
			'highlight.noteSaved' => 'Note enregistrée',
			'highlight.hintSelected' => 'Appuyez sur « Surligner » pour colorer la sélection',
			'highlight.hintIdle' => 'Sélectionnez du texte pour afficher le bouton Surligner',
			'highlight.previousChapter' => 'Chapitre précédent',
			'highlight.nextChapter' => 'Chapitre suivant',
			'highlight.note' => 'Note',
			'highlight.noteHint' => 'Saisissez une note',
			'highlight.noteOptional' => 'Note (facultative)',
			'highlight.colorLabel' => ({required Object color}) => 'Couleur : ${color}',
			'highlight.count' => ({required Object count}) => 'Surlignages : ${count}',
			'highlight.empty' => 'Aucun surlignage pour l’instant.',
			'highlight.noteLine' => ({required Object note}) => 'Note : ${note}',
			'highlight.menu' => 'Menu du surlignage',
			'highlight.editNote' => 'Modifier la note',
			'highlight.delete' => 'Supprimer',
			'highlight.colors.yellow' => 'Jaune',
			'highlight.colors.green' => 'Vert',
			'highlight.colors.blue' => 'Bleu',
			'highlight.colors.pink' => 'Rose',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => 'page ${index}/${total}',
			'epubReader.fileTooLarge' => 'Ce fichier est trop volumineux pour être ouvert.',
			'epubReader.networkFailure' => 'Le livre n’a pas pu être récupéré à cause d’une erreur réseau.',
			'epubReader.corruptedFile' => 'Cet EPUB est endommagé ou non valide.',
			'epubReader.openFailed' => 'Une erreur s’est produite à l’ouverture du livre.',
			'epubReader.positionRestoreFailed' => 'Impossible de retrouver votre dernière position : le livre s’affiche depuis le début',
			'epubReader.emptyBook' => 'Ce livre n’a rien à afficher.',
			'epubReader.emptyPage' => 'Cette page n’a rien à afficher.',
			'epubReader.chapterLoadFailed' => 'Impossible de charger le texte.',
			'epubReader.pageLoadFailed' => 'Impossible de charger la page.',
			'epubReader.formula' => 'Formule',
			_ => null,
		};
	}
}
