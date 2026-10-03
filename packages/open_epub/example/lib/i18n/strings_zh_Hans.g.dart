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
	@override late final _Translations$samples$zh_Hans samples = _Translations$samples$zh_Hans._(_root);
	@override late final _Translations$reader$zh_Hans reader = _Translations$reader$zh_Hans._(_root);
	@override late final _Translations$core$zh_Hans core = _Translations$core$zh_Hans._(_root);
	@override late final _Translations$highlight$zh_Hans highlight = _Translations$highlight$zh_Hans._(_root);
	@override late final _Translations$fixedLayout$zh_Hans fixedLayout = _Translations$fixedLayout$zh_Hans._(_root);
	@override late final _Translations$epubReader$zh_Hans epubReader = _Translations$epubReader$zh_Hans._(_root);
}

// Path: app
class _Translations$app$zh_Hans extends Translations$app$ko {
	_Translations$app$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => 'open_epub 演示';
}

// Path: common
class _Translations$common$zh_Hans extends Translations$common$ko {
	_Translations$common$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get previousPage => '上一页';
	@override String get nextPage => '下一页';
	@override String get cancel => '取消';
	@override String get save => '保存';
	@override String get close => '关闭';
}

// Path: home
class _Translations$home$zh_Hans extends Translations$home$ko {
	_Translations$home$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$zh_Hans library = _Translations$home$library$zh_Hans._(_root);
	@override late final _Translations$home$core$zh_Hans core = _Translations$home$core$zh_Hans._(_root);
	@override late final _Translations$home$highlight$zh_Hans highlight = _Translations$home$highlight$zh_Hans._(_root);
	@override late final _Translations$home$fixedLayout$zh_Hans fixedLayout = _Translations$home$fixedLayout$zh_Hans._(_root);
}

// Path: samples
class _Translations$samples$zh_Hans extends Translations$samples$ko {
	_Translations$samples$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$zh_Hans nohoechan = _Translations$samples$nohoechan$zh_Hans._(_root);
	@override late final _Translations$samples$wasteland$zh_Hans wasteland = _Translations$samples$wasteland$zh_Hans._(_root);
	@override late final _Translations$samples$arabicRtl$zh_Hans arabicRtl = _Translations$samples$arabicRtl$zh_Hans._(_root);
	@override late final _Translations$samples$mathml$zh_Hans mathml = _Translations$samples$mathml$zh_Hans._(_root);
	@override late final _Translations$samples$vertical$zh_Hans vertical = _Translations$samples$vertical$zh_Hans._(_root);
	@override late final _Translations$samples$mediaOverlay$zh_Hans mediaOverlay = _Translations$samples$mediaOverlay$zh_Hans._(_root);
	@override late final _Translations$samples$accessible$zh_Hans accessible = _Translations$samples$accessible$zh_Hans._(_root);
	@override late final _Translations$samples$cfi$zh_Hans cfi = _Translations$samples$cfi$zh_Hans._(_root);
	@override late final _Translations$samples$fixedA4$zh_Hans fixedA4 = _Translations$samples$fixedA4$zh_Hans._(_root);
}

// Path: reader
class _Translations$reader$zh_Hans extends Translations$reader$ko {
	_Translations$reader$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => '这本书没有 Media Overlay';
	@override String get mediaOverlayLoadFailed => 'Media Overlay（SMIL）加载失败';
	@override String audioFailed({required Object error}) => '音频播放失败（可能是模拟器限制）：${error}';
	@override String localFixture({required Object asset}) => '此示例（${asset}）是未包含在仓库中的本地测试文件（因体积或许可原因被 gitignore 排除）。\n请在本地开发环境中把对应的 EPUB 文件放到 packages/open_epub/example/assets/，然后重新运行。';
	@override String get mode => '模式';
	@override String get swipe => '滑动';
	@override String get scroll => '滚动';
	@override String get vertical => '竖排';
	@override String get fontSmaller => '缩小字号';
	@override String get fontLarger => '放大字号';
	@override String get verticalScroll => '纵向滚动';
	@override String get rtlDirection => 'RTL 翻页方向';
	@override String get verticalWriting => '竖排';
	@override String get narration => '朗读（Media Overlay）';
}

// Path: core
class _Translations$core$zh_Hans extends Translations$core$ko {
	_Translations$core$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · 修正 ${count} 处';
	@override String get recordHighlight => 'recordHighlight() — toolUse 事件';
	@override String get recordBookmark => 'recordBookmark() — toolUse 事件';
	@override String assetLoadFailed({required Object error}) => '资源加载失败：${error}';
	@override String get positionTokenTitle => 'BookPosition v1 令牌';
	@override String get eventLog => '事件日志';
	@override String get positionToken => '位置令牌';
	@override String get waitingForEvents => '正在等待事件…';
}

// Path: highlight
class _Translations$highlight$zh_Hans extends Translations$highlight$ko {
	_Translations$highlight$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get list => '高亮列表';
	@override String get action => '高亮';
	@override String openFailed({required Object error}) => '无法打开这本书：${error}';
	@override String get selectFirst => '请先选择正文文本。';
	@override String saved({required Object color}) => '已保存高亮（${color}）';
	@override String get deleted => '已删除高亮';
	@override String get noteSaved => '已保存笔记';
	@override String get hintSelected => '点击“高亮”按钮为选中内容上色';
	@override String get hintIdle => '选择正文文本后会出现高亮按钮';
	@override String get previousChapter => '上一章';
	@override String get nextChapter => '下一章';
	@override String get note => '笔记';
	@override String get noteHint => '输入笔记';
	@override String get noteOptional => '笔记（可选）';
	@override String colorLabel({required Object color}) => '颜色：${color}';
	@override String count({required Object count}) => '高亮：${count}';
	@override String get empty => '还没有保存的高亮。';
	@override String noteLine({required Object note}) => '笔记：${note}';
	@override String get menu => '高亮菜单';
	@override String get editNote => '编辑笔记';
	@override String get delete => '删除';
	@override late final _Translations$highlight$colors$zh_Hans colors = _Translations$highlight$colors$zh_Hans._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$zh_Hans extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => '第 ${index}/${total} 页';
}

// Path: epubReader
class _Translations$epubReader$zh_Hans extends Translations$epubReader$ko {
	_Translations$epubReader$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => '文件太大，无法打开。';
	@override String get networkFailure => '网络错误，未能获取这本书。';
	@override String get corruptedFile => 'EPUB 已损坏或格式不正确。';
	@override String get openFailed => '打开这本书时出错。';
	@override String get positionRestoreFailed => '找不到上次的位置，将从头开始显示';
	@override String get emptyBook => '这本书没有可显示的内容。';
	@override String get emptyPage => '这一页没有可显示的内容。';
	@override String get chapterLoadFailed => '无法加载正文。';
	@override String get pageLoadFailed => '无法加载页面。';
	@override String get formula => '公式';
}

// Path: home.library
class _Translations$home$library$zh_Hans extends Translations$home$library$ko {
	_Translations$home$library$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => 'EPUB3 示例书库';
	@override String get description => '验证 RTL、MathML、竖排、Media Overlay、CFI 等功能';
}

// Path: home.core
class _Translations$home$core$zh_Hans extends Translations$home$core$ko {
	_Translations$home$core$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '1.0 核心演示';
}

// Path: home.highlight
class _Translations$home$highlight$zh_Hans extends Translations$home$highlight$ko {
	_Translations$home$highlight$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '高亮演示';
	@override String get description => '选择文本 → 选颜色 → 高亮 + 笔记';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$zh_Hans extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fixed Layout A4 演示';
	@override String get description => '将预分页（pre-paginated）正文按 A4（794×1123）尺寸渲染';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$zh_Hans extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '真实 EPUB2 流式排版 · 22MB 大文件';
	@override String get tag => 'EPUB2 · 大文件';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$zh_Hans extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · EPUB3 基础（nav、CSS）';
	@override String get tag => 'EPUB3 基础';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$zh_Hans extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '阿拉伯语 · page-progression-direction=rtl';
	@override String get tag => 'RTL 翻页 (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$zh_Hans extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '71 个 MathML 公式 · TeX 转换/回退';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$zh_Hans extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '日语竖排（vertical-rl）+ RTL';
	@override String get tag => '竖排 (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$zh_Hans extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'SMIL 朗读 + 音频同步高亮';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$zh_Hans extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · landmarks、多级目录';
	@override String get tag => '综合 EPUB3 (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$zh_Hans extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · page-list 7 项';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$zh_Hans extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '预分页固定版式 · A4（794×1123）共 3 页';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$zh_Hans extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get yellow => '黄色';
	@override String get green => '绿色';
	@override String get blue => '蓝色';
	@override String get pink => '粉色';
}

/// The flat map containing all translations for locale <zh-Hans>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhHans {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'open_epub 演示',
			'common.previousPage' => '上一页',
			'common.nextPage' => '下一页',
			'common.cancel' => '取消',
			'common.save' => '保存',
			'common.close' => '关闭',
			'home.library.title' => 'EPUB3 示例书库',
			'home.library.description' => '验证 RTL、MathML、竖排、Media Overlay、CFI 等功能',
			'home.core.title' => '1.0 核心演示',
			'home.highlight.title' => '高亮演示',
			'home.highlight.description' => '选择文本 → 选颜色 → 高亮 + 笔记',
			'home.fixedLayout.title' => 'Fixed Layout A4 演示',
			'home.fixedLayout.description' => '将预分页（pre-paginated）正文按 A4（794×1123）尺寸渲染',
			'samples.nohoechan.subtitle' => '真实 EPUB2 流式排版 · 22MB 大文件',
			'samples.nohoechan.tag' => 'EPUB2 · 大文件',
			'samples.wasteland.subtitle' => 'T.S. Eliot · EPUB3 基础（nav、CSS）',
			'samples.wasteland.tag' => 'EPUB3 基础',
			'samples.arabicRtl.subtitle' => '阿拉伯语 · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'RTL 翻页 (E14)',
			'samples.mathml.subtitle' => '71 个 MathML 公式 · TeX 转换/回退',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => '日语竖排（vertical-rl）+ RTL',
			'samples.vertical.tag' => '竖排 (E15)',
			'samples.mediaOverlay.subtitle' => 'SMIL 朗读 + 音频同步高亮',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · landmarks、多级目录',
			'samples.accessible.tag' => '综合 EPUB3 (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list 7 项',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => '预分页固定版式 · A4（794×1123）共 3 页',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => '这本书没有 Media Overlay',
			'reader.mediaOverlayLoadFailed' => 'Media Overlay（SMIL）加载失败',
			'reader.audioFailed' => ({required Object error}) => '音频播放失败（可能是模拟器限制）：${error}',
			'reader.localFixture' => ({required Object asset}) => '此示例（${asset}）是未包含在仓库中的本地测试文件（因体积或许可原因被 gitignore 排除）。\n请在本地开发环境中把对应的 EPUB 文件放到 packages/open_epub/example/assets/，然后重新运行。',
			'reader.mode' => '模式',
			'reader.swipe' => '滑动',
			'reader.scroll' => '滚动',
			'reader.vertical' => '竖排',
			'reader.fontSmaller' => '缩小字号',
			'reader.fontLarger' => '放大字号',
			'reader.verticalScroll' => '纵向滚动',
			'reader.rtlDirection' => 'RTL 翻页方向',
			'reader.verticalWriting' => '竖排',
			'reader.narration' => '朗读（Media Overlay）',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · 修正 ${count} 处',
			'core.recordHighlight' => 'recordHighlight() — toolUse 事件',
			'core.recordBookmark' => 'recordBookmark() — toolUse 事件',
			'core.assetLoadFailed' => ({required Object error}) => '资源加载失败：${error}',
			'core.positionTokenTitle' => 'BookPosition v1 令牌',
			'core.eventLog' => '事件日志',
			'core.positionToken' => '位置令牌',
			'core.waitingForEvents' => '正在等待事件…',
			'highlight.list' => '高亮列表',
			'highlight.action' => '高亮',
			'highlight.openFailed' => ({required Object error}) => '无法打开这本书：${error}',
			'highlight.selectFirst' => '请先选择正文文本。',
			'highlight.saved' => ({required Object color}) => '已保存高亮（${color}）',
			'highlight.deleted' => '已删除高亮',
			'highlight.noteSaved' => '已保存笔记',
			'highlight.hintSelected' => '点击“高亮”按钮为选中内容上色',
			'highlight.hintIdle' => '选择正文文本后会出现高亮按钮',
			'highlight.previousChapter' => '上一章',
			'highlight.nextChapter' => '下一章',
			'highlight.note' => '笔记',
			'highlight.noteHint' => '输入笔记',
			'highlight.noteOptional' => '笔记（可选）',
			'highlight.colorLabel' => ({required Object color}) => '颜色：${color}',
			'highlight.count' => ({required Object count}) => '高亮：${count}',
			'highlight.empty' => '还没有保存的高亮。',
			'highlight.noteLine' => ({required Object note}) => '笔记：${note}',
			'highlight.menu' => '高亮菜单',
			'highlight.editNote' => '编辑笔记',
			'highlight.delete' => '删除',
			'highlight.colors.yellow' => '黄色',
			'highlight.colors.green' => '绿色',
			'highlight.colors.blue' => '蓝色',
			'highlight.colors.pink' => '粉色',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => '第 ${index}/${total} 页',
			'epubReader.fileTooLarge' => '文件太大，无法打开。',
			'epubReader.networkFailure' => '网络错误，未能获取这本书。',
			'epubReader.corruptedFile' => 'EPUB 已损坏或格式不正确。',
			'epubReader.openFailed' => '打开这本书时出错。',
			'epubReader.positionRestoreFailed' => '找不到上次的位置，将从头开始显示',
			'epubReader.emptyBook' => '这本书没有可显示的内容。',
			'epubReader.emptyPage' => '这一页没有可显示的内容。',
			'epubReader.chapterLoadFailed' => '无法加载正文。',
			'epubReader.pageLoadFailed' => '无法加载页面。',
			'epubReader.formula' => '公式',
			_ => null,
		};
	}
}
