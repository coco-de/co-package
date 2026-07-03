// Data Codec — open_epub 1.0
// Story: S1.10 (#16) — BookPosition v1 codec wrapper
//
// 실제 직렬화 로직은 [EpubPosition.toToken] / [EpubPosition.fromToken]에
// 위치한다. 본 클래스는 외부에서 codec 추상을 통해 의존성을 주입하고 싶을
// 때 사용하는 façade이다.

import '../../api/epub_position.dart';

class BookPositionCodec {
  const BookPositionCodec();

  /// [EpubPosition]을 JSON 토큰 문자열로 인코딩.
  String encode(EpubPosition position) => position.toToken();

  /// 토큰 문자열을 [EpubPosition]으로 디코딩.
  EpubPosition decode(String token) => EpubPosition.fromToken(token);
}
