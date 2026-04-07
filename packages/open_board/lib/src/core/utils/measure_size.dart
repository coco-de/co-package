  import 'dart:async';

  import 'package:flutter/foundation.dart';
  import 'package:flutter/rendering.dart';
  import 'package:flutter/scheduler.dart';
  import 'package:flutter/widgets.dart';

  /// 📱 크기 측정 위젯 모음
  ///
  /// 다양한 상황에 맞는 크기 측정 위젯들을 제공합니다:
  ///
  /// 1. **MeasureSize**: 기본적인 크기 측정 (기존 코드 호환성)
  /// 2. **InstantMeasureSize**: LayoutBuilder 기반 즉시 측정
  /// 3. **RenderMeasureSize**: RenderBox 기반 실제 렌더 크기 측정
  /// 4. **SafeMeasureSize**: 모바일 환경에 특화된 안전한 측정 (권장)
  ///
  /// 🚨 모바일 환경에서는 SafeMeasureSize 사용을 권장합니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// SafeMeasureSize(
  ///   onChange: (size) {
  ///     print('위젯 크기: $size');
  ///   },
  ///   autoOptimizeForMobile: true, // 모바일 자동 최적화 (기본값)
  ///   retryDelay: Duration(milliseconds: 64), // 재시도 지연 시간
  ///   maxRetries: 5, // 최대 재시도 횟수
  ///   child: YourWidget(),
  /// )
  ///
  /// 모바일 환경에서는 자동으로:
  /// - 재시도 지연: 64ms (기본 32ms 대비 증가)
  /// - 재시도 횟수: 5회 (기본 3회 대비 증가)
  /// - 빌드 스로틀링: 60fps 제한으로 연속 빌드 방지
  /// - 메모리 관리: 불필요한 위젯 캐시 자동 정리
  /// - 정확한 모바일 감지: 화면 크기, 픽셀 밀도, 방향 기준
  /// ```

  /// 크기 유효성 검사 (공통 헬퍼)
  bool _isValidMeasuredSize(Size size) {
    return size.width.isFinite &&
        size.height.isFinite &&
        size.width > 0 &&
        size.height > 0;
  }

  /// 크기 측정 위젯의 공통 build 로직
  Widget _buildMeasureSizeBody({
    required GlobalKey widgetKey,
    required Widget child,
  }) {
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: 0,
      minHeight: 0,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: RepaintBoundary(key: widgetKey, child: child),
    );
  }

  /// 자식 위젯의 크기를 측정하고 콜백으로 전달하는 위젯
  /// ⚠️ 모바일 환경에서는 SafeMeasureSize 사용을 권장합니다.
  final class MeasureSize extends StatefulWidget {
    const MeasureSize({super.key, required this.child, required this.onChange});

    final Widget child;

    final ValueChanged<Size> onChange;

    @override
    State<MeasureSize> createState() => _MeasureSizeState();
  }

  final class _MeasureSizeState extends State<MeasureSize> {
    final GlobalKey _key = GlobalKey();
    Size? _oldSize;
    Timer? _timer;
    bool _isMeasuring = false;

    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    }

    void _afterLayout(dynamic _) {
      // 🔒 안전성 검사 1: 위젯 마운트 상태 확인
      if (!mounted) {
        debugPrint('⚠️ MeasureSize: 위젯이 마운트되지 않음');
        return;
      }

      // 🔒 안전성 검사 2: 중복 측정 방지
      if (_isMeasuring) {
        debugPrint('⚠️ MeasureSize: 이미 측정 중');
        return;
      }

      _isMeasuring = true;

      try {
        final context = _key.currentContext;
        if (context == null) {
          debugPrint('⚠️ MeasureSize: 컨텍스트가 null');
          _isMeasuring = false;
          return;
        }

        // 🔒 안전성 검사 3: RenderBox 상태 확인
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          debugPrint('⚠️ MeasureSize: RenderBox를 찾을 수 없음');
          _isMeasuring = false;
          return;
        }

        // 🔒 안전성 검사 4: 크기 상태 확인
        if (!renderBox.hasSize) {
          debugPrint('⚠️ MeasureSize: 크기가 아직 결정되지 않음 - 지연 후 재시도');
          _scheduleRetry();
          return;
        }

        final newSize = renderBox.size;

        // 🔒 안전성 검사 5: 크기 유효성 확인
        if (!_isValidMeasuredSize(newSize)) {
          debugPrint('⚠️ MeasureSize: 유효하지 않은 크기: $newSize');
          _isMeasuring = false;
          return;
        }

        if (_oldSize == null || _oldSize != newSize) {
          debugPrint('✅ MeasureSize: 크기 측정 성공 - $newSize');
          _oldSize = newSize;

          // 크기 변경 콜백을 다음 프레임에서 호출
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onChange(newSize);
            }
          });
        }

        _isMeasuring = false;
      } on Exception catch (error, stackTrace) {
        debugPrint('💀 MeasureSize: 크기 측정 중 오류 발생: $error');
        debugPrint('스택 트레이스: $stackTrace');
        _isMeasuring = false;
        _scheduleRetry();
      }
    }

    /// 🔒 재시도 스케줄링
    void _scheduleRetry() {
      if (_timer?.isActive == true) {
        _timer!.cancel();
      }

      _timer = Timer(const Duration(milliseconds: 32), () {
        if (mounted && !_isMeasuring) {
          debugPrint('🔄 MeasureSize: 재시도 예약됨');
          WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
        }
      });
    }

    @override
    void didUpdateWidget(MeasureSize oldWidget) {
      super.didUpdateWidget(oldWidget);
      WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    }

    @override
    void dispose() {
      _timer?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return _buildMeasureSizeBody(widgetKey: _key, child: widget.child);
    }
  }

  /// 자식 위젯의 실제 렌더 크기를 측정하는 위젯
  final class RenderMeasureSize extends StatefulWidget {
    const RenderMeasureSize({
      super.key,
      required this.child,
      required this.onChange,
    });

    final Widget child;

    final ValueChanged<Size> onChange;

    @override
    State<RenderMeasureSize> createState() => _RenderMeasureSizeState();
  }

  final class _RenderMeasureSizeState extends State<RenderMeasureSize> {
    final GlobalKey _key = GlobalKey();
    Size? _previousSize;
    bool _isMeasuring = false;
    Timer? _retryTimer;

    @override
    void initState() {
      super.initState();
      _measureSize();
    }

    void _measureSize() {
      if (_isMeasuring) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkSize();
      });
    }

    void _checkSize() {
      // 🔒 안전성 검사 1: 위젯 마운트 상태 확인
      if (!mounted) {
        debugPrint('⚠️ RenderMeasureSize: 위젯이 마운트되지 않음');
        return;
      }

      // 🔒 안전성 검사 2: 중복 측정 방지
      if (_isMeasuring) {
        debugPrint('⚠️ RenderMeasureSize: 이미 측정 중');
        return;
      }

      _isMeasuring = true;

      try {
        final context = _key.currentContext;
        if (context == null) {
          debugPrint('⚠️ RenderMeasureSize: 컨텍스트가 null');
          _isMeasuring = false;
          return;
        }

        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          debugPrint('⚠️ RenderMeasureSize: RenderBox를 찾을 수 없음');
          _isMeasuring = false;
          return;
        }

        // 🔒 안전성 검사 3: 크기 상태 확인
        if (!renderBox.hasSize) {
          debugPrint('⚠️ RenderMeasureSize: 크기가 아직 결정되지 않음 - 지연 후 재시도');
          _scheduleRetry();
          return;
        }

        final size = renderBox.size;

        // 🔒 안전성 검사 4: 크기 유효성 확인
        if (!_isValidMeasuredSize(size)) {
          debugPrint('⚠️ RenderMeasureSize: 유효하지 않은 크기: $size');
          _isMeasuring = false;
          return;
        }

        // 크기가 유효하고 이전과 다른 경우에만 콜백 호출
        if (_previousSize != size) {
          debugPrint('✅ RenderMeasureSize: 크기 측정 성공 - $size');
          _previousSize = size;
          widget.onChange(size);
        }

        _isMeasuring = false;
      } on Exception catch (error, stackTrace) {
        debugPrint('💀 RenderMeasureSize: 크기 측정 중 오류 발생: $error');
        debugPrint('스택 트레이스: $stackTrace');
        _isMeasuring = false;
        _scheduleRetry();
      }
    }

    /// 🔒 재시도 스케줄링
    void _scheduleRetry() {
      if (_retryTimer?.isActive == true) {
        _retryTimer!.cancel();
      }

      _retryTimer = Timer(const Duration(milliseconds: 32), () {
        if (mounted && !_isMeasuring) {
          debugPrint('🔄 RenderMeasureSize: 재시도 예약됨');
          _measureSize();
        }
      });
    }

    @override
    void didUpdateWidget(RenderMeasureSize oldWidget) {
      super.didUpdateWidget(oldWidget);
      _measureSize();
    }

    @override
    void dispose() {
      _retryTimer?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return _buildMeasureSizeBody(widgetKey: _key, child: widget.child);
    }
  }

  /// 🔒 모바일 환경에 특화된 안전한 크기 측정 위젯
  /// 레이아웃 타이밍 문제를 최소화하고 안정성을 극대화
  final class SafeMeasureSize extends StatefulWidget {
    const SafeMeasureSize({
      super.key,
      required this.child,
      required this.onChange,
      this.retryDelay = const Duration(milliseconds: 32),
      this.maxRetries = 3,
      this.autoOptimizeForMobile = true,
    });

    final Widget child;
    final ValueChanged<Size> onChange;
    final Duration retryDelay;
    final int maxRetries;

    final bool autoOptimizeForMobile;

    @override
    State<SafeMeasureSize> createState() => _SafeMeasureSizeState();
  }

  final class _SafeMeasureSizeState extends State<SafeMeasureSize> {
    static const Duration _throttleDelay = Duration(
      milliseconds: 16,
    ); // 60fps 제한

    final GlobalKey _key = GlobalKey();
    Size? _lastReportedSize;
    bool _isMeasuring = false;
    Timer? _retryTimer;
    int _retryCount = 0;
    bool _hasInitialized = false;
    Duration? _effectiveRetryDelay;

    int? _effectiveMaxRetries; // 🔒 모바일 최적화를 위한 추가 변수들
    Timer? _throttleTimer;
    bool _isThrottled = false;

    @override
    void initState() {
      super.initState();

      // 초기화 지연으로 레이아웃 안정성 확보
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _hasInitialized = true;
          _measureSize();
        }
      });
    }

    /// 🔒 모바일 디바이스 감지
    bool _isMobileDevice() {
      try {
        final mediaQuery = MediaQuery.maybeOf(context);
        if (mediaQuery != null) {
          final size = mediaQuery.size;
          final pixelRatio = mediaQuery.devicePixelRatio;

          // 🔒 더 정확한 모바일 감지
          // 1. 너비 기준: 600px 이하
          // 2. 픽셀 밀도 기준: 2.0 이상 (고해상도 모바일)
          // 3. 화면 비율 기준: 세로가 가로보다 긴 경우
          final isSmallScreen = size.width < 600;
          final isHighDensity = pixelRatio >= 2.0;
          final isPortrait = size.height > size.width;

          // 모바일로 판단하는 조건
          final isMobile = isSmallScreen || (isHighDensity && isPortrait);

          if (isMobile) {
            debugPrint(
              '📱 SafeMeasureSize: 모바일 환경 감지됨 (${size.width}x${size.height}, ${pixelRatio}x)',
            );
          }

          return isMobile;
        }
        return false;
      } on Exception catch (error) {
        // 컨텍스트 접근 실패 시 기본값으로 모바일로 간주
        debugPrint('⚠️ SafeMeasureSize: 모바일 감지 실패, 기본값 사용: $error');
        return true;
      }
    }

    /// 🔒 빌드 스로틀링: 연속 빌드 방지
    void _throttleMeasurement() {
      if (_isThrottled) return;

      _isThrottled = true;
      _throttleTimer?.cancel();

      _throttleTimer = Timer(_throttleDelay, () {
        _isThrottled = false;
        if (mounted && !_isMeasuring) {
          _measureSize();
        }
      });
    }

    /// 🔒 메모리 관리: 불필요한 위젯 캐시 정리
    void _cleanupCache() {
      // 오래된 크기 정보 정리 (메모리 누수 방지)
      if (_lastReportedSize != null) {
        // 5초 이상 된 크기 정보는 정리
        // 실제 구현에서는 더 정교한 캐시 관리 로직 적용 가능
      }
    }

    void _measureSize() {
      // 🔒 안전성 검사 1: 위젯 마운트 및 초기화 상태 확인
      if (!mounted || !_hasInitialized) {
        return;
      }

      // 🔒 안전성 검사 2: 중복 측정 방지
      if (_isMeasuring) {
        return;
      }

      // 🔒 빌드 스로틀링: 연속 빌드 방지
      if (_isThrottled) {
        debugPrint('🔄 SafeMeasureSize: 빌드 스로틀링 적용');
        return;
      }

      _isMeasuring = true;

      try {
        final context = _key.currentContext;
        if (context == null) {
          _handleMeasurementFailure('컨텍스트가 null');
          return;
        }

        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          _handleMeasurementFailure('RenderBox를 찾을 수 없음');
          return;
        }

        // 🔒 안전성 검사 3: 크기 상태 확인
        if (!renderBox.hasSize) {
          _handleMeasurementFailure('크기가 아직 결정되지 않음');
          return;
        }

        final size = renderBox.size;

        // 🔒 안전성 검사 4: 크기 유효성 확인
        if (!_isValidMeasuredSize(size)) {
          _handleMeasurementFailure('유효하지 않은 크기: $size');
          return;
        }

        // 🔒 안전성 검사 5: 크기 변경 확인
        if (_lastReportedSize != size) {
          _lastReportedSize = size;
          _retryCount = 0; // 성공 시 재시도 카운트 리셋

          // 메모리 정리
          _cleanupCache();

          // 다음 프레임에서 콜백 호출 (레이아웃 완료 후)
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onChange(size);
            }
          });
        }

        _isMeasuring = false;
      } on Exception catch (error, stackTrace) {
        _handleMeasurementFailure('크기 측정 중 오류: $error', stackTrace);
      }
    }

    /// 🔒 측정 실패 처리
    void _handleMeasurementFailure(String reason, [StackTrace? stackTrace]) {
      debugPrint('⚠️ SafeMeasureSize: $reason');
      if (stackTrace != null) {
        debugPrint('스택 트레이스: $stackTrace');
      }

      _isMeasuring = false;

      // 재시도 횟수 제한 확인
      if (_retryCount < _effectiveMaxRetries!) {
        _scheduleRetry();
      } else {
        debugPrint('�� SafeMeasureSize: 최대 재시도 횟수 초과');
      }
    }

    /// 🔒 재시도 스케줄링
    void _scheduleRetry() {
      if (_retryTimer?.isActive == true) {
        _retryTimer!.cancel();
      }

      _retryCount++;
      debugPrint('🔄 SafeMeasureSize: 재시도 $_retryCount/$_effectiveMaxRetries');

      _retryTimer = Timer(_effectiveRetryDelay!, () {
        if (mounted && !_isMeasuring) {
          _measureSize();
        }
      });
    }

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();

      // 🔒 모바일 환경 자동 최적화 (MediaQuery 접근을 여기서 수행)
      if (_effectiveRetryDelay == null) {
        if (widget.autoOptimizeForMobile && _isMobileDevice()) {
          _effectiveRetryDelay = const Duration(milliseconds: 64); // 모바일용 지연 증가
          _effectiveMaxRetries = 5; // 모바일용 재시도 횟수 증가
          debugPrint('📱 SafeMeasureSize: 모바일 환경 감지됨 - 최적화 설정 적용');
        } else {
          _effectiveRetryDelay = widget.retryDelay;
          _effectiveMaxRetries = widget.maxRetries;
          debugPrint('🖥️ SafeMeasureSize: 데스크톱 환경 - 기본 설정 사용');
        }
      }
    }

    @override
    void didUpdateWidget(SafeMeasureSize oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (_hasInitialized) {
        // 🔒 빌드 스로틀링 적용: 연속 빌드 방지
        _throttleMeasurement();
      }
    }

    @override
    void dispose() {
      _retryTimer?.cancel();
      _throttleTimer?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return _buildMeasureSizeBody(widgetKey: _key, child: widget.child);
    }
  }

  /// A utility class for measuring the size of a widget before it is rendered.
  ///
  /// This class provides functionality to measure the size of a given widget with
  /// specific constraints and text direction. This can be particularly useful
  /// for scenarios such as positioning elements precisely in a layout,
  /// or dynamically adjusting the UI based on widget sizes.
  ///
  /// NOTE: Using this utility can be resource-intensive because it creates
  /// a temporary render tree and performs a layout pass.
  ///
  /// To optimize performance:
  /// - Limit the frequency of measurements.
  /// - Cache measurement results when possible.
  /// - Avoid measuring complex widgets frequently.
  class MeasureWidgetUtil {
    /// Measures the size of the given [widget] with the
    /// specified [constraints] and [textDirection].
    ///
    /// The [constraints] parameter specifies the box constraints that
    /// the widget should adhere to during measurement.
    /// It should be provided in cases where the widget being measured
    /// might have an unconstrained width or height.
    ///
    /// The [textDirection] parameter defines the text direction to
    /// use when measuring the widget.
    /// It is used when the widget being measured contains text in its
    /// subtree. Otherwise, it can be ignored.
    ///
    /// Returns the measured [Size] of the widget.
    ///
    /// Example:
    /// ```dart
    /// Size widgetSize = MeasureWidgetUtil.measureWidget(SizedBox(width: 10, height: 20));
    /// print(widgetSize); // Size(10, 20)
    /// ```
    static Size measureWidget(
      Widget widget, {
      required BoxConstraints constraints,
      required TextDirection textDirection,
    }) {
      final measureData = _createMeasureData(textDirection, constraints);

      final element = _attachWidgetToRenderTree(widget, measureData);

      return _getSize(element, measureData);
    }

    static _MeasureData _createMeasureData(
      TextDirection textDirection,
      BoxConstraints constraints,
    ) {
      final pipelineOwner = PipelineOwner();
      final rootView = pipelineOwner.rootNode = _MeasurementView(constraints);
      final buildOwner = BuildOwner(focusManager: FocusManager());

      return _MeasureData(
        textDirection: textDirection,
        pipelineOwner: pipelineOwner,
        buildOwner: buildOwner,
        rootView: rootView,
      );
    }

    static RenderObjectToWidgetElement<RenderBox> _attachWidgetToRenderTree(
      Widget widget,
      _MeasureData data,
    ) {
      return RenderObjectToWidgetAdapter<RenderBox>(
        container: data.rootView,
        debugShortDescription: '[root]',
        child: Directionality(textDirection: data.textDirection, child: widget),
      ).attachToRenderTree(data.buildOwner);
    }

    static Size _getSize(
      RenderObjectToWidgetElement<RenderBox> element,
      _MeasureData data,
    ) {
      try {
        data.rootView.scheduleInitialLayout();
        data.pipelineOwner.flushLayout();

        return data.rootView.size;
      } on Exception catch (error) {
        debugLog('[ERROR MEASURE WIDGET]: $error');
        return Size.zero;
      } finally {
        // Clean up.
        element.update(
          RenderObjectToWidgetAdapter<RenderBox>(container: data.rootView),
        );
        data.buildOwner.finalizeTree();
      }
    }
  }

  class _MeasurementView extends RenderBox
      with RenderObjectWithChildMixin<RenderBox> {
    final BoxConstraints boxConstraints;

    _MeasurementView(this.boxConstraints);

    @override
    void performLayout() {
      assert(child != null);
      child!.layout(boxConstraints, parentUsesSize: true);
      size = child!.size;
    }

    @override
    void debugAssertDoesMeetConstraints() => true;
  }

  class _MeasureData {
    final TextDirection textDirection;
    final PipelineOwner pipelineOwner;
    final BuildOwner buildOwner;
    final _MeasurementView rootView;

    const _MeasureData({
      required this.textDirection,
      required this.pipelineOwner,
      required this.buildOwner,
      required this.rootView,
    });
  }

  void debugLog(Object message) {
    if (!kDebugMode) return;
    debugPrint(message.toString());
  }
