// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// 텍스트 CRUD 관리 클래스
///
/// ScribbleNotifier에서 추출된 immutable 방식의 텍스트 관리자로,
/// Scribble을 입력받아 텍스트가 업데이트된 새 Scribble을 반환합니다.
///
/// 이 클래스는 ScribbleNotifier에 대한 의존성을 갖지 않습니다.
class TextDrawableManager {
  const TextDrawableManager();

  /// 텍스트를 추가한 새 Scribble을 반환합니다.
  Scribble add(Scribble scribble, TextDrawable textDrawable) {
    final currentTextDrawables = getAll(scribble);
    final updatedTextDrawables = [...currentTextDrawables, textDrawable];
    return applyToScribble(scribble, updatedTextDrawables);
  }

  /// 텍스트를 수정한 새 Scribble을 반환합니다.
  Scribble update(
    Scribble scribble,
    String id,
    TextDrawable updatedTextDrawable,
  ) {
    final currentTextDrawables = getAll(scribble);
    final updatedTextDrawables = currentTextDrawables.map((textDrawable) {
      return textDrawable.id == id ? updatedTextDrawable : textDrawable;
    }).toList();
    return applyToScribble(scribble, updatedTextDrawables);
  }

  /// 텍스트를 삭제한 새 Scribble을 반환합니다.
  Scribble remove(Scribble scribble, String id) {
    final currentTextDrawables = getAll(scribble);
    final updatedTextDrawables = currentTextDrawables
        .where((textDrawable) => textDrawable.id != id)
        .toList();
    return applyToScribble(scribble, updatedTextDrawables);
  }

  /// 현재 텍스트 목록을 가져옵니다.
  List<TextDrawable> getAll(Scribble scribble) {
    return scribble.textDrawables;
  }

  /// 텍스트 목록을 Scribble에 적용한 새 Scribble을 반환합니다.
  Scribble applyToScribble(
    Scribble scribble,
    List<TextDrawable> textDrawables,
  ) {
    return Scribble(
      x: scribble.x,
      y: scribble.y,
      width: scribble.width,
      height: scribble.height,
      strokes: scribble.strokes,
      textDrawables: textDrawables,
      createdAt: scribble.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      version: scribble.version,
    );
  }
}
