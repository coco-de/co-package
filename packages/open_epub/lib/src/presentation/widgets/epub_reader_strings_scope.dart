import 'package:flutter/widgets.dart';

import 'epub_reader_strings.dart';

/// 아래쪽 리더 · 엔진 위젯에 [EpubReaderStrings] 를 전달한다.
///
/// [EpubReader.strings] 를 넘기면 리더가 스스로 이 스코프로 자기 하위 트리를
/// 감싼다. 앱 전체에 한 번 넣으려면 `MaterialApp.builder` 등에서 직접 감싼다.
/// 스코프가 없으면 [EpubReaderStrings] 기본값(현재 글)이 쓰인다.
class EpubReaderStringsScope extends InheritedWidget {
  /// [strings] 를 [child] 아래에 전달한다.
  const EpubReaderStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  /// 전달할 문구 묶음.
  final EpubReaderStrings strings;

  /// 가장 가까운 스코프의 문구, 없으면 기본값. 문구가 바뀌면 다시 빌드된다.
  static EpubReaderStrings of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EpubReaderStringsScope>()
          ?.strings ??
      const EpubReaderStrings();

  @override
  bool updateShouldNotify(EpubReaderStringsScope oldWidget) =>
      strings != oldWidget.strings;
}
