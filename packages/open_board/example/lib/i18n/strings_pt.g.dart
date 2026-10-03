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
	@override late final _Translations$tools$pt tools = _Translations$tools$pt._(_root);
	@override late final _Translations$link$pt link = _Translations$link$pt._(_root);
	@override late final _Translations$drawing$pt drawing = _Translations$drawing$pt._(_root);
	@override late final _Translations$split$pt split = _Translations$split$pt._(_root);
	@override late final _Translations$epub$pt epub = _Translations$epub$pt._(_root);
}

// Path: app
class _Translations$app$pt extends Translations$app$ko {
	_Translations$app$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo do Open Board';
}

// Path: common
class _Translations$common$pt extends Translations$common$ko {
	_Translations$common$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get undo => 'Desfazer';
	@override String get redo => 'Refazer';
	@override String get clear => 'Limpar tudo';
	@override String get previousPage => 'Página anterior';
	@override String get nextPage => 'Próxima página';
	@override String get loading => 'Carregando…';
}

// Path: home
class _Translations$home$pt extends Translations$home$ko {
	_Translations$home$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$board$pt board = _Translations$home$board$pt._(_root);
	@override late final _Translations$home$split$pt split = _Translations$home$split$pt._(_root);
	@override late final _Translations$home$epub$pt epub = _Translations$home$epub$pt._(_root);
}

// Path: tools
class _Translations$tools$pt extends Translations$tools$ko {
	_Translations$tools$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get pen => 'Caneta';
	@override String get pencil => 'Lápis';
	@override String get marker => 'Marcador';
	@override String get highlighter => 'Marca-texto';
	@override String get fixedPen => 'Caneta fixa';
	@override String get uniformPen => 'Caneta uniforme';
	@override String get eraser => 'Borracha';
	@override String get text => 'Texto';
	@override String get shape => 'Forma';
	@override String get lasso => 'Laço';
	@override String get image => 'Imagem';
}

// Path: link
class _Translations$link$pt extends Translations$link$ko {
	_Translations$link$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get add => 'Adicionar link';
	@override String get edit => 'Editar link';
	@override String get remove => 'Remover link';
	@override String get done => 'Concluído';
	@override String get dialogTitle => 'Link';
	@override String get external => 'URL externa';
	@override String get internal => 'Página interna';
	@override String get pageNumber => 'Número da página';
	@override String get url => 'URL';
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'OK';
}

// Path: drawing
class _Translations$drawing$pt extends Translations$drawing$ko {
	_Translations$drawing$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get startRecording => 'Iniciar gravação';
	@override String get stopRecording => 'Parar gravação';
	@override String get replay => 'Reproduzir';
	@override String get stopReplay => 'Parar reprodução';
	@override String recording({required Object count}) => 'Gravando · eventos: ${count}';
	@override String replaying({required Object index, required Object total}) => 'Reproduzindo · ${index}/${total}';
	@override String ready({required Object count}) => 'Pronto para reproduzir · eventos: ${count}';
	@override String get noRecording => 'Nenhuma gravação';
	@override String page({required Object number}) => 'Página ${number}';
	@override late final _Translations$drawing$features$pt features = _Translations$drawing$features$pt._(_root);
	@override late final _Translations$drawing$recordingGuide$pt recordingGuide = _Translations$drawing$recordingGuide$pt._(_root);
	@override late final _Translations$drawing$multiPage$pt multiPage = _Translations$drawing$multiPage$pt._(_root);
}

// Path: split
class _Translations$split$pt extends Translations$split$ko {
	_Translations$split$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tela dividida — um único painel de ferramentas flutuante';
}

// Path: epub
class _Translations$epub$pt extends Translations$epub$ko {
	_Translations$epub$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get readingMode => 'Modo leitura';
	@override String get annotationMode => 'Modo anotação';
	@override String get info => 'As anotações são salvas por capítulo (spineHref) — open_epub 1.0 EpubReader com EpubViewController.';
	@override String get webNote => 'Na web, as anotações ficam salvas apenas durante esta sessão.';
	@override String sample({required Object title}) => 'Amostra: ${title}';
}

// Path: home.board
class _Translations$home$board$pt extends Translations$home$board$ko {
	_Translations$home$board$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo do quadro';
	@override String get description => 'Oito ferramentas de escrita, várias páginas, gravação e reprodução';
}

// Path: home.split
class _Translations$home$split$pt extends Translations$home$split$ko {
	_Translations$home$split$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de tela dividida';
	@override String get description => 'Duas áreas de escrita lado a lado com um único painel de ferramentas flutuante';
}

// Path: home.epub
class _Translations$home$epub$pt extends Translations$home$epub$ko {
	_Translations$home$epub$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Demo de anotação EPUB';
	@override String get description => 'Escrita à mão vinculada à página sobre o leitor open_epub (alterne entre leitura e escrita)';
}

// Path: drawing.features
class _Translations$drawing$features$pt extends Translations$drawing$features$ko {
	_Translations$drawing$features$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Recursos';
	@override List<String> get items => [
		'Ferramentas de escrita: caneta, lápis, marcador e caneta fixa',
		'Seis cores predefinidas',
		'Espessura do traço ajustável (0,5–10,0)',
		'Borracha para apagar traços',
		'Reconhecimento de formas (círculo, retângulo, linha)',
		'Seleção com laço para mover traços',
		'Ferramenta de texto para adicionar anotações',
		'Desfazer e refazer',
	];
}

// Path: drawing.recordingGuide
class _Translations$drawing$recordingGuide$pt extends Translations$drawing$recordingGuide$ko {
	_Translations$drawing$recordingGuide$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gravação e reprodução';
	@override List<String> get items => [
		'Toque no botão vermelho para começar a gravar',
		'Escreva, troque de página, aumente ou diminua o zoom: tudo é gravado',
		'Toque em parar para encerrar a gravação',
		'Toque em reproduzir para rever a sessão inteira',
		'Traços, trocas de página e mudanças de visualização são gravados',
	];
}

// Path: drawing.multiPage
class _Translations$drawing$multiPage$pt extends Translations$drawing$multiPage$ko {
	_Translations$drawing$multiPage$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Várias páginas';
	@override List<String> get items => [
		'Navegue entre as páginas com a barra de páginas acima',
		'Cada página tem seus próprios traços e histórico de desfazer',
		'ScribbleBookController gerencia todas as páginas',
		'ScribbleCacheManager cuida do cache e do salvamento',
		'Experimente escrever em várias páginas e alternar entre elas',
	];
	@override String get tip => 'Dica: escreva nesta página, depois em outra e volte. Seus traços continuam aqui.';
}

/// The flat map containing all translations for locale <pt>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Demo do Open Board',
			'common.undo' => 'Desfazer',
			'common.redo' => 'Refazer',
			'common.clear' => 'Limpar tudo',
			'common.previousPage' => 'Página anterior',
			'common.nextPage' => 'Próxima página',
			'common.loading' => 'Carregando…',
			'home.board.title' => 'Demo do quadro',
			'home.board.description' => 'Oito ferramentas de escrita, várias páginas, gravação e reprodução',
			'home.split.title' => 'Demo de tela dividida',
			'home.split.description' => 'Duas áreas de escrita lado a lado com um único painel de ferramentas flutuante',
			'home.epub.title' => 'Demo de anotação EPUB',
			'home.epub.description' => 'Escrita à mão vinculada à página sobre o leitor open_epub (alterne entre leitura e escrita)',
			'tools.pen' => 'Caneta',
			'tools.pencil' => 'Lápis',
			'tools.marker' => 'Marcador',
			'tools.highlighter' => 'Marca-texto',
			'tools.fixedPen' => 'Caneta fixa',
			'tools.uniformPen' => 'Caneta uniforme',
			'tools.eraser' => 'Borracha',
			'tools.text' => 'Texto',
			'tools.shape' => 'Forma',
			'tools.lasso' => 'Laço',
			'tools.image' => 'Imagem',
			'link.add' => 'Adicionar link',
			'link.edit' => 'Editar link',
			'link.remove' => 'Remover link',
			'link.done' => 'Concluído',
			'link.dialogTitle' => 'Link',
			'link.external' => 'URL externa',
			'link.internal' => 'Página interna',
			'link.pageNumber' => 'Número da página',
			'link.url' => 'URL',
			'link.cancel' => 'Cancelar',
			'link.confirm' => 'OK',
			'drawing.startRecording' => 'Iniciar gravação',
			'drawing.stopRecording' => 'Parar gravação',
			'drawing.replay' => 'Reproduzir',
			'drawing.stopReplay' => 'Parar reprodução',
			'drawing.recording' => ({required Object count}) => 'Gravando · eventos: ${count}',
			'drawing.replaying' => ({required Object index, required Object total}) => 'Reproduzindo · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => 'Pronto para reproduzir · eventos: ${count}',
			'drawing.noRecording' => 'Nenhuma gravação',
			'drawing.page' => ({required Object number}) => 'Página ${number}',
			'drawing.features.title' => 'Recursos',
			'drawing.features.items.0' => 'Ferramentas de escrita: caneta, lápis, marcador e caneta fixa',
			'drawing.features.items.1' => 'Seis cores predefinidas',
			'drawing.features.items.2' => 'Espessura do traço ajustável (0,5–10,0)',
			'drawing.features.items.3' => 'Borracha para apagar traços',
			'drawing.features.items.4' => 'Reconhecimento de formas (círculo, retângulo, linha)',
			'drawing.features.items.5' => 'Seleção com laço para mover traços',
			'drawing.features.items.6' => 'Ferramenta de texto para adicionar anotações',
			'drawing.features.items.7' => 'Desfazer e refazer',
			'drawing.recordingGuide.title' => 'Gravação e reprodução',
			'drawing.recordingGuide.items.0' => 'Toque no botão vermelho para começar a gravar',
			'drawing.recordingGuide.items.1' => 'Escreva, troque de página, aumente ou diminua o zoom: tudo é gravado',
			'drawing.recordingGuide.items.2' => 'Toque em parar para encerrar a gravação',
			'drawing.recordingGuide.items.3' => 'Toque em reproduzir para rever a sessão inteira',
			'drawing.recordingGuide.items.4' => 'Traços, trocas de página e mudanças de visualização são gravados',
			'drawing.multiPage.title' => 'Várias páginas',
			'drawing.multiPage.items.0' => 'Navegue entre as páginas com a barra de páginas acima',
			'drawing.multiPage.items.1' => 'Cada página tem seus próprios traços e histórico de desfazer',
			'drawing.multiPage.items.2' => 'ScribbleBookController gerencia todas as páginas',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager cuida do cache e do salvamento',
			'drawing.multiPage.items.4' => 'Experimente escrever em várias páginas e alternar entre elas',
			'drawing.multiPage.tip' => 'Dica: escreva nesta página, depois em outra e volte. Seus traços continuam aqui.',
			'split.title' => 'Tela dividida — um único painel de ferramentas flutuante',
			'epub.readingMode' => 'Modo leitura',
			'epub.annotationMode' => 'Modo anotação',
			'epub.info' => 'As anotações são salvas por capítulo (spineHref) — open_epub 1.0 EpubReader com EpubViewController.',
			'epub.webNote' => 'Na web, as anotações ficam salvas apenas durante esta sessão.',
			'epub.sample' => ({required Object title}) => 'Amostra: ${title}',
			_ => null,
		};
	}
}
