import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

void main() {
  test('kind names are the persisted ones', () {
    expect(
      [for (final kind in NoteAiPenKind.values) kind.name],
      ['solve', 'explain', 'translate'],
    );
  });

  group('request', () {
    final full = NoteAiPenRequest(
      kind: NoteAiPenKind.translate,
      imagePng: Uint8List.fromList([137, 80, 78, 71, 0, 255]),
      text: '안녕',
      targetLocale: 'en-US',
    );

    test('round-trips through JSON', () {
      final decoded = NoteAiPenRequest.fromJson(
        jsonDecode(jsonEncode(full.toJson())),
      );

      expect(decoded, full);
      expect(decoded.hashCode, full.hashCode);
    });

    test('leaves absent inputs out', () {
      const request = NoteAiPenRequest(kind: NoteAiPenKind.solve);

      expect(request.toJson(), {'kind': 'solve'});
    });

    test('malformed input never throws', () {
      final decoded = NoteAiPenRequest.fromJson({
        'kind': 'sing',
        'imagePng': '%%% not base64',
        'text': 5,
      });

      expect(decoded.kind, NoteAiPenKind.solve);
      expect(decoded.imagePng, isNull);
      expect(decoded.text, isNull);
      expect(NoteAiPenRequest.fromJson(null).kind, NoteAiPenKind.solve);
    });

    test('knows whether it has anything to work on', () {
      expect(full.hasInput, isTrue);
      expect(
        const NoteAiPenRequest(kind: NoteAiPenKind.solve, text: '   ').hasInput,
        isFalse,
      );
      expect(
        NoteAiPenRequest(
          kind: NoteAiPenKind.solve,
          imagePng: Uint8List(0),
        ).hasInput,
        isFalse,
      );
    });

    test('copyWith changes one thing, equality compares the bytes', () {
      final explain = full.copyWith(kind: NoteAiPenKind.explain);

      expect(explain.text, full.text);
      expect(explain, isNot(full));
      expect(full.copyWith(), full);
      expect(full.copyWith(imagePng: Uint8List.fromList(full.imagePng!)), full);
      expect(full.copyWith(imagePng: Uint8List.fromList([1])), isNot(full));
      expect(full.toString(), contains('6 bytes'));
    });
  });

  group('result', () {
    final full = NoteAiPenResult(
      kind: NoteAiPenKind.solve,
      text: 'x = 2',
      steps: const ['2x = 4', 'x = 2'],
    );

    test('round-trips through JSON', () {
      final decoded = NoteAiPenResult.fromJson(
        jsonDecode(jsonEncode(full.toJson())),
      );

      expect(decoded, full);
      expect(decoded.hashCode, full.hashCode);
      expect(full.toJson().containsKey('steps'), isTrue);
      expect(NoteAiPenResult(kind: NoteAiPenKind.explain, text: 'a').toJson(), {
        'kind': 'explain',
        'text': 'a',
      });
    });

    test('malformed input never throws', () {
      final decoded = NoteAiPenResult.fromJson({
        'kind': 4,
        'steps': ['ok', 2, null],
      });

      expect(decoded.kind, NoteAiPenKind.solve);
      expect(decoded.text, '');
      expect(decoded.steps, ['ok']);
      expect(NoteAiPenResult.fromJson({'steps': 'no'}).steps, isNull);
      expect(NoteAiPenResult.fromJson('no').text, '');
    });

    test('steps are copied and cannot be changed', () {
      final steps = ['a'];
      final result = NoteAiPenResult(
        kind: NoteAiPenKind.solve,
        text: '',
        steps: steps,
      );

      steps.add('b');

      expect(result.steps, ['a']);
      expect(() => result.steps!.add('c'), throwsUnsupportedError);
    });

    test('plain text numbers the steps', () {
      expect(full.plainText, 'x = 2\n\n1. 2x = 4\n2. x = 2');
      expect(
        NoteAiPenResult(kind: NoteAiPenKind.explain, text: 'hi').plainText,
        'hi',
      );
      expect(
        NoteAiPenResult(
          kind: NoteAiPenKind.solve,
          text: '',
          steps: const ['only'],
        ).plainText,
        '1. only',
      );
    });

    test('copyWith and equality', () {
      expect(full.copyWith(), full);
      expect(full.copyWith(text: 'y'), isNot(full));
      expect(full.copyWith(steps: const ['z']), isNot(full));
    });
  });

  test('the exception describes itself and compares by value', () {
    const failure = NoteAiPenException(
      'offline',
      code: NoteAiPenErrorCode.network,
    );

    expect(failure.toString(), 'NoteAiPenException(network): offline');
    expect(
      failure,
      const NoteAiPenException('offline', code: NoteAiPenErrorCode.network),
    );
    expect(failure, isNot(const NoteAiPenException('offline')));
  });

  test('strings name every tab and every kind of failure', () {
    const strings = NoteStudyOverlayStrings();

    expect(
      [for (final kind in NoteAiPenKind.values) strings.kindLabel(kind)],
      ['Solve', 'Explain', 'Translate'],
    );
    expect({
      for (final code in NoteAiPenErrorCode.values)
        strings.errorMessage(NoteAiPenException('x', code: code)),
    }, hasLength(NoteAiPenErrorCode.values.length));
  });
}
