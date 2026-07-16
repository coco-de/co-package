import 'package:coarc_tui/coarc_tui.dart';
import 'package:test/test.dart';

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

  group('parseLabelInput', () {
    test('+ 접두는 추가', () {
      final edit = parseLabelInput('+flutter,ios');
      expect(edit, isA<LabelAdd>());
      expect(edit.labels, ['flutter', 'ios']);
    });

    test('- 접두는 삭제', () {
      final edit = parseLabelInput('-flutter');
      expect(edit, isA<LabelRemove>());
      expect(edit.labels, ['flutter']);
    });

    test('접두 없는 CSV는 전체 교체', () {
      final edit = parseLabelInput('a,b,c');
      expect(edit, isA<LabelReplace>());
      expect(edit.labels, ['a', 'b', 'c']);
    });

    test('빈 입력은 빈 교체 (커스텀 라벨 전체 삭제)', () {
      final edit = parseLabelInput('   ');
      expect(edit, isA<LabelReplace>());
      expect(edit.labels, isEmpty);
    });

    test('접두 앞뒤 공백 허용', () {
      final edit = parseLabelInput('  +a, b ');
      expect(edit, isA<LabelAdd>());
      expect(edit.labels, ['a', 'b']);
    });

    test('접두만 있으면 빈 라벨 리스트', () {
      expect(parseLabelInput('+').labels, isEmpty);
      expect(parseLabelInput('-').labels, isEmpty);
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
