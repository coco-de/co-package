// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:open_board/src/core/theme/color_s.dart';

/// 잉크 모드 상수 정의
class InkModes {
  static const String pen = 'pen';
  static const String pencil = 'pencil';
  static const String marker = 'marker';
  static const String erase = 'erase';
  static const String lasso = 'lasso';
  static const String shape = 'shape';
  static const String text = 'text';
}

class InkGroupInfo {
  /// 선택된 잉크
  String selectedInk;

  /// 선택된 잉크 그룹
  String selectedInkGroup;

  /// 잉크 그룹 정보
  Map<String, Map<String, dynamic>> inkGroups;

  InkGroupInfo({
    required this.selectedInk,
    this.selectedInkGroup = InkModes.pen,
    this.inkGroups = const {
      InkModes.pen: {
        InkModes.pen: {"color": Colors.black, "width": 3.0},
        InkModes.marker: {"color": Colors.black, "width": 5.0},
        InkModes.pencil: {"color": Colors.black, "width": 2.0},
        InkModes.lasso: {"color": Colors.blue, "width": 2.0},
        InkModes.shape: {"color": Colors.black, "width": 2.0},
        InkModes.text: {"color": Colors.black, "width": 14.0},
      },
      InkModes.erase: {
        InkModes.erase: {"color": Colors.transparent, "width": 20.0},
      },
    },
  });

  Color get selectedColor => _colorBox[selectedInk] ?? Colors.black;

  double get seletedStrokeWidth => _strokeBox[selectedInk] ?? 1.0;

  Map<String, Color> _colorBox = {
    InkModes.pen: ColorS.getColors(inkType: InkModes.pen)[0],
    InkModes.pencil: ColorS.getColors(inkType: InkModes.pencil)[0],
    InkModes.marker: ColorS.getColors(inkType: InkModes.marker)[0],
    InkModes.erase: ColorS.getColors(inkType: InkModes.erase)[0],
    InkModes.lasso: Colors.blue,
    InkModes.shape: ColorS.getColors(inkType: InkModes.shape)[0],
    InkModes.text: ColorS.getColors(inkType: InkModes.text)[0],
  };

  Map<String, double> _strokeBox = {
    InkModes.pen: 0.5,
    InkModes.pencil: 0.5,
    InkModes.marker: 2.5,
    InkModes.erase: 2.5,
    InkModes.lasso: 1.8,
    InkModes.shape: 1.0,
    InkModes.text: 14.0,
  };

  void _changeColor(Color color) {
    _colorBox[selectedInk] = color;
  }

  void _changeStrokeWidth(double width) {
    _strokeBox[selectedInk] = width;
  }

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
}
