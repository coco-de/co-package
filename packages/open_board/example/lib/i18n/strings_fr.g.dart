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
	@override late final _Translations$tools$fr tools = _Translations$tools$fr._(_root);
	@override late final _Translations$link$fr link = _Translations$link$fr._(_root);
	@override late final _Translations$drawing$fr drawing = _Translations$drawing$fr._(_root);
	@override late final _Translations$split$fr split = _Translations$split$fr._(_root);
	@override late final _Translations$epub$fr epub = _Translations$epub$fr._(_root);
}

// Path: app
class _Translations$app$fr extends Translations$app$ko {
	_Translations$app$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Démo Open Board';
}

// Path: common
class _Translations$common$fr extends Translations$common$ko {
	_Translations$common$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get undo => 'Annuler';
	@override String get redo => 'Rétablir';
	@override String get clear => 'Tout effacer';
	@override String get previousPage => 'Page précédente';
	@override String get nextPage => 'Page suivante';
	@override String get loading => 'Chargement…';
}

// Path: home
class _Translations$home$fr extends Translations$home$ko {
	_Translations$home$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$fr board = _Translations$home$board$fr._(_root);
	@override late final _Translations$home$split$fr split = _Translations$home$split$fr._(_root);
	@override late final _Translations$home$epub$fr epub = _Translations$home$epub$fr._(_root);
}

// Path: tools
class _Translations$tools$fr extends Translations$tools$ko {
	_Translations$tools$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get pen => 'Stylo';
	@override String get pencil => 'Crayon';
	@override String get marker => 'Marqueur';
	@override String get highlighter => 'Surligneur';
	@override String get fixedPen => 'Stylo fixe';
	@override String get uniformPen => 'Stylo uniforme';
	@override String get eraser => 'Gomme';
	@override String get text => 'Texte';
	@override String get shape => 'Forme';
	@override String get lasso => 'Lasso';
	@override String get image => 'Image';
}

// Path: link
class _Translations$link$fr extends Translations$link$ko {
	_Translations$link$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get add => 'Ajouter un lien';
	@override String get edit => 'Modifier le lien';
	@override String get remove => 'Supprimer le lien';
	@override String get done => 'Terminé';
	@override String get dialogTitle => 'Lien';
	@override String get external => 'URL externe';
	@override String get internal => 'Page interne';
	@override String get pageNumber => 'Numéro de page';
	@override String get url => 'URL';
	@override String get cancel => 'Annuler';
	@override String get confirm => 'OK';
}

// Path: drawing
class _Translations$drawing$fr extends Translations$drawing$ko {
	_Translations$drawing$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get startRecording => 'Démarrer l’enregistrement';
	@override String get stopRecording => 'Arrêter l’enregistrement';
	@override String get replay => 'Relire';
	@override String get stopReplay => 'Arrêter la relecture';
	@override String recording({required Object count}) => 'Enregistrement · événements : ${count}';
	@override String replaying({required Object index, required Object total}) => 'Relecture · ${index}/${total}';
	@override String ready({required Object count}) => 'Prêt à relire · événements : ${count}';
	@override String get noRecording => 'Aucun enregistrement';
	@override String page({required Object number}) => 'Page ${number}';
	@override late final _Translations$drawing$features$fr features = _Translations$drawing$features$fr._(_root);
	@override late final _Translations$drawing$recordingGuide$fr recordingGuide = _Translations$drawing$recordingGuide$fr._(_root);
	@override late final _Translations$drawing$multiPage$fr multiPage = _Translations$drawing$multiPage$fr._(_root);
}

// Path: split
class _Translations$split$fr extends Translations$split$ko {
	_Translations$split$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Écran partagé — un seul panneau d’outils flottant';
}

// Path: epub
class _Translations$epub$fr extends Translations$epub$ko {
	_Translations$epub$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get readingMode => 'Mode lecture';
	@override String get annotationMode => 'Mode annotation';
	@override String get info => 'Les notes sont enregistrées par chapitre (spineHref) — open_epub 1.0 EpubReader avec EpubViewController.';
	@override String get webNote => 'Sur le web, les notes ne durent que le temps de cette session.';
	@override String sample({required Object title}) => 'Exemple : ${title}';
}

// Path: home.board
class _Translations$home$board$fr extends Translations$home$board$ko {
	_Translations$home$board$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Démo du tableau';
	@override String get description => 'Huit outils d’écriture, plusieurs pages, enregistrement et relecture';
}

// Path: home.split
class _Translations$home$split$fr extends Translations$home$split$ko {
	_Translations$home$split$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Démo écran partagé';
	@override String get description => 'Deux zones d’écriture côte à côte avec un seul panneau d’outils flottant';
}

// Path: home.epub
class _Translations$home$epub$fr extends Translations$home$epub$ko {
	_Translations$home$epub$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Démo d’annotation EPUB';
	@override String get description => 'Écriture manuscrite liée aux pages sur le lecteur open_epub (bascule lecture / écriture)';
}

// Path: drawing.features
class _Translations$drawing$features$fr extends Translations$drawing$features$ko {
	_Translations$drawing$features$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fonctionnalités';
	@override List<String> get items => [
		'Outils d’écriture : stylo, crayon, marqueur et stylo fixe',
		'Six couleurs prédéfinies',
		'Épaisseur du trait réglable (0,5–10,0)',
		'Gomme pour effacer les traits',
		'Reconnaissance de formes (cercle, rectangle, ligne)',
		'Sélection au lasso pour déplacer les traits',
		'Outil texte pour ajouter des notes',
		'Annuler et rétablir',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$fr extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Enregistrement et relecture';
	@override List<String> get items => [
		'Appuyez sur le bouton rouge pour démarrer l’enregistrement',
		'Écrivez, changez de page, zoomez : tout est enregistré',
		'Appuyez sur stop pour terminer l’enregistrement',
		'Appuyez sur lecture pour relire toute la session',
		'Les traits, les changements de page et de vue sont enregistrés',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$fr extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plusieurs pages';
	@override List<String> get items => [
		'Passez d’une page à l’autre avec la barre de pages ci-dessus',
		'Chaque page a ses propres traits et son propre historique d’annulation',
		'ScribbleBookController gère toutes les pages',
		'ScribbleCacheManager gère le cache et l’enregistrement',
		'Écrivez sur plusieurs pages et passez de l’une à l’autre',
	];
	@override String get tip => 'Astuce : écrivez sur cette page, puis sur une autre, et revenez. Vos traits sont toujours là.';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Démo Open Board',
			'common.undo' => 'Annuler',
			'common.redo' => 'Rétablir',
			'common.clear' => 'Tout effacer',
			'common.previousPage' => 'Page précédente',
			'common.nextPage' => 'Page suivante',
			'common.loading' => 'Chargement…',
			'home.board.title' => 'Démo du tableau',
			'home.board.description' => 'Huit outils d’écriture, plusieurs pages, enregistrement et relecture',
			'home.split.title' => 'Démo écran partagé',
			'home.split.description' => 'Deux zones d’écriture côte à côte avec un seul panneau d’outils flottant',
			'home.epub.title' => 'Démo d’annotation EPUB',
			'home.epub.description' => 'Écriture manuscrite liée aux pages sur le lecteur open_epub (bascule lecture / écriture)',
			'tools.pen' => 'Stylo',
			'tools.pencil' => 'Crayon',
			'tools.marker' => 'Marqueur',
			'tools.highlighter' => 'Surligneur',
			'tools.fixedPen' => 'Stylo fixe',
			'tools.uniformPen' => 'Stylo uniforme',
			'tools.eraser' => 'Gomme',
			'tools.text' => 'Texte',
			'tools.shape' => 'Forme',
			'tools.lasso' => 'Lasso',
			'tools.image' => 'Image',
			'link.add' => 'Ajouter un lien',
			'link.edit' => 'Modifier le lien',
			'link.remove' => 'Supprimer le lien',
			'link.done' => 'Terminé',
			'link.dialogTitle' => 'Lien',
			'link.external' => 'URL externe',
			'link.internal' => 'Page interne',
			'link.pageNumber' => 'Numéro de page',
			'link.url' => 'URL',
			'link.cancel' => 'Annuler',
			'link.confirm' => 'OK',
			'drawing.startRecording' => 'Démarrer l’enregistrement',
			'drawing.stopRecording' => 'Arrêter l’enregistrement',
			'drawing.replay' => 'Relire',
			'drawing.stopReplay' => 'Arrêter la relecture',
			'drawing.recording' => ({required Object count}) => 'Enregistrement · événements : ${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => 'Relecture · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => 'Prêt à relire · événements : ${count}',
			'drawing.noRecording' => 'Aucun enregistrement',
			'drawing.page' => ({required Object number}) => 'Page ${number}',
			'drawing.features.title' => 'Fonctionnalités',
			'drawing.features.items.0' => 'Outils d’écriture : stylo, crayon, marqueur et stylo fixe',
			'drawing.features.items.1' => 'Six couleurs prédéfinies',
			'drawing.features.items.2' => 'Épaisseur du trait réglable (0,5–10,0)',
			'drawing.features.items.3' => 'Gomme pour effacer les traits',
			'drawing.features.items.4' => 'Reconnaissance de formes (cercle, rectangle, ligne)',
			'drawing.features.items.5' => 'Sélection au lasso pour déplacer les traits',
			'drawing.features.items.6' => 'Outil texte pour ajouter des notes',
			'drawing.features.items.7' => 'Annuler et rétablir',
			'drawing.recordingGuide.title' => 'Enregistrement et relecture',
			'drawing.recordingGuide.items.0' => 'Appuyez sur le bouton rouge pour démarrer l’enregistrement',
			'drawing.recordingGuide.items.1' => 'Écrivez, changez de page, zoomez : tout est enregistré',
			'drawing.recordingGuide.items.2' => 'Appuyez sur stop pour terminer l’enregistrement',
			'drawing.recordingGuide.items.3' => 'Appuyez sur lecture pour relire toute la session',
			'drawing.recordingGuide.items.4' => 'Les traits, les changements de page et de vue sont enregistrés',
			'drawing.multiPage.title' => 'Plusieurs pages',
			'drawing.multiPage.items.0' => 'Passez d’une page à l’autre avec la barre de pages ci-dessus',
			'drawing.multiPage.items.1' => 'Chaque page a ses propres traits et son propre historique d’annulation',
			'drawing.multiPage.items.2' => 'ScribbleBookController gère toutes les pages',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager gère le cache et l’enregistrement',
			'drawing.multiPage.items.4' => 'Écrivez sur plusieurs pages et passez de l’une à l’autre',
			'drawing.multiPage.tip' => 'Astuce : écrivez sur cette page, puis sur une autre, et revenez. Vos traits sont toujours là.',
			'split.title' => 'Écran partagé — un seul panneau d’outils flottant',
			'epub.readingMode' => 'Mode lecture',
			'epub.annotationMode' => 'Mode annotation',
			'epub.info' => 'Les notes sont enregistrées par chapitre (spineHref) — open_epub 1.0 EpubReader avec EpubViewController.',
			'epub.webNote' => 'Sur le web, les notes ne durent que le temps de cette session.',
			'epub.sample' => ({required Object title}) => 'Exemple : ${title}',
			_ => null,
		};
	}
}
