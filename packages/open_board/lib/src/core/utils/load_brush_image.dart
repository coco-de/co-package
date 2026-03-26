// 🎯 Dart imports:
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

// 🐦 Flutter imports:
import 'package:flutter/services.dart' show rootBundle;

/// Load [Image] from asset path.
/// https://stackoverflow.com/a/61338308/1321917
Future<ui.Image> loadUiImage(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final list = Uint8List.view(data.buffer);
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(list, completer.complete);
  return completer.future;
}
