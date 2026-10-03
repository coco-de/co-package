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
	@override late final _Translations$samples$es samples = _Translations$samples$es._(_root);
	@override late final _Translations$reader$es reader = _Translations$reader$es._(_root);
	@override late final _Translations$core$es core = _Translations$core$es._(_root);
	@override late final _Translations$highlight$es highlight = _Translations$highlight$es._(_root);
	@override late final _Translations$fixedLayout$es fixedLayout = _Translations$fixedLayout$es._(_root);
	@override late final _Translations$epubReader$es epubReader = _Translations$epubReader$es._(_root);
}

// Path: app
class _Translations$app$es extends Translations$app$ko {
	_Translations$app$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de open_epub';
}

// Path: common
class _Translations$common$es extends Translations$common$ko {
	_Translations$common$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get previousPage => 'Página anterior';
	@override String get nextPage => 'Página siguiente';
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get close => 'Cerrar';
}

// Path: home
class _Translations$home$es extends Translations$home$ko {
	_Translations$home$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$es library = _Translations$home$library$es._(_root);
	@override late final _Translations$home$core$es core = _Translations$home$core$es._(_root);
	@override late final _Translations$home$highlight$es highlight = _Translations$home$highlight$es._(_root);
	@override late final _Translations$home$fixedLayout$es fixedLayout = _Translations$home$fixedLayout$es._(_root);
}

// Path: samples
class _Translations$samples$es extends Translations$samples$ko {
	_Translations$samples$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$es nohoechan = _Translations$samples$nohoechan$es._(_root);
	@override late final _Translations$samples$wasteland$es wasteland = _Translations$samples$wasteland$es._(_root);
	@override late final _Translations$samples$arabicRtl$es arabicRtl = _Translations$samples$arabicRtl$es._(_root);
	@override late final _Translations$samples$mathml$es mathml = _Translations$samples$mathml$es._(_root);
	@override late final _Translations$samples$vertical$es vertical = _Translations$samples$vertical$es._(_root);
	@override late final _Translations$samples$mediaOverlay$es mediaOverlay = _Translations$samples$mediaOverlay$es._(_root);
	@override late final _Translations$samples$accessible$es accessible = _Translations$samples$accessible$es._(_root);
	@override late final _Translations$samples$cfi$es cfi = _Translations$samples$cfi$es._(_root);
	@override late final _Translations$samples$fixedA4$es fixedA4 = _Translations$samples$fixedA4$es._(_root);
}

// Path: reader
class _Translations$reader$es extends Translations$reader$ko {
	_Translations$reader$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => 'Este libro no tiene Media Overlay';
	@override String get mediaOverlayLoadFailed => 'No se pudo cargar el Media Overlay (SMIL)';
	@override String audioFailed({required Object error}) => 'Falló la reproducción de audio (puede ser una limitación del simulador): ${error}';
	@override String localFixture({required Object asset}) => 'Esta muestra (${asset}) es un archivo de prueba local que no está en el repositorio (excluido por .gitignore por tamaño o licencia).\nPara abrirla, coloca el archivo EPUB en packages/open_epub/example/assets/ de tu copia local y vuelve a ejecutar la app.';
	@override String get mode => 'Modo';
	@override String get swipe => 'deslizar';
	@override String get scroll => 'desplazamiento';
	@override String get vertical => 'Vertical';
	@override String get fontSmaller => 'Texto más pequeño';
	@override String get fontLarger => 'Texto más grande';
	@override String get verticalScroll => 'Desplazamiento vertical';
	@override String get rtlDirection => 'Dirección de página RTL';
	@override String get verticalWriting => 'Escritura vertical';
	@override String get narration => 'Narración (Media Overlay)';
}

// Path: core
class _Translations$core$es extends Translations$core$ko {
	_Translations$core$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · correcciones: ${count}';
	@override String get recordHighlight => 'recordHighlight() — evento toolUse';
	@override String get recordBookmark => 'recordBookmark() — evento toolUse';
	@override String assetLoadFailed({required Object error}) => 'No se pudo cargar el recurso: ${error}';
	@override String get positionTokenTitle => 'Token de BookPosition v1';
	@override String get eventLog => 'Registro de eventos';
	@override String get positionToken => 'Token de posición';
	@override String get waitingForEvents => 'Esperando eventos…';
}

// Path: highlight
class _Translations$highlight$es extends Translations$highlight$ko {
	_Translations$highlight$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get list => 'Resaltados';
	@override String get action => 'Resaltar';
	@override String openFailed({required Object error}) => 'No se puede abrir el libro: ${error}';
	@override String get selectFirst => 'Primero selecciona texto.';
	@override String saved({required Object color}) => 'Resaltado guardado (${color})';
	@override String get deleted => 'Resaltado eliminado';
	@override String get noteSaved => 'Nota guardada';
	@override String get hintSelected => 'Pulsa «Resaltar» para colorear la selección';
	@override String get hintIdle => 'Selecciona texto para ver el botón Resaltar';
	@override String get previousChapter => 'Capítulo anterior';
	@override String get nextChapter => 'Capítulo siguiente';
	@override String get note => 'Nota';
	@override String get noteHint => 'Escribe una nota';
	@override String get noteOptional => 'Nota (opcional)';
	@override String colorLabel({required Object color}) => 'Color: ${color}';
	@override String count({required Object count}) => 'Resaltados: ${count}';
	@override String get empty => 'Aún no hay resaltados.';
	@override String noteLine({required Object note}) => 'Nota: ${note}';
	@override String get menu => 'Menú del resaltado';
	@override String get editNote => 'Editar nota';
	@override String get delete => 'Eliminar';
	@override late final _Translations$highlight$colors$es colors = _Translations$highlight$colors$es._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$es extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => 'página ${index}/${total}';
}

// Path: epubReader
class _Translations$epubReader$es extends Translations$epubReader$ko {
	_Translations$epubReader$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => 'El archivo es demasiado grande para abrirlo.';
	@override String get networkFailure => 'No se pudo obtener el libro por un error de red.';
	@override String get corruptedFile => 'Este EPUB está dañado o no es válido.';
	@override String get openFailed => 'Se produjo un error al abrir el libro.';
	@override String get positionRestoreFailed => 'No se encontró tu última posición, así que el libro empieza desde el principio';
	@override String get emptyBook => 'Este libro no tiene nada que mostrar.';
	@override String get emptyPage => 'Esta página no tiene nada que mostrar.';
	@override String get chapterLoadFailed => 'No se pudo cargar el texto.';
	@override String get pageLoadFailed => 'No se pudo cargar la página.';
	@override String get formula => 'Fórmula';
}

// Path: home.library
class _Translations$home$library$es extends Translations$home$library$ko {
	_Translations$home$library$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteca de muestras EPUB3';
	@override String get description => 'Comprueba RTL, MathML, escritura vertical, Media Overlay y CFI';
}

// Path: home.core
class _Translations$home$core$es extends Translations$home$core$ko {
	_Translations$home$core$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo del núcleo 1.0';
}

// Path: home.highlight
class _Translations$home$highlight$es extends Translations$home$highlight$ko {
	_Translations$home$highlight$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de resaltado';
	@override String get description => 'Seleccionar texto → color → resaltado + nota';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$es extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de Fixed Layout A4';
	@override String get description => 'Muestra un libro prepaginado en tamaño A4 (794×1123)';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$es extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB2 real con texto adaptable · 22 MB';
	@override String get tag => 'EPUB2 · archivo grande';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$es extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · EPUB3 básico (nav, CSS)';
	@override String get tag => 'EPUB3 básico';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$es extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Árabe · page-progression-direction=rtl';
	@override String get tag => 'Paso de página RTL (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$es extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '71 fórmulas MathML · conversión a TeX y alternativa';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$es extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Escritura vertical japonesa (vertical-rl) + RTL';
	@override String get tag => 'Escritura vertical (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$es extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Narración SMIL con resaltado sincronizado con el audio';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$es extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · puntos de referencia y tabla de contenido anidada';
	@override String get tag => 'EPUB3 completo (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$es extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · page-list de 7 entradas';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$es extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Diseño fijo prepaginado · A4 (794×1123), 3 páginas';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$es extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get yellow => 'Amarillo';
	@override String get green => 'Verde';
	@override String get blue => 'Azul';
	@override String get pink => 'Rosa';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Demo de open_epub',
			'common.previousPage' => 'Página anterior',
			'common.nextPage' => 'Página siguiente',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Guardar',
			'common.close' => 'Cerrar',
			'home.library.title' => 'Biblioteca de muestras EPUB3',
			'home.library.description' => 'Comprueba RTL, MathML, escritura vertical, Media Overlay y CFI',
			'home.core.title' => 'Demo del núcleo 1.0',
			'home.highlight.title' => 'Demo de resaltado',
			'home.highlight.description' => 'Seleccionar texto → color → resaltado + nota',
			'home.fixedLayout.title' => 'Demo de Fixed Layout A4',
			'home.fixedLayout.description' => 'Muestra un libro prepaginado en tamaño A4 (794×1123)',
			'samples.nohoechan.subtitle' => 'EPUB2 real con texto adaptable · 22 MB',
			'samples.nohoechan.tag' => 'EPUB2 · archivo grande',
			'samples.wasteland.subtitle' => 'T.S. Eliot · EPUB3 básico (nav, CSS)',
			'samples.wasteland.tag' => 'EPUB3 básico',
			'samples.arabicRtl.subtitle' => 'Árabe · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'Paso de página RTL (E14)',
			'samples.mathml.subtitle' => '71 fórmulas MathML · conversión a TeX y alternativa',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => 'Escritura vertical japonesa (vertical-rl) + RTL',
			'samples.vertical.tag' => 'Escritura vertical (E15)',
			'samples.mediaOverlay.subtitle' => 'Narración SMIL con resaltado sincronizado con el audio',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · puntos de referencia y tabla de contenido anidada',
			'samples.accessible.tag' => 'EPUB3 completo (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list de 7 entradas',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'Diseño fijo prepaginado · A4 (794×1123), 3 páginas',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => 'Este libro no tiene Media Overlay',
			'reader.mediaOverlayLoadFailed' => 'No se pudo cargar el Media Overlay (SMIL)',
			'reader.audioFailed' => ({required Object error}) => 'Falló la reproducción de audio (puede ser una limitación del simulador): ${error}',
			'reader.localFixture' => ({required Object asset}) => 'Esta muestra (${asset}) es un archivo de prueba local que no está en el repositorio (excluido por .gitignore por tamaño o licencia).\nPara abrirla, coloca el archivo EPUB en packages/open_epub/example/assets/ de tu copia local y vuelve a ejecutar la app.',
			'reader.mode' => 'Modo',
			'reader.swipe' => 'deslizar',
			'reader.scroll' => 'desplazamiento',
			'reader.vertical' => 'Vertical',
			'reader.fontSmaller' => 'Texto más pequeño',
			'reader.fontLarger' => 'Texto más grande',
			'reader.verticalScroll' => 'Desplazamiento vertical',
			'reader.rtlDirection' => 'Dirección de página RTL',
			'reader.verticalWriting' => 'Escritura vertical',
			'reader.narration' => 'Narración (Media Overlay)',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · correcciones: ${count}',
			'core.recordHighlight' => 'recordHighlight() — evento toolUse',
			'core.recordBookmark' => 'recordBookmark() — evento toolUse',
			'core.assetLoadFailed' => ({required Object error}) => 'No se pudo cargar el recurso: ${error}',
			'core.positionTokenTitle' => 'Token de BookPosition v1',
			'core.eventLog' => 'Registro de eventos',
			'core.positionToken' => 'Token de posición',
			'core.waitingForEvents' => 'Esperando eventos…',
			'highlight.list' => 'Resaltados',
			'highlight.action' => 'Resaltar',
			'highlight.openFailed' => ({required Object error}) => 'No se puede abrir el libro: ${error}',
			'highlight.selectFirst' => 'Primero selecciona texto.',
			'highlight.saved' => ({required Object color}) => 'Resaltado guardado (${color})',
			'highlight.deleted' => 'Resaltado eliminado',
			'highlight.noteSaved' => 'Nota guardada',
			'highlight.hintSelected' => 'Pulsa «Resaltar» para colorear la selección',
			'highlight.hintIdle' => 'Selecciona texto para ver el botón Resaltar',
			'highlight.previousChapter' => 'Capítulo anterior',
			'highlight.nextChapter' => 'Capítulo siguiente',
			'highlight.note' => 'Nota',
			'highlight.noteHint' => 'Escribe una nota',
			'highlight.noteOptional' => 'Nota (opcional)',
			'highlight.colorLabel' => ({required Object color}) => 'Color: ${color}',
			'highlight.count' => ({required Object count}) => 'Resaltados: ${count}',
			'highlight.empty' => 'Aún no hay resaltados.',
			'highlight.noteLine' => ({required Object note}) => 'Nota: ${note}',
			'highlight.menu' => 'Menú del resaltado',
			'highlight.editNote' => 'Editar nota',
			'highlight.delete' => 'Eliminar',
			'highlight.colors.yellow' => 'Amarillo',
			'highlight.colors.green' => 'Verde',
			'highlight.colors.blue' => 'Azul',
			'highlight.colors.pink' => 'Rosa',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => 'página ${index}/${total}',
			'epubReader.fileTooLarge' => 'El archivo es demasiado grande para abrirlo.',
			'epubReader.networkFailure' => 'No se pudo obtener el libro por un error de red.',
			'epubReader.corruptedFile' => 'Este EPUB está dañado o no es válido.',
			'epubReader.openFailed' => 'Se produjo un error al abrir el libro.',
			'epubReader.positionRestoreFailed' => 'No se encontró tu última posición, así que el libro empieza desde el principio',
			'epubReader.emptyBook' => 'Este libro no tiene nada que mostrar.',
			'epubReader.emptyPage' => 'Esta página no tiene nada que mostrar.',
			'epubReader.chapterLoadFailed' => 'No se pudo cargar el texto.',
			'epubReader.pageLoadFailed' => 'No se pudo cargar la página.',
			'epubReader.formula' => 'Fórmula',
			_ => null,
		};
	}
}
