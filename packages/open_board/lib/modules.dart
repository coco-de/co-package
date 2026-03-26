library;

// 기존 위젯들
export 'src/module/widgets/scribble_widget.dart';
export 'src/module/widgets/simple_scribble_widget.dart'; // ✨ 간편한 위젯들

// ✨ 통합된 필기 시스템 (ScribbleCacheManager로 통합됨)
export 'src/module/widgets/scribble_drawing_toolbar.dart';

// 컨트롤러
export 'src/module/scribble_controller.dart'; // ✨ 새로운 컨트롤러

// 통합 캐시 매니저 (ScribbleController 관리 포함)
export 'src/module/managers/scribble_cache_manager.dart';

// 🔄 메타데이터 및 동기화 시스템
export 'src/module/state/scribble_metadata.dart'; // ✨ 새로운 메타데이터 시스템

// 유틸리티들
export 'src/core/utils/measure_size.dart'; // ✨ 크기 측정 유틸리티

// 노티파이어들
export 'src/module/scribble.notifier.dart';
export 'src/module/state/scribble.state.dart';
export 'src/module/state/scribble_state_builder.dart';

export 'src/module/scribble_mode.notifier.dart';
export 'src/module/state/scribble_mode.state.dart';

// 🌍 전역 필기 도구 상태 관리
export 'src/module/state/drawing_state.dart';

export 'src/module/keys/keys.dart';
