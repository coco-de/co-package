library;

// 기존 위젯들
export 'src/module/widgets/scribble_widget.dart';
export 'src/module/widgets/simple_scribble_widget.dart'; // ✨ 간편한 위젯들
export 'src/module/widgets/scribble_floating_toolbar.dart'; // ✨ 플로팅 도구 패널

// 컨트롤러
export 'src/module/scribble_controller.dart'; // ✨ 새로운 컨트롤러

// 통합 캐시 매니저 (ScribbleController 관리 포함)
export 'src/module/managers/scribble_cache_manager.dart';

// 다중 페이지 관리 컨트롤러
export 'src/module/managers/scribble_book_controller.dart';

// 이벤트 시스템 (리플레이/동기화용)
export 'src/module/events/scribble_book_event.dart';
export 'src/module/events/scribble_event_bridge.dart';

// 스트로크 해시 유틸리티 (중복 제거용)
export 'src/core/utils/scribble_hash_util.dart';

// 리플레이 엔진
export 'src/module/replay/scribble_replay_controller.dart';
export 'src/module/replay/timeline_file.dart';
export 'src/module/replay/content_fingerprint_util.dart';
export 'src/module/replay/timeline_migrator.dart';
export 'src/module/replay/scribble_timeline_recorder.dart';
export 'src/module/replay/stroke_animator.dart';
export 'src/module/replay/scribble_replay_handler.dart';

// 타임라인 모델
export 'src/data/model/timeline/timeline_models.dart';
export 'src/data/model/timeline/timeline_serializer.dart';

// 실시간 세션 (Transport 추상화)
export 'src/module/live/domain/transport/live_session_transport.dart';
export 'src/module/live/domain/model/transport_state.dart';
export 'src/module/live/domain/model/transport_message.dart';
export 'src/module/live/domain/model/session_participant.dart';
export 'src/module/live/domain/batcher/event_batcher.dart';
export 'src/module/live/domain/batcher/viewport_throttler.dart';
export 'src/module/live/data/transport/local_loopback_transport.dart';
export 'src/module/live/data/renderer/remote_stroke_renderer.dart';
export 'src/module/live/presentation/live_session_controller.dart';
export 'src/module/live/presentation/adaptive_viewport_calculator.dart';
export 'src/module/live/presentation/viewport_animator.dart';
export 'src/module/live/domain/model/live_session.dart';
export 'src/module/live/domain/sync/late_join_synchronizer.dart';
export 'src/module/live/di/live_session_scope.dart';
export 'src/module/live/presentation/synced_replay_controller.dart';
export 'src/module/live/domain/storage/session_storage.dart';
export 'src/module/live/domain/recording/egress_controller.dart';

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

// 🖼️ 이미지 임베드 (Story #172 / Epic #171)
export 'src/module/adapters/image_picker_adapter.dart';
export 'src/module/image/image_drawable_factory.dart';
export 'src/module/image/image_drawable_extensions.dart';
export 'src/module/image/image_drawable_manager.dart';

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
export 'src/module/state/viewer_gesture_bus.dart'; // ✨ G1 도구바 핸들↔캔버스 게이트
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
