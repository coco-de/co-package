import 'package:flutter/material.dart';

class PenToolKeys {
  // 잉크 타입 (ink type) - 펜,마커,연필,지우개 등
  static const pen = Key('pen');
  static const marker = Key('marker');
  static const pencil = Key('pencil');
  static const erase = Key('erase');
  static const inkEtc = Key('inkEtc');

  // 펜 두께(stroke weight) , 작은것(1)부터 큰것까지
  static const strokeWeight1 = Key('strokeWeight1');
  static const strokeWeight2 = Key('strokeWeight2');
  static const strokeWeight3 = Key('strokeWeight3');
  static const strokeWeight4 = Key('strokeWeight4');
  static const strokeWeight5 = Key('strokeWeight5');

  // 펜 두께 선택된것
  static const strokeSelected = Key('strokeSelected');

  // 필기 색깔
  static const black = Key('black');
  static const red = Key('red');
  static const yellow = Key('yellow');
  static const green = Key('green');
  static const blue = Key('blue');
  static const colorEtc = Key('colorEtc');

  // 필기 색 선택된것
  static const colorSelected = Key('colorSelected');

  // 클리어
  static const clear = Key('clear');

  // 언두, 리두 (필기 했던것 취소)
  static const undo = Key('undo');
  static const redo = Key('redo');
}
