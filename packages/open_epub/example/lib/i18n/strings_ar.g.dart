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
class TranslationsAr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsAr _root = this; // ignore: unused_field

	@override 
	TranslationsAr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsAr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ar app = _Translations$app$ar._(_root);
	@override late final _Translations$common$ar common = _Translations$common$ar._(_root);
	@override late final _Translations$home$ar home = _Translations$home$ar._(_root);
	@override late final _Translations$samples$ar samples = _Translations$samples$ar._(_root);
	@override late final _Translations$reader$ar reader = _Translations$reader$ar._(_root);
	@override late final _Translations$core$ar core = _Translations$core$ar._(_root);
	@override late final _Translations$highlight$ar highlight = _Translations$highlight$ar._(_root);
	@override late final _Translations$fixedLayout$ar fixedLayout = _Translations$fixedLayout$ar._(_root);
	@override late final _Translations$epubReader$ar epubReader = _Translations$epubReader$ar._(_root);
}

// Path: app
class _Translations$app$ar extends Translations$app$ko {
	_Translations$app$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عرض open_epub التوضيحي';
}

// Path: common
class _Translations$common$ar extends Translations$common$ko {
	_Translations$common$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get previousPage => 'الصفحة السابقة';
	@override String get nextPage => 'الصفحة التالية';
	@override String get cancel => 'إلغاء';
	@override String get save => 'حفظ';
	@override String get close => 'إغلاق';
}

// Path: home
class _Translations$home$ar extends Translations$home$ko {
	_Translations$home$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$ar library = _Translations$home$library$ar._(_root);
	@override late final _Translations$home$core$ar core = _Translations$home$core$ar._(_root);
	@override late final _Translations$home$highlight$ar highlight = _Translations$home$highlight$ar._(_root);
	@override late final _Translations$home$fixedLayout$ar fixedLayout = _Translations$home$fixedLayout$ar._(_root);
}

// Path: samples
class _Translations$samples$ar extends Translations$samples$ko {
	_Translations$samples$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$ar nohoechan = _Translations$samples$nohoechan$ar._(_root);
	@override late final _Translations$samples$wasteland$ar wasteland = _Translations$samples$wasteland$ar._(_root);
	@override late final _Translations$samples$arabicRtl$ar arabicRtl = _Translations$samples$arabicRtl$ar._(_root);
	@override late final _Translations$samples$mathml$ar mathml = _Translations$samples$mathml$ar._(_root);
	@override late final _Translations$samples$vertical$ar vertical = _Translations$samples$vertical$ar._(_root);
	@override late final _Translations$samples$mediaOverlay$ar mediaOverlay = _Translations$samples$mediaOverlay$ar._(_root);
	@override late final _Translations$samples$accessible$ar accessible = _Translations$samples$accessible$ar._(_root);
	@override late final _Translations$samples$cfi$ar cfi = _Translations$samples$cfi$ar._(_root);
	@override late final _Translations$samples$fixedA4$ar fixedA4 = _Translations$samples$fixedA4$ar._(_root);
}

// Path: reader
class _Translations$reader$ar extends Translations$reader$ko {
	_Translations$reader$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => 'لا يحتوي هذا الكتاب على Media Overlay';
	@override String get mediaOverlayLoadFailed => 'تعذّر تحميل Media Overlay (SMIL)';
	@override String audioFailed({required Object error}) => 'تعذّر تشغيل الصوت (قد يكون ذلك قيدًا في المحاكي): ${error}';
	@override String localFixture({required Object asset}) => 'هذا النموذج (${asset}) ملف اختبار محلي غير موجود في المستودع (مستبعد عبر .gitignore بسبب الحجم أو الترخيص).\nلفتحه، ضع ملف EPUB في packages/open_epub/example/assets/ في نسختك المحلية ثم شغّل التطبيق من جديد.';
	@override String get mode => 'الوضع';
	@override String get swipe => 'سحب';
	@override String get scroll => 'تمرير';
	@override String get vertical => 'عمودي';
	@override String get fontSmaller => 'تصغير النص';
	@override String get fontLarger => 'تكبير النص';
	@override String get verticalScroll => 'تمرير عمودي';
	@override String get rtlDirection => 'تقليب من اليمين إلى اليسار';
	@override String get verticalWriting => 'كتابة عمودية';
	@override String get narration => 'القراءة الصوتية (Media Overlay)';
}

// Path: core
class _Translations$core$ar extends Translations$core$ko {
	_Translations$core$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · التصحيحات: ${count}';
	@override String get recordHighlight => 'recordHighlight() — حدث toolUse';
	@override String get recordBookmark => 'recordBookmark() — حدث toolUse';
	@override String assetLoadFailed({required Object error}) => 'تعذّر تحميل الأصل: ${error}';
	@override String get positionTokenTitle => 'رمز BookPosition v1';
	@override String get eventLog => 'سجل الأحداث';
	@override String get positionToken => 'رمز الموضع';
	@override String get waitingForEvents => 'في انتظار الأحداث…';
}

// Path: highlight
class _Translations$highlight$ar extends Translations$highlight$ko {
	_Translations$highlight$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get list => 'التظليلات';
	@override String get action => 'تظليل';
	@override String openFailed({required Object error}) => 'تعذّر فتح الكتاب: ${error}';
	@override String get selectFirst => 'حدّد نصًا أولًا.';
	@override String saved({required Object color}) => 'تم حفظ التظليل (${color})';
	@override String get deleted => 'تم حذف التظليل';
	@override String get noteSaved => 'تم حفظ الملاحظة';
	@override String get hintSelected => 'اضغط «تظليل» لتلوين التحديد';
	@override String get hintIdle => 'حدّد نصًا ليظهر زر التظليل';
	@override String get previousChapter => 'الفصل السابق';
	@override String get nextChapter => 'الفصل التالي';
	@override String get note => 'ملاحظة';
	@override String get noteHint => 'اكتب ملاحظة';
	@override String get noteOptional => 'ملاحظة (اختيارية)';
	@override String colorLabel({required Object color}) => 'اللون: ${color}';
	@override String count({required Object count}) => 'التظليلات: ${count}';
	@override String get empty => 'لا توجد تظليلات محفوظة بعد.';
	@override String noteLine({required Object note}) => 'ملاحظة: ${note}';
	@override String get menu => 'قائمة التظليل';
	@override String get editNote => 'تعديل الملاحظة';
	@override String get delete => 'حذف';
	@override late final _Translations$highlight$colors$ar colors = _Translations$highlight$colors$ar._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$ar extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => 'الصفحة ${index}/${total}';
}

// Path: epubReader
class _Translations$epubReader$ar extends Translations$epubReader$ko {
	_Translations$epubReader$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => 'الملف كبير جدًا ولا يمكن فتحه.';
	@override String get networkFailure => 'تعذّر جلب الكتاب بسبب خطأ في الشبكة.';
	@override String get corruptedFile => 'ملف EPUB هذا تالف أو غير صالح.';
	@override String get openFailed => 'حدث خطأ أثناء فتح الكتاب.';
	@override String get positionRestoreFailed => 'تعذّر العثور على آخر موضع، لذا يبدأ الكتاب من البداية';
	@override String get emptyBook => 'لا يحتوي هذا الكتاب على شيء لعرضه.';
	@override String get emptyPage => 'لا تحتوي هذه الصفحة على شيء لعرضه.';
	@override String get chapterLoadFailed => 'تعذّر تحميل النص.';
	@override String get pageLoadFailed => 'تعذّر تحميل الصفحة.';
	@override String get formula => 'معادلة';
}

// Path: home.library
class _Translations$home$library$ar extends Translations$home$library$ko {
	_Translations$home$library$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مكتبة نماذج EPUB3';
	@override String get description => 'التحقق من RTL وMathML والكتابة العمودية وMedia Overlay وCFI';
}

// Path: home.core
class _Translations$home$core$ar extends Translations$home$core$ko {
	_Translations$home$core$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عرض النواة 1.0';
}

// Path: home.highlight
class _Translations$home$highlight$ar extends Translations$home$highlight$ko {
	_Translations$home$highlight$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عرض التظليل';
	@override String get description => 'تحديد النص ← اللون ← التظليل + ملاحظة';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$ar extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عرض Fixed Layout بحجم A4';
	@override String get description => 'يعرض كتابًا مقسّمًا مسبقًا إلى صفحات بحجم A4 (794×1123)';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$ar extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'ملف EPUB2 حقيقي بنص متدفق · 22 ميغابايت';
	@override String get tag => 'EPUB2 · ملف كبير';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$ar extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · أساسيات EPUB3 (nav وCSS)';
	@override String get tag => 'أساسيات EPUB3';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$ar extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'العربية · page-progression-direction=rtl';
	@override String get tag => 'تقليب الصفحات من اليمين إلى اليسار (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$ar extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '71 معادلة MathML · التحويل إلى TeX والبديل';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$ar extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'الكتابة العمودية اليابانية (vertical-rl) + RTL';
	@override String get tag => 'الكتابة العمودية (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$ar extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'قراءة صوتية SMIL مع تظليل متزامن مع الصوت';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$ar extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · المعالم وفهرس متداخل';
	@override String get tag => 'EPUB3 شامل (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$ar extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · قائمة صفحات من 7 عناصر';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$ar extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'تخطيط ثابت مقسّم مسبقًا · A4 (794×1123)، 3 صفحات';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$ar extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get yellow => 'أصفر';
	@override String get green => 'أخضر';
	@override String get blue => 'أزرق';
	@override String get pink => 'وردي';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'عرض open_epub التوضيحي',
			'common.previousPage' => 'الصفحة السابقة',
			'common.nextPage' => 'الصفحة التالية',
			'common.cancel' => 'إلغاء',
			'common.save' => 'حفظ',
			'common.close' => 'إغلاق',
			'home.library.title' => 'مكتبة نماذج EPUB3',
			'home.library.description' => 'التحقق من RTL وMathML والكتابة العمودية وMedia Overlay وCFI',
			'home.core.title' => 'عرض النواة 1.0',
			'home.highlight.title' => 'عرض التظليل',
			'home.highlight.description' => 'تحديد النص ← اللون ← التظليل + ملاحظة',
			'home.fixedLayout.title' => 'عرض Fixed Layout بحجم A4',
			'home.fixedLayout.description' => 'يعرض كتابًا مقسّمًا مسبقًا إلى صفحات بحجم A4 (794×1123)',
			'samples.nohoechan.subtitle' => 'ملف EPUB2 حقيقي بنص متدفق · 22 ميغابايت',
			'samples.nohoechan.tag' => 'EPUB2 · ملف كبير',
			'samples.wasteland.subtitle' => 'T.S. Eliot · أساسيات EPUB3 (nav وCSS)',
			'samples.wasteland.tag' => 'أساسيات EPUB3',
			'samples.arabicRtl.subtitle' => 'العربية · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'تقليب الصفحات من اليمين إلى اليسار (E14)',
			'samples.mathml.subtitle' => '71 معادلة MathML · التحويل إلى TeX والبديل',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => 'الكتابة العمودية اليابانية (vertical-rl) + RTL',
			'samples.vertical.tag' => 'الكتابة العمودية (E15)',
			'samples.mediaOverlay.subtitle' => 'قراءة صوتية SMIL مع تظليل متزامن مع الصوت',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · المعالم وفهرس متداخل',
			'samples.accessible.tag' => 'EPUB3 شامل (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · قائمة صفحات من 7 عناصر',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'تخطيط ثابت مقسّم مسبقًا · A4 (794×1123)، 3 صفحات',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => 'لا يحتوي هذا الكتاب على Media Overlay',
			'reader.mediaOverlayLoadFailed' => 'تعذّر تحميل Media Overlay (SMIL)',
			'reader.audioFailed' => ({required Object error}) => 'تعذّر تشغيل الصوت (قد يكون ذلك قيدًا في المحاكي): ${error}',
			'reader.localFixture' => ({required Object asset}) => 'هذا النموذج (${asset}) ملف اختبار محلي غير موجود في المستودع (مستبعد عبر .gitignore بسبب الحجم أو الترخيص).\nلفتحه، ضع ملف EPUB في packages/open_epub/example/assets/ في نسختك المحلية ثم شغّل التطبيق من جديد.',
			'reader.mode' => 'الوضع',
			'reader.swipe' => 'سحب',
			'reader.scroll' => 'تمرير',
			'reader.vertical' => 'عمودي',
			'reader.fontSmaller' => 'تصغير النص',
			'reader.fontLarger' => 'تكبير النص',
			'reader.verticalScroll' => 'تمرير عمودي',
			'reader.rtlDirection' => 'تقليب من اليمين إلى اليسار',
			'reader.verticalWriting' => 'كتابة عمودية',
			'reader.narration' => 'القراءة الصوتية (Media Overlay)',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · التصحيحات: ${count}',
			'core.recordHighlight' => 'recordHighlight() — حدث toolUse',
			'core.recordBookmark' => 'recordBookmark() — حدث toolUse',
			'core.assetLoadFailed' => ({required Object error}) => 'تعذّر تحميل الأصل: ${error}',
			'core.positionTokenTitle' => 'رمز BookPosition v1',
			'core.eventLog' => 'سجل الأحداث',
			'core.positionToken' => 'رمز الموضع',
			'core.waitingForEvents' => 'في انتظار الأحداث…',
			'highlight.list' => 'التظليلات',
			'highlight.action' => 'تظليل',
			'highlight.openFailed' => ({required Object error}) => 'تعذّر فتح الكتاب: ${error}',
			'highlight.selectFirst' => 'حدّد نصًا أولًا.',
			'highlight.saved' => ({required Object color}) => 'تم حفظ التظليل (${color})',
			'highlight.deleted' => 'تم حذف التظليل',
			'highlight.noteSaved' => 'تم حفظ الملاحظة',
			'highlight.hintSelected' => 'اضغط «تظليل» لتلوين التحديد',
			'highlight.hintIdle' => 'حدّد نصًا ليظهر زر التظليل',
			'highlight.previousChapter' => 'الفصل السابق',
			'highlight.nextChapter' => 'الفصل التالي',
			'highlight.note' => 'ملاحظة',
			'highlight.noteHint' => 'اكتب ملاحظة',
			'highlight.noteOptional' => 'ملاحظة (اختيارية)',
			'highlight.colorLabel' => ({required Object color}) => 'اللون: ${color}',
			'highlight.count' => ({required Object count}) => 'التظليلات: ${count}',
			'highlight.empty' => 'لا توجد تظليلات محفوظة بعد.',
			'highlight.noteLine' => ({required Object note}) => 'ملاحظة: ${note}',
			'highlight.menu' => 'قائمة التظليل',
			'highlight.editNote' => 'تعديل الملاحظة',
			'highlight.delete' => 'حذف',
			'highlight.colors.yellow' => 'أصفر',
			'highlight.colors.green' => 'أخضر',
			'highlight.colors.blue' => 'أزرق',
			'highlight.colors.pink' => 'وردي',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => 'الصفحة ${index}/${total}',
			'epubReader.fileTooLarge' => 'الملف كبير جدًا ولا يمكن فتحه.',
			'epubReader.networkFailure' => 'تعذّر جلب الكتاب بسبب خطأ في الشبكة.',
			'epubReader.corruptedFile' => 'ملف EPUB هذا تالف أو غير صالح.',
			'epubReader.openFailed' => 'حدث خطأ أثناء فتح الكتاب.',
			'epubReader.positionRestoreFailed' => 'تعذّر العثور على آخر موضع، لذا يبدأ الكتاب من البداية',
			'epubReader.emptyBook' => 'لا يحتوي هذا الكتاب على شيء لعرضه.',
			'epubReader.emptyPage' => 'لا تحتوي هذه الصفحة على شيء لعرضه.',
			'epubReader.chapterLoadFailed' => 'تعذّر تحميل النص.',
			'epubReader.pageLoadFailed' => 'تعذّر تحميل الصفحة.',
			'epubReader.formula' => 'معادلة',
			_ => null,
		};
	}
}
