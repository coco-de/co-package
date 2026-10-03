///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsKo = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ko,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ko>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$ko app = Translations$app$ko.internal(_root);
	late final Translations$common$ko common = Translations$common$ko.internal(_root);
	late final Translations$home$ko home = Translations$home$ko.internal(_root);
	late final Translations$tools$ko tools = Translations$tools$ko.internal(_root);
	late final Translations$link$ko link = Translations$link$ko.internal(_root);
	late final Translations$drawing$ko drawing = Translations$drawing$ko.internal(_root);
	late final Translations$split$ko split = Translations$split$ko.internal(_root);
	late final Translations$epub$ko epub = Translations$epub$ko.internal(_root);
}

// Path: app
class Translations$app$ko {
	Translations$app$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'Open Board 데모'
	String get title => 'Open Board 데모';
}

// Path: common
class Translations$common$ko {
	Translations$common$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '실행 취소'
	String get undo => '실행 취소';

	/// ko: '다시 실행'
	String get redo => '다시 실행';

	/// ko: '모두 지우기'
	String get clear => '모두 지우기';

	/// ko: '이전 페이지'
	String get previousPage => '이전 페이지';

	/// ko: '다음 페이지'
	String get nextPage => '다음 페이지';

	/// ko: '불러오는 중…'
	String get loading => '불러오는 중…';
}

// Path: home
class Translations$home$ko {
	Translations$home$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$home$board$ko board = Translations$home$board$ko.internal(_root);
	late final Translations$home$split$ko split = Translations$home$split$ko.internal(_root);
	late final Translations$home$epub$ko epub = Translations$home$epub$ko.internal(_root);
}

// Path: tools
class Translations$tools$ko {
	Translations$tools$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '펜'
	String get pen => '펜';

	/// ko: '연필'
	String get pencil => '연필';

	/// ko: '마커'
	String get marker => '마커';

	/// ko: '형광펜'
	String get highlighter => '형광펜';

	/// ko: '고정 펜'
	String get fixedPen => '고정 펜';

	/// ko: '균일 펜'
	String get uniformPen => '균일 펜';

	/// ko: '지우개'
	String get eraser => '지우개';

	/// ko: '텍스트'
	String get text => '텍스트';

	/// ko: '도형'
	String get shape => '도형';

	/// ko: '올가미'
	String get lasso => '올가미';

	/// ko: '이미지'
	String get image => '이미지';
}

// Path: link
class Translations$link$ko {
	Translations$link$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '링크 추가'
	String get add => '링크 추가';

	/// ko: '링크 편집'
	String get edit => '링크 편집';

	/// ko: '링크 삭제'
	String get remove => '링크 삭제';

	/// ko: '완료'
	String get done => '완료';

	/// ko: '링크 입력'
	String get dialogTitle => '링크 입력';

	/// ko: '외부 URL'
	String get external => '외부 URL';

	/// ko: '내부 페이지'
	String get internal => '내부 페이지';

	/// ko: '페이지 번호'
	String get pageNumber => '페이지 번호';

	/// ko: 'URL'
	String get url => 'URL';

	/// ko: '취소'
	String get cancel => '취소';

	/// ko: '확인'
	String get confirm => '확인';
}

// Path: drawing
class Translations$drawing$ko {
	Translations$drawing$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '녹화 시작'
	String get startRecording => '녹화 시작';

	/// ko: '녹화 중지'
	String get stopRecording => '녹화 중지';

	/// ko: '재생'
	String get replay => '재생';

	/// ko: '재생 중지'
	String get stopReplay => '재생 중지';

	/// ko: '녹화 중 · 이벤트 {count}개'
	String recording({required Object count}) => '녹화 중 · 이벤트 ${count}개';

	/// ko: '재생 중 · {index}/{total}'
	String replaying({required Object index, required Object total}) => '재생 중 · ${index}/${total}';

	/// ko: '재생 준비 · 이벤트 {count}개'
	String ready({required Object count}) => '재생 준비 · 이벤트 ${count}개';

	/// ko: '녹화 없음'
	String get noRecording => '녹화 없음';

	/// ko: '{number} 페이지'
	String page({required Object number}) => '${number} 페이지';

	late final Translations$drawing$features$ko features = Translations$drawing$features$ko.internal(_root);
	late final Translations$drawing$recordingGuide$ko recordingGuide = Translations$drawing$recordingGuide$ko.internal(_root);
	late final Translations$drawing$multiPage$ko multiPage = Translations$drawing$multiPage$ko.internal(_root);
}

// Path: split
class Translations$split$ko {
	Translations$split$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '분할 필기 — 하나의 플로팅 도구'
	String get title => '분할 필기 — 하나의 플로팅 도구';
}

// Path: epub
class Translations$epub$ko {
	Translations$epub$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '읽기 모드'
	String get readingMode => '읽기 모드';

	/// ko: '필기 모드'
	String get annotationMode => '필기 모드';

	/// ko: '필기는 챕터(spineHref) 기준으로 저장됩니다 — open_epub 1.0 EpubReader + EpubViewController 연동.'
	String get info => '필기는 챕터(spineHref) 기준으로 저장됩니다 — open_epub 1.0 EpubReader + EpubViewController 연동.';

	/// ko: '웹에서는 세션 안에서만 필기가 유지됩니다.'
	String get webNote => '웹에서는 세션 안에서만 필기가 유지됩니다.';

	/// ko: '샘플: {title}'
	String sample({required Object title}) => '샘플: ${title}';
}

// Path: home.board
class Translations$home$board$ko {
	Translations$home$board$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '보드 데모'
	String get title => '보드 데모';

	/// ko: '필기 도구 8종, 다중 페이지, 녹화/리플레이 데모'
	String get description => '필기 도구 8종, 다중 페이지, 녹화/리플레이 데모';
}

// Path: home.split
class Translations$home$split$ko {
	Translations$home$split$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '분할 필기 데모'
	String get title => '분할 필기 데모';

	/// ko: '좌우 분할 필기 + 플로팅 필기 도구 패널 데모'
	String get description => '좌우 분할 필기 + 플로팅 필기 도구 패널 데모';
}

// Path: home.epub
class Translations$home$epub$ko {
	Translations$home$epub$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'EPUB 주석 데모'
	String get title => 'EPUB 주석 데모';

	/// ko: 'open_epub 리더 위에 페이지 연동 필기 (읽기/필기 모드 토글)'
	String get description => 'open_epub 리더 위에 페이지 연동 필기 (읽기/필기 모드 토글)';
}

// Path: drawing.features
class Translations$drawing$features$ko {
	Translations$drawing$features$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기능'
	String get title => '기능';

	List<String> get items => [
		'펜 · 연필 · 마커 · 고정 펜 필기 도구',
		'기본 색상 6가지',
		'선 굵기 조절 (0.5–10.0)',
		'획을 지우는 지우개',
		'도형 인식 (원 · 사각형 · 직선)',
		'올가미로 획을 골라 옮기기',
		'텍스트 메모를 넣는 텍스트 도구',
		'실행 취소 / 다시 실행',
	];
}

// Path: drawing.recordingGuide
class Translations$drawing$recordingGuide$ko {
	Translations$drawing$recordingGuide$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '녹화와 재생'
	String get title => '녹화와 재생';

	List<String> get items => [
		'빨간 녹화 버튼을 누르면 녹화가 시작됩니다',
		'그리기 · 페이지 이동 · 확대와 축소가 모두 기록됩니다',
		'정지 버튼을 누르면 녹화가 끝납니다',
		'재생 버튼을 누르면 전체 과정을 다시 봅니다',
		'획 · 페이지 전환 · 화면 이동이 기록됩니다',
	];
}

// Path: drawing.multiPage
class Translations$drawing$multiPage$ko {
	Translations$drawing$multiPage$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '여러 페이지'
	String get title => '여러 페이지';

	List<String> get items => [
		'위쪽 페이지 막대로 페이지를 오갑니다',
		'페이지마다 획과 실행 취소 기록이 따로 있습니다',
		'ScribbleBookController 가 모든 페이지를 관리합니다',
		'ScribbleCacheManager 가 캐시와 저장을 맡습니다',
		'여러 페이지에 그려 보고 오가며 확인해 보세요',
	];

	/// ko: '팁: 이 페이지에 그린 뒤 다른 페이지에도 그리고 다시 돌아와 보세요. 그린 획이 그대로 남아 있습니다.'
	String get tip => '팁: 이 페이지에 그린 뒤 다른 페이지에도 그리고 다시 돌아와 보세요. 그린 획이 그대로 남아 있습니다.';
}

/// The flat map containing all translations for locale <ko>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Open Board 데모',
			'common.undo' => '실행 취소',
			'common.redo' => '다시 실행',
			'common.clear' => '모두 지우기',
			'common.previousPage' => '이전 페이지',
			'common.nextPage' => '다음 페이지',
			'common.loading' => '불러오는 중…',
			'home.board.title' => '보드 데모',
			'home.board.description' => '필기 도구 8종, 다중 페이지, 녹화/리플레이 데모',
			'home.split.title' => '분할 필기 데모',
			'home.split.description' => '좌우 분할 필기 + 플로팅 필기 도구 패널 데모',
			'home.epub.title' => 'EPUB 주석 데모',
			'home.epub.description' => 'open_epub 리더 위에 페이지 연동 필기 (읽기/필기 모드 토글)',
			'tools.pen' => '펜',
			'tools.pencil' => '연필',
			'tools.marker' => '마커',
			'tools.highlighter' => '형광펜',
			'tools.fixedPen' => '고정 펜',
			'tools.uniformPen' => '균일 펜',
			'tools.eraser' => '지우개',
			'tools.text' => '텍스트',
			'tools.shape' => '도형',
			'tools.lasso' => '올가미',
			'tools.image' => '이미지',
			'link.add' => '링크 추가',
			'link.edit' => '링크 편집',
			'link.remove' => '링크 삭제',
			'link.done' => '완료',
			'link.dialogTitle' => '링크 입력',
			'link.external' => '외부 URL',
			'link.internal' => '내부 페이지',
			'link.pageNumber' => '페이지 번호',
			'link.url' => 'URL',
			'link.cancel' => '취소',
			'link.confirm' => '확인',
			'drawing.startRecording' => '녹화 시작',
			'drawing.stopRecording' => '녹화 중지',
			'drawing.replay' => '재생',
			'drawing.stopReplay' => '재생 중지',
			'drawing.recording' => ({required Object count}) => '녹화 중 · 이벤트 ${count}개',
			'drawing.replaying' => ({required Object index, required Object total}) => '재생 중 · ${index}/${total}',
			'drawing.ready' => ({required Object count}) => '재생 준비 · 이벤트 ${count}개',
			'drawing.noRecording' => '녹화 없음',
			'drawing.page' => ({required Object number}) => '${number} 페이지',
			'drawing.features.title' => '기능',
			'drawing.features.items.0' => '펜 · 연필 · 마커 · 고정 펜 필기 도구',
			'drawing.features.items.1' => '기본 색상 6가지',
			'drawing.features.items.2' => '선 굵기 조절 (0.5–10.0)',
			'drawing.features.items.3' => '획을 지우는 지우개',
			'drawing.features.items.4' => '도형 인식 (원 · 사각형 · 직선)',
			'drawing.features.items.5' => '올가미로 획을 골라 옮기기',
			'drawing.features.items.6' => '텍스트 메모를 넣는 텍스트 도구',
			'drawing.features.items.7' => '실행 취소 / 다시 실행',
			'drawing.recordingGuide.title' => '녹화와 재생',
			'drawing.recordingGuide.items.0' => '빨간 녹화 버튼을 누르면 녹화가 시작됩니다',
			'drawing.recordingGuide.items.1' => '그리기 · 페이지 이동 · 확대와 축소가 모두 기록됩니다',
			'drawing.recordingGuide.items.2' => '정지 버튼을 누르면 녹화가 끝납니다',
			'drawing.recordingGuide.items.3' => '재생 버튼을 누르면 전체 과정을 다시 봅니다',
			'drawing.recordingGuide.items.4' => '획 · 페이지 전환 · 화면 이동이 기록됩니다',
			'drawing.multiPage.title' => '여러 페이지',
			'drawing.multiPage.items.0' => '위쪽 페이지 막대로 페이지를 오갑니다',
			'drawing.multiPage.items.1' => '페이지마다 획과 실행 취소 기록이 따로 있습니다',
			'drawing.multiPage.items.2' => 'ScribbleBookController 가 모든 페이지를 관리합니다',
			'drawing.multiPage.items.3' => 'ScribbleCacheManager 가 캐시와 저장을 맡습니다',
			'drawing.multiPage.items.4' => '여러 페이지에 그려 보고 오가며 확인해 보세요',
			'drawing.multiPage.tip' => '팁: 이 페이지에 그린 뒤 다른 페이지에도 그리고 다시 돌아와 보세요. 그린 획이 그대로 남아 있습니다.',
			'split.title' => '분할 필기 — 하나의 플로팅 도구',
			'epub.readingMode' => '읽기 모드',
			'epub.annotationMode' => '필기 모드',
			'epub.info' => '필기는 챕터(spineHref) 기준으로 저장됩니다 — open_epub 1.0 EpubReader + EpubViewController 연동.',
			'epub.webNote' => '웹에서는 세션 안에서만 필기가 유지됩니다.',
			'epub.sample' => ({required Object title}) => '샘플: ${title}',
			_ => null,
		};
	}
}
