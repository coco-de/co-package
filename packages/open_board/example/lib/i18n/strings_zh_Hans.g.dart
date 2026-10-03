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
class TranslationsZhHans extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhHans({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhHans,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-Hans>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsZhHans _root = this; // ignore: unused_field

	@override 
	TranslationsZhHans $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhHans(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$zh_Hans app = _Translations$app$zh_Hans._(_root);
	@override late final _Translations$common$zh_Hans common = _Translations$common$zh_Hans._(_root);
	@override late final _Translations$home$zh_Hans home = _Translations$home$zh_Hans._(_root);
	@override late final _Translations$tools$zh_Hans tools = _Translations$tools$zh_Hans._(_root);
	@override late final _Translations$link$zh_Hans link = _Translations$link$zh_Hans._(_root);
	@override late final _Translations$drawing$zh_Hans drawing = _Translations$drawing$zh_Hans._(_root);
	@override late final _Translations$split$zh_Hans split = _Translations$split$zh_Hans._(_root);
	@override late final _Translations$epub$zh_Hans epub = _Translations$epub$zh_Hans._(_root);
}

// Path: app
class _Translations$app$zh_Hans extends Translations$app$ko {
	_Translations$app$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => 'Open Board 演示';
}

// Path: common
class _Translations$common$zh_Hans extends Translations$common$ko {
	_Translations$common$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get undo => '撤销';
	@override String get redo => '重做';
	@override String get clear => '全部清除';
	@override String get previousPage => '上一页';
	@override String get nextPage => '下一页';
	@override String get loading => '正在加载…';
}

// Path: home
class _Translations$home$zh_Hans extends Translations$home$ko {
	_Translations$home$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$zh_Hans board = _Translations$home$board$zh_Hans._(_root);
	@override late final _Translations$home$split$zh_Hans split = _Translations$home$split$zh_Hans._(_root);
	@override late final _Translations$home$epub$zh_Hans epub = _Translations$home$epub$zh_Hans._(_root);
}

// Path: tools
class _Translations$tools$zh_Hans extends Translations$tools$ko {
	_Translations$tools$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get pen => '钢笔';
	@override String get pencil => '铅笔';
	@override String get marker => '马克笔';
	@override String get highlighter => '荧光笔';
	@override String get fixedPen => '固定笔';
	@override String get uniformPen => '匀宽笔';
	@override String get eraser => '橡皮擦';
	@override String get text => '文本';
	@override String get shape => '形状';
	@override String get lasso => '套索';
	@override String get image => '图片';
}

// Path: link
class _Translations$link$zh_Hans extends Translations$link$ko {
	_Translations$link$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get add => '添加链接';
	@override String get edit => '编辑链接';
	@override String get remove => '删除链接';
	@override String get done => '完成';
	@override String get dialogTitle => '链接';
	@override String get external => '外部 URL';
	@override String get internal => '内部页面';
	@override String get pageNumber => '页码';
	@override String get url => 'URL';
	@override String get cancel => '取消';
	@override String get confirm => '确定';
}

// Path: drawing
class _Translations$drawing$zh_Hans extends Translations$drawing$ko {
	_Translations$drawing$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get startRecording => '开始录制';
	@override String get stopRecording => '停止录制';
	@override String get replay => '回放';
	@override String get stopReplay => '停止回放';
	@override String recording({required Object count}) => '录制中 · 事件：${count}';
	@override String replaying({required Object index, required Object total}) => '回放中 · ${index}/${total}';
	@override String ready({required Object count}) => '可以回放 · 事件：${count}';
	@override String get noRecording => '暂无录制';
	@override String page({required Object number}) => '第 ${number} 页';
	@override late final _Translations$drawing$features$zh_Hans features = _Translations$drawing$features$zh_Hans._(_root);
	@override late final _Translations$drawing$recordingGuide$zh_Hans recordingGuide = _Translations$drawing$recordingGuide$zh_Hans._(_root);
	@override late final _Translations$drawing$multiPage$zh_Hans multiPage = _Translations$drawing$multiPage$zh_Hans._(_root);
}

// Path: split
class _Translations$split$zh_Hans extends Translations$split$ko {
	_Translations$split$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '分屏书写 — 一个浮动工具面板';
}

// Path: epub
class _Translations$epub$zh_Hans extends Translations$epub$ko {
	_Translations$epub$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get readingMode => '阅读模式';
	@override String get annotationMode => '批注模式';
	@override String get info => '批注按章节（spineHref）保存 — open_epub 1.0 EpubReader 配合 EpubViewController。';
	@override String get webNote => '在网页中，批注只在本次会话内保留。';
	@override String sample({required Object title}) => '示例：${title}';
}

// Path: home.board
class _Translations$home$board$zh_Hans extends Translations$home$board$ko {
	_Translations$home$board$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '画板演示';
	@override String get description => '8 种书写工具、多页面、录制与回放';
}

// Path: home.split
class _Translations$home$split$zh_Hans extends Translations$home$split$ko {
	_Translations$home$split$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '分屏书写演示';
	@override String get description => '左右两块书写区域，共用一个浮动工具面板';
}

// Path: home.epub
class _Translations$home$epub$zh_Hans extends Translations$home$epub$ko {
	_Translations$home$epub$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => 'EPUB 批注演示';
	@override String get description => '在 open_epub 阅读器上进行与页面关联的手写批注（可切换阅读/书写模式）';
}

// Path: drawing.features
class _Translations$drawing$features$zh_Hans extends Translations$drawing$features$ko {
	_Translations$drawing$features$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '功能';
	@override List<String> get items => [
		'钢笔、铅笔、马克笔、固定笔等书写工具',
		'6 种预设颜色',
		'可调节笔画粗细（0.5–10.0）',
		'用橡皮擦删除笔画',
		'形状识别（圆形、矩形、直线）',
		'用套索选中并移动笔画',
		'用文本工具添加文字批注',
		'撤销与重做',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$zh_Hans extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '录制与回放';
	@override List<String> get items => [
		'按下红色录制按钮开始录制',
		'书写、翻页、放大缩小——所有操作都会被记录',
		'按下停止按钮结束录制',
		'按下播放按钮回放整个过程',
		'笔画、翻页和视图变化都会被记录',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$zh_Hans extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '多页面支持';
	@override List<String> get items => [
		'用上方的页面栏在各页之间切换',
		'每一页都有独立的笔画和撤销记录',
		'ScribbleBookController 管理所有页面',
		'ScribbleCacheManager 负责缓存与持久化',
		'试着在不同页面上书写并来回切换',
	];
	@override String get tip => '提示：在本页书写后，到另一页再写一些，然后回来看看——笔画依然保留。';
}

/// The flat map containing all translations for locale <zh-Hans>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhHans {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Open Board 演示',
			'common.undo' => '撤销',
			'common.redo' => '重做',
			'common.clear' => '全部清除',
			'common.previousPage' => '上一页',
			'common.nextPage' => '下一页',
			'common.loading' => '正在加载…',
			'home.board.title' => '画板演示',
			'home.board.description' => '8 种书写工具、多页面、录制与回放',
			'home.split.title' => '分屏书写演示',
			'home.split.description' => '左右两块书写区域，共用一个浮动工具面板',
			'home.epub.title' => 'EPUB 批注演示',
			'home.epub.description' => '在 open_epub 阅读器上进行与页面关联的手写批注（可切换阅读/书写模式）',
			'tools.pen' => '钢笔',
			'tools.pencil' => '铅笔',
			'tools.marker' => '马克笔',
			'tools.highlighter' => '荧光笔',
			'tools.fixedPen' => '固定笔',
			'tools.uniformPen' => '匀宽笔',
			'tools.eraser' => '橡皮擦',
			'tools.text' => '文本',
			'tools.shape' => '形状',
			'tools.lasso' => '套索',
			'tools.image' => '图片',
			'link.add' => '添加链接',
			'link.edit' => '编辑链接',
			'link.remove' => '删除链接',
			'link.done' => '完成',
			'link.dialogTitle' => '链接',
			'link.external' => '外部 URL',
			'link.internal' => '内部页面',
			'link.pageNumber' => '页码',
			'link.url' => 'URL',
			'link.cancel' => '取消',
			'link.confirm' => '确定',
			'drawing.startRecording' => '开始录制',
			'drawing.stopRecording' => '停止录制',
			'drawing.replay' => '回放',
			'drawing.stopReplay' => '停止回放',
			'drawing.recording' => ({required Object count}) => '录制中 · 事件：${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => '回放中 · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => '可以回放 · 事件：${count}',
			'drawing.noRecording' => '暂无录制',
			'drawing.page' => ({required Object number}) => '第 ${number} 页',
			'drawing.features.title' => '功能',
			'drawing.features.items.0' => '钢笔、铅笔、马克笔、固定笔等书写工具',
			'drawing.features.items.1' => '6 种预设颜色',
			'drawing.features.items.2' => '可调节笔画粗细（0.5–10.0）',
			'drawing.features.items.3' => '用橡皮擦删除笔画',
			'drawing.features.items.4' => '形状识别（圆形、矩形、直线）',
			'drawing.features.items.5' => '用套索选中并移动笔画',
			'drawing.features.items.6' => '用文本工具添加文字批注',
			'drawing.features.items.7' => '撤销与重做',
			'drawing.recordingGuide.title' => '录制与回放',
			'drawing.recordingGuide.items.0' => '按下红色录制按钮开始录制',
			'drawing.recordingGuide.items.1' => '书写、翻页、放大缩小——所有操作都会被记录',
			'drawing.recordingGuide.items.2' => '按下停止按钮结束录制',
			'drawing.recordingGuide.items.3' => '按下播放按钮回放整个过程',
			'drawing.recordingGuide.items.4' => '笔画、翻页和视图变化都会被记录',
			'drawing.multiPage.title' => '多页面支持',
			'drawing.multiPage.items.0' => '用上方的页面栏在各页之间切换',
			'drawing.multiPage.items.1' => '每一页都有独立的笔画和撤销记录',
			'drawing.multiPage.items.2' => 'ScribbleBookController 管理所有页面',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager 负责缓存与持久化',
			'drawing.multiPage.items.4' => '试着在不同页面上书写并来回切换',
			'drawing.multiPage.tip' => '提示：在本页书写后，到另一页再写一些，然后回来看看——笔画依然保留。',
			'split.title' => '分屏书写 — 一个浮动工具面板',
			'epub.readingMode' => '阅读模式',
			'epub.annotationMode' => '批注模式',
			'epub.info' => '批注按章节（spineHref）保存 — open_epub 1.0 EpubReader 配合 EpubViewController。',
			'epub.webNote' => '在网页中，批注只在本次会话内保留。',
			'epub.sample' => ({required Object title}) => '示例：${title}',
			_ => null,
		};
	}
}
