// Data Parser — open_epub 1.0
// Story: S13.6 (#103) — SMIL 미디어 오버레이 파서 (gap #6 파싱분)
//
// EPUB Media Overlay(.smil) 구조:
// <smil xmlns="http://www.w3.org/ns/SMIL" version="3.0">
//   <body>
//     <seq>
//       <par>
//         <text src="ch1.xhtml#s1"/>
//         <audio src="ch1.mp3" clipBegin="0s" clipEnd="5.2s"/>
//       </par>
//     </seq>
//   </body>
// </smil>
//
// <seq> 중첩은 평탄화하여 <par>를 document 순서로 수집한다. 오디오 재생·동기화는
// reader(E14/별도) 책임이며, 여기서는 파싱만 한다.

import 'package:xml/xml.dart';

import '../../domain/entity/epub_media_overlay.dart';

class SmilParser {
  const SmilParser();

  static const String _smilNs = 'http://www.w3.org/ns/SMIL';

  /// SMIL XML을 [EpubMediaOverlay]로 파싱한다. 유효하지 않으면
  /// [EpubMediaOverlay.empty] (예외를 던지지 않음 — 보조 콘텐츠).
  EpubMediaOverlay parse(String smilXml) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(smilXml);
    } on XmlException {
      return EpubMediaOverlay.empty;
    }
    // namespace가 선언되지 않은 SMIL도 관대하게 처리(localName로 탐색).
    final pars = <EpubMediaPar>[];
    for (final par in doc.findAllElements('par').where(_isSmil)) {
      final parsed = _parsePar(par);
      if (parsed != null) pars.add(parsed);
    }
    return pars.isEmpty ? EpubMediaOverlay.empty : EpubMediaOverlay(pars: pars);
  }

  bool _isSmil(XmlElement el) =>
      el.namespaceUri == null || el.namespaceUri == _smilNs;

  EpubMediaPar? _parsePar(XmlElement par) {
    final text = par.childElements
        .where((e) => e.localName == 'text' && _isSmil(e))
        .firstOrNull;
    final textSrc = text?.getAttribute('src');
    if (textSrc == null || textSrc.isEmpty) return null; // text는 필수

    final audio = par.childElements
        .where((e) => e.localName == 'audio' && _isSmil(e))
        .firstOrNull;

    return EpubMediaPar(
      textSrc: textSrc,
      audioSrc: audio?.getAttribute('src'),
      clipBegin: parseClock(audio?.getAttribute('clipBegin')) ?? Duration.zero,
      clipEnd: parseClock(audio?.getAttribute('clipEnd')),
    );
  }

  /// SMIL clock value → [Duration]. 지원 형식:
  /// - full/partial clock: `1:02:03.5`, `02:03`
  /// - timecount: `5.2s`, `234ms`, `1.5min`, `2h`, 또는 단위 없는 초(`12`)
  ///
  /// 파싱 불가/null이면 null.
  static Duration? parseClock(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v.isEmpty) return null;

    if (v.contains(':')) {
      return _parseClockNotation(v);
    }
    return _parseTimecount(v);
  }

  static Duration? _parseClockNotation(String v) {
    final parts = v.split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    final nums = parts.map((p) => double.tryParse(p)).toList();
    if (nums.any((n) => n == null)) return null;
    double seconds;
    if (nums.length == 3) {
      seconds = nums[0]! * 3600 + nums[1]! * 60 + nums[2]!;
    } else {
      seconds = nums[0]! * 60 + nums[1]!;
    }
    return _fromSeconds(seconds);
  }

  static Duration? _parseTimecount(String v) {
    final match = RegExp(r'^([0-9]*\.?[0-9]+)\s*(h|min|ms|s)?$').firstMatch(v);
    if (match == null) return null;
    final value = double.parse(match.group(1)!);
    switch (match.group(2)) {
      case 'h':
        return _fromSeconds(value * 3600);
      case 'min':
        return _fromSeconds(value * 60);
      case 'ms':
        return Duration(microseconds: (value * 1000).round());
      case 's':
      case null:
      default:
        return _fromSeconds(value);
    }
  }

  static Duration _fromSeconds(double seconds) =>
      Duration(microseconds: (seconds * 1000000).round());
}
