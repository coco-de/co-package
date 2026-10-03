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
	late final Translations$samples$ko samples = Translations$samples$ko.internal(_root);
	late final Translations$reader$ko reader = Translations$reader$ko.internal(_root);
	late final Translations$core$ko core = Translations$core$ko.internal(_root);
	late final Translations$highlight$ko highlight = Translations$highlight$ko.internal(_root);
	late final Translations$fixedLayout$ko fixedLayout = Translations$fixedLayout$ko.internal(_root);
	late final Translations$epubReader$ko epubReader = Translations$epubReader$ko.internal(_root);
}

// Path: app
class Translations$app$ko {
	Translations$app$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'open_epub 데모'
	String get title => 'open_epub 데모';
}

// Path: common
class Translations$common$ko {
	Translations$common$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '이전 페이지'
	String get previousPage => '이전 페이지';

	/// ko: '다음 페이지'
	String get nextPage => '다음 페이지';

	/// ko: '취소'
	String get cancel => '취소';

	/// ko: '저장'
	String get save => '저장';

	/// ko: '닫기'
	String get close => '닫기';
}

// Path: home
class Translations$home$ko {
	Translations$home$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$home$library$ko library = Translations$home$library$ko.internal(_root);
	late final Translations$home$core$ko core = Translations$home$core$ko.internal(_root);
	late final Translations$home$highlight$ko highlight = Translations$home$highlight$ko.internal(_root);
	late final Translations$home$fixedLayout$ko fixedLayout = Translations$home$fixedLayout$ko.internal(_root);
}

// Path: samples
class Translations$samples$ko {
	Translations$samples$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$samples$nohoechan$ko nohoechan = Translations$samples$nohoechan$ko.internal(_root);
	late final Translations$samples$wasteland$ko wasteland = Translations$samples$wasteland$ko.internal(_root);
	late final Translations$samples$arabicRtl$ko arabicRtl = Translations$samples$arabicRtl$ko.internal(_root);
	late final Translations$samples$mathml$ko mathml = Translations$samples$mathml$ko.internal(_root);
	late final Translations$samples$vertical$ko vertical = Translations$samples$vertical$ko.internal(_root);
	late final Translations$samples$mediaOverlay$ko mediaOverlay = Translations$samples$mediaOverlay$ko.internal(_root);
	late final Translations$samples$accessible$ko accessible = Translations$samples$accessible$ko.internal(_root);
	late final Translations$samples$cfi$ko cfi = Translations$samples$cfi$ko.internal(_root);
	late final Translations$samples$fixedA4$ko fixedA4 = Translations$samples$fixedA4$ko.internal(_root);
}

// Path: reader
class Translations$reader$ko {
	Translations$reader$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '이 책에는 Media Overlay가 없습니다'
	String get noMediaOverlay => '이 책에는 Media Overlay가 없습니다';

	/// ko: 'Media Overlay(SMIL) 로드 실패'
	String get mediaOverlayLoadFailed => 'Media Overlay(SMIL) 로드 실패';

	/// ko: '오디오 재생 실패(시뮬레이터 제약일 수 있음): {error}'
	String audioFailed({required Object error}) => '오디오 재생 실패(시뮬레이터 제약일 수 있음): ${error}';

	/// ko: '이 샘플({asset})은 저장소에 포함되지 않은 로컬 전용 테스트 픽스처입니다(대용량/라이선스 사유로 gitignore 처리됨). 로컬 개발 환경에서 해당 EPUB 파일을 packages/open_epub/example/assets/ 에 배치한 뒤 다시 실행해 주세요.'
	String localFixture({required Object asset}) => '이 샘플(${asset})은 저장소에 포함되지 않은 로컬 전용 테스트 픽스처입니다(대용량/라이선스 사유로 gitignore 처리됨).\n로컬 개발 환경에서 해당 EPUB 파일을 packages/open_epub/example/assets/ 에 배치한 뒤 다시 실행해 주세요.';

	/// ko: '모드'
	String get mode => '모드';

	/// ko: '스와이프'
	String get swipe => '스와이프';

	/// ko: '스크롤'
	String get scroll => '스크롤';

	/// ko: '세로'
	String get vertical => '세로';

	/// ko: '글자 작게'
	String get fontSmaller => '글자 작게';

	/// ko: '글자 크게'
	String get fontLarger => '글자 크게';

	/// ko: '세로 스크롤'
	String get verticalScroll => '세로 스크롤';

	/// ko: 'RTL 넘김 방향'
	String get rtlDirection => 'RTL 넘김 방향';

	/// ko: '세로쓰기'
	String get verticalWriting => '세로쓰기';

	/// ko: '낭독(Media Overlay)'
	String get narration => '낭독(Media Overlay)';
}

// Path: core
class Translations$core$ko {
	Translations$core$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'layout: {layout} · 보정 {count}건'
	String layoutPatches({required Object layout, required Object count}) => 'layout: ${layout} · 보정 ${count}건';

	/// ko: 'recordHighlight() — toolUse 이벤트'
	String get recordHighlight => 'recordHighlight() — toolUse 이벤트';

	/// ko: 'recordBookmark() — toolUse 이벤트'
	String get recordBookmark => 'recordBookmark() — toolUse 이벤트';

	/// ko: 'asset 로드 실패: {error}'
	String assetLoadFailed({required Object error}) => 'asset 로드 실패: ${error}';

	/// ko: 'BookPosition v1 토큰'
	String get positionTokenTitle => 'BookPosition v1 토큰';

	/// ko: '이벤트 로그'
	String get eventLog => '이벤트 로그';

	/// ko: '위치 토큰'
	String get positionToken => '위치 토큰';

	/// ko: '이벤트 대기 중...'
	String get waitingForEvents => '이벤트 대기 중...';
}

// Path: highlight
class Translations$highlight$ko {
	Translations$highlight$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '하이라이트 목록'
	String get list => '하이라이트 목록';

	/// ko: '하이라이트'
	String get action => '하이라이트';

	/// ko: '책을 열 수 없습니다: {error}'
	String openFailed({required Object error}) => '책을 열 수 없습니다: ${error}';

	/// ko: '먼저 본문 텍스트를 선택하세요.'
	String get selectFirst => '먼저 본문 텍스트를 선택하세요.';

	/// ko: '하이라이트 저장됨 ({color})'
	String saved({required Object color}) => '하이라이트 저장됨 (${color})';

	/// ko: '하이라이트 삭제됨'
	String get deleted => '하이라이트 삭제됨';

	/// ko: '메모 저장됨'
	String get noteSaved => '메모 저장됨';

	/// ko: '"하이라이트" 버튼을 눌러 색을 칠하세요'
	String get hintSelected => '"하이라이트" 버튼을 눌러 색을 칠하세요';

	/// ko: '본문 텍스트를 선택하면 하이라이트 버튼이 나타납니다'
	String get hintIdle => '본문 텍스트를 선택하면 하이라이트 버튼이 나타납니다';

	/// ko: '이전 챕터'
	String get previousChapter => '이전 챕터';

	/// ko: '다음 챕터'
	String get nextChapter => '다음 챕터';

	/// ko: '메모'
	String get note => '메모';

	/// ko: '메모를 입력하세요'
	String get noteHint => '메모를 입력하세요';

	/// ko: '메모 (선택)'
	String get noteOptional => '메모 (선택)';

	/// ko: '색상 {color}'
	String colorLabel({required Object color}) => '색상 ${color}';

	/// ko: '하이라이트 {count}개'
	String count({required Object count}) => '하이라이트 ${count}개';

	/// ko: '저장된 하이라이트가 없습니다.'
	String get empty => '저장된 하이라이트가 없습니다.';

	/// ko: '메모: {note}'
	String noteLine({required Object note}) => '메모: ${note}';

	/// ko: '하이라이트 메뉴'
	String get menu => '하이라이트 메뉴';

	/// ko: '메모 편집'
	String get editNote => '메모 편집';

	/// ko: '삭제'
	String get delete => '삭제';

	late final Translations$highlight$colors$ko colors = Translations$highlight$colors$ko.internal(_root);
}

// Path: fixedLayout
class Translations$fixedLayout$ko {
	Translations$fixedLayout$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '{index}/{total}쪽'
	String pageOf({required Object index, required Object total}) => '${index}/${total}쪽';
}

// Path: epubReader
class Translations$epubReader$ko {
	Translations$epubReader$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '파일이 너무 커서 열 수 없습니다.'
	String get fileTooLarge => '파일이 너무 커서 열 수 없습니다.';

	/// ko: '네트워크 오류로 책을 가져오지 못했습니다.'
	String get networkFailure => '네트워크 오류로 책을 가져오지 못했습니다.';

	/// ko: '손상되었거나 올바르지 않은 EPUB입니다.'
	String get corruptedFile => '손상되었거나 올바르지 않은 EPUB입니다.';

	/// ko: '책을 여는 중 오류가 발생했습니다.'
	String get openFailed => '책을 여는 중 오류가 발생했습니다.';

	/// ko: '마지막 위치를 찾을 수 없어 처음부터 표시합니다'
	String get positionRestoreFailed => '마지막 위치를 찾을 수 없어 처음부터 표시합니다';

	/// ko: '이 책에는 표시할 내용이 없습니다.'
	String get emptyBook => '이 책에는 표시할 내용이 없습니다.';

	/// ko: '이 페이지에는 표시할 내용이 없습니다.'
	String get emptyPage => '이 페이지에는 표시할 내용이 없습니다.';

	/// ko: '본문을 불러올 수 없습니다.'
	String get chapterLoadFailed => '본문을 불러올 수 없습니다.';

	/// ko: '페이지를 불러올 수 없습니다.'
	String get pageLoadFailed => '페이지를 불러올 수 없습니다.';

	/// ko: '수식'
	String get formula => '수식';
}

// Path: home.library
class Translations$home$library$ko {
	Translations$home$library$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'EPUB3 샘플 라이브러리'
	String get title => 'EPUB3 샘플 라이브러리';

	/// ko: 'RTL·MathML·세로쓰기·Media Overlay·CFI 기능 검증'
	String get description => 'RTL·MathML·세로쓰기·Media Overlay·CFI 기능 검증';
}

// Path: home.core
class Translations$home$core$ko {
	Translations$home$core$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '1.0 코어 데모'
	String get title => '1.0 코어 데모';
}

// Path: home.highlight
class Translations$home$highlight$ko {
	Translations$home$highlight$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '하이라이트 데모'
	String get title => '하이라이트 데모';

	/// ko: '텍스트 선택 → 색상 → 하이라이트 + 메모'
	String get description => '텍스트 선택 → 색상 → 하이라이트 + 메모';
}

// Path: home.fixedLayout
class Translations$home$fixedLayout$ko {
	Translations$home$fixedLayout$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'Fixed Layout A4 데모'
	String get title => 'Fixed Layout A4 데모';

	/// ko: 'pre-paginated 본문을 A4(794×1123) 크기로 렌더'
	String get description => 'pre-paginated 본문을 A4(794×1123) 크기로 렌더';
}

// Path: samples.nohoechan
class Translations$samples$nohoechan$ko {
	Translations$samples$nohoechan$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '실제 EPUB2 리플로우 · 22MB 대용량'
	String get subtitle => '실제 EPUB2 리플로우 · 22MB 대용량';

	/// ko: 'EPUB2 · 대용량'
	String get tag => 'EPUB2 · 대용량';
}

// Path: samples.wasteland
class Translations$samples$wasteland$ko {
	Translations$samples$wasteland$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'T.S. Eliot · EPUB3 기본(nav·CSS)'
	String get subtitle => 'T.S. Eliot · EPUB3 기본(nav·CSS)';

	/// ko: 'EPUB3 기본'
	String get tag => 'EPUB3 기본';
}

// Path: samples.arabicRtl
class Translations$samples$arabicRtl$ko {
	Translations$samples$arabicRtl$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '아랍어 · page-progression-direction=rtl'
	String get subtitle => '아랍어 · page-progression-direction=rtl';

	/// ko: 'RTL 넘김 (E14)'
	String get tag => 'RTL 넘김 (E14)';
}

// Path: samples.mathml
class Translations$samples$mathml$ko {
	Translations$samples$mathml$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'MathML 71수식 · TeX 변환/폴백'
	String get subtitle => 'MathML 71수식 · TeX 변환/폴백';

	/// ko: 'MathML (E14)'
	String get tag => 'MathML (E14)';
}

// Path: samples.vertical
class Translations$samples$vertical$ko {
	Translations$samples$vertical$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '일본어 세로쓰기(vertical-rl) + RTL'
	String get subtitle => '일본어 세로쓰기(vertical-rl) + RTL';

	/// ko: '세로쓰기 (E15)'
	String get tag => '세로쓰기 (E15)';
}

// Path: samples.mediaOverlay
class Translations$samples$mediaOverlay$ko {
	Translations$samples$mediaOverlay$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'SMIL 낭독 + 오디오 동기 하이라이트'
	String get subtitle => 'SMIL 낭독 + 오디오 동기 하이라이트';

	/// ko: 'Media Overlay (E15)'
	String get tag => 'Media Overlay (E15)';
}

// Path: samples.accessible
class Translations$samples$accessible$ko {
	Translations$samples$accessible$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'O'Reilly · landmarks·목차 계층'
	String get subtitle => 'O\'Reilly · landmarks·목차 계층';

	/// ko: '종합 EPUB3 (E13)'
	String get tag => '종합 EPUB3 (E13)';
}

// Path: samples.cfi
class Translations$samples$cfi$ko {
	Translations$samples$cfi$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'EPUB CFI · page-list 7'
	String get subtitle => 'EPUB CFI · page-list 7';

	/// ko: 'CFI (E12)'
	String get tag => 'CFI (E12)';
}

// Path: samples.fixedA4
class Translations$samples$fixedA4$ko {
	Translations$samples$fixedA4$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'pre-paginated 고정 레이아웃 · A4(794×1123) 3쪽'
	String get subtitle => 'pre-paginated 고정 레이아웃 · A4(794×1123) 3쪽';

	/// ko: 'Fixed Layout (F3)'
	String get tag => 'Fixed Layout (F3)';
}

// Path: highlight.colors
class Translations$highlight$colors$ko {
	Translations$highlight$colors$ko.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '노랑'
	String get yellow => '노랑';

	/// ko: '초록'
	String get green => '초록';

	/// ko: '파랑'
	String get blue => '파랑';

	/// ko: '분홍'
	String get pink => '분홍';
}

/// The flat map containing all translations for locale <ko>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'open_epub 데모',
			'common.previousPage' => '이전 페이지',
			'common.nextPage' => '다음 페이지',
			'common.cancel' => '취소',
			'common.save' => '저장',
			'common.close' => '닫기',
			'home.library.title' => 'EPUB3 샘플 라이브러리',
			'home.library.description' => 'RTL·MathML·세로쓰기·Media Overlay·CFI 기능 검증',
			'home.core.title' => '1.0 코어 데모',
			'home.highlight.title' => '하이라이트 데모',
			'home.highlight.description' => '텍스트 선택 → 색상 → 하이라이트 + 메모',
			'home.fixedLayout.title' => 'Fixed Layout A4 데모',
			'home.fixedLayout.description' => 'pre-paginated 본문을 A4(794×1123) 크기로 렌더',
			'samples.nohoechan.subtitle' => '실제 EPUB2 리플로우 · 22MB 대용량',
			'samples.nohoechan.tag' => 'EPUB2 · 대용량',
			'samples.wasteland.subtitle' => 'T.S. Eliot · EPUB3 기본(nav·CSS)',
			'samples.wasteland.tag' => 'EPUB3 기본',
			'samples.arabicRtl.subtitle' => '아랍어 · page-progression-direction=rtl',
			'samples.arabicRtl.tag' => 'RTL 넘김 (E14)',
			'samples.mathml.subtitle' => 'MathML 71수식 · TeX 변환/폴백',
			'samples.mathml.tag' => 'MathML (E14)',
			'samples.vertical.subtitle' => '일본어 세로쓰기(vertical-rl) + RTL',
			'samples.vertical.tag' => '세로쓰기 (E15)',
			'samples.mediaOverlay.subtitle' => 'SMIL 낭독 + 오디오 동기 하이라이트',
			'samples.mediaOverlay.tag' => 'Media Overlay (E15)',
			'samples.accessible.subtitle' => 'O\'Reilly · landmarks·목차 계층',
			'samples.accessible.tag' => '종합 EPUB3 (E13)',
			'samples.cfi.subtitle' => 'EPUB CFI · page-list 7',
			'samples.cfi.tag' => 'CFI (E12)',
			'samples.fixedA4.subtitle' => 'pre-paginated 고정 레이아웃 · A4(794×1123) 3쪽',
			'samples.fixedA4.tag' => 'Fixed Layout (F3)',
			'reader.noMediaOverlay' => '이 책에는 Media Overlay가 없습니다',
			'reader.mediaOverlayLoadFailed' => 'Media Overlay(SMIL) 로드 실패',
			'reader.audioFailed' => ({required Object error}) => '오디오 재생 실패(시뮬레이터 제약일 수 있음): ${error}',
			'reader.localFixture' => ({required Object asset}) => '이 샘플(${asset})은 저장소에 포함되지 않은 로컬 전용 테스트 픽스처입니다(대용량/라이선스 사유로 gitignore 처리됨).\n로컬 개발 환경에서 해당 EPUB 파일을 packages/open_epub/example/assets/ 에 배치한 뒤 다시 실행해 주세요.',
			'reader.mode' => '모드',
			'reader.swipe' => '스와이프',
			'reader.scroll' => '스크롤',
			'reader.vertical' => '세로',
			'reader.fontSmaller' => '글자 작게',
			'reader.fontLarger' => '글자 크게',
			'reader.verticalScroll' => '세로 스크롤',
			'reader.rtlDirection' => 'RTL 넘김 방향',
			'reader.verticalWriting' => '세로쓰기',
			'reader.narration' => '낭독(Media Overlay)',
			'core.layoutPatches' => ({required Object layout, required Object count}) => 'layout: ${layout} · 보정 ${count}건',
			'core.recordHighlight' => 'recordHighlight() — toolUse 이벤트',
			'core.recordBookmark' => 'recordBookmark() — toolUse 이벤트',
			'core.assetLoadFailed' => ({required Object error}) => 'asset 로드 실패: ${error}',
			'core.positionTokenTitle' => 'BookPosition v1 토큰',
			'core.eventLog' => '이벤트 로그',
			'core.positionToken' => '위치 토큰',
			'core.waitingForEvents' => '이벤트 대기 중...',
			'highlight.list' => '하이라이트 목록',
			'highlight.action' => '하이라이트',
			'highlight.openFailed' => ({required Object error}) => '책을 열 수 없습니다: ${error}',
			'highlight.selectFirst' => '먼저 본문 텍스트를 선택하세요.',
			'highlight.saved' => ({required Object color}) => '하이라이트 저장됨 (${color})',
			'highlight.deleted' => '하이라이트 삭제됨',
			'highlight.noteSaved' => '메모 저장됨',
			'highlight.hintSelected' => '"하이라이트" 버튼을 눌러 색을 칠하세요',
			'highlight.hintIdle' => '본문 텍스트를 선택하면 하이라이트 버튼이 나타납니다',
			'highlight.previousChapter' => '이전 챕터',
			'highlight.nextChapter' => '다음 챕터',
			'highlight.note' => '메모',
			'highlight.noteHint' => '메모를 입력하세요',
			'highlight.noteOptional' => '메모 (선택)',
			'highlight.colorLabel' => ({required Object color}) => '색상 ${color}',
			'highlight.count' => ({required Object count}) => '하이라이트 ${count}개',
			'highlight.empty' => '저장된 하이라이트가 없습니다.',
			'highlight.noteLine' => ({required Object note}) => '메모: ${note}',
			'highlight.menu' => '하이라이트 메뉴',
			'highlight.editNote' => '메모 편집',
			'highlight.delete' => '삭제',
			'highlight.colors.yellow' => '노랑',
			'highlight.colors.green' => '초록',
			'highlight.colors.blue' => '파랑',
			'highlight.colors.pink' => '분홍',
			'fixedLayout.pageOf' => ({required Object index, required Object total}) => '${index}/${total}쪽',
			'epubReader.fileTooLarge' => '파일이 너무 커서 열 수 없습니다.',
			'epubReader.networkFailure' => '네트워크 오류로 책을 가져오지 못했습니다.',
			'epubReader.corruptedFile' => '손상되었거나 올바르지 않은 EPUB입니다.',
			'epubReader.openFailed' => '책을 여는 중 오류가 발생했습니다.',
			'epubReader.positionRestoreFailed' => '마지막 위치를 찾을 수 없어 처음부터 표시합니다',
			'epubReader.emptyBook' => '이 책에는 표시할 내용이 없습니다.',
			'epubReader.emptyPage' => '이 페이지에는 표시할 내용이 없습니다.',
			'epubReader.chapterLoadFailed' => '본문을 불러올 수 없습니다.',
			'epubReader.pageLoadFailed' => '페이지를 불러올 수 없습니다.',
			'epubReader.formula' => '수식',
			_ => null,
		};
	}
}
