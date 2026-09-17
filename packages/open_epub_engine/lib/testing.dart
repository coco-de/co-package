/// open_epub_engine 테스트 지원 라이브러리.
///
/// 메모리에서 최소 EPUB 2/3 ZIP 컨테이너를 생성하는 픽스처를 제공한다. 엔진 테스트와
/// open_epub(Flutter) 테스트가 공유하는 단일 출처다(S10.5). 프로덕션 API(메인 배럴
/// open_epub_engine.dart)와 분리해 테스트에서만 import 한다.
library;

export 'src/testing/epub_fixtures.dart';
