// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:open_board/src/core/theme/color_s.dart';

/// 잉크 모드 상수 정의
class InkModes {
  static const String pen = 'pen';
  static const String pencil = 'pencil';
  static const String marker = 'marker';
  static const String fixedPen = 'fixedPen';

  /// 균일 두께 펜 — 압력/속도에 따른 두께 변화 없이(thinning 0, simulatePressure
  /// false) 콘텐츠 좌표계 고정 두께를 유지한다. `fixedPen`(화면 물리 두께 보정)과
  /// 달리 줌 배율 보정을 적용하지 않아 확대 시 콘텐츠와 함께 굵어진다.
  static const String uniformPen = 'uniformPen';

  static const String erase = 'erase';
  static const String lasso = 'lasso';
  static const String shape = 'shape';
  static const String text = 'text';
}

class InkGroupInfo {
  /// 선택된 잉크
  String selectedInk;

  Map<String, Color> _colorBox = {
    InkModes.pen: ColorS.getColors(inkType: InkModes.pen)[0],
    InkModes.pencil: ColorS.getColors(inkType: InkModes.pencil)[0],
    InkModes.marker: ColorS.getColors(inkType: InkModes.marker)[0],
    InkModes.fixedPen: ColorS.getColors(inkType: InkModes.pen)[0],
    InkModes.uniformPen: ColorS.getColors(inkType: InkModes.pen)[0],
    InkModes.erase: ColorS.getColors(inkType: InkModes.erase)[0],
    InkModes.lasso: Colors.blue,
    InkModes.shape: ColorS.getColors(inkType: InkModes.shape)[0],
    InkModes.text: ColorS.getColors(inkType: InkModes.text)[0],
  };

  Map<String, double> _strokeBox = {
    InkModes.pen: 0.5,
    InkModes.pencil: 0.5,
    InkModes.marker: 2.5,
    InkModes.fixedPen: 0.5,
    InkModes.uniformPen: 0.5,
    InkModes.erase: 2.5,
    InkModes.lasso: 1.8,
    InkModes.shape: 1.0,
    InkModes.text: 14.0,
  };

  InkGroupInfo({required this.selectedInk});

  Color get selectedColor => _colorBox[selectedInk] ?? Colors.black;

  double get seletedStrokeWidth => _strokeBox[selectedInk] ?? 1.0;

  void setColorBox(Map<String, Color> colorBox) {
    _colorBox = colorBox;
  }

  void setStrokeBox(Map<String, double> strokeBox) {
    _strokeBox = strokeBox;
  }

  InkGroupInfo copyWith({
    String? selectedInk,
    Color? inkColor,
    double? strokeWidth,
  }) {
    InkGroupInfo newInkInfo = InkGroupInfo(
      selectedInk: selectedInk ?? this.selectedInk,
    );

    newInkInfo.setColorBox(_colorBox);
    if (inkColor != null) {
      newInkInfo._changeColor(inkColor);
    }

    newInkInfo.setStrokeBox(_strokeBox);
    if (strokeWidth != null) {
      newInkInfo._changeStrokeWidth(strokeWidth);
    }

    return newInkInfo;
  }

  void _changeColor(Color color) {
    _colorBox[selectedInk] = color;
  }

  void _changeStrokeWidth(double width) {
    _strokeBox[selectedInk] = width;
  }
}
