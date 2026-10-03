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
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$es app = _Translations$app$es._(_root);
	@override late final _Translations$common$es common = _Translations$common$es._(_root);
	@override late final _Translations$home$es home = _Translations$home$es._(_root);
	@override late final _Translations$tools$es tools = _Translations$tools$es._(_root);
	@override late final _Translations$link$es link = _Translations$link$es._(_root);
	@override late final _Translations$drawing$es drawing = _Translations$drawing$es._(_root);
	@override late final _Translations$split$es split = _Translations$split$es._(_root);
	@override late final _Translations$epub$es epub = _Translations$epub$es._(_root);
}

// Path: app
class _Translations$app$es extends Translations$app$ko {
	_Translations$app$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de Open Board';
}

// Path: common
class _Translations$common$es extends Translations$common$ko {
	_Translations$common$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get undo => 'Deshacer';
	@override String get redo => 'Rehacer';
	@override String get clear => 'Borrar todo';
	@override String get previousPage => 'Página anterior';
	@override String get nextPage => 'Página siguiente';
	@override String get loading => 'Cargando…';
}

// Path: home
class _Translations$home$es extends Translations$home$ko {
	_Translations$home$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$es board = _Translations$home$board$es._(_root);
	@override late final _Translations$home$split$es split = _Translations$home$split$es._(_root);
	@override late final _Translations$home$epub$es epub = _Translations$home$epub$es._(_root);
}

// Path: tools
class _Translations$tools$es extends Translations$tools$ko {
	_Translations$tools$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get pen => 'Bolígrafo';
	@override String get pencil => 'Lápiz';
	@override String get marker => 'Rotulador';
	@override String get highlighter => 'Resaltador';
	@override String get fixedPen => 'Bolígrafo fijo';
	@override String get uniformPen => 'Bolígrafo uniforme';
	@override String get eraser => 'Borrador';
	@override String get text => 'Texto';
	@override String get shape => 'Forma';
	@override String get lasso => 'Lazo';
	@override String get image => 'Imagen';
}

// Path: link
class _Translations$link$es extends Translations$link$ko {
	_Translations$link$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get add => 'Añadir enlace';
	@override String get edit => 'Editar enlace';
	@override String get remove => 'Eliminar enlace';
	@override String get done => 'Listo';
	@override String get dialogTitle => 'Enlace';
	@override String get external => 'URL externa';
	@override String get internal => 'Página interna';
	@override String get pageNumber => 'Número de página';
	@override String get url => 'URL';
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'Aceptar';
}

// Path: drawing
class _Translations$drawing$es extends Translations$drawing$ko {
	_Translations$drawing$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get startRecording => 'Iniciar grabación';
	@override String get stopRecording => 'Detener grabación';
	@override String get replay => 'Reproducir';
	@override String get stopReplay => 'Detener reproducción';
	@override String recording({required Object count}) => 'Grabando · eventos: ${count}';
	@override String replaying({required Object index, required Object total}) => 'Reproduciendo · ${index}/${total}';
	@override String ready({required Object count}) => 'Listo para reproducir · eventos: ${count}';
	@override String get noRecording => 'Sin grabación';
	@override String page({required Object number}) => 'Página ${number}';
	@override late final _Translations$drawing$features$es features = _Translations$drawing$features$es._(_root);
	@override late final _Translations$drawing$recordingGuide$es recordingGuide = _Translations$drawing$recordingGuide$es._(_root);
	@override late final _Translations$drawing$multiPage$es multiPage = _Translations$drawing$multiPage$es._(_root);
}

// Path: split
class _Translations$split$es extends Translations$split$ko {
	_Translations$split$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pantalla dividida: un solo panel de herramientas flotante';
}

// Path: epub
class _Translations$epub$es extends Translations$epub$ko {
	_Translations$epub$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get readingMode => 'Modo lectura';
	@override String get annotationMode => 'Modo anotación';
	@override String get info => 'Las notas se guardan por capítulo (spineHref) — open_epub 1.0 EpubReader con EpubViewController.';
	@override String get webNote => 'En la web, las notas solo se conservan durante esta sesión.';
	@override String sample({required Object title}) => 'Muestra: ${title}';
}

// Path: home.board
class _Translations$home$board$es extends Translations$home$board$ko {
	_Translations$home$board$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de pizarra';
	@override String get description => 'Ocho herramientas de escritura, varias páginas, grabación y reproducción';
}

// Path: home.split
class _Translations$home$split$es extends Translations$home$split$ko {
	_Translations$home$split$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de pantalla dividida';
	@override String get description => 'Dos áreas de escritura lado a lado con un solo panel de herramientas flotante';
}

// Path: home.epub
class _Translations$home$epub$es extends Translations$home$epub$ko {
	_Translations$home$epub$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de anotación EPUB';
	@override String get description => 'Escritura a mano vinculada a la página sobre el lector open_epub (alterna entre lectura y escritura)';
}

// Path: drawing.features
class _Translations$drawing$features$es extends Translations$drawing$features$ko {
	_Translations$drawing$features$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Funciones';
	@override List<String> get items => [
		'Herramientas de escritura: bolígrafo, lápiz, rotulador y bolígrafo fijo',
		'Seis colores predefinidos',
		'Grosor de trazo ajustable (0,5–10,0)',
		'Borrador para eliminar trazos',
		'Reconocimiento de formas (círculo, rectángulo, línea)',
		'Selección con lazo para mover trazos',
		'Herramienta de texto para añadir notas',
		'Deshacer y rehacer',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$es extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Grabación y reproducción';
	@override List<String> get items => [
		'Pulsa el botón rojo para empezar a grabar',
		'Escribe, cambia de página, amplía o reduce: todo queda grabado',
		'Pulsa detener para terminar la grabación',
		'Pulsa reproducir para ver de nuevo toda la sesión',
		'Se graban los trazos, los cambios de página y los cambios de vista',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$es extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Varias páginas';
	@override List<String> get items => [
		'Cambia de página con la barra de páginas de arriba',
		'Cada página tiene sus propios trazos e historial de deshacer',
		'ScribbleBookController gestiona todas las páginas',
		'ScribbleCacheManager se encarga de la caché y el guardado',
		'Prueba a escribir en varias páginas y a cambiar entre ellas',
	];
	@override String get tip => 'Consejo: escribe en esta página, luego en otra y vuelve. Tus trazos siguen aquí.';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Demo de Open Board',
			'common.undo' => 'Deshacer',
			'common.redo' => 'Rehacer',
			'common.clear' => 'Borrar todo',
			'common.previousPage' => 'Página anterior',
			'common.nextPage' => 'Página siguiente',
			'common.loading' => 'Cargando…',
			'home.board.title' => 'Demo de pizarra',
			'home.board.description' => 'Ocho herramientas de escritura, varias páginas, grabación y reproducción',
			'home.split.title' => 'Demo de pantalla dividida',
			'home.split.description' => 'Dos áreas de escritura lado a lado con un solo panel de herramientas flotante',
			'home.epub.title' => 'Demo de anotación EPUB',
			'home.epub.description' => 'Escritura a mano vinculada a la página sobre el lector open_epub (alterna entre lectura y escritura)',
			'tools.pen' => 'Bolígrafo',
			'tools.pencil' => 'Lápiz',
			'tools.marker' => 'Rotulador',
			'tools.highlighter' => 'Resaltador',
			'tools.fixedPen' => 'Bolígrafo fijo',
			'tools.uniformPen' => 'Bolígrafo uniforme',
			'tools.eraser' => 'Borrador',
			'tools.text' => 'Texto',
			'tools.shape' => 'Forma',
			'tools.lasso' => 'Lazo',
			'tools.image' => 'Imagen',
			'link.add' => 'Añadir enlace',
			'link.edit' => 'Editar enlace',
			'link.remove' => 'Eliminar enlace',
			'link.done' => 'Listo',
			'link.dialogTitle' => 'Enlace',
			'link.external' => 'URL externa',
			'link.internal' => 'Página interna',
			'link.pageNumber' => 'Número de página',
			'link.url' => 'URL',
			'link.cancel' => 'Cancelar',
			'link.confirm' => 'Aceptar',
			'drawing.startRecording' => 'Iniciar grabación',
			'drawing.stopRecording' => 'Detener grabación',
			'drawing.replay' => 'Reproducir',
			'drawing.stopReplay' => 'Detener reproducción',
			'drawing.recording' => ({required Object count}) => 'Grabando · eventos: ${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => 'Reproduciendo · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => 'Listo para reproducir · eventos: ${count}',
			'drawing.noRecording' => 'Sin grabación',
			'drawing.page' => ({required Object number}) => 'Página ${number}',
			'drawing.features.title' => 'Funciones',
			'drawing.features.items.0' => 'Herramientas de escritura: bolígrafo, lápiz, rotulador y bolígrafo fijo',
			'drawing.features.items.1' => 'Seis colores predefinidos',
			'drawing.features.items.2' => 'Grosor de trazo ajustable (0,5–10,0)',
			'drawing.features.items.3' => 'Borrador para eliminar trazos',
			'drawing.features.items.4' => 'Reconocimiento de formas (círculo, rectángulo, línea)',
			'drawing.features.items.5' => 'Selección con lazo para mover trazos',
			'drawing.features.items.6' => 'Herramienta de texto para añadir notas',
			'drawing.features.items.7' => 'Deshacer y rehacer',
			'drawing.recordingGuide.title' => 'Grabación y reproducción',
			'drawing.recordingGuide.items.0' => 'Pulsa el botón rojo para empezar a grabar',
			'drawing.recordingGuide.items.1' => 'Escribe, cambia de página, amplía o reduce: todo queda grabado',
			'drawing.recordingGuide.items.2' => 'Pulsa detener para terminar la grabación',
			'drawing.recordingGuide.items.3' => 'Pulsa reproducir para ver de nuevo toda la sesión',
			'drawing.recordingGuide.items.4' => 'Se graban los trazos, los cambios de página y los cambios de vista',
			'drawing.multiPage.title' => 'Varias páginas',
			'drawing.multiPage.items.0' => 'Cambia de página con la barra de páginas de arriba',
			'drawing.multiPage.items.1' => 'Cada página tiene sus propios trazos e historial de deshacer',
			'drawing.multiPage.items.2' => 'ScribbleBookController gestiona todas las páginas',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager se encarga de la caché y el guardado',
			'drawing.multiPage.items.4' => 'Prueba a escribir en varias páginas y a cambiar entre ellas',
			'drawing.multiPage.tip' => 'Consejo: escribe en esta página, luego en otra y vuelve. Tus trazos siguen aquí.',
			'split.title' => 'Pantalla dividida: un solo panel de herramientas flotante',
			'epub.readingMode' => 'Modo lectura',
			'epub.annotationMode' => 'Modo anotación',
			'epub.info' => 'Las notas se guardan por capítulo (spineHref) — open_epub 1.0 EpubReader con EpubViewController.',
			'epub.webNote' => 'En la web, las notas solo se conservan durante esta sesión.',
			'epub.sample' => ({required Object title}) => 'Muestra: ${title}',
			_ => null,
		};
	}
}
