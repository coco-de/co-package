// Domain UseCase — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.13.
// BDD: F5.5, F5.6, F7.4 (Fixed Layout 텍스트 레이어 자동 감지)

import '../entity/text_layer_verdict.dart';

class DetectTextLayerUseCase {
  /// XHTML 콘텐츠의 가시 텍스트가 임계값(50자)을 넘는지 판정.
  Future<TextLayerVerdict> call(String xhtmlContent) {
    throw UnimplementedError('S1.13');
  }
}
