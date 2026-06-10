import 'dart:async';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// 필기 데이터 자동저장 스케줄러
///
/// 디바운스 기반으로 자동저장을 스케줄링합니다.
/// 짧은 시간 내 여러 변경이 발생해도 마지막 변경만 저장합니다.
class AutoSaveScheduler {
  /// 자동 저장 지연 시간 (밀리초)
  static const int autoSaveDelayMs = 1000;

  /// 실제 저장을 수행하는 콜백
  final Future<void> Function(String key, Scribble scribble) onSave;

  /// dispose 상태 확인 콜백
  final bool Function() isDisposed;

  /// 자동 저장 타이머 맵 (normalizedKey -> Timer)
  final Map<String, Timer> _autoSaveTimers = {};

  /// 타이머 발화 전까지 보관되는 최신 스냅샷 (normalizedKey -> Scribble)
  ///
  /// flush 시 호출 측이 이 최신본을 즉시 저장할 수 있어야 하므로
  /// 타이머 클로저 캡처 대신 맵으로 관리한다.
  final Map<String, Scribble> _pendingScribbles = {};

  /// 마지막으로 저장된 Scribble (중복 저장 방지)
  ///
  /// strokes 개수만 비교하면 동수 변경(올가미 이동, 색 변경, 같은 수의
  /// 추가+삭제)과 텍스트/이미지 변경, 전체 지우기가 전부 저장에서
  /// 누락되므로 protobuf deep equality로 비교한다. 비교는 타이머 발화
  /// 시점에만 수행되어 초당 최대 1회로 제한된다.
  final Map<String, Scribble> _lastSaved = {};

  AutoSaveScheduler({required this.onSave, required this.isDisposed});

  /// 자동 저장 스케줄링
  ///
  /// [key]는 이미 정규화된 키여야 합니다.
  void schedule(String key, Scribble scribble) {
    final normalizedKey = _normalizeKey(key);

    // 항상 최신 스냅샷으로 교체한다. 사전 게이트로 early-return하면
    // 대기 중이던 옛 타이머(stale 스냅샷)가 그대로 발화해 최신 상태를
    // 덮어쓰는 역행이 발생한다.
    _pendingScribbles[normalizedKey] = scribble;

    _autoSaveTimers[normalizedKey]?.cancel();
    _autoSaveTimers[normalizedKey] = Timer(
      const Duration(milliseconds: autoSaveDelayMs),
      () async {
        _autoSaveTimers.remove(normalizedKey);
        final pending = _pendingScribbles.remove(normalizedKey);
        if (isDisposed() || pending == null) return;

        // 내용이 같으면 저장 생략 (loadScribble→onScribbleChanged→save
        // 무한루프 방지). 빈 Scribble도 저장 대상이다 — 전체 지우기를
        // 영속화하지 않으면 재실행 시 지운 필기가 부활한다.
        if (_lastSaved[normalizedKey] == pending) return;

        await onSave(normalizedKey, pending);
        _lastSaved[normalizedKey] = pending;
      },
    );
  }

  /// 특정 키의 대기 중인 자동 저장 타이머를 취소하고 pending 스냅샷을 반환
  ///
  /// 회전/모드 전환 등 즉시 영속화가 필요한 시점에 사용합니다.
  /// `onSave` 콜백은 호출하지 않으며, 호출 측이 반환된 스냅샷을
  /// 별도로 즉시 저장해야 합니다.
  ///
  /// Returns: 대기 중이던 최신 스냅샷, 없으면 `null`
  Scribble? flush(String key) {
    final normalizedKey = _normalizeKey(key);
    _autoSaveTimers.remove(normalizedKey)?.cancel();
    return _pendingScribbles.remove(normalizedKey);
  }

  /// 특정 키의 추적 상태를 모두 제거
  ///
  /// 필기 삭제 시 호출하지 않으면 대기 중이던 타이머가 발화해
  /// 삭제된 파일이 부활하고, 비교 기준(_lastSaved)이 오염됩니다.
  void invalidate(String key) {
    final normalizedKey = _normalizeKey(key);
    _autoSaveTimers.remove(normalizedKey)?.cancel();
    _pendingScribbles.remove(normalizedKey);
    _lastSaved.remove(normalizedKey);
  }

  /// 프리픽스에 해당하는 모든 키의 추적 상태 제거
  ///
  /// 예: keyPrefix가 'content123'이면 'content123/page1' 등 모두 제거
  void invalidateByPrefix(String keyPrefix) {
    final prefix = '${_normalizeKey(keyPrefix)}/';
    for (final key in _autoSaveTimers.keys
        .where((k) => k.startsWith(prefix))
        .toList()) {
      _autoSaveTimers.remove(key)?.cancel();
    }
    _pendingScribbles.removeWhere((k, _) => k.startsWith(prefix));
    _lastSaved.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// 모든 자동 저장 타이머 취소
  void cancelAll() {
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
    _pendingScribbles.clear();
  }

  /// 스케줄러 정리
  void dispose() {
    cancelAll();
    _lastSaved.clear();
  }

  /// 캐시 키 정규화 (특수 문자 처리)
  static String _normalizeKey(String key) {
    return key.replaceAll(RegExp(r'[<>:"|?*]'), '_');
  }
}
