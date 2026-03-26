import 'package:flutter/material.dart';

class ColorS {
  static List<Color> getColors({required String inkType}) {
    switch (inkType) {
      case 'pencil':
        return const [
          Color(0xFF000000),
          Color(0xFFFF0000),
          Color(0xFFFFE400),
          Color(0xFF1DDB16),
          Color(0xFF0100FF),
        ];

      case 'pen':
        return const [
          Color(0xFF000000), // 🔥 펜 기본 색상을 검정으로 변경
          Color(0xFFF15F5F),
          Color(0xFFFFE08C),
          Color(0xFF22741C),
          Color(0xFF6799FF),
        ];

      case 'marker':
        return const [
          Color(0x7FDAD9FF),
          Color(0x7FFFD9EC),
          Color(0x7FFAF4C0),
          Color(0x7FE4F7BA),
          Color(0x7FD4F4FA),
        ];

      case 'shape':
        return const [
          Color(0xFF000000),
          Color(0xFFFF0000),
          Color(0xFFFFE400),
          Color(0xFF1DDB16),
          Color(0xFF0100FF),
        ];
    }
    return const [
      Color(0xFF000000),
      Color(0xFFFF0000),
      Color(0xFFFFE400),
      Color(0xFF1DDB16),
      Color(0xFF0100FF),
    ];
  }

  static const Color black = Color(0xFF222222);
  static const Color red = Color(0xFFEC3A3A);
  static const Color yellow = Color(0xFFFFE927);
  static const Color green = Color(0xFF0AD35A);
  static const Color blue = Color(0xFF0D84F2);
  static const Color etc = Color(0xFF111111);
}

/*
연필
검은 #000000
빨강 #FF0000
노랑 #FFE400
초록 #1DDB16
파랑 #0100FF

펜
회색 #5D5D5D
다홍 #F15F5F
노랑 #FFE08C
초록 #22741C
하늘 #6799FF

하일라이트
보라 #DAD9FF
분홍 #FFD9EC
노랑 #FAF4C0
초록 #E4F7BA
하늘 #D4F4FA
*/
