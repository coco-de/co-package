// Public API — open_epub 1.0
// Story: S1.21 (#37) — EpubBookSession.open() lifecycle + position + analytics
// Story: S1.22 (#38) — swapSource() 위치 보존 hot-swap
// BDD: F1 (책 열기), F1.2/F1.3 (위치 복원/fallback), F10 (hot-swap), F11 (analytics)

import 'dart:async';

import '../data/compat/patch_catalog.dart'
    show BookSessionDiagnostics, BookSessionDiagnosticsData, UnresolvedIssue;
import '../data/repository/epub_repository_impl.dart';
import '../domain/usecase/open_epub_use_case.dart';
import '../domain/usecase/resolve_position_use_case.dart';
import 'epub_analytics.dart';
import 'epub_book.dart';
import 'epub_position.dart';
import 'epub_security_config.dart';
import 'epub_source.dart';

/// EPUB 책 런타임 세션. open/jumpTo/page navigation/hot-swap/dispose 책임.
///
/// [open]은 [EpubSource]로부터 책을 조립하고(파싱 + 호환성 보정), 저장된
/// [initialPosition]을 복원하며(실패 시 첫 페이지로 fallback), lifecycle 분석
/// 이벤트([EpubSessionStarted])를 발사한다.
abstract class EpubBookSession implements EpubBookSessionAnalytics {
  static Future<EpubBookSession> open(
    EpubSource source, {
    EpubPosition? initialPosition,
    EpubSessionOptions options = const EpubSessionOptions(),
  }) {
    return _EpubBookSessionImpl.open(source, initialPosition, options);
  }

  /// 조립·보정 완료된 책.
  EpubBook get book;

  /// 적용된 보정 + 미해결 이슈(예: position-restore-failed) 진단.
  BookSessionDiagnostics get diagnostics;

  /// 현재 읽기 위치.
  EpubPosition get position;

  /// 현재 진도(0.0~1.0). [position]의 progress를 위임.
  double get progress;

  Future<void> jumpTo(EpubPosition position);
  Future<void> nextPage();
  Future<void> previousPage();

  /// 현재 위치에서 하이라이트 도구 사용 이벤트를 발사한다(분석용, F11).
  void recordHighlight();

  /// 현재 위치에서 북마크 도구 사용 이벤트를 발사한다(분석용, F11).
  void recordBookmark();

  /// 현재 위치를 최대한 보존하며 [newSource]로 책을 교체한다(hot-swap).
  /// 같은 spineHref가 새 책에 있으면 위치를 그대로 복원하고, 없으면 첫
  /// 페이지로 fallback하며 진단에 기록한다. (BDD F10)
  Future<void> swapSource(EpubSource newSource);

  Future<void> dispose();
}

class EpubSessionOptions {
  const EpubSessionOptions({
    this.security = const EpubSecurityConfig(),
    this.progressThrottle = const Duration(seconds: 30),
  });

  /// 책 열기 시 적용할 보안 가드(크기 제한 등).
  final EpubSecurityConfig security;

  /// progressEvents 발사 최소 간격(BDD F11 — 기본 30초마다 1회).
  final Duration progressThrottle;
}

/// 책 1권을 조립·복원한 결과(open/swap 공통). 세션 내부 상태의 스냅샷.
class _SessionState {
  _SessionState({
    required this.book,
    required this.diagnostics,
    required this.position,
    required this.navHrefs,
  });

  final EpubBook book;
  final BookSessionDiagnostics diagnostics;
  final EpubPosition position;
  final List<String> navHrefs;
}

class _EpubBookSessionImpl implements EpubBookSession {
  _EpubBookSessionImpl._(_SessionState state, this._security, this._throttle)
      : _state = state,
        _position = state.position;

  static Future<EpubBookSession> open(
    EpubSource source,
    EpubPosition? initialPosition,
    EpubSessionOptions options,
  ) async {
    final state = await _assemble(source, initialPosition, options.security);
    final session = _EpubBookSessionImpl._(
      state,
      options.security,
      options.progressThrottle,
    );

    // SessionStarted는 listener가 아직 없을 수 있으므로 버퍼에 쌓고
    // 첫 구독 시 재생한다(broadcast stream은 과거 이벤트를 보관하지 않음).
    session._emitLifecycle(
      EpubSessionStarted(epubVersion: state.book.metadata.epubVersion),
    );
    return session;
  }

  /// source → 보정 완료 책 + [target] 위치 복원/fallback → 세션 상태.
  static Future<_SessionState> _assemble(
    EpubSource source,
    EpubPosition? target,
    EpubSecurityConfig security,
  ) async {
    final loaded = await OpenEpubUseCase(
      EpubRepositoryImpl(security: security),
    ).call(source);
    final book = loaded.book;

    if (book.spine.isEmpty) {
      throw StateError('EPUB has no spine items; cannot open a session');
    }

    final resolved = const ResolvePositionUseCase().call(book, target);

    // 페이지 이동에 사용할 linear spine href 순서(없으면 전체 spine).
    final linear = [for (final s in book.spine) if (s.linear) s.href];
    final navHrefs =
        linear.isNotEmpty ? linear : [for (final s in book.spine) s.href];

    // 위치 복원 실패 시 진단에 기록(BDD F1.3 — position-restore-failed).
    var diagnostics = loaded.diagnostics;
    if (resolved.wasFallback) {
      diagnostics = BookSessionDiagnosticsData(
        appliedPatches: diagnostics.appliedPatches,
        unresolvedIssues: [
          ...diagnostics.unresolvedIssues,
          const UnresolvedIssue(
            code: 'position-restore-failed',
            message: '마지막 위치를 찾을 수 없어 처음부터 표시합니다',
          ),
        ],
      );
    }

    return _SessionState(
      book: book,
      diagnostics: diagnostics,
      position: resolved.position,
      navHrefs: navHrefs,
    );
  }

  _SessionState _state;
  final EpubSecurityConfig _security;
  final Duration _throttle;
  final Stopwatch _clock = Stopwatch()..start();
  Duration? _lastProgressAt;
  bool _disposed = false;

  late final StreamController<EpubLifecycleEvent> _lifecycle =
      StreamController<EpubLifecycleEvent>.broadcast(onListen: _flushLifecycle);
  final StreamController<EpubProgressEvent> _progress =
      StreamController<EpubProgressEvent>.broadcast();
  final StreamController<EpubToolUseEvent> _toolUse =
      StreamController<EpubToolUseEvent>.broadcast();

  final List<EpubLifecycleEvent> _lifecycleBuffer = [];

  @override
  EpubBook get book => _state.book;
  @override
  BookSessionDiagnostics get diagnostics => _state.diagnostics;

  @override
  Stream<EpubLifecycleEvent> get lifecycleEvents => _lifecycle.stream;
  @override
  Stream<EpubProgressEvent> get progressEvents => _progress.stream;
  @override
  Stream<EpubToolUseEvent> get toolUseEvents => _toolUse.stream;

  EpubPosition _position;

  @override
  EpubPosition get position => _position;

  @override
  double get progress => _position.progress;

  List<String> get _navHrefs => _state.navHrefs;

  int get _index {
    final i = _navHrefs.indexOf(_position.spineHref);
    return i < 0 ? 0 : i;
  }

  @override
  Future<void> jumpTo(EpubPosition position) async {
    _ensureActive();
    _position = position;
    _emitProgress();
  }

  @override
  Future<void> nextPage() async {
    _ensureActive();
    final next = _index + 1;
    if (next >= _navHrefs.length) return;
    _position = _positionAt(next);
    _emitProgress();
  }

  @override
  Future<void> previousPage() async {
    _ensureActive();
    final prev = _index - 1;
    if (prev < 0) return;
    _position = _positionAt(prev);
    _emitProgress();
  }

  EpubPosition _positionAt(int index) {
    final href = _navHrefs[index];
    final denom = _navHrefs.length <= 1 ? 1 : _navHrefs.length - 1;
    final p = index / denom;
    if (book.layout == EpubLayout.fixedLayout) {
      return EpubFixedPosition(spineHref: href, progress: p, pageIndex: 0);
    }
    return EpubReflowablePosition(spineHref: href, progress: p, charOffset: 0);
  }

  @override
  void recordHighlight() {
    _ensureActive();
    if (!_toolUse.isClosed) {
      _toolUse.add(EpubHighlightToolUse(position: _position));
    }
  }

  @override
  void recordBookmark() {
    _ensureActive();
    if (!_toolUse.isClosed) {
      _toolUse.add(EpubBookmarkToolUse(position: _position));
    }
  }

  @override
  Future<void> swapSource(EpubSource newSource) async {
    _ensureActive();
    // 현재 위치를 보존 대상으로 전달 → 새 책에 같은 spineHref가 있으면 복원,
    // 없으면 첫 페이지 fallback + position-restore-failed 진단. (BDD F10)
    final next = await _assemble(newSource, _position, _security);
    _ensureActive();
    _state = next;
    _position = next.position;
    _emitProgress();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _clock.stop();
    _emitLifecycle(EpubSessionEnded(sessionElapsed: _clock.elapsed));
    await _lifecycle.close();
    await _progress.close();
    await _toolUse.close();
  }

  void _emitLifecycle(EpubLifecycleEvent event) {
    if (_lifecycle.isClosed) return;
    if (_lifecycle.hasListener) {
      _lifecycle.add(event);
    } else {
      _lifecycleBuffer.add(event);
    }
  }

  void _flushLifecycle() {
    // 첫 listener 구독 시점에 버퍼된 이벤트(SessionStarted 등)를 재생한다.
    scheduleMicrotask(() {
      for (final event in _lifecycleBuffer) {
        if (!_lifecycle.isClosed) _lifecycle.add(event);
      }
      _lifecycleBuffer.clear();
    });
  }

  void _emitProgress() {
    if (_progress.isClosed) return;
    final now = _clock.elapsed;
    // throttle: 직전 발사 이후 [_throttle] 미만이면 억제(위치는 이미 갱신됨).
    if (_lastProgressAt != null && now - _lastProgressAt! < _throttle) return;
    _lastProgressAt = now;
    _progress.add(
      EpubProgressEvent(progress: _position.progress, sessionElapsed: now),
    );
  }

  void _ensureActive() {
    if (_disposed) throw StateError('EpubBookSession already disposed');
  }
}
