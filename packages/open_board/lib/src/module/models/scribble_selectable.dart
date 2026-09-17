/// 선택 후보 1건의 판정용 디스크립터 (kobic unibook#12445, UB-639).
///
/// 호스트가 "이 항목을 **새로** 선택 대상에 넣어도 되는가"를 판정할 때
/// 필요한 값만 담는다 — raw protobuf 모델([Stroke]/[TextDrawable])을
/// 노출하지 않아 호스트 정책이 엔진 내부 표현에 결합되지 않는다.
sealed class ScribbleSelectable {
  const ScribbleSelectable();
}

/// 스트로크(펜/마커/도형 잉크) 후보.
final class ScribbleSelectableStroke extends ScribbleSelectable {
  const ScribbleSelectableStroke({required this.ink, required this.shapeType});

  /// 생성 시 기록된 도구 문자열 ([InkModes] 어휘).
  ///
  /// proto3 특성상 미기록 레거시 데이터는 빈 문자열('')로 온다 — 호스트는
  /// 빈 ink 의 귀속 규칙을 명시적으로 정해야 한다(어느 도구로도 매칭하지
  /// 않으면 그 스트로크는 영구 선택·삭제 불가가 된다).
  final String ink;

  /// [ShapeTargets] 어휘 ('' = 도형 아님, 'pending' = 자동 인식 대기).
  final String shapeType;
}

/// 텍스트박스 후보 — 모델 타입 자체가 정체성이라 ink 필드가 없다.
final class ScribbleSelectableText extends ScribbleSelectable {
  const ScribbleSelectableText({required this.id});

  /// [TextDrawable.id].
  final String id;
}

/// 호스트가 "이 항목을 새로 선택 대상에 넣어도 되는가"를 판정하는 콜백.
///
/// **선택 진입에만** 적용된다 — 이미 선택된 객체의 이동/삭제/변형에는
/// 적용되지 않는다 (kobic#12374 가 확립한 "다른 도구 모드에서도 이미
/// 선택된 텍스트박스는 계속 조작 가능" 동작을 보존하기 위함).
///
/// 미주입(`null`) 시 기존과 완전히 동일하게 모든 항목이 선택 후보다 —
/// 기본값은 어떤 기존 소비자의 동작도 바꾸지 않는다
/// ([ScribbleWidget.shouldDeferDrawStart] 와 같은 계약).
typedef CanSelectScribbleItem = bool Function(ScribbleSelectable item);
