// 🎯 Dart imports:
import 'dart:async';

// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide showDialog;

class Debouncer {
  final int? milliseconds;
  VoidCallback? action;
  Timer? _timer;
  Debouncer({this.milliseconds = 100});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds!), action);
  }
}
