/// `ImageDrawable.source` 문자열을 플랫폼에 맞는 `ImageProvider` 로 해석한다.
///
/// `source` 는 open-board 에 불투명하다(파일 경로/URL/앱 식별자). 네이티브에서는
/// 로컬 파일 경로를 `FileImage` 로, 웹에서는 blob/네트워크 URL 을 `NetworkImage`
/// 로 로드하기 위해 conditional import 로 플랫폼별 구현을 선택한다.
///
/// 호스트가 자체 해석 전략을 갖고 있으면 `ImageDrawableLayer.imageProviderResolver`
/// 로 주입해 이 기본 동작을 재정의할 수 있다.
library;

export 'image_source_resolver_network.dart'
    if (dart.library.io) 'image_source_resolver_io.dart';
