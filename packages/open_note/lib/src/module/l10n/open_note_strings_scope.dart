import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/l10n/open_note_strings.dart';

/// 🌐 아래쪽 open_note 위젯에 [OpenNoteStrings] 를 전달한다.
///
/// 스코프가 없으면 [OpenNoteStrings] 기본값(현재 글)이 쓰인다. 인라인 텍스트
/// 에디터는 필기 위젯 위치에서 문구를 읽어 Overlay 로 넘기므로, 스코프는 필기
/// 위젯 위 어디에 두어도 된다. 링크 입력 대화상자도 에디터가 받은 문구를 그대로
/// 쓴다.
class OpenNoteStringsScope extends InheritedWidget {
  /// [strings] 를 [child] 아래에 전달한다.
  const OpenNoteStringsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  /// 전달할 문구 묶음.
  final OpenNoteStrings strings;

  /// 가장 가까운 스코프의 문구, 없으면 기본값. 문구가 바뀌면 다시 빌드된다.
  static OpenNoteStrings of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<OpenNoteStringsScope>()
          ?.strings ??
      const OpenNoteStrings();

  /// [of] 와 같지만 의존을 등록하지 않는다 — 빌드 밖(이벤트 처리 · Overlay
  /// 삽입 시점)에서 한 번 읽을 때 쓴다.
  static OpenNoteStrings read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<OpenNoteStringsScope>()?.strings ??
      const OpenNoteStrings();

  @override
  bool updateShouldNotify(OpenNoteStringsScope oldWidget) =>
      strings != oldWidget.strings;
}
