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
	@override late final _Translations$tools$ru tools = _Translations$tools$ru._(_root);
	@override late final _Translations$link$ru link = _Translations$link$ru._(_root);
	@override late final _Translations$drawing$ru drawing = _Translations$drawing$ru._(_root);
	@override late final _Translations$split$ru split = _Translations$split$ru._(_root);
	@override late final _Translations$epub$ru epub = _Translations$epub$ru._(_root);
}

// Path: app
class _Translations$app$ru extends Translations$app$ko {
	_Translations$app$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Демо Open Board';
}

// Path: common
class _Translations$common$ru extends Translations$common$ko {
	_Translations$common$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get undo => 'Отменить';
	@override String get redo => 'Повторить';
	@override String get clear => 'Очистить всё';
	@override String get previousPage => 'Предыдущая страница';
	@override String get nextPage => 'Следующая страница';
	@override String get loading => 'Загрузка…';
}

// Path: home
class _Translations$home$ru extends Translations$home$ko {
	_Translations$home$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$ru board = _Translations$home$board$ru._(_root);
	@override late final _Translations$home$split$ru split = _Translations$home$split$ru._(_root);
	@override late final _Translations$home$epub$ru epub = _Translations$home$epub$ru._(_root);
}

// Path: tools
class _Translations$tools$ru extends Translations$tools$ko {
	_Translations$tools$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get pen => 'Ручка';
	@override String get pencil => 'Карандаш';
	@override String get marker => 'Маркер';
	@override String get highlighter => 'Текстовыделитель';
	@override String get fixedPen => 'Фиксированная ручка';
	@override String get uniformPen => 'Ровная ручка';
	@override String get eraser => 'Ластик';
	@override String get text => 'Текст';
	@override String get shape => 'Фигура';
	@override String get lasso => 'Лассо';
	@override String get image => 'Изображение';
}

// Path: link
class _Translations$link$ru extends Translations$link$ko {
	_Translations$link$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get add => 'Добавить ссылку';
	@override String get edit => 'Изменить ссылку';
	@override String get remove => 'Удалить ссылку';
	@override String get done => 'Готово';
	@override String get dialogTitle => 'Ссылка';
	@override String get external => 'Внешний URL';
	@override String get internal => 'Внутренняя страница';
	@override String get pageNumber => 'Номер страницы';
	@override String get url => 'URL';
	@override String get cancel => 'Отмена';
	@override String get confirm => 'ОК';
}

// Path: drawing
class _Translations$drawing$ru extends Translations$drawing$ko {
	_Translations$drawing$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get startRecording => 'Начать запись';
	@override String get stopRecording => 'Остановить запись';
	@override String get replay => 'Воспроизвести';
	@override String get stopReplay => 'Остановить воспроизведение';
	@override String recording({required Object count}) => 'Запись · событий: ${count}';
	@override String replaying({required Object index, required Object total}) => 'Воспроизведение · ${index}/${total}';
	@override String ready({required Object count}) => 'Готово к воспроизведению · событий: ${count}';
	@override String get noRecording => 'Записи нет';
	@override String page({required Object number}) => 'Страница ${number}';
	@override late final _Translations$drawing$features$ru features = _Translations$drawing$features$ru._(_root);
	@override late final _Translations$drawing$recordingGuide$ru recordingGuide = _Translations$drawing$recordingGuide$ru._(_root);
	@override late final _Translations$drawing$multiPage$ru multiPage = _Translations$drawing$multiPage$ru._(_root);
}

// Path: split
class _Translations$split$ru extends Translations$split$ko {
	_Translations$split$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Разделённый экран — одна плавающая панель инструментов';
}

// Path: epub
class _Translations$epub$ru extends Translations$epub$ko {
	_Translations$epub$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get readingMode => 'Режим чтения';
	@override String get annotationMode => 'Режим заметок';
	@override String get info => 'Заметки сохраняются по главам (spineHref) — open_epub 1.0 EpubReader вместе с EpubViewController.';
	@override String get webNote => 'В вебе заметки хранятся только в течение этого сеанса.';
	@override String sample({required Object title}) => 'Пример: ${title}';
}

// Path: home.board
class _Translations$home$board$ru extends Translations$home$board$ko {
	_Translations$home$board$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Демо доски';
	@override String get description => 'Восемь инструментов рисования, несколько страниц, запись и воспроизведение';
}

// Path: home.split
class _Translations$home$split$ru extends Translations$home$split$ko {
	_Translations$home$split$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Демо разделённого экрана';
	@override String get description => 'Две области рисования рядом и одна плавающая панель инструментов';
}

// Path: home.epub
class _Translations$home$epub$ru extends Translations$home$epub$ko {
	_Translations$home$epub$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Демо аннотаций EPUB';
	@override String get description => 'Рукописные заметки, привязанные к страницам, поверх читалки open_epub (переключение между чтением и письмом)';
}

// Path: drawing.features
class _Translations$drawing$features$ru extends Translations$drawing$features$ko {
	_Translations$drawing$features$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Возможности';
	@override List<String> get items => [
		'Инструменты рисования: ручка, карандаш, маркер и фиксированная ручка',
		'Шесть готовых цветов',
		'Настраиваемая толщина линии (0,5–10,0)',
		'Ластик для удаления штрихов',
		'Распознавание фигур (круг, прямоугольник, линия)',
		'Выделение лассо для перемещения штрихов',
		'Текстовый инструмент для заметок',
		'Отмена и повтор действий',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$ru extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Запись и воспроизведение';
	@override List<String> get items => [
		'Нажмите красную кнопку, чтобы начать запись',
		'Рисуйте, листайте страницы, меняйте масштаб — записывается всё',
		'Нажмите «Стоп», чтобы закончить запись',
		'Нажмите «Воспроизвести», чтобы просмотреть весь сеанс',
		'Записываются штрихи, смена страниц и изменения области просмотра',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$ru extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Несколько страниц';
	@override List<String> get items => [
		'Переходите между страницами с помощью панели страниц вверху',
		'У каждой страницы свои штрихи и своя история отмены',
		'ScribbleBookController управляет всеми страницами',
		'ScribbleCacheManager отвечает за кеш и сохранение',
		'Попробуйте рисовать на разных страницах и переключаться между ними',
	];
	@override String get tip => 'Совет: нарисуйте что-нибудь на этой странице, затем на другой и вернитесь. Ваши штрихи на месте.';
}

/// The flat map containing all translations for locale <ru>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Демо Open Board',
			'common.undo' => 'Отменить',
			'common.redo' => 'Повторить',
			'common.clear' => 'Очистить всё',
			'common.previousPage' => 'Предыдущая страница',
			'common.nextPage' => 'Следующая страница',
			'common.loading' => 'Загрузка…',
			'home.board.title' => 'Демо доски',
			'home.board.description' => 'Восемь инструментов рисования, несколько страниц, запись и воспроизведение',
			'home.split.title' => 'Демо разделённого экрана',
			'home.split.description' => 'Две области рисования рядом и одна плавающая панель инструментов',
			'home.epub.title' => 'Демо аннотаций EPUB',
			'home.epub.description' => 'Рукописные заметки, привязанные к страницам, поверх читалки open_epub (переключение между чтением и письмом)',
			'tools.pen' => 'Ручка',
			'tools.pencil' => 'Карандаш',
			'tools.marker' => 'Маркер',
			'tools.highlighter' => 'Текстовыделитель',
			'tools.fixedPen' => 'Фиксированная ручка',
			'tools.uniformPen' => 'Ровная ручка',
			'tools.eraser' => 'Ластик',
			'tools.text' => 'Текст',
			'tools.shape' => 'Фигура',
			'tools.lasso' => 'Лассо',
			'tools.image' => 'Изображение',
			'link.add' => 'Добавить ссылку',
			'link.edit' => 'Изменить ссылку',
			'link.remove' => 'Удалить ссылку',
			'link.done' => 'Готово',
			'link.dialogTitle' => 'Ссылка',
			'link.external' => 'Внешний URL',
			'link.internal' => 'Внутренняя страница',
			'link.pageNumber' => 'Номер страницы',
			'link.url' => 'URL',
			'link.cancel' => 'Отмена',
			'link.confirm' => 'ОК',
			'drawing.startRecording' => 'Начать запись',
			'drawing.stopRecording' => 'Остановить запись',
			'drawing.replay' => 'Воспроизвести',
			'drawing.stopReplay' => 'Остановить воспроизведение',
			'drawing.recording' => ({required Object count}) => 'Запись · событий: ${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => 'Воспроизведение · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => 'Готово к воспроизведению · событий: ${count}',
			'drawing.noRecording' => 'Записи нет',
			'drawing.page' => ({required Object number}) => 'Страница ${number}',
			'drawing.features.title' => 'Возможности',
			'drawing.features.items.0' => 'Инструменты рисования: ручка, карандаш, маркер и фиксированная ручка',
			'drawing.features.items.1' => 'Шесть готовых цветов',
			'drawing.features.items.2' => 'Настраиваемая толщина линии (0,5–10,0)',
			'drawing.features.items.3' => 'Ластик для удаления штрихов',
			'drawing.features.items.4' => 'Распознавание фигур (круг, прямоугольник, линия)',
			'drawing.features.items.5' => 'Выделение лассо для перемещения штрихов',
			'drawing.features.items.6' => 'Текстовый инструмент для заметок',
			'drawing.features.items.7' => 'Отмена и повтор действий',
			'drawing.recordingGuide.title' => 'Запись и воспроизведение',
			'drawing.recordingGuide.items.0' => 'Нажмите красную кнопку, чтобы начать запись',
			'drawing.recordingGuide.items.1' => 'Рисуйте, листайте страницы, меняйте масштаб — записывается всё',
			'drawing.recordingGuide.items.2' => 'Нажмите «Стоп», чтобы закончить запись',
			'drawing.recordingGuide.items.3' => 'Нажмите «Воспроизвести», чтобы просмотреть весь сеанс',
			'drawing.recordingGuide.items.4' => 'Записываются штрихи, смена страниц и изменения области просмотра',
			'drawing.multiPage.title' => 'Несколько страниц',
			'drawing.multiPage.items.0' => 'Переходите между страницами с помощью панели страниц вверху',
			'drawing.multiPage.items.1' => 'У каждой страницы свои штрихи и своя история отмены',
			'drawing.multiPage.items.2' => 'ScribbleBookController управляет всеми страницами',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager отвечает за кеш и сохранение',
			'drawing.multiPage.items.4' => 'Попробуйте рисовать на разных страницах и переключаться между ними',
			'drawing.multiPage.tip' => 'Совет: нарисуйте что-нибудь на этой странице, затем на другой и вернитесь. Ваши штрихи на месте.',
			'split.title' => 'Разделённый экран — одна плавающая панель инструментов',
			'epub.readingMode' => 'Режим чтения',
			'epub.annotationMode' => 'Режим заметок',
			'epub.info' => 'Заметки сохраняются по главам (spineHref) — open_epub 1.0 EpubReader вместе с EpubViewController.',
			'epub.webNote' => 'В вебе заметки хранятся только в течение этого сеанса.',
			'epub.sample' => ({required Object title}) => 'Пример: ${title}',
			_ => null,
		};
	}
}
