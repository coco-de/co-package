// ignore_for_file: prefer-match-file-name

/// .feature 파일 파서.
///
/// Gherkin 문법을 파싱하여 [FeatureFile] 모델로 변환합니다.
/// 외부 패키지 의존 없이 경량 파서로 구현합니다.
library;

/// 파싱된 .feature 파일.
class FeatureFile {
  /// [FeatureFile]을 생성합니다.
  const FeatureFile({
    required this.name,
    required this.tags,
    required this.background,
    required this.scenarios,
    this.description,
  });

  /// Feature 이름.
  final String name;

  /// Feature 레벨 태그 (`@smoke`, `@auth` 등).
  final List<String> tags;

  /// Feature 설명.
  final String? description;

  /// Background 단계 (모든 시나리오 공통).
  final List<Step> background;

  /// 시나리오 목록.
  final List<Scenario> scenarios;
}

/// 시나리오.
class Scenario {
  /// [Scenario]를 생성합니다.
  const Scenario({required this.name, required this.tags, required this.steps});

  /// 시나리오 이름.
  final String name;

  /// 시나리오 태그.
  final List<String> tags;

  /// 단계 목록.
  final List<Step> steps;

  /// 이 시나리오의 실행 대상을 결정합니다.
  TestTarget get target {
    if (tags.contains('widget-only')) return TestTarget.widgetOnly;
    if (tags.contains('patrol-only')) return TestTarget.patrolOnly;
    return TestTarget.both;
  }
}

/// GWT 단계.
class Step {
  /// [Step]을 생성합니다.
  const Step({required this.keyword, required this.text, required this.params});

  /// Given / When / Then / And / But.
  final String keyword;

  /// 단계 원문 텍스트 (파라미터 플레이스홀더 포함).
  final String text;

  /// `{'value'}` 에서 추출한 파라미터 값 목록.
  final List<String> params;

  /// Step 텍스트를 camelCase 함수명으로 변환합니다.
  ///
  /// `I enter {'email'} in the email field` → `iEnterInTheEmailField`
  String get functionName {
    // 파라미터 플레이스홀더 제거
    var cleaned = text
        .replaceAll(RegExp(r"\{'[^']*'\}"), '')
        .replaceAll(RegExp(r'\{[^}]*\}'), '');
    // 특수문자 제거, 단어 분리
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    // ignore: avoid-unsafe-collection-methods — isEmpty 가드 통과 후 접근
    return words.first.toLowerCase() + words.skip(1).map(_capitalize).join();
  }

  /// Step 텍스트를 snake_case 파일명으로 변환합니다.
  ///
  /// `I enter {'email'} in the email field` → `i_enter_in_the_email_field`
  String get fileName {
    var cleaned = text
        .replaceAll(RegExp(r"\{'[^']*'\}"), '')
        .replaceAll(RegExp(r'\{[^}]*\}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    final words = cleaned.split(RegExp(r'\s+'));
    return words.map((word) => word.toLowerCase()).join('_');
  }

  static String _capitalize(String word) => word.isEmpty
      ? ''
      : word[0].toUpperCase() + word.substring(1).toLowerCase();
}

/// 테스트 실행 대상.
enum TestTarget {
  /// Widget Test + Patrol Test 양쪽.
  both,

  /// Widget Test만.
  widgetOnly,

  /// Patrol E2E Test만.
  patrolOnly,
}

/// .feature 파일 내용을 파싱합니다.
FeatureFile parseFeature(String content) {
  final lines = content.split('\n');
  final featureTags = <String>[];
  var featureName = '';
  String? featureDescription;
  final background = <Step>[];
  final scenarios = <Scenario>[];

  var pendingTags = <String>[];
  var currentSection = _Section.none;
  var currentScenarioName = '';
  var currentScenarioTags = <String>[];
  var currentSteps = <Step>[];

  for (final rawLine in lines) {
    final line = rawLine.trim();

    // 빈 줄 / 주석 건너뛰기
    if (line.isEmpty) continue;
    if (line.startsWith('#')) continue;

    // 태그 라인
    if (line.startsWith('@')) {
      final tags = line
          .split(RegExp(r'\s+'))
          .map((tag) => tag.substring(1))
          .toList();
      pendingTags.addAll(tags);
      continue;
    }

    // Feature:
    if (line.startsWith('Feature:')) {
      featureName = line.substring('Feature:'.length).trim();
      featureTags.addAll(pendingTags);
      pendingTags = [];
      currentSection = _Section.feature;
      continue;
    }

    // Feature 설명 (Feature: 바로 다음 줄, 들여쓰기)
    if (currentSection == _Section.feature &&
        rawLine.startsWith('  ') &&
        !_isKeyword(line)) {
      featureDescription = (featureDescription ?? '') + line;
      continue;
    }

    // Background:
    if (line.startsWith('Background:')) {
      pendingTags = [];
      currentSection = _Section.background;
      continue;
    }

    // Scenario: / Scenario Outline:
    if (line.startsWith('Scenario:') || line.startsWith('Scenario Outline:')) {
      // 이전 시나리오 저장
      _saveScenario(
        scenarios,
        currentScenarioName,
        currentSteps,
        currentScenarioTags,
      );

      final prefix = line.startsWith('Scenario Outline:')
          ? 'Scenario Outline:'
          : 'Scenario:';
      currentScenarioName = line.substring(prefix.length).trim();
      currentScenarioTags = List.of(pendingTags);
      pendingTags = [];
      currentSteps = [];
      currentSection = _Section.scenario;
      continue;
    }

    // Step 라인 (Given / When / Then / And / But)
    if (_isStepKeyword(line)) {
      final step = _parseStep(line);
      switch (currentSection) {
        case _Section.background:
          background.add(step);
        case _Section.scenario:
          currentSteps.add(step);
        case _Section.none || _Section.feature:
          break;
      }
    }
  }

  // 마지막 시나리오 저장
  _saveScenario(
    scenarios,
    currentScenarioName,
    currentSteps,
    currentScenarioTags,
  );

  return FeatureFile(
    name: featureName,
    tags: featureTags,
    background: background,
    scenarios: scenarios,
    description: featureDescription,
  );
}

void _saveScenario(
  List<Scenario> scenarios,
  String name,
  List<Step> steps,
  List<String> tags,
) {
  if (name.isEmpty) return;
  scenarios.add(
    Scenario(name: name, tags: List.of(tags), steps: List.of(steps)),
  );
}

bool _isKeyword(String line) =>
    line.startsWith('Feature:') ||
    line.startsWith('Background:') ||
    line.startsWith('Scenario:') ||
    line.startsWith('Scenario Outline:') ||
    _isStepKeyword(line);

bool _isStepKeyword(String line) =>
    line.startsWith('Given ') ||
    line.startsWith('When ') ||
    line.startsWith('Then ') ||
    line.startsWith('And ') ||
    line.startsWith('But ');

Step _parseStep(String line) {
  // keyword 추출
  final spaceIdx = line.indexOf(' ');
  final keyword = line.substring(0, spaceIdx);
  final text = line.substring(spaceIdx + 1).trim();

  // 한글 주석 제거 (# 이후)
  final commentIdx = text.indexOf(' # ');
  final cleanText = commentIdx >= 0
      ? text.substring(0, commentIdx).trim()
      : text;

  // 파라미터 추출: {'value'} 패턴
  final paramRegex = RegExp(r"\{'([^']*)'\}");
  final params = paramRegex
      .allMatches(cleanText)
      .map((match) => match.group(1)!)
      .toList();

  return Step(keyword: keyword, text: cleanText, params: params);
}

enum _Section { none, feature, background, scenario }
