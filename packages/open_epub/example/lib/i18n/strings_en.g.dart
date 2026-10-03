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
	@override late final _Translations$samples$en samples = _Translations$samples$en._(_root);
	@override late final _Translations$reader$en reader = _Translations$reader$en._(_root);
	@override late final _Translations$core$en core = _Translations$core$en._(_root);
	@override late final _Translations$highlight$en highlight = _Translations$highlight$en._(_root);
	@override late final _Translations$fixedLayout$en fixedLayout = _Translations$fixedLayout$en._(_root);
	@override late final _Translations$epubReader$en epubReader = _Translations$epubReader$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$ko {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'open_epub Demo';
}

// Path: common
class _Translations$common$en extends Translations$common$ko {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get previousPage => 'Previous page';
	@override String get nextPage => 'Next page';
	@override String get cancel => 'Cancel';
	@override String get save => 'Save';
	@override String get close => 'Close';
}

// Path: home
class _Translations$home$en extends Translations$home$ko {
	_Translations$home$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$en library = _Translations$home$library$en._(_root);
	@override late final _Translations$home$core$en core = _Translations$home$core$en._(_root);
	@override late final _Translations$home$highlight$en highlight = _Translations$home$highlight$en._(_root);
	@override late final _Translations$home$fixedLayout$en fixedLayout = _Translations$home$fixedLayout$en._(_root);
}

// Path: samples
class _Translations$samples$en extends Translations$samples$ko {
	_Translations$samples$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$en nohoechan = _Translations$samples$nohoechan$en._(_root);
	@override late final _Translations$samples$wasteland$en wasteland = _Translations$samples$wasteland$en._(_root);
	@override late final _Translations$samples$arabicRtl$en arabicRtl = _Translations$samples$arabicRtl$en._(_root);
	@override late final _Translations$samples$mathml$en mathml = _Translations$samples$mathml$en._(_root);
	@override late final _Translations$samples$vertical$en vertical = _Translations$samples$vertical$en._(_root);
	@override late final _Translations$samples$mediaOverlay$en mediaOverlay = _Translations$samples$mediaOverlay$en._(_root);
	@override late final _Translations$samples$accessible$en accessible = _Translations$samples$accessible$en._(_root);
	@override late final _Translations$samples$cfi$en cfi = _Translations$samples$cfi$en._(_root);
	@override late final _Translations$samples$fixedA4$en fixedA4 = _Translations$samples$fixedA4$en._(_root);
}

// Path: reader
class _Translations$reader$en extends Translations$reader$ko {
	_Translations$reader$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => 'This book has no Media Overlay';
	@override String get mediaOverlayLoadFailed => 'Could not load the Media Overlay (SMIL)';
	@override String audioFailed({required Object error}) => 'Audio playback failed (possibly a simulator limitation): ${error}';
	@override String localFixture({required Object asset}) => 'This sample (${asset}) is a local-only test fixture that is not in the repository (excluded by .gitignore for size or licensing reasons).\nTo open it, put the EPUB file in packages/open_epub/example/assets/ in your local checkout and run the app again.';
	@override String get mode => 'Mode';
	@override String get swipe => 'swipe';
	@override String get scroll => 'scroll';
	@override String get vertical => 'Vertical';
	@override String get fontSmaller => 'Smaller text';
	@override String get fontLarger => 'Larger text';
	@override String get verticalScroll => 'Vertical scrolling';
	@override String get rtlDirection => 'Right-to-left page turns';
	@override String get verticalWriting => 'Vertical writing';
	@override String get narration => 'Narration (Media Overlay)';
}

// Path: core
class _Translations$core$en extends Translations$core$ko {
	_Translations$core$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · fixes: ${count}';
	@override String get recordHighlight => 'recordHighlight() — toolUse event';
	@override String get recordBookmark => 'recordBookmark() — toolUse event';
	@override String assetLoadFailed({required Object error}) => 'Could not load the asset: ${error}';
	@override String get positionTokenTitle => 'BookPosition v1 token';
	@override String get eventLog => 'Event log';
	@override String get positionToken => 'Position token';
	@override String get waitingForEvents => 'Waiting for events…';
}

// Path: highlight
class _Translations$highlight$en extends Translations$highlight$ko {
	_Translations$highlight$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get list => 'Highlights';
	@override String get action => 'Highlight';
	@override String openFailed({required Object error}) => 'Could not open the book: ${error}';
	@override String get selectFirst => 'Select some text first.';
	@override String saved({required Object color}) => 'Highlight saved (${color})';
	@override String get deleted => 'Highlight deleted';
	@override String get noteSaved => 'Note saved';
	@override String get hintSelected => 'Press “Highlight” to color the selection';
	@override String get hintIdle => 'Select text to show the Highlight button';
	@override String get previousChapter => 'Previous chapter';
	@override String get nextChapter => 'Next chapter';
	@override String get note => 'Note';
	@override String get noteHint => 'Enter a note';
	@override String get noteOptional => 'Note (optional)';
	@override String colorLabel({required Object color}) => 'Color: ${color}';
	@override String count({required Object count}) => 'Highlights: ${count}';
	@override String get empty => 'No highlights yet.';
	@override String noteLine({required Object note}) => 'Note: ${note}';
	@override String get menu => 'Highlight menu';
	@override String get editNote => 'Edit note';
	@override String get delete => 'Delete';
	@override late final _Translations$highlight$colors$en colors = _Translations$highlight$colors$en._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$en extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => 'page ${index}/${total}';
}

// Path: epubReader
class _Translations$epubReader$en extends Translations$epubReader$ko {
	_Translations$epubReader$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => 'This file is too large to open.';
	@override String get networkFailure => 'The book could not be downloaded because of a network error.';
	@override String get corruptedFile => 'This EPUB is damaged or not valid.';
	@override String get openFailed => 'Something went wrong while opening the book.';
	@override String get positionRestoreFailed => 'Could not find your last position, so the book starts from the beginning';
	@override String get emptyBook => 'This book has nothing to show.';
	@override String get emptyPage => 'This page has nothing to show.';
	@override String get chapterLoadFailed => 'Could not load this chapter.';
	@override String get pageLoadFailed => 'Could not load this page.';
	@override String get formula => 'Formula';
}

// Path: home.library
class _Translations$home$library$en extends Translations$home$library$ko {
	_Translations$home$library$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'EPUB3 Sample Library';
	@override String get description => 'Checks for RTL, MathML, vertical writing, Media Overlay and CFI';
}

// Path: home.core
class _Translations$home$core$en extends Translations$home$core$ko {
	_Translations$home$core$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => '1.0 Core Demo';
}

// Path: home.highlight
class _Translations$home$highlight$en extends Translations$home$highlight$ko {
	_Translations$home$highlight$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Highlight Demo';
	@override String get description => 'Select text → color → highlight + note';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$en extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fixed Layout A4 Demo';
	@override String get description => 'Renders a pre-paginated book at A4 size (794×1123)';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$en extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Real-world EPUB2 reflowable · 22 MB';
	@override String get tag => 'EPUB2 · large file';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$en extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · EPUB3 basics (nav, CSS)';
	@override String get tag => 'EPUB3 basics';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$en extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Arabic · page-progression-direction=rtl';
	@override String get tag => 'RTL page turns (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$en extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '71 MathML formulas · TeX conversion and fallback';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$en extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Japanese vertical writing (vertical-rl) + RTL';
	@override String get tag => 'Vertical writing (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$en extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'SMIL narration with synchronized audio highlights';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$en extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · landmarks and a nested table of contents';
	@override String get tag => 'Comprehensive EPUB3 (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$en extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · page-list of 7';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$en extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Pre-paginated fixed layout · A4 (794×1123), 3 pages';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$en extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get yellow => 'Yellow';
	@override String get green => 'Green';
	@override String get blue => 'Blue';
	@override String get pink => 'Pink';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'open_epub Demo',
			'common.previousPage' => 'Previous page',
			'common.nextPage' => 'Next page',
			'common.cancel' => 'Cancel',
			'common.save' => 'Save',
			'common.close' => 'Close',
			'home.library.title' => 'EPUB3 Sample Library',
			'home.library.description' => 'Checks for RTL, MathML, vertical writing, Media Overlay and CFI',
			'home.core.title' => '1.0 Core Demo',
			'home.highlight.title' => 'Highlight Demo',
			'home.highlight.description' => 'Select text → color → highlight + note',
			'home.fixedLayout.title' => 'Fixed Layout A4 Demo',
			'home.fixedLayout.description' => 'Renders a pre-paginated book at A4 size (794×1123)',
			'samples.nohoechan.subtitle' => 'Real-world EPUB2 reflowable · 22 MB',
			'samples.nohoechan.tag' => 'EPUB2 · large file',
			'samples.wasteland.subtitle' => 'T.S. Eliot · EPUB3 basics (nav, CSS)',
			'samples.wasteland.tag' => 'EPUB3 basics',
			'samples.arabicRtl.subtitle' => 'Arabic · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'RTL page turns (E14)',
			'samples.mathml.subtitle' => '71 MathML formulas · TeX conversion and fallback',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => 'Japanese vertical writing (vertical-rl) + RTL',
			'samples.vertical.tag' => 'Vertical writing (E15)',
			'samples.mediaOverlay.subtitle' => 'SMIL narration with synchronized audio highlights',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · landmarks and a nested table of contents',
			'samples.accessible.tag' => 'Comprehensive EPUB3 (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list of 7',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'Pre-paginated fixed layout · A4 (794×1123), 3 pages',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => 'This book has no Media Overlay',
			'reader.mediaOverlayLoadFailed' => 'Could not load the Media Overlay (SMIL)',
			'reader.audioFailed' => ({required Object error}) => 'Audio playback failed (possibly a simulator limitation): ${error}',
			'reader.localFixture' => ({required Object asset}) => 'This sample (${asset}) is a local-only test fixture that is not in the repository (excluded by .gitignore for size or licensing reasons).\nTo open it, put the EPUB file in packages/open_epub/example/assets/ in your local checkout and run the app again.',
			'reader.mode' => 'Mode',
			'reader.swipe' => 'swipe',
			'reader.scroll' => 'scroll',
			'reader.vertical' => 'Vertical',
			'reader.fontSmaller' => 'Smaller text',
			'reader.fontLarger' => 'Larger text',
			'reader.verticalScroll' => 'Vertical scrolling',
			'reader.rtlDirection' => 'Right-to-left page turns',
			'reader.verticalWriting' => 'Vertical writing',
			'reader.narration' => 'Narration (Media Overlay)',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · fixes: ${count}',
			'core.recordHighlight' => 'recordHighlight() — toolUse event',
			'core.recordBookmark' => 'recordBookmark() — toolUse event',
			'core.assetLoadFailed' => ({required Object error}) => 'Could not load the asset: ${error}',
			'core.positionTokenTitle' => 'BookPosition v1 token',
			'core.eventLog' => 'Event log',
			'core.positionToken' => 'Position token',
			'core.waitingForEvents' => 'Waiting for events…',
			'highlight.list' => 'Highlights',
			'highlight.action' => 'Highlight',
			'highlight.openFailed' => ({required Object error}) => 'Could not open the book: ${error}',
			'highlight.selectFirst' => 'Select some text first.',
			'highlight.saved' => ({required Object color}) => 'Highlight saved (${color})',
			'highlight.deleted' => 'Highlight deleted',
			'highlight.noteSaved' => 'Note saved',
			'highlight.hintSelected' => 'Press “Highlight” to color the selection',
			'highlight.hintIdle' => 'Select text to show the Highlight button',
			'highlight.previousChapter' => 'Previous chapter',
			'highlight.nextChapter' => 'Next chapter',
			'highlight.note' => 'Note',
			'highlight.noteHint' => 'Enter a note',
			'highlight.noteOptional' => 'Note (optional)',
			'highlight.colorLabel' => ({required Object color}) => 'Color: ${color}',
			'highlight.count' => ({required Object count}) => 'Highlights: ${count}',
			'highlight.empty' => 'No highlights yet.',
			'highlight.noteLine' => ({required Object note}) => 'Note: ${note}',
			'highlight.menu' => 'Highlight menu',
			'highlight.editNote' => 'Edit note',
			'highlight.delete' => 'Delete',
			'highlight.colors.yellow' => 'Yellow',
			'highlight.colors.green' => 'Green',
			'highlight.colors.blue' => 'Blue',
			'highlight.colors.pink' => 'Pink',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => 'page ${index}/${total}',
			'epubReader.fileTooLarge' => 'This file is too large to open.',
			'epubReader.networkFailure' => 'The book could not be downloaded because of a network error.',
			'epubReader.corruptedFile' => 'This EPUB is damaged or not valid.',
			'epubReader.openFailed' => 'Something went wrong while opening the book.',
			'epubReader.positionRestoreFailed' => 'Could not find your last position, so the book starts from the beginning',
			'epubReader.emptyBook' => 'This book has nothing to show.',
			'epubReader.emptyPage' => 'This page has nothing to show.',
			'epubReader.chapterLoadFailed' => 'Could not load this chapter.',
			'epubReader.pageLoadFailed' => 'Could not load this page.',
			'epubReader.formula' => 'Formula',
			_ => null,
		};
	}
}
