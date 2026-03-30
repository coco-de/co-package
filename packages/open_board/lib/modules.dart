library;

// 기존 위젯들
export 'src/module/widgets/scribble_widget.dart';
export 'src/module/widgets/simple_scribble_widget.dart'; // ✨ 간편한 위젯들

// 컨트롤러
export 'src/module/scribble_controller.dart'; // ✨ 새로운 컨트롤러

// 통합 캐시 매니저 (ScribbleController 관리 포함)
export 'src/module/managers/scribble_cache_manager.dart';

// 🔄 메타데이터 및 동기화 시스템
export 'src/module/state/scribble_metadata.dart'; // ✨ 새로운 메타데이터 시스템

// 좌표 변환
export 'src/module/coordinate_transformer.dart'; // ♻️ 스크린 ↔ 캔버스 좌표 변환 유틸리티

// 변형 핸들러
export 'src/module/transform_handler.dart'; // ♻️ 이동/크기조절/회전 공통 변형 핸들러

// ♻️ 분해된 프로세서들
export 'src/module/stroke/stroke_processor.dart'; // ♻️ 스트로크 생성/계산 유틸리티
export 'src/module/stroke/eraser_processor.dart'; // ♻️ 지우개 유틸리티
export 'src/module/text/text_drawable_manager.dart'; // ♻️ 텍스트 CRUD 관리자

// 유틸리티들
export 'src/core/utils/measure_size.dart'; // ✨ 크기 측정 유틸리티

// 노티파이어들
export 'src/module/scribble.notifier.dart';
export 'src/module/state/scribble.state.dart';

export 'src/module/scribble_mode.notifier.dart';
export 'src/module/state/scribble_mode.state.dart';

// 🌍 전역 필기 도구 상태 관리
export 'src/module/state/drawing_state.dart';
export 'src/module/state/notifier_registry.dart';
export 'src/module/state/state_synchronizer.dart';
export 'src/module/state/undo_redo_tracker.dart';
export 'src/module/state/drawing_settings_persistence.dart';

export 'src/module/keys/keys.dart';

// 모델 및 유틸리티
export 'src/core/utils/ink_group_info.dart';
export 'src/module/models/lasso_selection_state.dart';
export 'src/module/models/oriented_bounding_box.dart';

// ♻️ PaintDelegate 패턴 (ScribblePainter 분리)
export 'src/module/painter/paint_delegate.dart';
export 'src/module/painter/stroke_paint_delegate.dart';
export 'src/module/painter/shape_paint_delegate.dart';
export 'src/module/painter/lasso_paint_delegate.dart';
export 'src/module/painter/cursor_paint_delegate.dart';
