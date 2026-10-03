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
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$en app = _Translations$app$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$home$en home = _Translations$home$en._(_root);
	@override late final _Translations$tools$en tools = _Translations$tools$en._(_root);
	@override late final _Translations$link$en link = _Translations$link$en._(_root);
	@override late final _Translations$drawing$en drawing = _Translations$drawing$en._(_root);
	@override late final _Translations$split$en split = _Translations$split$en._(_root);
	@override late final _Translations$epub$en epub = _Translations$epub$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$ko {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Open Board Demo';
}

// Path: common
class _Translations$common$en extends Translations$common$ko {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get undo => 'Undo';
	@override String get redo => 'Redo';
	@override String get clear => 'Clear';
	@override String get previousPage => 'Previous page';
	@override String get nextPage => 'Next page';
	@override String get loading => 'Loading…';
}

// Path: home
class _Translations$home$en extends Translations$home$ko {
	_Translations$home$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$en board = _Translations$home$board$en._(_root);
	@override late final _Translations$home$split$en split = _Translations$home$split$en._(_root);
	@override late final _Translations$home$epub$en epub = _Translations$home$epub$en._(_root);
}

// Path: tools
class _Translations$tools$en extends Translations$tools$ko {
	_Translations$tools$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pen => 'Pen';
	@override String get pencil => 'Pencil';
	@override String get marker => 'Marker';
	@override String get highlighter => 'Highlighter';
	@override String get fixedPen => 'Fixed';
	@override String get uniformPen => 'Uniform';
	@override String get eraser => 'Eraser';
	@override String get text => 'Text';
	@override String get shape => 'Shape';
	@override String get lasso => 'Lasso';
	@override String get image => 'Image';
}

// Path: link
class _Translations$link$en extends Translations$link$ko {
	_Translations$link$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get add => 'Add link';
	@override String get edit => 'Edit link';
	@override String get remove => 'Remove link';
	@override String get done => 'Done';
	@override String get dialogTitle => 'Link';
	@override String get external => 'External URL';
	@override String get internal => 'Internal page';
	@override String get pageNumber => 'Page number';
	@override String get url => 'URL';
	@override String get cancel => 'Cancel';
	@override String get confirm => 'OK';
}

// Path: drawing
class _Translations$drawing$en extends Translations$drawing$ko {
	_Translations$drawing$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get startRecording => 'Start recording';
	@override String get stopRecording => 'Stop recording';
	@override String get replay => 'Replay';
	@override String get stopReplay => 'Stop replay';
	@override String recording({required Object count}) => 'Recording · events: ${count}';
	@override String replaying({required Object index, required Object total}) => 'Replaying · ${index}/${total}';
	@override String ready({required Object count}) => 'Ready to replay · events: ${count}';
	@override String get noRecording => 'No recording';
	@override String page({required Object number}) => 'Page ${number}';
	@override late final _Translations$drawing$features$en features = _Translations$drawing$features$en._(_root);
	@override late final _Translations$drawing$recordingGuide$en recordingGuide = _Translations$drawing$recordingGuide$en._(_root);
	@override late final _Translations$drawing$multiPage$en multiPage = _Translations$drawing$multiPage$en._(_root);
}

// Path: split
class _Translations$split$en extends Translations$split$ko {
	_Translations$split$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Split drawing — one floating tool panel';
}

// Path: epub
class _Translations$epub$en extends Translations$epub$ko {
	_Translations$epub$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get readingMode => 'Reading mode';
	@override String get annotationMode => 'Annotation mode';
	@override String get info => 'Notes are saved per chapter (spineHref) — open_epub 1.0 EpubReader with EpubViewController.';
	@override String get webNote => 'On the web, notes last only for this session.';
	@override String sample({required Object title}) => 'Sample: ${title}';
}

// Path: home.board
class _Translations$home$board$en extends Translations$home$board$ko {
	_Translations$home$board$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Board Demo';
	@override String get description => 'Eight drawing tools, multiple pages, recording and replay';
}

// Path: home.split
class _Translations$home$split$en extends Translations$home$split$ko {
	_Translations$home$split$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Split Drawing Demo';
	@override String get description => 'Two side-by-side drawing areas with one floating tool panel';
}

// Path: home.epub
class _Translations$home$epub$en extends Translations$home$epub$ko {
	_Translations$home$epub$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'EPUB Annotation Demo';
	@override String get description => 'Page-linked handwriting on top of the open_epub reader (switch between reading and writing)';
}

// Path: drawing.features
class _Translations$drawing$features$en extends Translations$drawing$features$ko {
	_Translations$drawing$features$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Features';
	@override List<String> get items => [
		'Pen, pencil, marker and fixed pen drawing tools',
		'Six preset colors',
		'Adjustable stroke width (0.5–10.0)',
		'Eraser for removing strokes',
		'Shape recognition (circle, rectangle, line)',
		'Lasso selection for moving strokes',
		'Text tool for adding text notes',
		'Undo and redo',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$en extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Recording & Replay';
	@override List<String> get items => [
		'Press the red record button to start recording',
		'Draw, switch pages, zoom in and out — every event is captured',
		'Press stop to end recording',
		'Press play to replay the whole session',
		'Strokes, page changes and viewport changes are recorded',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$en extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Multi-Page Support';
	@override List<String> get items => [
		'Move between pages with the page bar above',
		'Each page has its own strokes and undo history',
		'ScribbleBookController manages all pages',
		'ScribbleCacheManager handles caching and persistence',
		'Try drawing on different pages and switching between them',
	];
	@override String get tip => 'Tip: draw on this page, then draw on another page and come back. Your strokes are still here.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Open Board Demo',
			'common.undo' => 'Undo',
			'common.redo' => 'Redo',
			'common.clear' => 'Clear',
			'common.previousPage' => 'Previous page',
			'common.nextPage' => 'Next page',
			'common.loading' => 'Loading…',
			'home.board.title' => 'Board Demo',
			'home.board.description' => 'Eight drawing tools, multiple pages, recording and replay',
			'home.split.title' => 'Split Drawing Demo',
			'home.split.description' => 'Two side-by-side drawing areas with one floating tool panel',
			'home.epub.title' => 'EPUB Annotation Demo',
			'home.epub.description' => 'Page-linked handwriting on top of the open_epub reader (switch between reading and writing)',
			'tools.pen' => 'Pen',
			'tools.pencil' => 'Pencil',
			'tools.marker' => 'Marker',
			'tools.highlighter' => 'Highlighter',
			'tools.fixedPen' => 'Fixed',
			'tools.uniformPen' => 'Uniform',
			'tools.eraser' => 'Eraser',
			'tools.text' => 'Text',
			'tools.shape' => 'Shape',
			'tools.lasso' => 'Lasso',
			'tools.image' => 'Image',
			'link.add' => 'Add link',
			'link.edit' => 'Edit link',
			'link.remove' => 'Remove link',
			'link.done' => 'Done',
			'link.dialogTitle' => 'Link',
			'link.external' => 'External URL',
			'link.internal' => 'Internal page',
			'link.pageNumber' => 'Page number',
			'link.url' => 'URL',
			'link.cancel' => 'Cancel',
			'link.confirm' => 'OK',
			'drawing.startRecording' => 'Start recording',
			'drawing.stopRecording' => 'Stop recording',
			'drawing.replay' => 'Replay',
			'drawing.stopReplay' => 'Stop replay',
			'drawing.recording' => ({required Object count}) => 'Recording · events: ${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => 'Replaying · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => 'Ready to replay · events: ${count}',
			'drawing.noRecording' => 'No recording',
			'drawing.page' => ({required Object number}) => 'Page ${number}',
			'drawing.features.title' => 'Features',
			'drawing.features.items.0' => 'Pen, pencil, marker and fixed pen drawing tools',
			'drawing.features.items.1' => 'Six preset colors',
			'drawing.features.items.2' => 'Adjustable stroke width (0.5–10.0)',
			'drawing.features.items.3' => 'Eraser for removing strokes',
			'drawing.features.items.4' => 'Shape recognition (circle, rectangle, line)',
			'drawing.features.items.5' => 'Lasso selection for moving strokes',
			'drawing.features.items.6' => 'Text tool for adding text notes',
			'drawing.features.items.7' => 'Undo and redo',
			'drawing.recordingGuide.title' => 'Recording & Replay',
			'drawing.recordingGuide.items.0' => 'Press the red record button to start recording',
			'drawing.recordingGuide.items.1' => 'Draw, switch pages, zoom in and out — every event is captured',
			'drawing.recordingGuide.items.2' => 'Press stop to end recording',
			'drawing.recordingGuide.items.3' => 'Press play to replay the whole session',
			'drawing.recordingGuide.items.4' => 'Strokes, page changes and viewport changes are recorded',
			'drawing.multiPage.title' => 'Multi-Page Support',
			'drawing.multiPage.items.0' => 'Move between pages with the page bar above',
			'drawing.multiPage.items.1' => 'Each page has its own strokes and undo history',
			'drawing.multiPage.items.2' => 'ScribbleBookController manages all pages',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager handles caching and persistence',
			'drawing.multiPage.items.4' => 'Try drawing on different pages and switching between them',
			'drawing.multiPage.tip' => 'Tip: draw on this page, then draw on another page and come back. Your strokes are still here.',
			'split.title' => 'Split drawing — one floating tool panel',
			'epub.readingMode' => 'Reading mode',
			'epub.annotationMode' => 'Annotation mode',
			'epub.info' => 'Notes are saved per chapter (spineHref) — open_epub 1.0 EpubReader with EpubViewController.',
			'epub.webNote' => 'On the web, notes last only for this session.',
			'epub.sample' => ({required Object title}) => 'Sample: ${title}',
			_ => null,
		};
	}
}
