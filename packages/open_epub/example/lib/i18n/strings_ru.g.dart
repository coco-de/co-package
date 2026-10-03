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
class TranslationsRu extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ru>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsRu _root = this; // ignore: unused_field

	@override 
	TranslationsRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRu(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ru app = _Translations$app$ru._(_root);
	@override late final _Translations$common$ru common = _Translations$common$ru._(_root);
	@override late final _Translations$home$ru home = _Translations$home$ru._(_root);
	@override late final _Translations$samples$ru samples = _Translations$samples$ru._(_root);
	@override late final _Translations$reader$ru reader = _Translations$reader$ru._(_root);
	@override late final _Translations$core$ru core = _Translations$core$ru._(_root);
	@override late final _Translations$highlight$ru highlight = _Translations$highlight$ru._(_root);
	@override late final _Translations$fixedLayout$ru fixedLayout = _Translations$fixedLayout$ru._(_root);
	@override late final _Translations$epubReader$ru epubReader = _Translations$epubReader$ru._(_root);
}

// Path: app
class _Translations$app$ru extends Translations$app$ko {
	_Translations$app$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Демо open_epub';
}

// Path: common
class _Translations$common$ru extends Translations$common$ko {
	_Translations$common$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get previousPage => 'Предыдущая страница';
	@override String get nextPage => 'Следующая страница';
	@override String get cancel => 'Отмена';
	@override String get save => 'Сохранить';
	@override String get close => 'Закрыть';
}

// Path: home
class _Translations$home$ru extends Translations$home$ko {
	_Translations$home$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$ru library = _Translations$home$library$ru._(_root);
	@override late final _Translations$home$core$ru core = _Translations$home$core$ru._(_root);
	@override late final _Translations$home$highlight$ru highlight = _Translations$home$highlight$ru._(_root);
	@override late final _Translations$home$fixedLayout$ru fixedLayout = _Translations$home$fixedLayout$ru._(_root);
}

// Path: samples
class _Translations$samples$ru extends Translations$samples$ko {
	_Translations$samples$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$ru nohoechan = _Translations$samples$nohoechan$ru._(_root);
	@override late final _Translations$samples$wasteland$ru wasteland = _Translations$samples$wasteland$ru._(_root);
	@override late final _Translations$samples$arabicRtl$ru arabicRtl = _Translations$samples$arabicRtl$ru._(_root);
	@override late final _Translations$samples$mathml$ru mathml = _Translations$samples$mathml$ru._(_root);
	@override late final _Translations$samples$vertical$ru vertical = _Translations$samples$vertical$ru._(_root);
	@override late final _Translations$samples$mediaOverlay$ru mediaOverlay = _Translations$samples$mediaOverlay$ru._(_root);
	@override late final _Translations$samples$accessible$ru accessible = _Translations$samples$accessible$ru._(_root);
	@override late final _Translations$samples$cfi$ru cfi = _Translations$samples$cfi$ru._(_root);
	@override late final _Translations$samples$fixedA4$ru fixedA4 = _Translations$samples$fixedA4$ru._(_root);
}

// Path: reader
class _Translations$reader$ru extends Translations$reader$ko {
	_Translations$reader$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => 'В этой книге нет Media Overlay';
	@override String get mediaOverlayLoadFailed => 'Не удалось загрузить Media Overlay (SMIL)';
	@override String audioFailed({required Object error}) => 'Не удалось воспроизвести звук (возможно, ограничение симулятора): ${error}';
	@override String localFixture({required Object asset}) => 'Этот пример (${asset}) — локальный тестовый файл, которого нет в репозитории (исключён через .gitignore из-за размера или лицензии).\nЧтобы открыть его, положите EPUB-файл в packages/open_epub/example/assets/ в локальной копии и запустите приложение снова.';
	@override String get mode => 'Режим';
	@override String get swipe => 'листание';
	@override String get scroll => 'прокрутка';
	@override String get vertical => 'Вертикально';
	@override String get fontSmaller => 'Уменьшить текст';
	@override String get fontLarger => 'Увеличить текст';
	@override String get verticalScroll => 'Вертикальная прокрутка';
	@override String get rtlDirection => 'Листание справа налево';
	@override String get verticalWriting => 'Вертикальное письмо';
	@override String get narration => 'Озвучка (Media Overlay)';
}

// Path: core
class _Translations$core$ru extends Translations$core$ko {
	_Translations$core$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · исправлений: ${count}';
	@override String get recordHighlight => 'recordHighlight() — событие toolUse';
	@override String get recordBookmark => 'recordBookmark() — событие toolUse';
	@override String assetLoadFailed({required Object error}) => 'Не удалось загрузить ресурс: ${error}';
	@override String get positionTokenTitle => 'Токен BookPosition v1';
	@override String get eventLog => 'Журнал событий';
	@override String get positionToken => 'Токен позиции';
	@override String get waitingForEvents => 'Ожидание событий…';
}

// Path: highlight
class _Translations$highlight$ru extends Translations$highlight$ko {
	_Translations$highlight$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get list => 'Выделения';
	@override String get action => 'Выделить';
	@override String openFailed({required Object error}) => 'Не удаётся открыть книгу: ${error}';
	@override String get selectFirst => 'Сначала выделите текст.';
	@override String saved({required Object color}) => 'Выделение сохранено (${color})';
	@override String get deleted => 'Выделение удалено';
	@override String get noteSaved => 'Заметка сохранена';
	@override String get hintSelected => 'Нажмите «Выделить», чтобы окрасить фрагмент';
	@override String get hintIdle => 'Выделите текст, и появится кнопка «Выделить»';
	@override String get previousChapter => 'Предыдущая глава';
	@override String get nextChapter => 'Следующая глава';
	@override String get note => 'Заметка';
	@override String get noteHint => 'Введите заметку';
	@override String get noteOptional => 'Заметка (необязательно)';
	@override String colorLabel({required Object color}) => 'Цвет: ${color}';
	@override String count({required Object count}) => 'Выделений: ${count}';
	@override String get empty => 'Сохранённых выделений пока нет.';
	@override String noteLine({required Object note}) => 'Заметка: ${note}';
	@override String get menu => 'Меню выделения';
	@override String get editNote => 'Изменить заметку';
	@override String get delete => 'Удалить';
	@override late final _Translations$highlight$colors$ru colors = _Translations$highlight$colors$ru._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$ru extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => 'стр. ${index}/${total}';
}

// Path: epubReader
class _Translations$epubReader$ru extends Translations$epubReader$ko {
	_Translations$epubReader$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => 'Файл слишком большой, его нельзя открыть.';
	@override String get networkFailure => 'Не удалось получить книгу из-за ошибки сети.';
	@override String get corruptedFile => 'Этот EPUB повреждён или некорректен.';
	@override String get openFailed => 'При открытии книги произошла ошибка.';
	@override String get positionRestoreFailed => 'Не удалось найти последнюю позицию, книга открыта с начала';
	@override String get emptyBook => 'В этой книге нечего показать.';
	@override String get emptyPage => 'На этой странице нечего показать.';
	@override String get chapterLoadFailed => 'Не удалось загрузить текст.';
	@override String get pageLoadFailed => 'Не удалось загрузить страницу.';
	@override String get formula => 'Формула';
}

// Path: home.library
class _Translations$home$library$ru extends Translations$home$library$ko {
	_Translations$home$library$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Библиотека примеров EPUB3';
	@override String get description => 'Проверка RTL, MathML, вертикального письма, Media Overlay и CFI';
}

// Path: home.core
class _Translations$home$core$ru extends Translations$home$core$ko {
	_Translations$home$core$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Демо ядра 1.0';
}

// Path: home.highlight
class _Translations$home$highlight$ru extends Translations$home$highlight$ko {
	_Translations$home$highlight$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Демо выделений';
	@override String get description => 'Выбор текста → цвет → выделение + заметка';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$ru extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Демо Fixed Layout A4';
	@override String get description => 'Показывает книгу с готовой разбивкой на страницы в формате A4 (794×1123)';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$ru extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Настоящая EPUB2 с перетекающим текстом · 22 МБ';
	@override String get tag => 'EPUB2 · большой файл';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$ru extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · основы EPUB3 (nav, CSS)';
	@override String get tag => 'Основы EPUB3';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$ru extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Арабский · page-progression-direction=rtl';
	@override String get tag => 'Листание справа налево (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$ru extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '71 формула MathML · преобразование в TeX и запасной вариант';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$ru extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Японское вертикальное письмо (vertical-rl) + RTL';
	@override String get tag => 'Вертикальное письмо (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$ru extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Озвучка SMIL с синхронной подсветкой';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$ru extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · ориентиры (landmarks) и вложенное оглавление';
	@override String get tag => 'Полный EPUB3 (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$ru extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · page-list из 7 пунктов';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$ru extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Фиксированный макет с разбивкой · A4 (794×1123), 3 страницы';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$ru extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get yellow => 'Жёлтый';
	@override String get green => 'Зелёный';
	@override String get blue => 'Синий';
	@override String get pink => 'Розовый';
}

/// The flat map containing all translations for locale <ru>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Демо open_epub',
			'common.previousPage' => 'Предыдущая страница',
			'common.nextPage' => 'Следующая страница',
			'common.cancel' => 'Отмена',
			'common.save' => 'Сохранить',
			'common.close' => 'Закрыть',
			'home.library.title' => 'Библиотека примеров EPUB3',
			'home.library.description' => 'Проверка RTL, MathML, вертикального письма, Media Overlay и CFI',
			'home.core.title' => 'Демо ядра 1.0',
			'home.highlight.title' => 'Демо выделений',
			'home.highlight.description' => 'Выбор текста → цвет → выделение + заметка',
			'home.fixedLayout.title' => 'Демо Fixed Layout A4',
			'home.fixedLayout.description' => 'Показывает книгу с готовой разбивкой на страницы в формате A4 (794×1123)',
			'samples.nohoechan.subtitle' => 'Настоящая EPUB2 с перетекающим текстом · 22 МБ',
			'samples.nohoechan.tag' => 'EPUB2 · большой файл',
			'samples.wasteland.subtitle' => 'T.S. Eliot · основы EPUB3 (nav, CSS)',
			'samples.wasteland.tag' => 'Основы EPUB3',
			'samples.arabicRtl.subtitle' => 'Арабский · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'Листание справа налево (E14)',
			'samples.mathml.subtitle' => '71 формула MathML · преобразование в TeX и запасной вариант',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => 'Японское вертикальное письмо (vertical-rl) + RTL',
			'samples.vertical.tag' => 'Вертикальное письмо (E15)',
			'samples.mediaOverlay.subtitle' => 'Озвучка SMIL с синхронной подсветкой',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · ориентиры (landmarks) и вложенное оглавление',
			'samples.accessible.tag' => 'Полный EPUB3 (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list из 7 пунктов',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'Фиксированный макет с разбивкой · A4 (794×1123), 3 страницы',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => 'В этой книге нет Media Overlay',
			'reader.mediaOverlayLoadFailed' => 'Не удалось загрузить Media Overlay (SMIL)',
			'reader.audioFailed' => ({required Object error}) => 'Не удалось воспроизвести звук (возможно, ограничение симулятора): ${error}',
			'reader.localFixture' => ({required Object asset}) => 'Этот пример (${asset}) — локальный тестовый файл, которого нет в репозитории (исключён через .gitignore из-за размера или лицензии).\nЧтобы открыть его, положите EPUB-файл в packages/open_epub/example/assets/ в локальной копии и запустите приложение снова.',
			'reader.mode' => 'Режим',
			'reader.swipe' => 'листание',
			'reader.scroll' => 'прокрутка',
			'reader.vertical' => 'Вертикально',
			'reader.fontSmaller' => 'Уменьшить текст',
			'reader.fontLarger' => 'Увеличить текст',
			'reader.verticalScroll' => 'Вертикальная прокрутка',
			'reader.rtlDirection' => 'Листание справа налево',
			'reader.verticalWriting' => 'Вертикальное письмо',
			'reader.narration' => 'Озвучка (Media Overlay)',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · исправлений: ${count}',
			'core.recordHighlight' => 'recordHighlight() — событие toolUse',
			'core.recordBookmark' => 'recordBookmark() — событие toolUse',
			'core.assetLoadFailed' => ({required Object error}) => 'Не удалось загрузить ресурс: ${error}',
			'core.positionTokenTitle' => 'Токен BookPosition v1',
			'core.eventLog' => 'Журнал событий',
			'core.positionToken' => 'Токен позиции',
			'core.waitingForEvents' => 'Ожидание событий…',
			'highlight.list' => 'Выделения',
			'highlight.action' => 'Выделить',
			'highlight.openFailed' => ({required Object error}) => 'Не удаётся открыть книгу: ${error}',
			'highlight.selectFirst' => 'Сначала выделите текст.',
			'highlight.saved' => ({required Object color}) => 'Выделение сохранено (${color})',
			'highlight.deleted' => 'Выделение удалено',
			'highlight.noteSaved' => 'Заметка сохранена',
			'highlight.hintSelected' => 'Нажмите «Выделить», чтобы окрасить фрагмент',
			'highlight.hintIdle' => 'Выделите текст, и появится кнопка «Выделить»',
			'highlight.previousChapter' => 'Предыдущая глава',
			'highlight.nextChapter' => 'Следующая глава',
			'highlight.note' => 'Заметка',
			'highlight.noteHint' => 'Введите заметку',
			'highlight.noteOptional' => 'Заметка (необязательно)',
			'highlight.colorLabel' => ({required Object color}) => 'Цвет: ${color}',
			'highlight.count' => ({required Object count}) => 'Выделений: ${count}',
			'highlight.empty' => 'Сохранённых выделений пока нет.',
			'highlight.noteLine' => ({required Object note}) => 'Заметка: ${note}',
			'highlight.menu' => 'Меню выделения',
			'highlight.editNote' => 'Изменить заметку',
			'highlight.delete' => 'Удалить',
			'highlight.colors.yellow' => 'Жёлтый',
			'highlight.colors.green' => 'Зелёный',
			'highlight.colors.blue' => 'Синий',
			'highlight.colors.pink' => 'Розовый',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => 'стр. ${index}/${total}',
			'epubReader.fileTooLarge' => 'Файл слишком большой, его нельзя открыть.',
			'epubReader.networkFailure' => 'Не удалось получить книгу из-за ошибки сети.',
			'epubReader.corruptedFile' => 'Этот EPUB повреждён или некорректен.',
			'epubReader.openFailed' => 'При открытии книги произошла ошибка.',
			'epubReader.positionRestoreFailed' => 'Не удалось найти последнюю позицию, книга открыта с начала',
			'epubReader.emptyBook' => 'В этой книге нечего показать.',
			'epubReader.emptyPage' => 'На этой странице нечего показать.',
			'epubReader.chapterLoadFailed' => 'Не удалось загрузить текст.',
			'epubReader.pageLoadFailed' => 'Не удалось загрузить страницу.',
			'epubReader.formula' => 'Формула',
			_ => null,
		};
	}
}
