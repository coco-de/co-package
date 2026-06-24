  import 'dart:async';
  import 'dart:developer';
  import 'dart:io';
  import 'dart:math' as math;
  import 'dart:ui' as ui;

  import 'package:flutter/foundation.dart'
      show kDebugMode, kIsWeb, visibleForTesting;
  import 'package:flutter/material.dart';
  import 'package:flutter/rendering.dart';
  import 'package:flutter/services.dart';
  import 'package:path_provider/path_provider.dart';

  import 'package:open_board/src/core/utils/extensions/merge_scribble.dart'; // 스트로크 분할/머지 import
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/managers/auto_save_scheduler.dart';
  import 'package:open_board/src/module/managers/scribble_book_controller.dart';
  import 'package:open_board/src/module/scribble_controller.dart';
  import 'package:open_board/src/module/state/drawing_state.dart';
  import 'package:open_board/src/module/state/scribble.state.dart';

  /// 통합된 필기 데이터 및 컨트롤러 관리 매니저
  ///
  /// 이 클래스는 다음 기능들을 제공합니다:
  /// - 키별 필기 데이터를 바이너리 파일로 저장/로드
  /// - ScribbleController 인스턴스 캐싱 및 관리
  /// - 전역 도구 상태 동기화
  /// - 자동 저장 및 메모리 관리
  /// - Assets에서 초기 필기 데이터 로드
  /// - 스트로크 분할/머지 시스템 (양면↔단면 전환)
  ///
  /// 키 형식: 'contentId/pageId' 또는 원하는 계층 구조
  class ScribbleCacheManager extends ChangeNotifier implements ScribblePageProvider {
    /// 저장 디바운스 시간 (기본 1.5초)
    static const Duration _saveDebounceTime = Duration(milliseconds: 1500);

    /// 전역 싱글턴 인스턴스 (lazy 초기화)
    ///
    /// 동일 컨트롤러/메모리 캐시를 모든 소비자가 공유해야 하므로
    /// 일반적으로는 [instance] 를 사용해 접근합니다.
    /// dispose 후 재접근 시 자동으로 새 인스턴스가 생성됩니다.
    static ScribbleCacheManager? _singleton;

    /// 전역 싱글턴 접근자
    ///
    /// `DrawingState` 와 동일한 패턴으로, dispose 된 인스턴스가 감지되면
    /// 새 인스턴스를 자동 생성하여 안전하게 재사용할 수 있습니다.
    static ScribbleCacheManager get instance {
      if (_singleton == null || _singleton!._isDisposed) {
        _singleton = ScribbleCacheManager();
      }
      return _singleton!;
    }

    /// 싱글턴 인스턴스 초기화 (테스트 전용)
    ///
    /// 테스트 격리가 필요한 경우에만 호출합니다.
    /// 운영 코드에서는 호출하지 마세요.
    @visibleForTesting
    static void resetInstance() {
      _singleton?.dispose();
      _singleton = null;
    }

    // ===== 콜백 함수들 =====

    /// 도구 변경 시 콜백
    void Function(String tool)? onToolChanged;

    /// 색상 변경 시 콜백
    void Function(Color color)? onColorChanged;

    /// 두께 변경 시 콜백
    void Function(double width)? onStrokeWidthChanged;

    /// 🎯 활성 컨트롤러 변경 시 콜백
    void Function(String key)? onActiveControllerChanged;

    /// 자동저장 스케줄러
    late final AutoSaveScheduler _autoSaveScheduler;

    /// 메모리 캐시 (key -> Scribble)
    final Map<String, Scribble> _memoryCache = {};

    /// ScribbleController 캐시 (key -> ScribbleController)
    final Map<String, ScribbleController> _controllerCache = {};

    /// 디스크 캐시 디렉토리
    Directory? _cacheDirectory;

    /// 공유되는 도구 설정
    String _currentTool = ScribbleTool.pen;

    Color _currentColor = Colors.black;

    double _currentStrokeWidth = 2.0;

    /// 🔥 디바운스 관련 필드들
    /// 키별 저장 타이머 관리
    final Map<String, Timer> _saveTimers = {};

    /// 즉시 저장이 예약된 키들 (앱 종료, 탭 전환 등)
    final Set<String> _immediateSaveKeys = {};

    /// 포인터 모드 설정 (🚫 손필기 방지: 기본값은 펜모드)
    String _currentPointerMode = 'penOnly'; // 'all' 또는 'penOnly'

    /// ✨ dispose 상태 추적
    bool _isDisposed = false;

    /// ✨ 각 키별 원본 이미지 크기 저장 (MeasureSize에서 측정됨)
    final Map<String, Size> _originalImageSizes = {};

    /// 자동 저장 활성화 상태
    bool _autoSaveEnabled = true;

    /// 스트로크 분할/머지 시스템
    /// 양면↔단면 모드 전환 시 분할 결과 캐시
    final Map<String, ScribbleSplitResult> _splitResultCache = {};

    /// 분할 시점의 원본 양면 Scribble (캐시 유효성 검증용)
    ///
    /// 캐시를 무조건 우선 사용하면 분할 이후의 모든 편집이 옛 분할
    /// 결과로 롤백되므로, 사용 전에 현재 데이터와 비교해 다르면 폐기한다.
    final Map<String, Scribble> _splitSourceCache = {};

    ScribbleCacheManager() {
      _autoSaveScheduler = AutoSaveScheduler(
        onSave: (key, scribble) async {
          await saveScribble(key, scribble);
        },
        isDisposed: () => _isDisposed,
      );
    }

    // ===== 현재 설정 접근자 =====

    String get currentTool => _currentTool;
    Color get currentColor => _currentColor;
    double get currentStrokeWidth => _currentStrokeWidth;

    /// 캐시 디렉토리 초기화
    Future<Directory> get cacheDirectory async {
      if (_isWeb) {
        throw UnsupportedError('File I/O is not supported on web');
      }
      if (_cacheDirectory != null) return _cacheDirectory!;

      final documentsDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${documentsDir.path}/scribbles');

      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }

      return _cacheDirectory!;
    }

    /// 웹 플랫폼 여부 (파일 I/O 불가)
    bool get _isWeb => kIsWeb;

    // ===== ScribbleController 관리 메서드들 =====

    /// 특정 키의 컨트롤러를 가져오거나 생성 (동기식)
    /// 키 형식: 'contentId/pageId' (예: 'book123/page1')
    ScribbleController getController(String key) {
      final normalizedKey = _normalizeKey(key);

      if (!_controllerCache.containsKey(normalizedKey)) {
        // 🌍 전역 상태에서 초기값 가져오기
        final globalState = DrawingState();

        _controllerCache[normalizedKey] = ScribbleController(
          initialTool: _convertToScribbleTool(globalState.selectedTool.value),
          initialColor: globalState.selectedColor.value,
          initialStrokeWidth: globalState.selectedThickness.value,
          onScribbleChanged: (scribble) {
            if (_isDisposed) return; // ✨ dispose 후 호출 방지

            if (_autoSaveEnabled) {
              scheduleAutoSave(normalizedKey, scribble);
            }

            // 🚨 Widget tree lock 방지: UI 업데이트를 다음 프레임으로 연기
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDisposed) {
                notifyListeners();
              }
            });
          },
          onToolChanged: (tool) {
            // 🚫 도구 변경 콜백 비활성화 (전역 상태와 충돌 방지)
          },
        );

        // ✨ 포인터 모드 동기화
        _applyPointerModeToController(_controllerCache[normalizedKey]!);

        // 🌍 DrawingState 등록은 ScribbleController에서 자동으로 처리됨 ✅
        // (중복 등록 코드 제거됨)
      }

      return _controllerCache[normalizedKey]!;
    }

    /// 특정 키의 컨트롤러가 존재하는지 확인
    bool hasController(String key) {
      final normalizedKey = _normalizeKey(key);
      return _controllerCache.containsKey(normalizedKey);
    }

    // ===== 이미지 캡처 메서드들 =====

    /// 🖼️ 특정 키의 필기를 이미지로 캡처
    ///
    /// [key] 캐시 키 (예: 'contentId/pageId')
    /// [pixelRatio] 이미지 해상도 배율 (기본값: 자동 계산)
    /// [format] 이미지 포맷 (기본값: PNG)
    ///
    /// 반환: 이미지 바이트 데이터 또는 null (캡처 실패 시)
    Future<Uint8List?> captureScribbleImage(
      String key, {
      double? pixelRatio,
      ui.ImageByteFormat format = ui.ImageByteFormat.png,
    }) async {
      try {
        log(
          '🎨 스크리블 이미지 캡처 시작 - key: $key, pixelRatio: $pixelRatio, format: $format',
        );

        final normalizedKey = _normalizeKey(key);
        log('🔑 정규화된 키: $normalizedKey');

        final controller = _controllerCache[normalizedKey];
        log('🎮 컨트롤러 조회 결과: ${controller != null ? "존재함" : "null"}');

        if (controller == null) {
          log('⚠️ 컨트롤러가 null입니다 - normalizedKey: $normalizedKey');
          log('📋 현재 캐시된 컨트롤러들: ${_controllerCache.keys.toList()}');
          return null;
        }

        log(
          '🔍 RepaintBoundaryKey 존재 확인됨: ${controller.repaintBoundaryKey.hashCode}',
        );

        final boundary =
            controller.repaintBoundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;

        if (boundary == null) {
          log('⚠️ RenderRepaintBoundary를 찾을 수 없습니다');
          log(
            '🔍 currentContext 상태: ${controller.repaintBoundaryKey.currentContext != null ? "존재함" : "null"}',
          );
          log(
            '🔍 renderObject 타입: ${controller.repaintBoundaryKey.currentContext?.findRenderObject()?.runtimeType}',
          );
          return null;
        }

        log('✅ RenderRepaintBoundary 찾음: ${boundary.runtimeType}');

        // 렌더링 크기 확인
        final size = boundary.size;
        log('📐 RenderRepaintBoundary 크기: ${size.width} x ${size.height}');

        if (size.isEmpty) {
          log('⚠️ RenderRepaintBoundary 크기가 0 - 위젯이 아직 레이아웃되지 않음');
          return null;
        }

        // 렌더링 상태 확인
        // debugNeedsPaint는 assert 내부에서만 초기화되는 디버그 전용 getter라
        // release/profile 빌드에서 접근하면 LateInitializationError를 던진다.
        if (kDebugMode && boundary.debugNeedsPaint) {
          log('⚠️ 위젯이 아직 페인트 대기 중 - 렌더링 완료 대기');

          // 렌더링 완료를 위해 프레임 대기
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // 다시 확인
          if (boundary.debugNeedsPaint) {
            log('⚠️ 렌더링 완료 대기 후에도 페인트 대기 중 - 강제 플러시 시도');

            // 렌더링 강제 플러시
            try {
              WidgetsBinding.instance.scheduleFrame();
              await WidgetsBinding.instance.endOfFrame;
            } on Exception catch (error) {
              log('⚠️ 렌더링 플러시 실패: $error');
            }

            // 최종 확인
            if (boundary.debugNeedsPaint) {
              log('❌ 렌더링 완료 실패 - 이미지 캡처 중단');
              return null;
            }
          }

          log('✅ 렌더링 완료 확인됨');
        } else {
          log('✅ 렌더링 상태 양호 - 즉시 캡처 가능');
        }

        // 픽셀 비율 자동 계산 (제공되지 않은 경우)
        final effectivePixelRatio =
            pixelRatio ?? _calculateOptimalPixelRatio(key);

        log('📐 사용될 픽셀 비율: $effectivePixelRatio');

        // 이미지 생성
        log('🖼️ 이미지 생성 시작...');
        final image = await boundary.toImage(pixelRatio: effectivePixelRatio);
        log('📏 생성된 이미지 크기: ${image.width}x${image.height}');

        log('💾 ByteData 변환 시작...');
        final byteData = await image.toByteData(format: format);

        if (byteData == null) {
          log('⚠️ ByteData 변환 실패');
          image.dispose();
          return null;
        }

        final resultBytes = byteData.buffer.asUint8List();
        log('✅ 이미지 캡처 성공 - 바이트 크기: ${resultBytes.length}');

        // 메모리 정리
        image.dispose();

        return resultBytes;
      } catch (error, stackTrace) {
        // Error 계열(LateInitializationError 등)도 "실패 시 null 반환"
        // 계약을 지키도록 일반 catch를 사용한다.
        log('❌ 스크리블 이미지 캡처 중 오류 발생', error: error, stackTrace: stackTrace);
        return null;
      }
    }

    /// 🖼️ 특정 키의 필기가 캡처 가능한 상태인지 확인
    ///
    /// [key] 캐시 키
    ///
    /// 반환: 캡처 가능 여부
    bool canCaptureScribbleImage(String key) {
      final normalizedKey = _normalizeKey(key);
      final controller = _controllerCache[normalizedKey];

      if (controller?.repaintBoundaryKey == null) {
        return false;
      }

      final boundary =
          controller!.repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      return boundary != null;
    }

    // ===== 컨트롤러 조작 메서드들 =====

    /// 특정 페이지 지우기
    void clearPage(String key) {
      final normalizedKey = _normalizeKey(key);
      final controller = _controllerCache[normalizedKey];
      controller?.clear();
    }

    /// 특정 페이지가 비어있는지 확인
    bool isPageEmpty(String key) {
      final normalizedKey = _normalizeKey(key);
      final controller = _controllerCache[normalizedKey];
      return controller?.isEmpty ?? true;
    }

    /// 특정 페이지에 필기 데이터 가져오기
    void importPageData(String key, Uint8List data) {
      try {
        final controller = getController(key);
        controller.importFromBytes(data);
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
      }
    }

    /// 페이지 통계 정보
    ScribbleStats? getPageStats(String key) {
      final normalizedKey = _normalizeKey(key);
      final controller = _controllerCache[normalizedKey];
      return controller?.stats;
    }

    // ===== 탭 전환 시 활성 컨트롤러 관리 =====

    /// 🎯 특정 컨트롤러를 활성 컨트롤러로 설정 (탭 전환 시 호출)
    void setActiveController(String key) {
      final normalizedKey = _normalizeKey(key);
      final controller = _controllerCache[normalizedKey];

      if (controller != null) {
        final globalState = DrawingState();

        // 🎯 활성 ScribbleNotifier 설정 (undo/redo 대상)
        globalState.setLastActiveScribbleNotifier(controller.scribbleNotifier);

        // 🎨 전역 상태를 현재 컨트롤러에 적용
        globalState.applyToModeNotifier(controller.modeNotifier);

        // 🔄 즉시 undo/redo 상태 업데이트
        globalState.updateUndoRedoState();

        // 🎯 현재 도구에 맞게 ScribbleNotifier 상태 동기화
        globalState.syncScribbleNotifierToGlobalTool(
          controller.scribbleNotifier,
        );

        // 콜백 호출
        onActiveControllerChanged?.call(key);
      }
    }

    /// 🔄 현재 활성 컨트롤러의 undo/redo 상태 강제 업데이트
    void updateActiveControllerUndoRedoState() {
      final globalState = DrawingState();
      globalState.updateUndoRedoState();
    }

    // ===== 도구 설정 관리 =====

    /// 도구 변경 (모든 페이지에 적용)
    void setTool(String tool) {
      if (_currentTool == tool) return;

      _currentTool = tool;
      _applyToolSettingsToAllControllers();
      onToolChanged?.call(tool);

      // 🔄 활성 컨트롤러의 undo/redo 상태 업데이트
      updateActiveControllerUndoRedoState();

      if (!_isDisposed) notifyListeners();
    }

    /// 색상 변경 (모든 페이지에 적용)
    void setColor(Color color) {
      if (_currentColor == color) return;

      _currentColor = color;
      _applyToolSettingsToAllControllers();
      onColorChanged?.call(color);

      // 🔄 활성 컨트롤러의 undo/redo 상태 업데이트
      updateActiveControllerUndoRedoState();

      if (!_isDisposed) notifyListeners();
    }

    /// 브러시 크기 변경 (모든 페이지에 적용)
    void setStrokeWidth(double width) {
      if (_currentStrokeWidth == width) return;

      _currentStrokeWidth = width;
      _applyToolSettingsToAllControllers();
      onStrokeWidthChanged?.call(width);

      // 🔄 활성 컨트롤러의 undo/redo 상태 업데이트
      updateActiveControllerUndoRedoState();

      if (!_isDisposed) notifyListeners();
    }

    /// 포인터 모드 설정
    void setPointerMode(String mode) {
      if (_currentPointerMode != mode) {
        _currentPointerMode = mode;
        _syncPointerModeToAllControllers();
        if (!_isDisposed) notifyListeners();
      }
    }

    /// 필기 데이터 저장 (디바운스 적용)
    Future<bool> saveScribble(
      String key,
      Scribble scribble, {
      bool immediate = false,
    }) async {
      try {
        final normalizedKey = _normalizeKey(key);

        // 🔥 메모리 캐시는 즉시 업데이트 (데이터 손실 방지)
        _memoryCache[normalizedKey] = scribble;

        // 🔥 즉시 저장이 요청되거나 즉시 저장 키로 등록된 경우
        if (immediate || _immediateSaveKeys.contains(normalizedKey)) {
          // 대기 중인 디바운스 타이머(옛 스냅샷)가 immediate 저장 직후
          // 발화해 파일을 stale 상태로 되돌리는 것을 방지한다.
          _saveTimers.remove(normalizedKey)?.cancel();
          return await _saveToFileImmediately(normalizedKey, scribble);
        }

        // 🔥 디바운스 처리: 기존 타이머 취소 후 새 타이머 설정
        _saveTimers[normalizedKey]?.cancel();

        _saveTimers[normalizedKey] = Timer(_saveDebounceTime, () async {
          _saveTimers.remove(normalizedKey);
          if (_isDisposed) return;
          // 클로저 캡처본 대신 메모리 캐시의 최신본을 저장한다.
          final latest = _memoryCache[normalizedKey];
          if (latest != null) {
            await _saveToFileImmediately(normalizedKey, latest);
          }
        });

        return true; // 메모리 저장 성공
      } on Exception catch (error) {
        debugPrint('ScribbleCacheManager: 필기 저장 실패 - $error');
        return false;
      }
    }

    /// 대기 중인 디바운스 저장을 즉시 실행 (flush)
    ///
    /// 다음 두 디바운스 레이어 중 하나라도 대기 중이면 타이머를 취소하고
    /// 메모리 캐시의 최신 [Scribble] 데이터를 즉시 파일로 저장합니다.
    ///   - [AutoSaveScheduler] (컨트롤러 변경 콜백 → 1.0초 디바운스)
    ///   - [saveScribble] 내부 디바운스 (1.5초)
    ///
    /// 회전/모드 전환 등 즉시 영속화가 필요한 시점에 호출합니다.
    ///
    /// Returns:
    /// - `true`: 대기 중인 디바운스가 있었고 즉시 저장에 성공한 경우
    /// - `false`: 대기 중인 디바운스가 없거나 메모리 캐시에 데이터가 없는 경우
    Future<bool> flushSave(String key) async {
      final normalizedKey = _normalizeKey(key);

      // 1단계: AutoSaveScheduler에 대기 중이던 최신 스냅샷이 있으면 그것을
      // 즉시 저장한다. (이 스냅샷은 아직 _memoryCache에 반영되지 않았으므로
      // 메모리 캐시를 저장하면 한 세대 전 데이터가 영속화된다)
      final pending = _autoSaveScheduler.flush(normalizedKey);
      if (pending != null) {
        return saveScribble(normalizedKey, pending, immediate: true);
      }

      // 2단계: saveScribble 내부 디바운스가 대기 중이면 메모리 캐시(이
      // 레이어에서는 항상 최신)를 즉시 저장한다.
      final pendingTimer = _saveTimers.remove(normalizedKey);
      pendingTimer?.cancel();
      if (pendingTimer == null) return false;

      final scribble = _memoryCache[normalizedKey];
      if (scribble == null) return false;

      return _saveToFileImmediately(normalizedKey, scribble);
    }

    /// 필기 데이터 로드
    Future<Scribble?> loadScribble(String key) async {
      try {
        final normalizedKey = _normalizeKey(key);

        // 메모리 캐시에서 먼저 확인
        if (_memoryCache.containsKey(normalizedKey)) {
          return _memoryCache[normalizedKey];
        }

        // 웹에서는 파일 I/O 불가 → 메모리 캐시에 없으면 null 반환
        if (_isWeb) return null;

        final filePath = await _getFilePath(normalizedKey);
        final file = File(filePath);

        // 파일이 존재하는지 확인
        if (!await file.exists()) {
          return null;
        }

        // 파일에서 로드
        final bytes = await file.readAsBytes();
        final scribble = Scribble.fromBuffer(bytes);

        // 메모리 캐시에 저장
        _memoryCache[normalizedKey] = scribble;

        return scribble;
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        return null;
      }
    }

    /// 필기 데이터 삭제
    Future<bool> deleteScribble(String key) async {
      try {
        final normalizedKey = _normalizeKey(key);

        // 대기 중인 저장 타이머를 취소한다 — 취소하지 않으면 삭제 직후
        // 타이머가 발화해 삭제된 파일이 부활한다.
        _saveTimers.remove(normalizedKey)?.cancel();
        _autoSaveScheduler.invalidate(normalizedKey);

        // 메모리 캐시에서 제거
        _memoryCache.remove(normalizedKey);

        // 웹에서는 파일 삭제 불가
        if (_isWeb) return true;

        final filePath = await _getFilePath(normalizedKey);

        // 파일 삭제
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }

        return true;
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        return false;
      }
    }

    /// 특정 경로의 모든 필기 데이터 삭제
    /// 예: keyPrefix가 'content123'이면 'content123/page1', 'content123/page2' 등 모두 삭제
    Future<bool> deleteScribblesByPrefix(String keyPrefix) async {
      try {
        final normalizedPrefix = _normalizeKey(keyPrefix);

        // 대기 중인 저장 타이머 취소 (삭제된 파일 부활 방지)
        for (final key in _saveTimers.keys
            .where((k) => k.startsWith('$normalizedPrefix/'))
            .toList()) {
          _saveTimers.remove(key)?.cancel();
        }
        _autoSaveScheduler.invalidateByPrefix(normalizedPrefix);

        // 메모리 캐시에서 해당 프리픽스 데이터 모두 제거
        _memoryCache.removeWhere(
          (key, value) => key.startsWith('$normalizedPrefix/'),
        );

        // 웹에서는 파일 삭제 불가
        if (_isWeb) return true;

        final dir = await cacheDirectory;
        final targetDir = Directory('${dir.path}/$normalizedPrefix');

        if (await targetDir.exists()) {
          await targetDir.delete(recursive: true);
        }

        return true;
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        return false;
      }
    }

    /// 필기 데이터 존재 여부 확인
    Future<bool> hasScribble(String key) async {
      final normalizedKey = _normalizeKey(key);

      // 메모리 캐시 확인
      if (_memoryCache.containsKey(normalizedKey)) {
        return true;
      }

      // 웹에서는 파일 확인 불가
      if (_isWeb) return false;

      // 파일 존재 확인
      final filePath = await _getFilePath(normalizedKey);
      return await File(filePath).exists();
    }

    /// 특정 프리픽스로 시작하는 모든 필기 키 목록 가져오기
    /// 예: keyPrefix가 'content123'이면 'content123/page1', 'content123/page2' 등 반환
    Future<List<String>> getScribbleKeys(String keyPrefix) async {
      if (_isWeb)
        return _memoryCache.keys
            .where((k) => k.startsWith(_normalizeKey(keyPrefix)))
            .toList();
      try {
        final dir = await cacheDirectory;
        final normalizedPrefix = _normalizeKey(keyPrefix);
        final targetDir = Directory('${dir.path}/$normalizedPrefix');

        if (!await targetDir.exists()) {
          return [];
        }

        final keys = <String>[];
        await for (final entity in targetDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.bin')) {
            // 파일 경로에서 키 추출
            final relativePath = entity.path
                .replaceFirst('${dir.path}/', '')
                .replaceAll('.bin', '');
            keys.add(relativePath);
          }
        }

        keys.sort();
        return keys;
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        return [];
      }
    }

    /// 메모리 캐시 정리
    void clearMemoryCache() {
      _memoryCache.clear();
    }

    /// 자동 저장 활성화 여부
    bool get autoSaveEnabled => _autoSaveEnabled;

    /// 자동 저장 활성화 설정
    ///
    /// 리플레이 등 표시 전용 구동 중에는 false로 설정해 중간 애니메이션
    /// 프레임이 onScribbleChanged → scheduleAutoSave 경로로 원본 파일을
    /// 오염시키는 것을 막는다.
    set autoSaveEnabled(bool value) {
      _autoSaveEnabled = value;
    }

    /// 특정 키의 컨트롤러와 관련 캐시를 모두 제거
    ///
    /// 페이지 삭제 시 호출하지 않으면 컨트롤러 캐시에 남은 옛 필기가
    /// 동일 키 재사용(getController) 시 그대로 반환되어 삭제된 필기가
    /// 새 페이지에 부활한다.
    @override
    void evictController(String key) {
      final normalizedKey = _normalizeKey(key);

      _saveTimers.remove(normalizedKey)?.cancel();
      _autoSaveScheduler.invalidate(normalizedKey);
      _memoryCache.remove(normalizedKey);
      _originalImageSizes.remove(normalizedKey);

      final controller = _controllerCache.remove(normalizedKey);
      controller?.dispose();
    }

    /// 자동 저장 스케줄링 — AutoSaveScheduler에 위임
    void scheduleAutoSave(String key, Scribble scribble) {
      _autoSaveScheduler.schedule(key, scribble);
    }

    /// 인스턴스 정리
    @override
    void dispose() {
      // ✨ dispose 상태 표시 (추가 호출 방지)
      _isDisposed = true;

      // 🌍 DrawingState 해제는 ScribbleController에서 자동으로 처리됨 ✅
      // (중복 해제 코드 제거됨)

      // 컨트롤러 정리 (ScribbleController 자체에서 DrawingState 해제)
      for (final controller in _controllerCache.values) {
        controller.dispose();
      }
      _controllerCache.clear();

      // 자동 저장 스케줄러 정리
      _autoSaveScheduler.dispose();

      // 디바운스 저장 타이머 정리
      for (final timer in _saveTimers.values) {
        timer.cancel();
      }
      _saveTimers.clear();

      // 메모리 캐시 정리
      clearMemoryCache();

      // 분할 결과 캐시 정리
      clearSplitResultCache();

      // ChangeNotifier dispose 호출
      super.dispose();
    }

    /// === 고급 기능 ===

    /// 양면 모드에서 단면 모드로 스트로크 분할
    ///
    /// 양면 모드에서 그린 필기를 단면 모드의 좌우 페이지로 분할합니다.
    ///
    /// [doublePageKey]: 양면 모드 필기 키 (예: 'book123/doublePage2')
    /// [leftPageKey]: 왼쪽 페이지 키 (예: 'book123/page2')
    /// [rightPageKey]: 오른쪽 페이지 키 (예: 'book123/page3')
    /// [pageWidth]: 페이지 너비 (분할 기준)
    /// [pageHeight]: 페이지 높이
    /// [preserveAspectRatio]: 종횡비 유지 여부 (기본값: true)
    /// [boundaryOffset]: 페이지 경계 오프셋 (기본값: 0.0)
    Future<bool> splitDoublePageToSinglePages({
      required String doublePageKey,
      required String leftPageKey,
      required String rightPageKey,
      required double pageWidth,
      required double pageHeight,
      bool preserveAspectRatio = true,
      double boundaryOffset = 0.0,
    }) async {
      try {
        debugPrint('  - 양면 키: $doublePageKey');
        debugPrint('  - 왼쪽 키: $leftPageKey');
        debugPrint('  - 오른쪽 키: $rightPageKey');

        // 🔍 **우선순위 1: 캐시된 분할 결과 확인**
        var cachedSplitResult = _splitResultCache[doublePageKey];
        if (cachedSplitResult != null) {
          // 분할 이후 양면 데이터가 편집되었으면 캐시는 무효 —
          // 그대로 쓰면 편집 내용이 옛 분할 결과로 롤백된다.
          final source = _splitSourceCache[doublePageKey];
          final current = await loadScribble(doublePageKey);
          if (source == null || current == null || source != current) {
            debugPrint('🗑️ 분할 캐시 무효 (양면 데이터 변경됨) — 실시간 분할로 폴백');
            _splitResultCache.remove(doublePageKey);
            _splitSourceCache.remove(doublePageKey);
            cachedSplitResult = null;
          }
        }
        if (cachedSplitResult != null) {
          // 클로저 캡처를 위한 non-null 로컬 (null promotion은 클로저에서 무효)
          final cached = cachedSplitResult;
          debugPrint('🔄 캐시된 분할 결과 복원 중...');
          debugPrint(
            '  - 왼쪽 스트로크: ${cached.leftPageScribble.strokes.length}',
          );
          debugPrint(
            '  - 오른쪽 스트로크: ${cached.rightPageScribble.strokes.length}',
          );

          // 💾 캐시된 결과를 각 페이지에 저장
          await saveScribble(leftPageKey, cached.leftPageScribble);
          await saveScribble(rightPageKey, cached.rightPageScribble);

          // 🎮 컨트롤러에도 반영
          if (hasController(leftPageKey)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDisposed) {
                getController(
                  leftPageKey,
                ).loadScribble(cached.leftPageScribble);
              }
            });
          }
          if (hasController(rightPageKey)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDisposed) {
                getController(
                  rightPageKey,
                ).loadScribble(cached.rightPageScribble);
              }
            });
          }

          debugPrint('✅ 캐시 기반 분할 복원 완료');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
              notifyListeners();
            }
          });
          return true;
        }

        // 🔍 **우선순위 2: 실시간 분할 (캐시 없는 경우만)**
        final doublePageScribble = await loadScribble(doublePageKey);
        if (doublePageScribble == null || doublePageScribble.strokes.isEmpty) {
          debugPrint('🔄 양면 페이지 필기 없음: $doublePageKey');
          return false;
        }

        debugPrint('  - 스트로크 수: ${doublePageScribble.strokes.length}');

        // 🎯 실제 페이지 경계 계산 (오프셋 적용)
        final adjustedPageWidth = pageWidth;

        // 🔄 스트로크 분할 실행 (개선된 정확도)
        final splitResult = doublePageScribble
            .splitStrokesForDoubleToSingleMode(
              pageWidth: adjustedPageWidth,
              pageHeight: pageHeight,
              isFirstPageSingle: true, // firstPageSingle 전략 적용
            );

        // 🎯 종횡비 유지를 위한 스케일 팩터 계산

        if (preserveAspectRatio) {
          final originalAspectRatio = pageWidth / pageHeight;
          final targetAspectRatio = (pageWidth / 2) / pageHeight;

          if (originalAspectRatio != targetAspectRatio) {
            final scaleAdjustment = targetAspectRatio / originalAspectRatio;

            debugPrint('🎯 종횡비 조정 적용: $scaleAdjustment');
          }
        }

        debugPrint('🔄 분할 결과:');
        debugPrint(
          '  - 왼쪽 스트로크: ${splitResult.leftPageScribble.strokes.length}',
        );
        debugPrint(
          '  - 오른쪽 스트로크: ${splitResult.rightPageScribble.strokes.length}',
        );
        debugPrint('  - 교차 스트로크: ${splitResult.crossPageStrokes.length}');

        // 🔄 분할 결과 캐시에 저장 (나중에 복원용) + 원본 보관(유효성 검증용)
        _splitResultCache[doublePageKey] = splitResult;
        _splitSourceCache[doublePageKey] = doublePageScribble;

        // 🛡️ **중요**: 원본 양면 데이터도 보존 (덮어쓰지 않음)
        // 원본 데이터를 _splitResultCache에 보관하므로 별도 보존 불필요

        // 💾 각 페이지별로 필기 데이터 저장
        await saveScribble(
          leftPageKey,
          splitResult.leftPageScribble,
          immediate: true,
        );
        await saveScribble(
          rightPageKey,
          splitResult.rightPageScribble,
          immediate: true,
        );

        // 🎮 컨트롤러에도 반영
        if (hasController(leftPageKey)) {
          // 🚨 Widget tree lock 방지: 컨트롤러 업데이트를 다음 프레임으로 연기
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
              getController(
                leftPageKey,
              ).loadScribble(splitResult.leftPageScribble);
            }
          });
        }
        if (hasController(rightPageKey)) {
          // 🚨 Widget tree lock 방지: 컨트롤러 업데이트를 다음 프레임으로 연기
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
              getController(
                rightPageKey,
              ).loadScribble(splitResult.rightPageScribble);
            }
          });
        }

        debugPrint('✅ 양면→단면 스트로크 분할 완료');

        // 🚨 Widget tree lock 방지: notifyListeners를 다음 프레임으로 연기
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) {
            notifyListeners();
          }
        });
        return true;
      } on Exception catch (error, stackTrace) {
        debugPrint('❌ 스트로크 분할 실패: $error');
        debugPrintStack(stackTrace: stackTrace);
        return false;
      }
    }

    /// 단면 모드에서 양면 모드로 스트로크 병합
    ///
    /// 좌우 페이지의 필기를 양면 모드로 병합합니다.
    ///
    /// [leftPageKey]: 왼쪽 페이지 키 (예: 'book123/page2')
    /// [rightPageKey]: 오른쪽 페이지 키 (예: 'book123/page3')
    /// [doublePageKey]: 양면 모드 필기 키 (예: 'book123/doublePage2')
    /// [pageWidth]: 최종 페이지 너비
    /// [pageHeight]: 최종 페이지 높이
    Future<bool> mergeSinglePagesToDoublePage({
      required String leftPageKey,
      required String rightPageKey,
      required String doublePageKey,
      required double pageWidth,
      required double pageHeight,
    }) async {
      try {
        debugPrint('🔄 단면→양면 스트로크 병합 시작');
        debugPrint('  - 왼쪽 키: $leftPageKey');
        debugPrint('  - 오른쪽 키: $rightPageKey');
        debugPrint('  - 양면 키: $doublePageKey');

        // 🔍 기존 분할 결과가 캐시에 있는지 확인
        var cachedSplitResult = _splitResultCache[doublePageKey];
        if (cachedSplitResult != null) {
          // 분할 이후 단면 페이지가 편집되었으면 캐시는 무효 —
          // 편집 보존을 위해 실시간 병합 경로로 폴백한다.
          final currentLeft = await loadScribble(leftPageKey);
          final currentRight = await loadScribble(rightPageKey);
          final cacheValid =
              currentLeft == cachedSplitResult.leftPageScribble &&
              currentRight == cachedSplitResult.rightPageScribble;
          if (!cacheValid) {
            debugPrint('🗑️ 분할 캐시 무효 (단면 페이지 편집됨) — 실시간 병합으로 폴백');
            _splitResultCache.remove(doublePageKey);
            _splitSourceCache.remove(doublePageKey);
            cachedSplitResult = null;
          }
        }
        if (cachedSplitResult != null) {
          debugPrint('🔄 캐시된 분할 결과 복원 중...');

          // 캐시된 분할 결과로부터 복원
          final mergedScribble = Scribble().mergeFromSplitResult(
            splitResult: cachedSplitResult,
            targetPageWidth: pageWidth,
            targetPageHeight: pageHeight,
          );

          await saveScribble(doublePageKey, mergedScribble);

          // 🎮 컨트롤러에도 반영
          if (hasController(doublePageKey)) {
            // 🚨 Widget tree lock 방지: 컨트롤러 업데이트를 다음 프레임으로 연기
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDisposed) {
                getController(doublePageKey).loadScribble(mergedScribble);
              }
            });
          }

          debugPrint('✅ 캐시 기반 병합 완료: ${mergedScribble.strokes.length} 스트로크');

          // 🚨 Widget tree lock 방지: notifyListeners를 다음 프레임으로 연기
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
              notifyListeners();
            }
          });
          return true;
        }

        // 🔍 좌우 페이지 필기 데이터 로드
        final leftScribble = await loadScribble(leftPageKey);
        final rightScribble = await loadScribble(rightPageKey);

        if (leftScribble == null && rightScribble == null) {
          debugPrint('🔄 양쪽 페이지 모두 필기 없음');
          return false;
        }

        // 🔄 양면 필기 생성
        final mergedScribble = Scribble()
          ..width = pageWidth
          ..height = pageHeight;

        // 🔄 왼쪽 페이지 스트로크 추가
        if (leftScribble != null && leftScribble.strokes.isNotEmpty) {
          mergedScribble.strokes.addAll(leftScribble.strokes);
          debugPrint('  - 왼쪽 스트로크 추가: ${leftScribble.strokes.length}');
        }

        // 🔄 텍스트/이미지 객체 보존 (왼쪽은 그대로, 오른쪽은 x 오프셋)
        if (leftScribble != null) {
          mergedScribble.textDrawables.addAll(
            leftScribble.textDrawables.map((t) => t.deepCopy()),
          );
          mergedScribble.imageDrawables.addAll(
            leftScribble.imageDrawables.map((i) => i.deepCopy()),
          );
        }
        if (rightScribble != null) {
          final boundaryX = pageWidth / 2;
          mergedScribble.textDrawables.addAll(
            rightScribble.textDrawables.map(
              (t) => t.deepCopy()..x += boundaryX,
            ),
          );
          mergedScribble.imageDrawables.addAll(
            rightScribble.imageDrawables.map(
              (i) => i.deepCopy()..x += boundaryX,
            ),
          );
        }

        // 🔄 오른쪽 페이지 스트로크를 오른쪽 위치로 이동하여 추가
        if (rightScribble != null && rightScribble.strokes.isNotEmpty) {
          final pageBoundaryX = pageWidth / 2;

          for (final stroke in rightScribble.strokes) {
            final adjustedStroke = Stroke()
              ..ink = stroke.ink
              ..width = stroke.width
              ..color = stroke.color;

            // 오른쪽 페이지 좌표를 양면 모드 좌표로 변환
            for (final point in stroke.points) {
              adjustedStroke.points.add(
                Point()
                  ..x =
                      point.x +
                      pageBoundaryX // X 좌표를 오른쪽으로 이동
                  ..y = point.y
                  ..p = point.p
                  ..altitude = point.altitude
                  ..azimuth = point.azimuth
                  ..opacity = point.opacity
                  ..size.addAll(point.size)
                  ..timestamp = point.timestamp,
              );
            }

            mergedScribble.strokes.add(adjustedStroke);
          }

          debugPrint(
            '  - 오른쪽 스트로크 추가 (좌표 조정): ${rightScribble.strokes.length}',
          );
        }

        // 💾 병합된 결과 저장
        await saveScribble(doublePageKey, mergedScribble);

        // 🎮 컨트롤러에도 반영
        if (hasController(doublePageKey)) {
          // 🚨 Widget tree lock 방지: 컨트롤러 업데이트를 다음 프레임으로 연기
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
              getController(doublePageKey).loadScribble(mergedScribble);
            }
          });
        }

        debugPrint('✅ 단면→양면 스트로크 병합 완료: ${mergedScribble.strokes.length} 스트로크');

        // 🚨 Widget tree lock 방지: notifyListeners를 다음 프레임으로 연기
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) {
            notifyListeners();
          }
        });
        return true;
      } on Exception catch (error, stackTrace) {
        debugPrint('❌ 스트로크 병합 실패: $error');
        debugPrintStack(stackTrace: stackTrace);
        return false;
      }
    }

    /// 🔄 **분할 결과 캐시 정리**
    void clearSplitResultCache() {
      _splitResultCache.clear();
      _splitSourceCache.clear();
      debugPrint('🗑️ 모든 분할 결과 캐시 제거');
    }

    /// 파일 경로 생성
    /// key 형식: 'contentId/pageId' -> 파일 경로: {cacheDir}/contentId/pageId.bin
    Future<String> _getFilePath(String key) async {
      final dir = await cacheDirectory;
      final keyParts = key.split('/');

      // 키가 계층 구조인 경우 디렉토리 생성
      if (keyParts.length > 1) {
        final subDirPath = keyParts.sublist(0, keyParts.length - 1).join('/');
        final subDir = Directory('${dir.path}/$subDirPath');

        if (!await subDir.exists()) {
          await subDir.create(recursive: true);
        }
      }

      return '${dir.path}/$key.bin';
    }

    /// 캐시 키 정규화 (특수 문자 처리)
    String _normalizeKey(String key) {
      return key.replaceAll(RegExp(r'[<>:"|?*]'), '_');
    }

    /// 🖼️ 필기 복잡도에 따른 최적 픽셀 비율 계산
    ///
    /// [key] 캐시 키
    ///
    /// 반환: 계산된 픽셀 비율 (2.0 ~ 4.0)
    double _calculateOptimalPixelRatio(String key) {
      final controller = getController(key);

      if (controller.repaintBoundaryKey.currentContext != null) {
        final renderBox =
            controller.repaintBoundaryKey.currentContext!.findRenderObject()
                as RenderBox?;

        if (renderBox != null) {
          final currentSize = renderBox.size;

          // ✨ 1순위: 저장된 원본 이미지 크기 사용
          final originalSize = _originalImageSizes[_normalizeKey(key)];
          Size targetSize;

          targetSize = originalSize != null
              ? originalSize
              : _determineTargetResolution(
                  currentSize,
                ); // 목표 해상도 대비 현재 위젯 크기 비율 계산
          final widthRatio = targetSize.width / currentSize.width;
          final heightRatio = targetSize.height / currentSize.height;

          // 🎯 원본 비율 유지를 위해 더 작은 비율 사용 (aspect ratio 보존)
          final calculatedRatio = math.min(widthRatio, heightRatio);

          // 안전 범위 내에서 제한 (0.5 ~ 8.0)
          return calculatedRatio.clamp(0.5, 8.0);
        }
      }

      // Fallback: 필기 복잡도 기반 계산
      final stats = getPageStats(key);
      if (stats == null) {
        return 2.0; // 기본값
      }

      // 필기 복잡도 계산 (스트로크 수 + 총 포인트 수 고려)
      final strokeCount = stats.strokeCount;
      final totalPointCount = stats.totalPointCount;

      // 복잡도 점수 계산 (0.0 ~ 100.0+)
      final complexity = (strokeCount * 0.3) + (totalPointCount / 100 * 0.7);

      // 복잡도에 따른 픽셀 비율 결정
      if (complexity < 10) {
        return 2.0; // 간단한 필기
      } else if (complexity < 30) {
        return 3.0; // 보통 복잡도
      } else {
        return 4.0; // 복잡한 필기
      }
    }

    /// ✨ 목표 해상도 결정 (원본 이미지 크기를 모를 때)
    Size _determineTargetResolution(Size currentSize) {
      // 방법 1: 표준 인쇄 해상도 기준 (A4 300DPI)
      const a4At300DPI = Size(2480, 3508);

      // 방법 2: 현재 크기의 배율 기준 (고해상도)
      final highRes3x = Size(currentSize.width * 3, currentSize.height * 3);

      // 방법 3: 디바이스 픽셀 밀도 기준
      final devicePixelRatio = math.max(2.0, 3.0); // 일반적인 모바일 기기 범위
      final deviceBasedRes = Size(
        currentSize.width * devicePixelRatio,
        currentSize.height * devicePixelRatio,
      );

      // 방법 4: 화면 크기별 적응적 해상도
      Size adaptiveRes;
      if (currentSize.width < 400) {
        // 작은 화면: 1080p 기준
        adaptiveRes = const Size(1080, 1920);
      } else if (currentSize.width < 800) {
        // 중간 화면: 1440p 기준
        adaptiveRes = const Size(1440, 2560);
      } else {
        // 큰 화면: 4K 기준
        adaptiveRes = const Size(2160, 3840);
      }

      // 우선순위: A4 표준 > 적응적 해상도 > 3배율 > 디바이스 기준
      // A4 표준이 현재 크기보다 충분히 크면 사용
      if (a4At300DPI.width > currentSize.width * 1.5) {
        return a4At300DPI;
      }

      // 적응적 해상도가 적절하면 사용
      if (adaptiveRes.width > currentSize.width * 1.2) {
        return adaptiveRes;
      }

      // 3배율이 적절하면 사용
      if (highRes3x.width <= 4000) {
        // 메모리 제한 고려
        return highRes3x;
      }

      // 기본: 디바이스 기준
      return deviceBasedRes;
    }

    // ===== 내부 헬퍼 메서드들 =====

    /// 모든 캐시된 컨트롤러에 동일한 작업을 적용하는 공통 헬퍼
    void _applyToAllControllers(
      void Function(ScribbleController controller) action,
    ) {
      for (final controller in _controllerCache.values) {
        action(controller);
      }
    }

    /// 모든 컨트롤러에 현재 도구 설정 적용
    void _applyToolSettingsToAllControllers() {
      _applyToAllControllers(_syncToolSettingsToController);
    }

    /// 특정 컨트롤러에 도구 설정 동기화
    void _syncToolSettingsToController(ScribbleController controller) {
      // 🌍 전역 상태가 우선, 매니저 상태는 참고용으로만 사용
      final globalState = DrawingState();

      // 🚫 전역 상태와 충돌 방지: 전역 상태를 modeNotifier에 적용
      globalState.applyToModeNotifier(controller.modeNotifier);

      // 🔄 매니저 내부 상태도 전역 상태와 동기화
      _currentTool = _convertToScribbleTool(globalState.selectedTool.value);
      _currentColor = globalState.selectedColor.value;
      _currentStrokeWidth = globalState.selectedThickness.value;
    }

    /// DrawingTool을 ScribbleTool로 변환
    String _convertToScribbleTool(DrawingTool tool) {
      switch (tool) {
        case DrawingTool.pen:
          return ScribbleTool.pen;
        case DrawingTool.pencil:
          return ScribbleTool.pencil;
        case DrawingTool.marker:
          return ScribbleTool.marker;
        case DrawingTool.fixedPen:
          return ScribbleTool.fixedPen;
        case DrawingTool.uniformPen:
          return ScribbleTool.uniformPen;
        case DrawingTool.erase:
          return ScribbleTool.eraser;
        case DrawingTool.highlighter:
          return ScribbleTool.marker; // 하이라이터는 마커로 처리
        case DrawingTool.text:
          return ScribbleTool.text;
        case DrawingTool.shape:
          return ScribbleTool.shape;
        case DrawingTool.lasso:
          return ScribbleTool.lasso;
      }
    }

    /// 모든 컨트롤러에 포인터 모드 동기화
    void _syncPointerModeToAllControllers() {
      _applyToAllControllers(_applyPointerModeToController);
    }

    /// 개별 컨트롤러에 포인터 모드 적용
    void _applyPointerModeToController(ScribbleController controller) {
      final scribbleMode = _currentPointerMode == 'all'
          ? ScribblePointerMode.all
          : ScribblePointerMode.penOnly;

      try {
        // ScribbleModeNotifier에 포인터 모드 설정
        controller.modeNotifier.setAllowedPointersMode(scribbleMode);
      } on Exception catch (error) {
        debugPrint('ScribbleCacheManager: 포인터 모드 설정 실패 - $error');
      }
    }

    /// 실제 파일 저장 수행 (내부 메서드)
    Future<bool> _saveToFileImmediately(
      String normalizedKey,
      Scribble scribble,
    ) async {
      // 웹에서는 파일 I/O 불가 → 메모리 캐시만 사용
      if (_isWeb) return true;

      try {
        final filePath = await _getFilePath(normalizedKey);

        // 바이너리 데이터로 변환
        final buffer = scribble.writeToBuffer();

        // 파일에 저장
        final file = File(filePath);
        await file.writeAsBytes(buffer);

        debugPrint('ScribbleCacheManager: 파일 저장 완료 - $normalizedKey');
        return true;
      } on Exception catch (error) {
        debugPrint('ScribbleCacheManager: 파일 저장 실패 - $normalizedKey: $error');
        return false;
      }
    }
  }
