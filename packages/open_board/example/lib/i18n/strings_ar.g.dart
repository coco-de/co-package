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
	@override late final _Translations$tools$ar tools = _Translations$tools$ar._(_root);
	@override late final _Translations$link$ar link = _Translations$link$ar._(_root);
	@override late final _Translations$drawing$ar drawing = _Translations$drawing$ar._(_root);
	@override late final _Translations$split$ar split = _Translations$split$ar._(_root);
	@override late final _Translations$epub$ar epub = _Translations$epub$ar._(_root);
}

// Path: app
class _Translations$app$ar extends Translations$app$ko {
	_Translations$app$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عرض Open Board التوضيحي';
}

// Path: common
class _Translations$common$ar extends Translations$common$ko {
	_Translations$common$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get undo => 'تراجع';
	@override String get redo => 'إعادة';
	@override String get clear => 'مسح الكل';
	@override String get previousPage => 'الصفحة السابقة';
	@override String get nextPage => 'الصفحة التالية';
	@override String get loading => 'جارٍ التحميل…';
}

// Path: home
class _Translations$home$ar extends Translations$home$ko {
	_Translations$home$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$ar board = _Translations$home$board$ar._(_root);
	@override late final _Translations$home$split$ar split = _Translations$home$split$ar._(_root);
	@override late final _Translations$home$epub$ar epub = _Translations$home$epub$ar._(_root);
}

// Path: tools
class _Translations$tools$ar extends Translations$tools$ko {
	_Translations$tools$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get pen => 'قلم';
	@override String get pencil => 'قلم رصاص';
	@override String get marker => 'ماركر';
	@override String get highlighter => 'قلم تمييز';
	@override String get fixedPen => 'قلم ثابت';
	@override String get uniformPen => 'قلم موحّد';
	@override String get eraser => 'ممحاة';
	@override String get text => 'نص';
	@override String get shape => 'شكل';
	@override String get lasso => 'تحديد حر';
	@override String get image => 'صورة';
}

// Path: link
class _Translations$link$ar extends Translations$link$ko {
	_Translations$link$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get add => 'إضافة رابط';
	@override String get edit => 'تعديل الرابط';
	@override String get remove => 'إزالة الرابط';
	@override String get done => 'تم';
	@override String get dialogTitle => 'رابط';
	@override String get external => 'عنوان URL خارجي';
	@override String get internal => 'صفحة داخلية';
	@override String get pageNumber => 'رقم الصفحة';
	@override String get url => 'URL';
	@override String get cancel => 'إلغاء';
	@override String get confirm => 'موافق';
}

// Path: drawing
class _Translations$drawing$ar extends Translations$drawing$ko {
	_Translations$drawing$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get startRecording => 'بدء التسجيل';
	@override String get stopRecording => 'إيقاف التسجيل';
	@override String get replay => 'إعادة التشغيل';
	@override String get stopReplay => 'إيقاف إعادة التشغيل';
	@override String recording({required Object count}) => 'جارٍ التسجيل · الأحداث: ${count}';
	@override String replaying({required Object index, required Object total}) => 'جارٍ إعادة التشغيل · ${index}/${total}';
	@override String ready({required Object count}) => 'جاهز لإعادة التشغيل · الأحداث: ${count}';
	@override String get noRecording => 'لا يوجد تسجيل';
	@override String page({required Object number}) => 'الصفحة ${number}';
	@override late final _Translations$drawing$features$ar features = _Translations$drawing$features$ar._(_root);
	@override late final _Translations$drawing$recordingGuide$ar recordingGuide = _Translations$drawing$recordingGuide$ar._(_root);
	@override late final _Translations$drawing$multiPage$ar multiPage = _Translations$drawing$multiPage$ar._(_root);
}

// Path: split
class _Translations$split$ar extends Translations$split$ko {
	_Translations$split$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'شاشة مقسومة — لوحة أدوات عائمة واحدة';
}

// Path: epub
class _Translations$epub$ar extends Translations$epub$ko {
	_Translations$epub$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get readingMode => 'وضع القراءة';
	@override String get annotationMode => 'وضع التعليق';
	@override String get info => 'تُحفظ الملاحظات لكل فصل (spineHref) — EpubReader من open_epub 1.0 مع EpubViewController.';
	@override String get webNote => 'على الويب، تبقى الملاحظات خلال هذه الجلسة فقط.';
	@override String sample({required Object title}) => 'نموذج: ${title}';
}

// Path: home.board
class _Translations$home$board$ar extends Translations$home$board$ko {
	_Translations$home$board$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عرض اللوحة';
	@override String get description => 'ثماني أدوات كتابة، وصفحات متعددة، وتسجيل وإعادة تشغيل';
}

// Path: home.split
class _Translations$home$split$ar extends Translations$home$split$ko {
	_Translations$home$split$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عرض الشاشة المقسومة';
	@override String get description => 'منطقتا كتابة متجاورتان مع لوحة أدوات عائمة واحدة';
}

// Path: home.epub
class _Translations$home$epub$ar extends Translations$home$epub$ko {
	_Translations$home$epub$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عرض التعليقات على EPUB';
	@override String get description => 'كتابة يدوية مرتبطة بالصفحات فوق قارئ open_epub (التبديل بين القراءة والكتابة)';
}

// Path: drawing.features
class _Translations$drawing$features$ar extends Translations$drawing$features$ko {
	_Translations$drawing$features$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الميزات';
	@override List<String> get items => [
		'أدوات الكتابة: القلم وقلم الرصاص والماركر والقلم الثابت',
		'ستة ألوان جاهزة',
		'سُمك خط قابل للتعديل (0.5–10.0)',
		'ممحاة لإزالة الخطوط',
		'التعرّف على الأشكال (دائرة، مستطيل، خط)',
		'التحديد الحر لنقل الخطوط',
		'أداة النص لإضافة ملاحظات نصية',
		'التراجع والإعادة',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$ar extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'التسجيل وإعادة التشغيل';
	@override List<String> get items => [
		'اضغط زر التسجيل الأحمر لبدء التسجيل',
		'اكتب، وانتقل بين الصفحات، وكبّر وصغّر — يُسجَّل كل شيء',
		'اضغط زر الإيقاف لإنهاء التسجيل',
		'اضغط زر التشغيل لإعادة تشغيل الجلسة كاملة',
		'تُسجَّل الخطوط وتغييرات الصفحات وتغييرات العرض',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$ar extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'صفحات متعددة';
	@override List<String> get items => [
		'انتقل بين الصفحات باستخدام شريط الصفحات في الأعلى',
		'لكل صفحة خطوطها وسجل تراجع خاص بها',
		'يدير ScribbleBookController جميع الصفحات',
		'يتولى ScribbleCacheManager التخزين المؤقت والحفظ',
		'جرّب الكتابة على صفحات مختلفة والتنقل بينها',
	];
	@override String get tip => 'نصيحة: اكتب على هذه الصفحة، ثم على صفحة أخرى، وعُد إليها. ستجد خطوطك كما هي.';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'عرض Open Board التوضيحي',
			'common.undo' => 'تراجع',
			'common.redo' => 'إعادة',
			'common.clear' => 'مسح الكل',
			'common.previousPage' => 'الصفحة السابقة',
			'common.nextPage' => 'الصفحة التالية',
			'common.loading' => 'جارٍ التحميل…',
			'home.board.title' => 'عرض اللوحة',
			'home.board.description' => 'ثماني أدوات كتابة، وصفحات متعددة، وتسجيل وإعادة تشغيل',
			'home.split.title' => 'عرض الشاشة المقسومة',
			'home.split.description' => 'منطقتا كتابة متجاورتان مع لوحة أدوات عائمة واحدة',
			'home.epub.title' => 'عرض التعليقات على EPUB',
			'home.epub.description' => 'كتابة يدوية مرتبطة بالصفحات فوق قارئ open_epub (التبديل بين القراءة والكتابة)',
			'tools.pen' => 'قلم',
			'tools.pencil' => 'قلم رصاص',
			'tools.marker' => 'ماركر',
			'tools.highlighter' => 'قلم تمييز',
			'tools.fixedPen' => 'قلم ثابت',
			'tools.uniformPen' => 'قلم موحّد',
			'tools.eraser' => 'ممحاة',
			'tools.text' => 'نص',
			'tools.shape' => 'شكل',
			'tools.lasso' => 'تحديد حر',
			'tools.image' => 'صورة',
			'link.add' => 'إضافة رابط',
			'link.edit' => 'تعديل الرابط',
			'link.remove' => 'إزالة الرابط',
			'link.done' => 'تم',
			'link.dialogTitle' => 'رابط',
			'link.external' => 'عنوان URL خارجي',
			'link.internal' => 'صفحة داخلية',
			'link.pageNumber' => 'رقم الصفحة',
			'link.url' => 'URL',
			'link.cancel' => 'إلغاء',
			'link.confirm' => 'موافق',
			'drawing.startRecording' => 'بدء التسجيل',
			'drawing.stopRecording' => 'إيقاف التسجيل',
			'drawing.replay' => 'إعادة التشغيل',
			'drawing.stopReplay' => 'إيقاف إعادة التشغيل',
			'drawing.recording' => ({required Object count}) => 'جارٍ التسجيل · الأحداث: ${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => 'جارٍ إعادة التشغيل · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => 'جاهز لإعادة التشغيل · الأحداث: ${count}',
			'drawing.noRecording' => 'لا يوجد تسجيل',
			'drawing.page' => ({required Object number}) => 'الصفحة ${number}',
			'drawing.features.title' => 'الميزات',
			'drawing.features.items.0' => 'أدوات الكتابة: القلم وقلم الرصاص والماركر والقلم الثابت',
			'drawing.features.items.1' => 'ستة ألوان جاهزة',
			'drawing.features.items.2' => 'سُمك خط قابل للتعديل (0.5–10.0)',
			'drawing.features.items.3' => 'ممحاة لإزالة الخطوط',
			'drawing.features.items.4' => 'التعرّف على الأشكال (دائرة، مستطيل، خط)',
			'drawing.features.items.5' => 'التحديد الحر لنقل الخطوط',
			'drawing.features.items.6' => 'أداة النص لإضافة ملاحظات نصية',
			'drawing.features.items.7' => 'التراجع والإعادة',
			'drawing.recordingGuide.title' => 'التسجيل وإعادة التشغيل',
			'drawing.recordingGuide.items.0' => 'اضغط زر التسجيل الأحمر لبدء التسجيل',
			'drawing.recordingGuide.items.1' => 'اكتب، وانتقل بين الصفحات، وكبّر وصغّر — يُسجَّل كل شيء',
			'drawing.recordingGuide.items.2' => 'اضغط زر الإيقاف لإنهاء التسجيل',
			'drawing.recordingGuide.items.3' => 'اضغط زر التشغيل لإعادة تشغيل الجلسة كاملة',
			'drawing.recordingGuide.items.4' => 'تُسجَّل الخطوط وتغييرات الصفحات وتغييرات العرض',
			'drawing.multiPage.title' => 'صفحات متعددة',
			'drawing.multiPage.items.0' => 'انتقل بين الصفحات باستخدام شريط الصفحات في الأعلى',
			'drawing.multiPage.items.1' => 'لكل صفحة خطوطها وسجل تراجع خاص بها',
			'drawing.multiPage.items.2' => 'يدير ScribbleBookController جميع الصفحات',
			'drawing.multiPage.items.3' => 'يتولى ScribbleCacheManager التخزين المؤقت والحفظ',
			'drawing.multiPage.items.4' => 'جرّب الكتابة على صفحات مختلفة والتنقل بينها',
			'drawing.multiPage.tip' => 'نصيحة: اكتب على هذه الصفحة، ثم على صفحة أخرى، وعُد إليها. ستجد خطوطك كما هي.',
			'split.title' => 'شاشة مقسومة — لوحة أدوات عائمة واحدة',
			'epub.readingMode' => 'وضع القراءة',
			'epub.annotationMode' => 'وضع التعليق',
			'epub.info' => 'تُحفظ الملاحظات لكل فصل (spineHref) — EpubReader من open_epub 1.0 مع EpubViewController.',
			'epub.webNote' => 'على الويب، تبقى الملاحظات خلال هذه الجلسة فقط.',
			'epub.sample' => ({required Object title}) => 'نموذج: ${title}',
			_ => null,
		};
	}
}
