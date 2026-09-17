import 'package:flutter/widgets.dart';

/// 웹/기본 플랫폼용 이미지 소스 해석기.
///
/// `dart:io` 를 참조하지 않아 웹 컴파일에 안전하다. blob/네트워크 URL 은
/// [NetworkImage] 로 로드된다. (웹 `image_picker` 는 blob URL 을 반환)
ImageProvider resolveImageSource(String source) => NetworkImage(source);
