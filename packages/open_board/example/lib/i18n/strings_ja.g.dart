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
	@override late final _Translations$tools$ja tools = _Translations$tools$ja._(_root);
	@override late final _Translations$link$ja link = _Translations$link$ja._(_root);
	@override late final _Translations$drawing$ja drawing = _Translations$drawing$ja._(_root);
	@override late final _Translations$split$ja split = _Translations$split$ja._(_root);
	@override late final _Translations$epub$ja epub = _Translations$epub$ja._(_root);
}

// Path: app
class _Translations$app$ja extends Translations$app$ko {
	_Translations$app$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Open Board デモ';
}

// Path: common
class _Translations$common$ja extends Translations$common$ko {
	_Translations$common$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get undo => '元に戻す';
	@override String get redo => 'やり直す';
	@override String get clear => 'すべて消去';
	@override String get previousPage => '前のページ';
	@override String get nextPage => '次のページ';
	@override String get loading => '読み込み中…';
}

// Path: home
class _Translations$home$ja extends Translations$home$ko {
	_Translations$home$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$ja board = _Translations$home$board$ja._(_root);
	@override late final _Translations$home$split$ja split = _Translations$home$split$ja._(_root);
	@override late final _Translations$home$epub$ja epub = _Translations$home$epub$ja._(_root);
}

// Path: tools
class _Translations$tools$ja extends Translations$tools$ko {
	_Translations$tools$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get pen => 'ペン';
	@override String get pencil => '鉛筆';
	@override String get marker => 'マーカー';
	@override String get highlighter => '蛍光ペン';
	@override String get fixedPen => '固定ペン';
	@override String get uniformPen => '均一ペン';
	@override String get eraser => '消しゴム';
	@override String get text => 'テキスト';
	@override String get shape => '図形';
	@override String get lasso => '投げ縄';
	@override String get image => '画像';
}

// Path: link
class _Translations$link$ja extends Translations$link$ko {
	_Translations$link$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get add => 'リンクを追加';
	@override String get edit => 'リンクを編集';
	@override String get remove => 'リンクを削除';
	@override String get done => '完了';
	@override String get dialogTitle => 'リンク';
	@override String get external => '外部 URL';
	@override String get internal => '内部ページ';
	@override String get pageNumber => 'ページ番号';
	@override String get url => 'URL';
	@override String get cancel => 'キャンセル';
	@override String get confirm => 'OK';
}

// Path: drawing
class _Translations$drawing$ja extends Translations$drawing$ko {
	_Translations$drawing$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get startRecording => '録画を開始';
	@override String get stopRecording => '録画を停止';
	@override String get replay => '再生';
	@override String get stopReplay => '再生を停止';
	@override String recording({required Object count}) => '録画中 · イベント：${count}';
	@override String replaying({required Object index, required Object total}) => '再生中 · ${index}/${total}';
	@override String ready({required Object count}) => '再生できます · イベント：${count}';
	@override String get noRecording => '録画なし';
	@override String page({required Object number}) => '${number} ページ';
	@override late final _Translations$drawing$features$ja features = _Translations$drawing$features$ja._(_root);
	@override late final _Translations$drawing$recordingGuide$ja recordingGuide = _Translations$drawing$recordingGuide$ja._(_root);
	@override late final _Translations$drawing$multiPage$ja multiPage = _Translations$drawing$multiPage$ja._(_root);
}

// Path: split
class _Translations$split$ja extends Translations$split$ko {
	_Translations$split$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '分割手書き — 1 つのフローティングツール';
}

// Path: epub
class _Translations$epub$ja extends Translations$epub$ko {
	_Translations$epub$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get readingMode => '閲覧モード';
	@override String get annotationMode => '手書きモード';
	@override String get info => '手書きはチャプター（spineHref）単位で保存されます — open_epub 1.0 の EpubReader と EpubViewController を連携。';
	@override String get webNote => 'Web では、手書きはこのセッションの間だけ保持されます。';
	@override String sample({required Object title}) => 'サンプル：${title}';
}

// Path: home.board
class _Translations$home$board$ja extends Translations$home$board$ko {
	_Translations$home$board$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ボードデモ';
	@override String get description => '8 種類の手書きツール、複数ページ、録画と再生';
}

// Path: home.split
class _Translations$home$split$ja extends Translations$home$split$ko {
	_Translations$home$split$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '分割手書きデモ';
	@override String get description => '左右 2 つの手書きエリアを 1 つのフローティングツールパネルで操作';
}

// Path: home.epub
class _Translations$home$epub$ja extends Translations$home$epub$ko {
	_Translations$home$epub$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'EPUB 注釈デモ';
	@override String get description => 'open_epub リーダー上でページに連動する手書き（閲覧／手書きモードを切り替え）';
}

// Path: drawing.features
class _Translations$drawing$features$ja extends Translations$drawing$features$ko {
	_Translations$drawing$features$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '機能';
	@override List<String> get items => [
		'ペン・鉛筆・マーカー・固定ペンの手書きツール',
		'6 色のプリセットカラー',
		'線の太さを調整（0.5–10.0）',
		'ストロークを消す消しゴム',
		'図形認識（円・四角形・直線）',
		'投げ縄でストロークを選んで移動',
		'テキストメモを追加するテキストツール',
		'元に戻す／やり直す',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$ja extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '録画と再生';
	@override List<String> get items => [
		'赤い録画ボタンを押すと録画が始まります',
		'描画・ページ移動・拡大縮小がすべて記録されます',
		'停止ボタンを押すと録画が終わります',
		'再生ボタンを押すとセッション全体を再生します',
		'ストローク・ページの切り替え・表示範囲の変化が記録されます',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$ja extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '複数ページ';
	@override List<String> get items => [
		'上のページバーでページを移動します',
		'ページごとにストロークと元に戻す履歴が独立しています',
		'ScribbleBookController がすべてのページを管理します',
		'ScribbleCacheManager がキャッシュと保存を担当します',
		'複数のページに描いて、行き来してみてください',
	];
	@override String get tip => 'ヒント：このページに描いたら別のページにも描き、また戻ってきてください。描いたストロークはそのまま残っています。';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Open Board デモ',
			'common.undo' => '元に戻す',
			'common.redo' => 'やり直す',
			'common.clear' => 'すべて消去',
			'common.previousPage' => '前のページ',
			'common.nextPage' => '次のページ',
			'common.loading' => '読み込み中…',
			'home.board.title' => 'ボードデモ',
			'home.board.description' => '8 種類の手書きツール、複数ページ、録画と再生',
			'home.split.title' => '分割手書きデモ',
			'home.split.description' => '左右 2 つの手書きエリアを 1 つのフローティングツールパネルで操作',
			'home.epub.title' => 'EPUB 注釈デモ',
			'home.epub.description' => 'open_epub リーダー上でページに連動する手書き（閲覧／手書きモードを切り替え）',
			'tools.pen' => 'ペン',
			'tools.pencil' => '鉛筆',
			'tools.marker' => 'マーカー',
			'tools.highlighter' => '蛍光ペン',
			'tools.fixedPen' => '固定ペン',
			'tools.uniformPen' => '均一ペン',
			'tools.eraser' => '消しゴム',
			'tools.text' => 'テキスト',
			'tools.shape' => '図形',
			'tools.lasso' => '投げ縄',
			'tools.image' => '画像',
			'link.add' => 'リンクを追加',
			'link.edit' => 'リンクを編集',
			'link.remove' => 'リンクを削除',
			'link.done' => '完了',
			'link.dialogTitle' => 'リンク',
			'link.external' => '外部 URL',
			'link.internal' => '内部ページ',
			'link.pageNumber' => 'ページ番号',
			'link.url' => 'URL',
			'link.cancel' => 'キャンセル',
			'link.confirm' => 'OK',
			'drawing.startRecording' => '録画を開始',
			'drawing.stopRecording' => '録画を停止',
			'drawing.replay' => '再生',
			'drawing.stopReplay' => '再生を停止',
			'drawing.recording' => ({required Object count}) => '録画中 · イベント：${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => '再生中 · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => '再生できます · イベント：${count}',
			'drawing.noRecording' => '録画なし',
			'drawing.page' => ({required Object number}) => '${number} ページ',
			'drawing.features.title' => '機能',
			'drawing.features.items.0' => 'ペン・鉛筆・マーカー・固定ペンの手書きツール',
			'drawing.features.items.1' => '6 色のプリセットカラー',
			'drawing.features.items.2' => '線の太さを調整（0.5–10.0）',
			'drawing.features.items.3' => 'ストロークを消す消しゴム',
			'drawing.features.items.4' => '図形認識（円・四角形・直線）',
			'drawing.features.items.5' => '投げ縄でストロークを選んで移動',
			'drawing.features.items.6' => 'テキストメモを追加するテキストツール',
			'drawing.features.items.7' => '元に戻す／やり直す',
			'drawing.recordingGuide.title' => '録画と再生',
			'drawing.recordingGuide.items.0' => '赤い録画ボタンを押すと録画が始まります',
			'drawing.recordingGuide.items.1' => '描画・ページ移動・拡大縮小がすべて記録されます',
			'drawing.recordingGuide.items.2' => '停止ボタンを押すと録画が終わります',
			'drawing.recordingGuide.items.3' => '再生ボタンを押すとセッション全体を再生します',
			'drawing.recordingGuide.items.4' => 'ストローク・ページの切り替え・表示範囲の変化が記録されます',
			'drawing.multiPage.title' => '複数ページ',
			'drawing.multiPage.items.0' => '上のページバーでページを移動します',
			'drawing.multiPage.items.1' => 'ページごとにストロークと元に戻す履歴が独立しています',
			'drawing.multiPage.items.2' => 'ScribbleBookController がすべてのページを管理します',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager がキャッシュと保存を担当します',
			'drawing.multiPage.items.4' => '複数のページに描いて、行き来してみてください',
			'drawing.multiPage.tip' => 'ヒント：このページに描いたら別のページにも描き、また戻ってきてください。描いたストロークはそのまま残っています。',
			'split.title' => '分割手書き — 1 つのフローティングツール',
			'epub.readingMode' => '閲覧モード',
			'epub.annotationMode' => '手書きモード',
			'epub.info' => '手書きはチャプター（spineHref）単位で保存されます — open_epub 1.0 の EpubReader と EpubViewController を連携。',
			'epub.webNote' => 'Web では、手書きはこのセッションの間だけ保持されます。',
			'epub.sample' => ({required Object title}) => 'サンプル：${title}',
			_ => null,
		};
	}
}
