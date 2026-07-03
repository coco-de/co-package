// Public API — open_epub 1.0
// Story: S8.1 (E8 follow-up) — 1.0 EpubReader 페이지 내비게이션 컨트롤러
//
// [EpubReader]의 paged 모드에서 호스트가 페이지를 프로그램적으로 이동(prev/next
// 버튼 등)하고 현재 spine 인덱스/총 개수를 관찰하기 위한 핸들. open-board 필기
// 오버레이가 페이지 연동 + 외부 네비게이션 버튼을 다는 데 사용한다.
//
// 레거시 0.1.x의 EpubReaderController(`open_epub.dart`)와는 다른 1.0 전용
// 타입이다(이름 충돌 회피 위해 `View` 접두). 1.0은 `open_epub_v1.dart`로만
// 노출되므로 같은 파일에서 두 타입을 동시에 import할 일은 없다.

import 'package:flutter/foundation.dart';

/// 1.0 [EpubReader] paged 모드의 페이지 내비게이션 핸들 + 상태 notifier.
class EpubViewController extends ChangeNotifier {
  int _currentSpineIndex = 0;
  int _spineCount = 0;

  /// 현재 표시 중인 spine 인덱스(0-based).
  int get currentSpineIndex => _currentSpineIndex;

  /// 전체 spine 수.
  int get spineCount => _spineCount;

  bool get hasNext => _currentSpineIndex < _spineCount - 1;
  bool get hasPrevious => _currentSpineIndex > 0;

  Future<void> Function(int index)? _navigate;

  /// [index] spine으로 이동한다(animation). 범위 밖이거나 미부착이면 무시.
  Future<void> goToSpine(int index) async {
    final navigate = _navigate;
    if (navigate == null || index < 0 || index >= _spineCount) return;
    await navigate(index);
  }

  Future<void> nextPage() => goToSpine(_currentSpineIndex + 1);
  Future<void> previousPage() => goToSpine(_currentSpineIndex - 1);

  // --- EpubReader 내부 바인딩 전용 (호스트는 직접 호출하지 않는다) ---

  /// EpubReader가 내부 PageView 이동 함수를 등록한다.
  void attachNavigator(Future<void> Function(int index) navigate) =>
      _navigate = navigate;

  /// EpubReader dispose 시 바인딩 해제.
  void detachNavigator() => _navigate = null;

  /// EpubReader가 현재 페이지 상태를 밀어넣는다(변경 시 listener 통지).
  void syncState({required int currentSpineIndex, required int spineCount}) {
    if (_currentSpineIndex == currentSpineIndex && _spineCount == spineCount) {
      return;
    }
    _currentSpineIndex = currentSpineIndex;
    _spineCount = spineCount;
    notifyListeners();
  }
}
