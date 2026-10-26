import 'design_analysis.dart';
import 'design_comparison.dart';
import 'model.dart';

const int _findingLimit = 40;
const int _knownLimit = 20;
const int _regionLimit = 15;

typedef _Entry = (GalleryScenario, GalleryImage, GalleryDesignComparison);

/// Renders a Markdown report of every design comparison in [catalog], for AI
/// agents that fix the implementation and for pull request comments.
///
/// Counts come first. Each variant whose tolerance-based verdict is `fail`
/// or `undetermined` then lists its findings, most severe first, with the
/// element, the design value and the implementation value, the source
/// location, the design-system component, and a fix hint; known differences
/// and pixel regions that no finding explains follow. Variants that match
/// are only listed. Comparisons recorded without an analysis keep their
/// exact-pixel result.
String renderGalleryDesignReport(
  GalleryCatalog catalog, {
  String title = '디자인 차이 리포트',
}) {
  final entries = <_Entry>[
    for (final scenario in catalog.scenarios)
      for (final image in scenario.images)
        if (image.designComparison case final design?)
          (scenario, image, design),
  ];
  final analysed = [
    for (final entry in entries)
      if (entry.$3.analysis != null) entry,
  ];
  List<_Entry> withVerdict(String verdict) => [
    for (final entry in analysed)
      if (entry.$3.analysis!.verdict == verdict) entry,
  ];
  final failing = withVerdict('fail');
  final undetermined = withVerdict('undetermined');
  final passing = withVerdict('pass');
  final exactOnly = [
    for (final entry in entries)
      if (entry.$3.analysis == null && entry.$3.status != 'matched') entry,
  ];

  final out = StringBuffer()
    ..writeln('# ${_text(title)}')
    ..writeln()
    ..writeln(
      'co_golden 이 캡처한 화면과 디자인 원본을 허용 오차 기준으로 비교한 결과입니다. '
      '캡처 성공(통과)과 디자인 일치는 별개입니다.',
    )
    ..writeln();
  final verdicts = catalog.designVerdicts;
  final findings = catalog.designFindingCounts;
  final categories = catalog.designFindingCategories;
  out
    ..writeln('- 디자인 비교 ${entries.length}건 · 허용 오차 분석 ${analysed.length}건')
    ..writeln(
      '- 판정: 일치 ${verdicts['pass']} · 불일치 ${verdicts['fail']} · '
      '판정 불가 ${verdicts['undetermined']}',
    )
    ..writeln(
      '- 지적 사항: 오류 ${findings['error']} · 경고 ${findings['warning']} · '
      '정보 ${findings['info']} · 알려진 차이 ${findings['known']}',
    );
  if (categories.isNotEmpty) {
    final ordered = [
      for (final category in galleryCategoryOrder)
        if (categories[category] case final count? when count > 0)
          '${galleryCategoryLabels[category]} $count',
      for (final MapEntry(:key, :value) in categories.entries)
        if (!galleryCategoryOrder.contains(key) && value > 0) '$key $value',
    ];
    if (ordered.isNotEmpty) out.writeln('- 분류: ${ordered.join(' · ')}');
  }
  if (exactOnly.isNotEmpty) {
    out.writeln('- 허용 오차 분석이 없는 픽셀 차이: ${exactOnly.length}건');
  }
  if (entries.isEmpty) {
    out
      ..writeln()
      ..writeln('디자인 비교가 기록된 캡처가 없습니다.');
  }

  for (final entry in [...failing, ...undetermined]) {
    _variant(out, entry);
  }

  if (passing.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## 일치한 변형 ${passing.length}건')
      ..writeln();
    for (final (scenario, image, design) in passing) {
      final analysis = design.analysis!;
      final notes = [
        if (analysis.warnings > 0) '경고 ${analysis.warnings}',
        if (analysis.known > 0) '알려진 차이 ${analysis.known}',
      ];
      out.writeln(
        '- ${_text(_title(scenario, image))}'
        '${notes.isEmpty ? '' : ' — ${notes.join(' · ')}'}',
      );
    }
  }

  if (exactOnly.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## 허용 오차 분석이 없는 디자인 비교 ${exactOnly.length}건')
      ..writeln()
      ..writeln('정확한 RGBA 비교만 기록되었습니다. 구조 지적 사항을 보려면 co_golden 으로 다시 캡처합니다.')
      ..writeln();
    for (final (scenario, image, design) in exactOnly) {
      out.writeln(
        '- ${_text(_title(scenario, image))} — ${_text(design.summary)} · '
        '디자인 ${_code(design.reference)}',
      );
    }
  }

  if (failing.isNotEmpty || undetermined.isNotEmpty || exactOnly.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## 다음 단계')
      ..writeln()
      ..writeln(
        '1. 오류부터 위치(`파일:줄:열`)에서 고칩니다. 값은 디자인 시스템의 컴포넌트와 토큰으로 맞추고, '
        '알려진 차이는 앱에서 고치지 않습니다.',
      )
      ..writeln(
        '2. 같은 상태를 다시 캡처합니다: '
        '`CO_GOLDEN_MODE=capture flutter test --tags co_golden`',
      )
      ..writeln(
        '3. 갤러리와 이 리포트를 다시 만들어 판정이 일치로 바뀌었는지 확인합니다: '
        '`dart run co_golden_gallery:co_golden_gallery build --input build/co_golden '
        '--design-report <file.md>`',
      )
      ..writeln('4. 디자인 원본은 디자인이 바뀔 때만 다시 내보냅니다. 구현 캡처로 바꾸지 않습니다.');
  }
  return out.toString();
}

void _variant(StringBuffer out, _Entry entry) {
  final (scenario, image, design) = entry;
  final analysis = design.analysis!;
  final details = analysis.details;
  out
    ..writeln()
    ..writeln(
      '## ${galleryVerdictLabels[analysis.verdict]} · '
      '${_text(_title(scenario, image))}',
    )
    ..writeln();
  final reasons = details?.reasons ?? const <String>[];
  if (reasons.isNotEmpty) {
    out.writeln('- 판정 이유: ${reasons.map(_code).join(', ')}');
  }
  out.writeln('- ${_text(analysis.line)}');
  if (details?.pixelDetail case final detail?) {
    out.writeln('- 픽셀 비교: ${_text(detail)}');
  }
  out.writeln('- 리포트: ${_code(analysis.report)}');
  final source = design.sourceUrl;
  final frame = details?.frameName;
  final designParts = [
    if (source != null)
      '[${_text(design.label)}](<$source>)'
    else
      _text(design.label),
    if (frame != null)
      '프레임 ${_text(frame)}${details?.frameId == null ? '' : ' (${_text(details!.frameId!)})'}',
    '원본 ${_code(design.reference)}',
  ];
  out.writeln('- 디자인: ${designParts.join(' · ')}');
  if (image.path.isNotEmpty) out.writeln('- 캡처: ${_code(image.path)}');
  if (details == null) {
    out.writeln('- 분석 리포트 파일이 없어 지적 사항을 읽지 못했습니다.');
    return;
  }

  final counting = [
    for (final finding in details.findings)
      if (!finding.known) finding,
  ];
  final known = [
    for (final finding in details.findings)
      if (finding.known) finding,
  ];
  if (counting.isNotEmpty) {
    out
      ..writeln()
      ..writeln('### 지적 사항 ${counting.length}건')
      ..writeln();
    var number = 0;
    for (final finding in counting.take(_findingLimit)) {
      number++;
      _finding(out, finding, number);
    }
    final hidden = counting.length - _findingLimit + details.findingsTruncated;
    if (hidden > 0) {
      out
        ..writeln()
        ..writeln('나머지 $hidden건은 리포트 JSON에 있습니다.');
    }
  }
  if (known.isNotEmpty) {
    out
      ..writeln()
      ..writeln('### 알려진 차이 ${known.length}건')
      ..writeln();
    for (final finding in known.take(_knownLimit)) {
      final issue = finding.knownIssue;
      out.writeln(
        '- [${finding.severityLabel}] ${finding.categoryLabel} '
        '${_text(finding.element)} — ${_text(finding.knownReason!)}'
        '${issue == null ? '' : ' ([추적 이슈](<$issue>))'}',
      );
    }
  }
  final unexplained = details.unexplainedRegions.toList();
  if (unexplained.isNotEmpty) {
    out
      ..writeln()
      ..writeln('### 설명되지 않은 픽셀 영역 ${unexplained.length}건')
      ..writeln()
      ..writeln(
        '구조 지적 사항이 없는 자리입니다. 아이콘 모양, 이미지, 그림자, 그라데이션처럼 노드 속성으로 드러나지 않는 차이일 수 있습니다.',
      )
      ..writeln();
    for (final region in unexplained.take(_regionLimit)) {
      out.writeln('- ${_code(region.id)} ${_text(region.label)}');
    }
  }
  if (details.warnings.isNotEmpty || details.toleranceChanged.isNotEmpty) {
    out
      ..writeln()
      ..writeln('### 비교 경고')
      ..writeln();
    for (final warning in details.warnings) {
      out.writeln('- ${_text(warning)}');
    }
    if (details.toleranceChanged.isNotEmpty) {
      out.writeln(
        '- 기본값과 다른 허용 오차: ${details.toleranceChanged.map(_code).join(', ')}',
      );
    }
  }
}

void _finding(StringBuffer out, GalleryDesignFinding finding, int number) {
  out.writeln(
    '$number. **[${finding.severityLabel}] ${finding.categoryLabel}** '
    '${_text(finding.element)} — ${_text(finding.message)}',
  );
  if (finding.diffs.isNotEmpty) {
    out.writeln(
      '   - 차이 (디자인 → 구현): '
      '${finding.diffs.map((diff) => _code(diff.text)).join(' · ')}',
    );
  }
  if (finding.designLabel case final label?) {
    out.writeln('   - 디자인: ${_text(label)}');
  }
  if (finding.widgetLabel case final label?) {
    final source = finding.widgetSource;
    out.writeln(
      '   - 구현: ${_text(label)}${source == null ? '' : ' — ${_code(source)}'}',
    );
  }
  if (finding.widgetPath case final path?) {
    out.writeln('   - 위젯 경로: ${_text(path)}');
  }
  if (finding.componentLabel case final label?) {
    final source = finding.componentSource;
    out.writeln(
      '   - 컴포넌트: ${_text(label)}'
      '${source == null ? '' : ' — ${_code(source)}'}',
    );
  }
  if (finding.widgetLabel == null &&
      finding.componentLabel == null &&
      finding.where != null) {
    out.writeln('   - 위치: ${_code(finding.where!)}');
  }
  if (finding.ownerLabel case final owner?) {
    out.writeln('   - 고칠 곳: ${_text(owner)}');
  }
  if (finding.hint case final hint?) {
    out.writeln('   - 고칠 방향: ${_text(hint)}');
  }
}

String _title(GalleryScenario scenario, GalleryImage image) =>
    '${scenario.suite} / ${scenario.name} · ${image.label}';

/// Plain text safe inside Markdown prose and lists. Underscores stay as they
/// are: CommonMark never opens emphasis inside a word such as `coui_flutter`,
/// and every line starts with a list marker, so `#` cannot start a heading.
String _text(String value) => value
    .replaceAll(RegExp(r'[\r\n]+'), ' ')
    .replaceAll(r'\', r'\\')
    .replaceAllMapped(RegExp(r'[`*\[\]|]'), (match) => '\\${match[0]}')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// An inline code span that survives backticks in [value].
String _code(String value) {
  final text = value.replaceAll(RegExp(r'[\r\n]+'), ' ');
  if (!text.contains('`')) return '`$text`';
  return '`` $text ``';
}
