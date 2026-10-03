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
class TranslationsPt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pt,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsPt _root = this; // ignore: unused_field

	@override 
	TranslationsPt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPt(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$pt app = _Translations$app$pt._(_root);
	@override late final _Translations$common$pt common = _Translations$common$pt._(_root);
	@override late final _Translations$home$pt home = _Translations$home$pt._(_root);
	@override late final _Translations$samples$pt samples = _Translations$samples$pt._(_root);
	@override late final _Translations$reader$pt reader = _Translations$reader$pt._(_root);
	@override late final _Translations$core$pt core = _Translations$core$pt._(_root);
	@override late final _Translations$highlight$pt highlight = _Translations$highlight$pt._(_root);
	@override late final _Translations$fixedLayout$pt fixedLayout = _Translations$fixedLayout$pt._(_root);
	@override late final _Translations$epubReader$pt epubReader = _Translations$epubReader$pt._(_root);
}

// Path: app
class _Translations$app$pt extends Translations$app$ko {
	_Translations$app$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo do open_epub';
}

// Path: common
class _Translations$common$pt extends Translations$common$ko {
	_Translations$common$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get previousPage => 'Página anterior';
	@override String get nextPage => 'Próxima página';
	@override String get cancel => 'Cancelar';
	@override String get save => 'Salvar';
	@override String get close => 'Fechar';
}

// Path: home
class _Translations$home$pt extends Translations$home$ko {
	_Translations$home$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$library$pt library = _Translations$home$library$pt._(_root);
	@override late final _Translations$home$core$pt core = _Translations$home$core$pt._(_root);
	@override late final _Translations$home$highlight$pt highlight = _Translations$home$highlight$pt._(_root);
	@override late final _Translations$home$fixedLayout$pt fixedLayout = _Translations$home$fixedLayout$pt._(_root);
}

// Path: samples
class _Translations$samples$pt extends Translations$samples$ko {
	_Translations$samples$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$samples$nohoechan$pt nohoechan = _Translations$samples$nohoechan$pt._(_root);
	@override late final _Translations$samples$wasteland$pt wasteland = _Translations$samples$wasteland$pt._(_root);
	@override late final _Translations$samples$arabicRtl$pt arabicRtl = _Translations$samples$arabicRtl$pt._(_root);
	@override late final _Translations$samples$mathml$pt mathml = _Translations$samples$mathml$pt._(_root);
	@override late final _Translations$samples$vertical$pt vertical = _Translations$samples$vertical$pt._(_root);
	@override late final _Translations$samples$mediaOverlay$pt mediaOverlay = _Translations$samples$mediaOverlay$pt._(_root);
	@override late final _Translations$samples$accessible$pt accessible = _Translations$samples$accessible$pt._(_root);
	@override late final _Translations$samples$cfi$pt cfi = _Translations$samples$cfi$pt._(_root);
	@override late final _Translations$samples$fixedA4$pt fixedA4 = _Translations$samples$fixedA4$pt._(_root);
}

// Path: reader
class _Translations$reader$pt extends Translations$reader$ko {
	_Translations$reader$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get noMediaOverlay => 'Este livro não tem Media Overlay';
	@override String get mediaOverlayLoadFailed => 'Falha ao carregar o Media Overlay (SMIL)';
	@override String audioFailed({required Object error}) => 'Falha na reprodução do áudio (pode ser uma limitação do simulador): ${error}';
	@override String localFixture({required Object asset}) => 'Esta amostra (${asset}) é um arquivo de teste local que não está no repositório (excluído pelo .gitignore por tamanho ou licença).\nPara abri-la, coloque o arquivo EPUB em packages/open_epub/example/assets/ na sua cópia local e execute o app de novo.';
	@override String get mode => 'Modo';
	@override String get swipe => 'deslizar';
	@override String get scroll => 'rolagem';
	@override String get vertical => 'Vertical';
	@override String get fontSmaller => 'Texto menor';
	@override String get fontLarger => 'Texto maior';
	@override String get verticalScroll => 'Rolagem vertical';
	@override String get rtlDirection => 'Direção de página RTL';
	@override String get verticalWriting => 'Escrita vertical';
	@override String get narration => 'Narração (Media Overlay)';
}

// Path: core
class _Translations$core$pt extends Translations$core$ko {
	_Translations$core$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · correções: ${count}';
	@override String get recordHighlight => 'recordHighlight() — evento toolUse';
	@override String get recordBookmark => 'recordBookmark() — evento toolUse';
	@override String assetLoadFailed({required Object error}) => 'Falha ao carregar o asset: ${error}';
	@override String get positionTokenTitle => 'Token BookPosition v1';
	@override String get eventLog => 'Registro de eventos';
	@override String get positionToken => 'Token de posição';
	@override String get waitingForEvents => 'Aguardando eventos…';
}

// Path: highlight
class _Translations$highlight$pt extends Translations$highlight$ko {
	_Translations$highlight$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get list => 'Destaques';
	@override String get action => 'Destacar';
	@override String openFailed({required Object error}) => 'Não foi possível abrir o livro: ${error}';
	@override String get selectFirst => 'Selecione um texto primeiro.';
	@override String saved({required Object color}) => 'Destaque salvo (${color})';
	@override String get deleted => 'Destaque excluído';
	@override String get noteSaved => 'Anotação salva';
	@override String get hintSelected => 'Toque em “Destacar” para colorir a seleção';
	@override String get hintIdle => 'Selecione um texto para ver o botão Destacar';
	@override String get previousChapter => 'Capítulo anterior';
	@override String get nextChapter => 'Próximo capítulo';
	@override String get note => 'Anotação';
	@override String get noteHint => 'Digite uma anotação';
	@override String get noteOptional => 'Anotação (opcional)';
	@override String colorLabel({required Object color}) => 'Cor: ${color}';
	@override String count({required Object count}) => 'Destaques: ${count}';
	@override String get empty => 'Nenhum destaque ainda.';
	@override String noteLine({required Object note}) => 'Anotação: ${note}';
	@override String get menu => 'Menu do destaque';
	@override String get editNote => 'Editar anotação';
	@override String get delete => 'Excluir';
	@override late final _Translations$highlight$colors$pt colors = _Translations$highlight$colors$pt._(_root);
}

// Path: fixedLayout
class _Translations$fixedLayout$pt extends Translations$fixedLayout$ko {
	_Translations$fixedLayout$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String pageOf({required Object index, required Object total}) => 'página ${index}/${total}';
}

// Path: epubReader
class _Translations$epubReader$pt extends Translations$epubReader$ko {
	_Translations$epubReader$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get fileTooLarge => 'O arquivo é grande demais para ser aberto.';
	@override String get networkFailure => 'Não foi possível obter o livro por causa de um erro de rede.';
	@override String get corruptedFile => 'Este EPUB está danificado ou não é válido.';
	@override String get openFailed => 'Ocorreu um erro ao abrir o livro.';
	@override String get positionRestoreFailed => 'Não foi possível encontrar sua última posição, então o livro começa do início';
	@override String get emptyBook => 'Este livro não tem nada para exibir.';
	@override String get emptyPage => 'Esta página não tem nada para exibir.';
	@override String get chapterLoadFailed => 'Não foi possível carregar o texto.';
	@override String get pageLoadFailed => 'Não foi possível carregar a página.';
	@override String get formula => 'Fórmula';
}

// Path: home.library
class _Translations$home$library$pt extends Translations$home$library$ko {
	_Translations$home$library$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteca de amostras EPUB3';
	@override String get description => 'Verifica RTL, MathML, escrita vertical, Media Overlay e CFI';
}

// Path: home.core
class _Translations$home$core$pt extends Translations$home$core$ko {
	_Translations$home$core$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo do núcleo 1.0';
}

// Path: home.highlight
class _Translations$home$highlight$pt extends Translations$home$highlight$ko {
	_Translations$home$highlight$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de destaque';
	@override String get description => 'Selecionar texto → cor → destaque + anotação';
}

// Path: home.fixedLayout
class _Translations$home$fixedLayout$pt extends Translations$home$fixedLayout$ko {
	_Translations$home$fixedLayout$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de Fixed Layout A4';
	@override String get description => 'Exibe um livro pré-paginado no tamanho A4 (794×1123)';
}

// Path: samples.nohoechan
class _Translations$samples$nohoechan$pt extends Translations$samples$nohoechan$ko {
	_Translations$samples$nohoechan$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB2 real com texto refluível · 22 MB';
	@override String get tag => 'EPUB2 · arquivo grande';
}

// Path: samples.wasteland
class _Translations$samples$wasteland$pt extends Translations$samples$wasteland$ko {
	_Translations$samples$wasteland$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'T.S. Eliot · EPUB3 básico (nav, CSS)';
	@override String get tag => 'EPUB3 básico';
}

// Path: samples.arabicRtl
class _Translations$samples$arabicRtl$pt extends Translations$samples$arabicRtl$ko {
	_Translations$samples$arabicRtl$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Árabe · page-progression-direction=rtl';
	@override String get tag => 'Virar páginas em RTL (E14)';
}

// Path: samples.mathml
class _Translations$samples$mathml$pt extends Translations$samples$mathml$ko {
	_Translations$samples$mathml$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => '71 fórmulas MathML · conversão para TeX e alternativa';
	@override String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class _Translations$samples$vertical$pt extends Translations$samples$vertical$ko {
	_Translations$samples$vertical$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Escrita vertical japonesa (vertical-rl) + RTL';
	@override String get tag => 'Escrita vertical (E15)';
}

// Path: samples.mediaOverlay
class _Translations$samples$mediaOverlay$pt extends Translations$samples$mediaOverlay$ko {
	_Translations$samples$mediaOverlay$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Narração SMIL com destaque sincronizado ao áudio';
	@override String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class _Translations$samples$accessible$pt extends Translations$samples$accessible$ko {
	_Translations$samples$accessible$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'O\'Reilly · pontos de referência e sumário aninhado';
	@override String get tag => 'EPUB3 completo (E13)';
}

// Path: samples.cfi
class _Translations$samples$cfi$pt extends Translations$samples$cfi$ko {
	_Translations$samples$cfi$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'EPUB CFI · page-list com 7 itens';
	@override String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class _Translations$samples$fixedA4$pt extends Translations$samples$fixedA4$ko {
	_Translations$samples$fixedA4$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Layout fixo pré-paginado · A4 (794×1123), 3 páginas';
	@override String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class _Translations$highlight$colors$pt extends Translations$highlight$colors$ko {
	_Translations$highlight$colors$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get yellow => 'Amarelo';
	@override String get green => 'Verde';
	@override String get blue => 'Azul';
	@override String get pink => 'Rosa';
}

/// The flat map containing all translations for locale <pt>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Demo do open_epub',
			'common.previousPage' => 'Página anterior',
			'common.nextPage' => 'Próxima página',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Salvar',
			'common.close' => 'Fechar',
			'home.library.title' => 'Biblioteca de amostras EPUB3',
			'home.library.description' => 'Verifica RTL, MathML, escrita vertical, Media Overlay e CFI',
			'home.core.title' => 'Demo do núcleo 1.0',
			'home.highlight.title' => 'Demo de destaque',
			'home.highlight.description' => 'Selecionar texto → cor → destaque + anotação',
			'home.fixedLayout.title' => 'Demo de Fixed Layout A4',
			'home.fixedLayout.description' => 'Exibe um livro pré-paginado no tamanho A4 (794×1123)',
			'samples.nohoechan.subtitle' => 'EPUB2 real com texto refluível · 22 MB',
			'samples.nohoechan.tag' => 'EPUB2 · arquivo grande',
			'samples.wasteland.subtitle' => 'T.S. Eliot · EPUB3 básico (nav, CSS)',
			'samples.wasteland.tag' => 'EPUB3 básico',
			'samples.arabicRtl.subtitle' => 'Árabe · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'Virar páginas em RTL (E14)',
			'samples.mathml.subtitle' => '71 fórmulas MathML · conversão para TeX e alternativa',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => 'Escrita vertical japonesa (vertical-rl) + RTL',
			'samples.vertical.tag' => 'Escrita vertical (E15)',
			'samples.mediaOverlay.subtitle' => 'Narração SMIL com destaque sincronizado ao áudio',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · pontos de referência e sumário aninhado',
			'samples.accessible.tag' => 'EPUB3 completo (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list com 7 itens',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'Layout fixo pré-paginado · A4 (794×1123), 3 páginas',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => 'Este livro não tem Media Overlay',
			'reader.mediaOverlayLoadFailed' => 'Falha ao carregar o Media Overlay (SMIL)',
			'reader.audioFailed' => ({required Object error}) => 'Falha na reprodução do áudio (pode ser uma limitação do simulador): ${error}',
			'reader.localFixture' => ({required Object asset}) => 'Esta amostra (${asset}) é um arquivo de teste local que não está no repositório (excluído pelo .gitignore por tamanho ou licença).\nPara abri-la, coloque o arquivo EPUB em packages/open_epub/example/assets/ na sua cópia local e execute o app de novo.',
			'reader.mode' => 'Modo',
			'reader.swipe' => 'deslizar',
			'reader.scroll' => 'rolagem',
			'reader.vertical' => 'Vertical',
			'reader.fontSmaller' => 'Texto menor',
			'reader.fontLarger' => 'Texto maior',
			'reader.verticalScroll' => 'Rolagem vertical',
			'reader.rtlDirection' => 'Direção de página RTL',
			'reader.verticalWriting' => 'Escrita vertical',
			'reader.narration' => 'Narração (Media Overlay)',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · correções: ${count}',
			'core.recordHighlight' => 'recordHighlight() — evento toolUse',
			'core.recordBookmark' => 'recordBookmark() — evento toolUse',
			'core.assetLoadFailed' => ({required Object error}) => 'Falha ao carregar o asset: ${error}',
			'core.positionTokenTitle' => 'Token BookPosition v1',
			'core.eventLog' => 'Registro de eventos',
			'core.positionToken' => 'Token de posição',
			'core.waitingForEvents' => 'Aguardando eventos…',
			'highlight.list' => 'Destaques',
			'highlight.action' => 'Destacar',
			'highlight.openFailed' => ({required Object error}) => 'Não foi possível abrir o livro: ${error}',
			'highlight.selectFirst' => 'Selecione um texto primeiro.',
			'highlight.saved' => ({required Object color}) => 'Destaque salvo (${color})',
			'highlight.deleted' => 'Destaque excluído',
			'highlight.noteSaved' => 'Anotação salva',
			'highlight.hintSelected' => 'Toque em “Destacar” para colorir a seleção',
			'highlight.hintIdle' => 'Selecione um texto para ver o botão Destacar',
			'highlight.previousChapter' => 'Capítulo anterior',
			'highlight.nextChapter' => 'Próximo capítulo',
			'highlight.note' => 'Anotação',
			'highlight.noteHint' => 'Digite uma anotação',
			'highlight.noteOptional' => 'Anotação (opcional)',
			'highlight.colorLabel' => ({required Object color}) => 'Cor: ${color}',
			'highlight.count' => ({required Object count}) => 'Destaques: ${count}',
			'highlight.empty' => 'Nenhum destaque ainda.',
			'highlight.noteLine' => ({required Object note}) => 'Anotação: ${note}',
			'highlight.menu' => 'Menu do destaque',
			'highlight.editNote' => 'Editar anotação',
			'highlight.delete' => 'Excluir',
			'highlight.colors.yellow' => 'Amarelo',
			'highlight.colors.green' => 'Verde',
			'highlight.colors.blue' => 'Azul',
			'highlight.colors.pink' => 'Rosa',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => 'página ${index}/${total}',
			'epubReader.fileTooLarge' => 'O arquivo é grande demais para ser aberto.',
			'epubReader.networkFailure' => 'Não foi possível obter o livro por causa de um erro de rede.',
			'epubReader.corruptedFile' => 'Este EPUB está danificado ou não é válido.',
			'epubReader.openFailed' => 'Ocorreu um erro ao abrir o livro.',
			'epubReader.positionRestoreFailed' => 'Não foi possível encontrar sua última posição, então o livro começa do início',
			'epubReader.emptyBook' => 'Este livro não tem nada para exibir.',
			'epubReader.emptyPage' => 'Esta página não tem nada para exibir.',
			'epubReader.chapterLoadFailed' => 'Não foi possível carregar o texto.',
			'epubReader.pageLoadFailed' => 'Não foi possível carregar a página.',
			'epubReader.formula' => 'Fórmula',
			_ => null,
		};
	}
}
