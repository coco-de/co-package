// 하이라이트 데모 페이지 (#43).
//
// 텍스트 선택 → 색상 선택 → 하이라이트 → 메모 기록 흐름을 1.0 공개 API
// (open_epub_v1.dart)만으로 구현한 호스트 앱 레퍼런스.
//
// 이 파일에서만 `package:open_epub/open_epub_v1.dart`를 import한다
// (레거시 barrel과 EpubSource 이름 충돌 — v1_demo_page.dart와 같은 규칙).
//
// 동작 방식:
//   - SelectionArea가 ReflowableEngine(내부 Text.rich)을 감싸 본문 선택 지원
//   - 텍스트 선택 시 "하이라이트" FAB가 나타남 (#45). 데스크톱 웹에서는
//     SelectionArea의 contextMenuBuilder 툴바가 표시되지 않으므로(드래그
//     선택 후 미표시 + BrowserContextMenu가 우클릭을 가로챔) FAB가 전
//     플랫폼에서 동작하는 기본 진입점이다. 모바일·네이티브에서는 컨텍스트
//     메뉴의 "하이라이트"도 함께 동작한다.
//   - 색상 4종 + 메모 입력 시트 → 저장
//   - 저장된 하이라이트는 xhtmlLoader에서 XHTML에 배경색 span으로 주입
//   - shared_preferences에 JSON으로 영속, session.recordHighlight()로
//     toolUseEvents(F11) 연동
//
// 한계(데모 수준, 코어 charOffset 기반 정밀 하이라이트는 E3/S3.13 범위):
//   - 위치 추적은 "선택 평문의 첫 일치" 기반 — 여러 문단에 걸친 선택 등
//     원문과 일치하지 않으면 목록에는 남고 본문 표시만 생략된다.
//   - 하이라이트 추가/삭제 시 엔진을 재생성해 본문을 다시 그리므로 챕터 내
//     스크롤 위치가 최상단으로 초기화된다 (엔진 reload API는 E3 검토 대상).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show BrowserContextMenu, rootBundle;
import 'package:open_epub/open_epub_v1.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 하이라이트 색상 팔레트 (BDD F5 — 4색).
const Map<String, Color> highlightPalette = {
  '노랑': Color(0xFFFFF59D),
  '초록': Color(0xFFC8E6C9),
  '파랑': Color(0xFFBBDEFB),
  '분홍': Color(0xFFF8BBD0),
};

String _cssHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// 데모 하이라이트 1건. 선택 평문 텍스트 + 색상 + 메모.
@immutable
class DemoHighlight {
  const DemoHighlight({
    required this.id,
    required this.spineHref,
    required this.text,
    required this.colorName,
    this.note = '',
  });

  factory DemoHighlight.fromJson(Map<String, dynamic> json) => DemoHighlight(
        id: json['id'] as String,
        spineHref: json['spineHref'] as String,
        text: json['text'] as String,
        colorName: json['colorName'] as String,
        note: (json['note'] as String?) ?? '',
      );

  final String id;
  final String spineHref;
  final String text;
  final String colorName;
  final String note;

  Color get color => highlightPalette[colorName] ?? highlightPalette['노랑']!;

  DemoHighlight copyWith({String? note}) => DemoHighlight(
        id: id,
        spineHref: spineHref,
        text: text,
        colorName: colorName,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'spineHref': spineHref,
        'text': text,
        'colorName': colorName,
        'note': note,
      };
}

/// XHTML 본문에 하이라이트 배경색 span을 주입한다 (각 하이라이트당 첫 일치
/// 1회). 일치하지 않는 하이라이트는 건너뛴다 — 본문 표시만 생략되고 목록에는
/// 남는다 (BDD @edge).
///
/// 마크업 안전 가드: 검색은 `<body` 이후부터 시작하고, 태그 내부(`<`와 `>`
/// 사이 — 태그명/속성/이미 주입된 span의 style 포함)에 걸린 일치는 건너뛰고
/// 다음 일치를 찾는다. "head" 같은 본문 단어가 태그를 파손하는 것을 방지.
String injectHighlightSpans(String xhtml, Iterable<DemoHighlight> highlights) {
  var out = xhtml;
  for (final highlight in highlights) {
    final text = highlight.text;
    if (text.isEmpty) continue;
    final start = _indexOfInTextContent(out, text);
    if (start < 0) continue;
    final replacement =
        '<span style="background-color:${_cssHex(highlight.color)};">'
        '$text</span>';
    out = out.replaceRange(start, start + text.length, replacement);
  }
  return out;
}

/// [xhtml]의 body 영역 텍스트 콘텐츠에서 [text]의 첫 일치 위치를 찾는다.
/// 태그 내부 일치는 건너뛴다. 없으면 -1.
int _indexOfInTextContent(String xhtml, String text) {
  final bodyStart = xhtml.indexOf('<body');
  var searchFrom = bodyStart < 0 ? 0 : bodyStart;
  while (true) {
    final start = xhtml.indexOf(text, searchFrom);
    if (start < 0) return -1;
    final lastOpen = xhtml.lastIndexOf('<', start);
    final lastClose = xhtml.lastIndexOf('>', start);
    final insideTag = lastOpen > lastClose;
    if (!insideTag) return start;
    searchFrom = start + 1;
  }
}

/// shared_preferences 기반 하이라이트 저장소.
class HighlightStore {
  const HighlightStore();

  static const String storageKey = 'open_epub_example.highlights';

  Future<List<DemoHighlight>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in decoded)
          DemoHighlight.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      // 손상된 저장 데이터는 무시하고 빈 목록으로 시작한다.
      return [];
    }
  }

  Future<void> save(List<DemoHighlight> highlights) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode([for (final h in highlights) h.toJson()]),
    );
  }
}

class HighlightDemoPage extends StatefulWidget {
  const HighlightDemoPage({super.key, this.bytesOverride});

  /// 테스트 주입용 EPUB 바이트. null이면 assets/example.epub 사용.
  final Uint8List? bytesOverride;

  @override
  State<HighlightDemoPage> createState() => HighlightDemoPageState();
}

@visibleForTesting
class HighlightDemoPageState extends State<HighlightDemoPage> {
  late final Future<EpubBookSession> _openFuture;

  /// 이 페이지가 세션을 직접 열고 소유한다 (EpubReader 미사용 —
  /// xhtmlLoader에 하이라이트 주입이 필요해 ReflowableEngine을 직접 구성).
  EpubBookSession? _session;

  final HighlightStore _store = const HighlightStore();
  List<DemoHighlight> _highlights = [];

  int _spineIndex = 0;

  /// 하이라이트 변경 시 증가 — ReflowableEngine을 재생성해 본문을 다시 그린다.
  int _revision = 0;

  /// 하이라이트 id 시퀀스 (단조 증가). 로드 시 기존 id의 최대 시퀀스 + 1로
  /// 시드하여 영속 데이터와도 충돌하지 않는다.
  int _idSeq = 0;

  String? _selectedText;

  bool get _hasSelection => (_selectedText ?? '').trim().isNotEmpty;

  @visibleForTesting
  EpubBookSession? get session => _session;

  @visibleForTesting
  List<DemoHighlight> get highlights => List.unmodifiable(_highlights);

  @visibleForTesting
  int get spineIndex => _spineIndex;

  /// 테스트에서 본문 선택을 시뮬레이션한다 (SelectionArea 드래그는 위젯
  /// 테스트에서 재현 불가).
  @visibleForTesting
  void debugSetSelection(String? text) {
    if (!mounted) return;
    setState(() => _selectedText = text);
  }

  @override
  void initState() {
    super.initState();
    // 데스크톱 웹에서 우클릭 시 브라우저 네이티브 메뉴가 Flutter 선택 툴바를
    // 가로채므로, 이 페이지에 있는 동안 비활성화한다(#45). FAB가 주 진입점이고
    // 이는 우클릭 경로를 보조로 살리기 위함이다.
    if (kIsWeb) {
      unawaited(BrowserContextMenu.disableContextMenu());
    }
    _openFuture = _open();
  }

  Future<EpubBookSession> _open() async {
    final bytes = widget.bytesOverride ?? await _loadAssetBytes();
    final session = await EpubBookSession.open(EpubSource.bytes(bytes));
    final saved = await _store.load();
    final seq = 1 + saved.fold<int>(-1, (max, h) {
      final match = RegExp(r'^h(\d+)').firstMatch(h.id);
      final value = match == null ? -1 : int.parse(match.group(1)!);
      return value > max ? value : max;
    });
    if (mounted) {
      setState(() {
        _session = session;
        _highlights = saved;
        _idSeq = seq;
      });
    } else {
      _session = session;
      _highlights = saved;
      _idSeq = seq;
    }
    return session;
  }

  Future<Uint8List> _loadAssetBytes() async {
    final data = await rootBundle.load('assets/example.epub');
    return data.buffer.asUint8List();
  }

  @override
  void dispose() {
    if (kIsWeb) {
      unawaited(BrowserContextMenu.enableContextMenu());
    }
    unawaited(_session?.dispose());
    super.dispose();
  }

  // --- 하이라이트 조작 (테스트에서 직접 호출 가능) ---

  List<String> get _navHrefs {
    final session = _session;
    if (session == null) return const [];
    final linear = [
      for (final item in session.book.spine)
        if (item.linear) item.href,
    ];
    if (linear.isNotEmpty) return linear;
    return [for (final item in session.book.spine) item.href];
  }

  String get _currentSpineHref {
    final hrefs = _navHrefs;
    if (hrefs.isEmpty) return '';
    return hrefs[_spineIndex.clamp(0, hrefs.length - 1)];
  }

  /// [_spineIndex]는 linear 필터된 [_navHrefs] 기준 인덱스다. 엔진은 전체
  /// spine(비선형 cover 포함)을 인덱싱하므로 href로 변환해 전달한다 —
  /// 그대로 넘기면 linear="no" 항목이 있는 책에서 챕터가 어긋난다.
  int get _engineSpineIndex {
    final session = _session;
    if (session == null) return 0;
    final index =
        session.book.spine.indexWhere((s) => s.href == _currentSpineHref);
    return index < 0 ? 0 : index;
  }

  /// 현재 spine에 하이라이트를 추가하고 영속 + analytics 이벤트를 발사한다.
  @visibleForTesting
  Future<void> addHighlight({
    required String text,
    required String colorName,
    String note = '',
  }) async {
    final session = _session;
    if (session == null || text.trim().isEmpty) return;
    final highlight = DemoHighlight(
      // 단조 증가 시퀀스 — 길이 기반 id는 삭제 후 재추가 시 충돌한다.
      id: 'h${_idSeq++}-${text.hashCode.toRadixString(16)}',
      spineHref: _currentSpineHref,
      text: text.trim(),
      colorName: colorName,
      note: note.trim(),
    );
    setState(() {
      _highlights = [..._highlights, highlight];
      _revision++;
      // 선택이 소비됨 — FAB를 숨긴다 (엔진 재생성으로도 곧 비워지지만 즉시 반영).
      _selectedText = null;
    });
    await _store.save(_highlights);
    // F11 — 호스트가 하이라이트 도구 사용을 analytics로 기록.
    session.recordHighlight();
  }

  @visibleForTesting
  Future<void> removeHighlight(String id) async {
    setState(() {
      _highlights = [for (final h in _highlights) if (h.id != id) h];
      _revision++;
    });
    await _store.save(_highlights);
  }

  @visibleForTesting
  Future<void> updateNote(String id, String note) async {
    setState(() {
      _highlights = [
        for (final h in _highlights)
          if (h.id == id) h.copyWith(note: note.trim()) else h,
      ];
    });
    await _store.save(_highlights);
  }

  /// 하이라이트가 있는 챕터로 이동한다 (목록 탭).
  @visibleForTesting
  Future<void> jumpToHighlight(DemoHighlight highlight) async {
    final session = _session;
    if (session == null) return;
    final hrefs = _navHrefs;
    final index = hrefs.indexOf(highlight.spineHref);
    if (index < 0) return;
    setState(() => _spineIndex = index);
    final denom = hrefs.length <= 1 ? 1 : hrefs.length - 1;
    await session.jumpTo(
      EpubReflowablePosition(
        spineHref: highlight.spineHref,
        progress: index / denom,
        charOffset: 0,
      ),
    );
  }

  void _moveSpine(int delta) {
    final hrefs = _navHrefs;
    if (hrefs.isEmpty) return;
    final next = (_spineIndex + delta).clamp(0, hrefs.length - 1);
    if (next == _spineIndex) return;
    setState(() => _spineIndex = next);
    // session.position도 동기화 — recordHighlight가 발사하는 analytics
    // 이벤트(F11)의 위치가 화면과 일치해야 한다.
    final denom = hrefs.length <= 1 ? 1 : hrefs.length - 1;
    unawaited(
      _session?.jumpTo(
        EpubReflowablePosition(
          spineHref: hrefs[next],
          progress: next / denom,
          charOffset: 0,
        ),
      ),
    );
  }

  // --- 본문 로딩 (하이라이트 주입) ---

  Future<String> _loadDecoratedXhtml(String spineHref) async {
    final raw = _session?.readSpineXhtml(spineHref) ?? '';
    final forSpine = _highlights.where((h) => h.spineHref == spineHref);
    return injectHighlightSpans(raw, forSpine);
  }

  Future<Uint8List?> _loadImage(String src) async =>
      _session?.resources.readBytes(src);

  // --- 선택 → 하이라이트 플로우 ---

  /// 선택 텍스트(또는 [textOverride])로 색상/메모 시트를 띄우고 저장한다.
  /// 실제 제스처 선택은 플랫폼 의존이라 테스트에서는 textOverride로 호출한다.
  @visibleForTesting
  Future<void> startHighlightFlow({String? textOverride}) async {
    final text = (textOverride ?? _selectedText)?.trim() ?? '';
    if (text.isEmpty) {
      _showSnack('먼저 본문 텍스트를 선택하세요.');
      return;
    }
    final result = await showModalBottomSheet<({String colorName, String note})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _HighlightSheet(excerpt: text),
    );
    if (result == null) return;
    await addHighlight(
      text: text,
      colorName: result.colorName,
      note: result.note,
    );
    _showSnack('하이라이트 저장됨 (${result.colorName})');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // --- 하이라이트 목록 ---

  Future<void> _showHighlightList() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _HighlightListSheet(
        highlights: _highlights,
        onTap: (highlight) async {
          Navigator.pop(sheetContext);
          await jumpToHighlight(highlight);
        },
        onDelete: (highlight) async {
          Navigator.pop(sheetContext);
          await removeHighlight(highlight.id);
          _showSnack('하이라이트 삭제됨');
        },
        onEditNote: (highlight) async {
          Navigator.pop(sheetContext);
          await _editNote(highlight);
        },
      ),
    );
  }

  Future<void> _editNote(DemoHighlight highlight) async {
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _NoteDialog(initialNote: highlight.note),
    );
    if (note == null) return;
    await updateNote(highlight.id, note);
    _showSnack('메모 저장됨');
  }

  // --- build ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('하이라이트 데모'),
        actions: [
          IconButton(
            tooltip: '하이라이트 목록',
            onPressed: _session == null ? null : _showHighlightList,
            icon: Badge.count(
              count: _highlights.length,
              isLabelVisible: _highlights.isNotEmpty,
              child: const Icon(Icons.format_list_bulleted),
            ),
          ),
        ],
      ),
      // 선택이 있을 때만 나타나는 명시적 진입점(#45). TapRegion의 groupId를
      // SelectableRegion으로 맞춰, FAB를 눌러도 SelectionArea가 "바깥 탭"으로
      // 간주해 선택을 지우지 않도록 한다.
      floatingActionButton: (_session != null && _hasSelection)
          ? TapRegion(
              groupId: SelectableRegion,
              child: FloatingActionButton.extended(
                onPressed: () => unawaited(startHighlightFlow()),
                icon: const Icon(Icons.border_color_outlined),
                label: const Text('하이라이트'),
              ),
            )
          : null,
      body: FutureBuilder<EpubBookSession>(
        future: _openFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('책을 열 수 없습니다: ${snapshot.error}'),
              ),
            );
          }
          final session = _session;
          if (session == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: SelectionArea(
                  onSelectionChanged: (content) {
                    final next = content?.plainText;
                    // FAB 표시/숨김은 선택 유무로 갈리므로 그 경계에서만 rebuild
                    // (드래그 중 매 프레임 setState 회피).
                    final had = _hasSelection;
                    _selectedText = next;
                    if (had != _hasSelection) setState(() {});
                  },
                  contextMenuBuilder: (context, selectableRegionState) =>
                      AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: selectableRegionState.contextMenuAnchors,
                    buttonItems: [
                      ContextMenuButtonItem(
                        label: '하이라이트',
                        onPressed: () {
                          selectableRegionState.hideToolbar();
                          unawaited(startHighlightFlow());
                        },
                      ),
                      ...selectableRegionState.contextMenuButtonItems,
                    ],
                  ),
                  child: ReflowableEngine(
                    key: ValueKey('engine-$_spineIndex-rev$_revision'),
                    book: session.book,
                    initialSpineIndex: _engineSpineIndex,
                    xhtmlLoader: _loadDecoratedXhtml,
                    imageLoader: _loadImage,
                  ),
                ),
              ),
              _buildBottomBar(theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final hrefs = _navHrefs;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _hasSelection
                      ? '"하이라이트" 버튼을 눌러 색을 칠하세요'
                      : '본문 텍스트를 선택하면 하이라이트 버튼이 나타납니다',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: '이전 챕터',
                icon: const Icon(Icons.chevron_left),
                onPressed: _spineIndex > 0 ? () => _moveSpine(-1) : null,
              ),
              Text(
                hrefs.isEmpty ? '-' : '${_spineIndex + 1}/${hrefs.length}',
                style: theme.textTheme.bodySmall,
              ),
              IconButton(
                tooltip: '다음 챕터',
                icon: const Icon(Icons.chevron_right),
                onPressed: _spineIndex < hrefs.length - 1
                    ? () => _moveSpine(1)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 메모 편집 다이얼로그. controller 수명은 이 위젯이 소유한다
/// (호출부에서 dispose하면 라우트 퇴장 애니메이션 중 사용 오류).
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initialNote});

  final String initialNote;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('메모'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(hintText: '메모를 입력하세요'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

/// 색상 4종 + 메모 입력 시트. 저장 시 (colorName, note)를 반환한다.
class _HighlightSheet extends StatefulWidget {
  const _HighlightSheet({required this.excerpt});

  final String excerpt;

  @override
  State<_HighlightSheet> createState() => _HighlightSheetState();
}

class _HighlightSheetState extends State<_HighlightSheet> {
  String _colorName = '노랑';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('하이라이트', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '"${widget.excerpt}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final entry in highlightPalette.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Semantics(
                        label: '색상 ${entry.key}',
                        button: true,
                        selected: _colorName == entry.key,
                        child: GestureDetector(
                          onTap: () => setState(() => _colorName = entry.key),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: entry.value,
                            child: _colorName == entry.key
                                ? const Icon(Icons.check, size: 18)
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  (colorName: _colorName, note: _noteController.text),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하이라이트 목록 시트.
class _HighlightListSheet extends StatelessWidget {
  const _HighlightListSheet({
    required this.highlights,
    required this.onTap,
    required this.onDelete,
    required this.onEditNote,
  });

  final List<DemoHighlight> highlights;
  final ValueChanged<DemoHighlight> onTap;
  final ValueChanged<DemoHighlight> onDelete;
  final ValueChanged<DemoHighlight> onEditNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '하이라이트 ${highlights.length}개',
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (highlights.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('저장된 하이라이트가 없습니다.')),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: highlights.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final highlight = highlights[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 10,
                        backgroundColor: highlight.color,
                      ),
                      title: Text(
                        highlight.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: highlight.note.isEmpty
                          ? null
                          : Text(
                              '메모: ${highlight.note}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: PopupMenuButton<String>(
                        tooltip: '하이라이트 메뉴',
                        onSelected: (action) {
                          if (action == 'note') onEditNote(highlight);
                          if (action == 'delete') onDelete(highlight);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'note', child: Text('메모 편집')),
                          PopupMenuItem(value: 'delete', child: Text('삭제')),
                        ],
                      ),
                      onTap: () => onTap(highlight),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
