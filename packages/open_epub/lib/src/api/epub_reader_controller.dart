// Public API — open_epub 1.0
// Story: S8.1 (E8 follow-up) — 1.0 EpubReader 페이지 내비게이션 컨트롤러
//
// [EpubReader]에서 호스트가 페이지를 프로그램적으로 이동(prev/next 버튼 등)하고
// 현재 spine 인덱스/총 개수를 관찰하기 위한 핸들. paged 모드·스크롤 모드 어느
// 쪽에서도 동작한다(open-epub#221) — 스크롤 모드에서는 대상 spine으로 점프한다.
// open-board 필기 오버레이가 페이지 연동 + 외부 네비게이션 버튼을 다는 데 사용한다.
//
// nextPage/previousPage는 "페이지" 단위 이동(step)과 "spine" 단위 이동
// (goToSpine)을 구분한다 — paged 모드는 화면 단위 윈도우가 spine보다 잘게
// 쪼개질 수 있으므로(open-epub#221 윈도잉), 페이지 버튼은 윈도우 단위로
// 이동해야 한다. 엔진이 attachPageStepper로 세분화된 이동 함수를 등록하면
// 그걸 쓰고, 없으면(레거시 엔진 등) spine 단위 이동으로 폴백한다.
//
// 레거시 0.1.x의 EpubReaderController(`open_epub.dart`)와는 다른 1.0 전용
// 타입이다(이름 충돌 회피 위해 `View` 접두). 1.0은 `open_epub.dart`로만
// 노출되므로 같은 파일에서 두 타입을 동시에 import할 일은 없다.

import 'package:flutter/foundation.dart';

/// 1.0 [EpubReader]의 페이지 내비게이션 핸들 + 상태 notifier(paged·스크롤 모드
/// 공통).
class EpubViewController extends ChangeNotifier {
  int _currentSpineIndex = 0;
  int _spineCount = 0;
  int _windowIndex = 0;
  int _windowCount = 1;

  /// 현재 표시 중인 spine 인덱스(0-based).
  int get currentSpineIndex => _currentSpineIndex;

  /// 전체 spine 수.
  int get spineCount => _spineCount;

  /// 현재 spine 내 윈도우(화면 단위 페이지) 인덱스(0-based) — paged 모드의
  /// 화면 단위 윈도잉을 지원하는 엔진에서만 의미가 있다. 윈도잉 미지원
  /// 엔진(스크롤모드 등)에서는 항상 0. (open-epub#228)
  int get windowIndex => _windowIndex;

  /// 현재 spine의 윈도우 수. 윈도잉 미지원 엔진에서는 항상 1. (open-epub#228)
  int get windowCount => _windowCount;

  /// 다음으로 이동할 것이 남아있는지 — 다음 spine이 있거나, paged 모드라면
  /// 현재 spine 안에 아직 안 본 다음 윈도우가 있으면 true. (open-epub#228 —
  /// 이전에는 spine 단위만 봐서, 마지막 spine이 여러 윈도우로 나뉜 경우
  /// 남은 윈도우가 있어도 false를 반환해 "다음" 버튼을 잘못 비활성화할 수 있었다)
  bool get hasNext =>
      _currentSpineIndex < _spineCount - 1 || _windowIndex < _windowCount - 1;

  /// 이전으로 이동할 것이 남아있는지 — [hasNext]와 대칭.
  bool get hasPrevious => _currentSpineIndex > 0 || _windowIndex > 0;

  Future<void> Function(int index)? _navigate;
  Future<void> Function(int direction)? _step;

  /// [index] spine으로 이동한다(animation). 범위 밖이거나 미부착이면 무시.
  Future<void> goToSpine(int index) async {
    final navigate = _navigate;
    if (navigate == null || index < 0 || index >= _spineCount) return;
    await navigate(index);
  }

  /// 다음/이전 "페이지"로 이동한다. 엔진이 [attachPageStepper]로 세분화된
  /// 이동 함수를 등록했으면 그 단위(paged 모드는 화면 단위 윈도우)로 이동하고,
  /// 등록하지 않았으면 spine 단위(goToSpine)로 폴백한다.
  Future<void> nextPage() => _advancePage(1);
  Future<void> previousPage() => _advancePage(-1);

  Future<void> _advancePage(int direction) async {
    final step = _step;
    if (step != null) {
      await step(direction);
      return;
    }
    await goToSpine(_currentSpineIndex + direction);
  }

  // --- EpubReader 내부 바인딩 전용 (호스트는 직접 호출하지 않는다) ---

  /// EpubReader가 spine 단위 이동 함수(goToSpine)를 등록한다.
  void attachNavigator(Future<void> Function(int index) navigate) =>
      _navigate = navigate;

  /// EpubReader가 페이지 단위 이동 함수(nextPage/previousPage가 우선 사용)를
  /// 등록한다. paged 모드에서는 화면 단위 윈도우, 스크롤모드에서는 spine
  /// 단위로 이동하도록 엔진이 구현한다. (open-epub#221 후속)
  void attachPageStepper(Future<void> Function(int direction) step) =>
      _step = step;

  /// EpubReader dispose 시 바인딩 해제.
  void detachNavigator() {
    _navigate = null;
    _step = null;
  }

  /// EpubReader가 현재 페이지 상태를 밀어넣는다(변경 시 listener 통지).
  /// [windowIndex]/[windowCount]는 화면 단위 윈도잉을 지원하는 엔진만 채운다
  /// (기본값 0/1 = "윈도우 없음", 기존 spine 전용 동작과 동일). (open-epub#228)
  void syncState({
    required int currentSpineIndex,
    required int spineCount,
    int windowIndex = 0,
    int windowCount = 1,
  }) {
    if (_currentSpineIndex == currentSpineIndex &&
        _spineCount == spineCount &&
        _windowIndex == windowIndex &&
        _windowCount == windowCount) {
      return;
    }
    _currentSpineIndex = currentSpineIndex;
    _spineCount = spineCount;
    _windowIndex = windowIndex;
    _windowCount = windowCount;
    notifyListeners();
  }
}
