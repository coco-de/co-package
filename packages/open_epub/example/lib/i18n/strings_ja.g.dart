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
class TranslationsJa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsJa _root = this; // ignore: unused_field

	@override 
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ja app = _Translations$app$ja._(_root);
	@override late final _Translations$common$ja common = _Translations$common$ja._(_root);
	@override late final _Translations$home$ja home = _Translations$home$ja._(_root);
	@override late final _Translations$samples$ja samples = _Translations$samples$ja._(_root);
	@override late final _Translations$reader$ja reader = _Translations$reader$ja._(_root);
	@override late final _Translations$core$ja core = _Translations$core$ja._(_root);
	@override late final _Translations$highlight$ja highlight = _Translations$highlight$ja._(_root);
	@override late final _Translations$fixedLayout$ja fixedLayout = _Translations$fixedLayout$ja._(_root);
	@override late final _Translations$epubReader$ja epubReader = _Translations$epubReader$ja._(_root);
}

// Path: app
class _Translations$app$ja extends Translations$app$ko {
	_Translations$app$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'open_epub デモ';
}

// Path: common
class _Translations$common$ja extends Translations$common$ko {
	_Translations$common$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get previousPage => '前のページ';
	@override String get nextPage => '次のページ';
	@override String get cancel => 'キャンセル';
	@override String get save => '保存';
	@override String get close => '閉じる';
}

// Path: home
class _Translations$home$ja extends Translations$home$ko {
	_Translations$home$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$ja library = _Translations$home$library$ja._(_root);
	@override late final _Translations$home$core$ja core = _Translations$home$core$ja._(_root);
	@override late final _Translations$home$highlight$ja highlight = _Translations$home$highlight$ja._(_root);
	@override late final _Translations$home$fixedLayout$ja fixedLayout = _Translations$home$fixedLayout$ja._(_root);
}

// Path: samples
class _Translations$samples$ja extends Translations$samples$ko {
	_Translations$samples$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$ja nohoechan = _Translations$samples$nohoechan$ja._(_root);
	@override late final _Translations$samples$wasteland$ja wasteland = _Translations$samples$wasteland$ja._(_root);
	@override late final _Translations$samples$arabicRtl$ja arabicRtl = _Translations$samples$arabicRtl$ja._(_root);
	@override late final _Translations$samples$mathml$ja mathml = _Translations$samples$mathml$ja._(_root);
	@override late final _Translations$samples$vertical$ja vertical = _Translations$samples$vertical$ja._(_root);
	@override late final _Translations$samples$mediaOverlay$ja mediaOverlay = _Translations$samples$mediaOverlay$ja._(_root);
	@override late final _Translations$samples$accessible$ja accessible = _Translations$samples$accessible$ja._(_root);
	@override late final _Translations$samples$cfi$ja cfi = _Translations$samples$cfi$ja._(_root);
	@override late final _Translations$samples$fixedA4$ja fixedA4 = _Translations$samples$fixedA4$ja._(_root);
}

// Path: reader
class _Translations$reader$ja extends Translations$reader$ko {
	_Translations$reader$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => 'この本には Media Overlay がありません';
	@override String get mediaOverlayLoadFailed => 'Media Overlay（SMIL）の読み込みに失敗しました';
	@override String audioFailed({required Object error}) => '音声の再生に失敗しました（シミュレーターの制約の可能性があります）：${error}';
	@override String localFixture({required Object asset}) => 'このサンプル（${asset}）はリポジトリに含まれていないローカル専用のテスト用ファイルです（容量またはライセンスの理由で gitignore 対象）。\nローカルの開発環境で該当する EPUB ファイルを packages/open_epub/example/assets/ に置いてから、もう一度実行してください。';
	@override String get mode => 'モード';
	@override String get swipe => 'スワイプ';
	@override String get scroll => 'スクロール';
	@override String get vertical => '縦書き';
	@override String get fontSmaller => '文字を小さく';
	@override String get fontLarger => '文字を大きく';
	@override String get verticalScroll => '縦スクロール';
	@override String get rtlDirection => 'RTL ページ送り方向';
	@override String get verticalWriting => '縦書き';
	@override String get narration => '読み上げ（Media Overlay）';
}

// Path: core
class _Translations$core$ja extends Translations$core$ko {
	_Translations$core$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · 補正 ${count} 件';
	@override String get recordHighlight => 'recordHighlight() — toolUse イベント';
	@override String get recordBookmark => 'recordBookmark() — toolUse イベント';
	@override String assetLoadFailed({required Object error}) => 'アセットの読み込みに失敗しました：${error}';
	@override String get positionTokenTitle => 'BookPosition v1 トークン';
	@override String get eventLog => 'イベントログ';
	@override String get positionToken => '位置トークン';
	@override String get waitingForEvents => 'イベントを待っています…';
}

// Path: highlight
class _Translations$highlight$ja extends Translations$highlight$ko {
	_Translations$highlight$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get list => 'ハイライト一覧';
	@override String get action => 'ハイライト';
	@override String openFailed({required Object error}) => '本を開けません：${error}';
	@override String get selectFirst => '先に本文のテキストを選択してください。';
	@override String saved({required Object color}) => 'ハイライトを保存しました（${color}）';
	@override String get deleted => 'ハイライトを削除しました';
	@override String get noteSaved => 'メモを保存しました';
	@override String get hintSelected => '「ハイライト」ボタンを押して色を付けてください';
	@override String get hintIdle => '本文のテキストを選択するとハイライトボタンが表示されます';
	@override String get previousChapter => '前の章';
	@override String get nextChapter => '次の章';
	@override String get note => 'メモ';
	@override String get noteHint => 'メモを入力してください';
	@override String get noteOptional => 'メモ（任意）';
	@override String colorLabel({required Object color}) => '色：${color}';
	@override String count({required Object count}) => 'ハイライト：${count}';
	@override String get empty => '保存されたハイライトはありません。';
	@override String noteLine({required Object note}) => 'メモ：${note}';
	@override String get menu => 'ハイライトメニュー';
	@override String get editNote => 'メモを編集';
	@override String get delete => '削除';
	@override late final _Translations$highlight$colors$ja colors = _Translations$highlight$colors$ja._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$ja extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => '${index}/${total} ページ';
}

// Path: epubReader
class _Translations$epubReader$ja extends Translations$epubReader$ko {
	_Translations$epubReader$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => 'ファイルが大きすぎて開けません。';
	@override String get networkFailure => 'ネットワークエラーのため本を取得できませんでした。';
	@override String get corruptedFile => '破損しているか、正しくない EPUB です。';
	@override String get openFailed => '本を開くときにエラーが発生しました。';
	@override String get positionRestoreFailed => '前回の位置が見つからないため、最初から表示します';
	@override String get emptyBook => 'この本には表示できる内容がありません。';
	@override String get emptyPage => 'このページには表示できる内容がありません。';
	@override String get chapterLoadFailed => '本文を読み込めません。';
	@override String get pageLoadFailed => 'ページを読み込めません。';
	@override String get formula => '数式';
}

// Path: home.library
class _Translations$home$library$ja extends Translations$home$library$ko {
	_Translations$home$library$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'EPUB3 サンプルライブラリ';
	@override String get description => 'RTL・MathML・縦書き・Media Overlay・CFI の機能を検証';
}

// Path: home.core
class _Translations$home$core$ja extends Translations$home$core$ko {
	_Translations$home$core$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '1.0 コアデモ';
}

// Path: home.highlight
class _Translations$home$highlight$ja extends Translations$home$highlight$ko {
	_Translations$home$highlight$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ハイライトデモ';
	@override String get description => 'テキスト選択 → 色 → ハイライト + メモ';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$ja extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fixed Layout A4 デモ';
	@override String get description => 'pre-paginated の本文を A4（794×1123）サイズで描画';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$ja extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '実際の EPUB2 リフロー · 22MB の大容量';
	@override String get tag => 'EPUB2 · 大容量';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$ja extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · EPUB3 の基本（nav・CSS）';
	@override String get tag => 'EPUB3 の基本';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$ja extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'アラビア語 · page-progression-direction=rtl';
	@override String get tag => 'RTL ページ送り (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$ja extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'MathML 数式 71 個 · TeX 変換／フォールバック';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$ja extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '日本語の縦書き（vertical-rl）+ RTL';
	@override String get tag => '縦書き (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$ja extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'SMIL 読み上げ + 音声同期ハイライト';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$ja extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · landmarks・目次の階層';
	@override String get tag => '総合 EPUB3 (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$ja extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · page-list 7 件';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$ja extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'pre-paginated 固定レイアウト · A4（794×1123）3 ページ';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$ja extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get yellow => '黄';
	@override String get green => '緑';
	@override String get blue => '青';
	@override String get pink => 'ピンク';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'open_epub デモ',
			'common.previousPage' => '前のページ',
			'common.nextPage' => '次のページ',
			'common.cancel' => 'キャンセル',
			'common.save' => '保存',
			'common.close' => '閉じる',
			'home.library.title' => 'EPUB3 サンプルライブラリ',
			'home.library.description' => 'RTL・MathML・縦書き・Media Overlay・CFI の機能を検証',
			'home.core.title' => '1.0 コアデモ',
			'home.highlight.title' => 'ハイライトデモ',
			'home.highlight.description' => 'テキスト選択 → 色 → ハイライト + メモ',
			'home.fixedLayout.title' => 'Fixed Layout A4 デモ',
			'home.fixedLayout.description' => 'pre-paginated の本文を A4（794×1123）サイズで描画',
			'samples.nohoechan.subtitle' => '実際の EPUB2 リフロー · 22MB の大容量',
			'samples.nohoechan.tag' => 'EPUB2 · 大容量',
			'samples.wasteland.subtitle' => 'T.S. Eliot · EPUB3 の基本（nav・CSS）',
			'samples.wasteland.tag' => 'EPUB3 の基本',
			'samples.arabicRtl.subtitle' => 'アラビア語 · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'RTL ページ送り (E14)',
			'samples.mathml.subtitle' => 'MathML 数式 71 個 · TeX 変換／フォールバック',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => '日本語の縦書き（vertical-rl）+ RTL',
			'samples.vertical.tag' => '縦書き (E15)',
			'samples.mediaOverlay.subtitle' => 'SMIL 読み上げ + 音声同期ハイライト',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · landmarks・目次の階層',
			'samples.accessible.tag' => '総合 EPUB3 (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list 7 件',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'pre-paginated 固定レイアウト · A4（794×1123）3 ページ',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => 'この本には Media Overlay がありません',
			'reader.mediaOverlayLoadFailed' => 'Media Overlay（SMIL）の読み込みに失敗しました',
			'reader.audioFailed' => ({required Object error}) => '音声の再生に失敗しました（シミュレーターの制約の可能性があります）：${error}',
			'reader.localFixture' => ({required Object asset}) => 'このサンプル（${asset}）はリポジトリに含まれていないローカル専用のテスト用ファイルです（容量またはライセンスの理由で gitignore 対象）。\nローカルの開発環境で該当する EPUB ファイルを packages/open_epub/example/assets/ に置いてから、もう一度実行してください。',
			'reader.mode' => 'モード',
			'reader.swipe' => 'スワイプ',
			'reader.scroll' => 'スクロール',
			'reader.vertical' => '縦書き',
			'reader.fontSmaller' => '文字を小さく',
			'reader.fontLarger' => '文字を大きく',
			'reader.verticalScroll' => '縦スクロール',
			'reader.rtlDirection' => 'RTL ページ送り方向',
			'reader.verticalWriting' => '縦書き',
			'reader.narration' => '読み上げ（Media Overlay）',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · 補正 ${count} 件',
			'core.recordHighlight' => 'recordHighlight() — toolUse イベント',
			'core.recordBookmark' => 'recordBookmark() — toolUse イベント',
			'core.assetLoadFailed' => ({required Object error}) => 'アセットの読み込みに失敗しました：${error}',
			'core.positionTokenTitle' => 'BookPosition v1 トークン',
			'core.eventLog' => 'イベントログ',
			'core.positionToken' => '位置トークン',
			'core.waitingForEvents' => 'イベントを待っています…',
			'highlight.list' => 'ハイライト一覧',
			'highlight.action' => 'ハイライト',
			'highlight.openFailed' => ({required Object error}) => '本を開けません：${error}',
			'highlight.selectFirst' => '先に本文のテキストを選択してください。',
			'highlight.saved' => ({required Object color}) => 'ハイライトを保存しました（${color}）',
			'highlight.deleted' => 'ハイライトを削除しました',
			'highlight.noteSaved' => 'メモを保存しました',
			'highlight.hintSelected' => '「ハイライト」ボタンを押して色を付けてください',
			'highlight.hintIdle' => '本文のテキストを選択するとハイライトボタンが表示されます',
			'highlight.previousChapter' => '前の章',
			'highlight.nextChapter' => '次の章',
			'highlight.note' => 'メモ',
			'highlight.noteHint' => 'メモを入力してください',
			'highlight.noteOptional' => 'メモ（任意）',
			'highlight.colorLabel' => ({required Object color}) => '色：${color}',
			'highlight.count' => ({required Object count}) => 'ハイライト：${count}',
			'highlight.empty' => '保存されたハイライトはありません。',
			'highlight.noteLine' => ({required Object note}) => 'メモ：${note}',
			'highlight.menu' => 'ハイライトメニュー',
			'highlight.editNote' => 'メモを編集',
			'highlight.delete' => '削除',
			'highlight.colors.yellow' => '黄',
			'highlight.colors.green' => '緑',
			'highlight.colors.blue' => '青',
			'highlight.colors.pink' => 'ピンク',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => '${index}/${total} ページ',
			'epubReader.fileTooLarge' => 'ファイルが大きすぎて開けません。',
			'epubReader.networkFailure' => 'ネットワークエラーのため本を取得できませんでした。',
			'epubReader.corruptedFile' => '破損しているか、正しくない EPUB です。',
			'epubReader.openFailed' => '本を開くときにエラーが発生しました。',
			'epubReader.positionRestoreFailed' => '前回の位置が見つからないため、最初から表示します',
			'epubReader.emptyBook' => 'この本には表示できる内容がありません。',
			'epubReader.emptyPage' => 'このページには表示できる内容がありません。',
			'epubReader.chapterLoadFailed' => '本文を読み込めません。',
			'epubReader.pageLoadFailed' => 'ページを読み込めません。',
			'epubReader.formula' => '数式',
			_ => null,
		};
	}
}
