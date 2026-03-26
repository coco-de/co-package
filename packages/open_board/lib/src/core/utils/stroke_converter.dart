// 🐦 Flutter imports:
import 'package:flutter/services.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pbserver.dart';

// 🌎 Project imports:

class ScribbleTools {
  static ScribbleTools? _instance;
  static ScribbleTools get instance => _getInstance();

  static ScribbleTools _getInstance() {
    _instance ??= ScribbleTools._();
    return _instance!;
  }

  static const MethodChannel _channel = MethodChannel(
    'im.laputa.unibook/open_board',
  );

  ScribbleTools._() {
    _channel.setMethodCallHandler(_handler);
  }

  /// PencilKit으로 부터 생성된 .data 바이너리 파일을
  /// 플러터에서 이해 가능한 프로토버퍼 바이너리로 변환 합니다
  Future<Scribble> getStrokesFromPencilKit(Uint8List data) async {
    final result = await _channel.invokeMethod("getStrokes", data);
    return Scribble.fromBuffer(result as List<int>);
  }

  Future<dynamic> _handler(MethodCall call) {
    switch (call.method) {
      case "something":
        break;
      default:
        break;
    }
    return Future.value(true);
  }

  Future<String> get platformVersion async {
    final String version =
        await _channel.invokeMethod('getPlatformVersion') as String;
    return version;
  }
}
