import 'dart:io';

import 'package:flutter/widgets.dart';

/// 네이티브(iOS/Android/데스크탑)용 이미지 소스 해석기.
///
/// http(s)/blob URL 은 [NetworkImage], 그 외 로컬 파일 경로는 [FileImage] 로
/// 로드한다. 네이티브 `image_picker` 는 로컬 파일 경로를 반환한다.
ImageProvider resolveImageSource(String source) {
  if (source.startsWith('http') || source.startsWith('blob:')) {
    return NetworkImage(source);
  }
  return FileImage(File(source));
}
