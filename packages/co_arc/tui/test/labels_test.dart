import 'package:coarc_tui/coarc_tui.dart';
import 'package:test/test.dart';

RunnerInfo _runner(
  String name, {
  List<String> custom = const [],
  List<String> readOnly = const ['self-hosted', 'macOS', 'ARM64'],
}) =>
    RunnerInfo(
      id: name.hashCode,
      name: name,
      os: 'macOS',
      status: 'online',
      busy: false,
      labels: [...readOnly, ...custom],
      customLabels: custom,
    );

void main() {
  group('splitLabelsCsv', () {
    test('trim + 빈 항목 제거', () {
      expect(splitLabelsCsv(' a , b ,, c '), ['a', 'b', 'c']);
    });

    test('중복은 첫 등장만 유지', () {
      expect(splitLabelsCsv('a,b,a,c,b'), ['a', 'b', 'c']);
    });

    test('빈 문자열은 빈 리스트', () {
      expect(splitLabelsCsv(''), isEmpty);
      expect(splitLabelsCsv(' , , '), isEmpty);
    });
  });

  group('pickerLabels', () {
    test('스코프 전체의 커스텀 라벨 합집합을 이름순으로 모은다', () {
      final target = _runner('a', custom: ['flutter']);
      final labels = pickerLabels([
        target,
        _runner('b', custom: ['ios', 'flutter']),
        _runner('c', custom: ['serverpod']),
      ], target);
      expect(labels, ['flutter', 'ios', 'serverpod']);
    });

    test('대상의 라벨은 다른 러너에 없어도 포함된다', () {
      // 목록에 대상이 빠져 있어도(늦은 갱신 등) 체크 상태를 표시할 항목은 있어야 한다.
      final target = _runner('a', custom: ['only-mine']);
      expect(
        pickerLabels([
          _runner('b', custom: ['shared'])
        ], target),
        ['only-mine', 'shared'],
      );
    });

    test('대상의 read-only 라벨은 다른 러너에서 커스텀이어도 제외한다', () {
      // GitHub 라벨 API가 거부하므로 고를 수 있게 두면 안 된다.
      final target = _runner('a', readOnly: const ['self-hosted', 'macOS']);
      expect(
        pickerLabels([
          target,
          _runner('b', custom: ['macOS', 'flutter']),
        ], target),
        ['flutter'],
      );
    });

    test('커스텀 라벨이 하나도 없으면 빈 목록', () {
      final target = _runner('a');
      expect(pickerLabels([target], target), isEmpty);
    });
  });

  group('splitEditableLabels', () {
    test('read-only 라벨을 걸러낸다', () {
      final (editable, skipped) = splitEditableLabels(
        ['flutter', 'self-hosted', 'ios', 'macOS'],
        {'self-hosted', 'macOS', 'ARM64'},
      );
      expect(editable, ['flutter', 'ios']);
      expect(skipped, ['self-hosted', 'macOS']);
    });

    test('read-only가 없으면 전부 편집 가능', () {
      final (editable, skipped) = splitEditableLabels(['a', 'b'], const {});
      expect(editable, ['a', 'b']);
      expect(skipped, isEmpty);
    });
  });
}
