// 🎯 Dart imports:
import 'dart:math';

/// [Stroke.id] 기본 발급자 — RFC 4122 v4 형식의 무작위 UUID.
///
/// ## 왜 무작위인가 (시각 기반 금지)
///
/// 이 식별자의 존재 이유는 **오프라인 다중 기기**에서 같은 스트로크를 알아보는
/// 것이다. `DateTime.now().millisecondsSinceEpoch` 류를 쓰면 두 기기가 같은
/// 밀리초에 그린 서로 다른 스트로크가 같은 id 를 갖게 되어, 상위 동기화 계층이
/// 둘을 하나로 접거나 서로를 덮어쓴다 — 고치려던 문제보다 나쁜 결과다.
///
/// ## 왜 의존성을 더하지 않았나
///
/// `uuid` 패키지를 넣으면 이 라이브러리를 쓰는 모든 소비자에게 전이 의존이
/// 생긴다. v4 는 "122비트 난수 + 버전·변형 비트" 가 전부라 직접 만드는 편이
/// 표면적이 작다. 난수원은 반드시 [Random.secure] 다 — 기본 [Random] 은
/// 시드가 예측 가능해 기기 간 충돌 확률이 올라간다.
String generateStrokeId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

  // RFC 4122 §4.4 — 버전(4)과 변형(10xx) 비트를 고정한다.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

final Random _random = Random.secure();
