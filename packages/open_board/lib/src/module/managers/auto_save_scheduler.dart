import 'dart:async';

import 'package:flutter/foundation.dart';
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

  /// 마지막 저장된 스트로크 수 해시 (무한루프 방지)
  final Map<String, int> _lastSavedHashes = {};

  AutoSaveScheduler({required this.onSave, required this.isDisposed});

  /// 자동 저장 스케줄링
  ///
  /// [key]는 이미 정규화된 키여야 합니다.
  void schedule(String key, Scribble scribble) {
    final normalizedKey = _normalizeKey(key);

    // 빈 스트로크는 저장하지 않음
    if (scribble.strokes.isEmpty) {
      debugPrint('🖊️ 빈 스트로크 자동저장 건너뜀: $normalizedKey');
      return;
    }

    // 동일한 스트로크 수는 저장하지 않음 (무한루프 방지)
    final currentHash = scribble.strokes.length;
    final lastHash = _lastSavedHashes[normalizedKey];
    if (lastHash == currentHash) {
      return;
    }

    // 기존 타이머 취소 후 새 타이머 설정
    _autoSaveTimers[normalizedKey]?.cancel();

    _autoSaveTimers[normalizedKey] = Timer(
      Duration(milliseconds: autoSaveDelayMs),
      () async {
        if (!isDisposed()) {
          await onSave(normalizedKey, scribble);
          _lastSavedHashes[normalizedKey] = currentHash;
          _autoSaveTimers.remove(normalizedKey);
        }
      },
    );
  }

  /// 모든 자동 저장 타이머 취소
  void cancelAll() {
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
  }

  /// 스케줄러 정리
  void dispose() {
    cancelAll();
    _lastSavedHashes.clear();
  }

  /// 캐시 키 정규화 (특수 문자 처리)
  static String _normalizeKey(String key) {
    return key.replaceAll(RegExp(r'[<>:"|?*]'), '_');
  }
}
