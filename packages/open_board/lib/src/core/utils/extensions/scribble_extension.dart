// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// Scribble 콘텐츠 교체 헬퍼
///
/// Scribble을 필드 나열로 수동 재구성하면 이후 proto에 추가된 필드
/// (imageDrawables 등)가 누락되어 데이터가 조용히 유실된다.
/// 콘텐츠 일부만 교체할 때는 반드시 이 헬퍼를 사용해 미지정 필드를
/// 보존한다.
extension ScribbleContentCopy on Scribble {
  /// 지정한 콘텐츠만 교체하고 나머지 모든 필드를 보존한 새 Scribble 반환
  ///
  /// 컬렉션은 참조를 공유한다(필드 단위 shallow copy). 깊은 복사가
  /// 필요하면 `deepCopy()`를 사용한다.
  Scribble copyWithContents({
    Iterable<Stroke>? strokes,
    Iterable<TextDrawable>? textDrawables,
    Iterable<ImageDrawable>? imageDrawables,
    bool touchUpdatedAt = true,
  }) {
    return Scribble(
      x: x,
      y: y,
      width: width,
      height: height,
      strokes: strokes ?? this.strokes,
      textDrawables: textDrawables ?? this.textDrawables,
      imageDrawables: imageDrawables ?? this.imageDrawables,
      createdAt: createdAt,
      updatedAt: touchUpdatedAt
          ? DateTime.now().toIso8601String()
          : updatedAt,
      version: version,
    );
  }
}
