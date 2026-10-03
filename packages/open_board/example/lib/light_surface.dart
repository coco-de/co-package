import 'package:flutter/material.dart';

import 'demo_settings.dart';

/// 콘텐츠 면(필기 종이 · 책 본문)을 앱 테마와 상관없이 라이트로 그린다.
///
/// 앱 크롬만 다크 테마를 따르고, 종이와 책은 원래 색(흰 바탕 · 검은 글)을
/// 유지한다. [Material] 이 바탕을 칠하고 기본 글 스타일을 라이트 테마로
/// 되돌린다.
class LightSurface extends StatelessWidget {
  const LightSurface({
    required this.child,
    this.color = Colors.white,
    super.key,
  });

  /// 라이트로 그릴 콘텐츠.
  final Widget child;

  /// 바탕색.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: exampleTheme(Brightness.light),
      child: Material(color: color, child: child),
    );
  }
}
