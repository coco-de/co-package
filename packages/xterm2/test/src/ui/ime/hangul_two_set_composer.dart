/// 두벌식 입력기 대역. 조합 중 음절은 표시 상태로 두고 다음 입력에서 확정한다.
class HangulTwoSetComposer {
  static const _initials = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
  static const _medials = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ';
  static const _finals = [
    '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', //
    'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];
  static const _compoundVowels = {
    'ㅗㅏ': 'ㅘ', 'ㅗㅐ': 'ㅙ', 'ㅗㅣ': 'ㅚ', 'ㅜㅓ': 'ㅝ', //
    'ㅜㅔ': 'ㅞ', 'ㅜㅣ': 'ㅟ', 'ㅡㅣ': 'ㅢ',
  };
  static const _compoundFinals = {
    'ㄱㅅ': 'ㄳ', 'ㄴㅈ': 'ㄵ', 'ㄴㅎ': 'ㄶ', 'ㄹㄱ': 'ㄺ', 'ㄹㅁ': 'ㄻ', 'ㄹㅂ': 'ㄼ', //
    'ㄹㅅ': 'ㄽ', 'ㄹㅌ': 'ㄾ', 'ㄹㅍ': 'ㄿ', 'ㄹㅎ': 'ㅀ', 'ㅂㅅ': 'ㅄ',
  };

  String? _initial;
  String? _medial;
  String? _final;

  String get marked {
    final initial = _initial;
    final medial = _medial;
    if (initial != null && medial != null) {
      final index =
          (_initials.indexOf(initial) * 21 + _medials.indexOf(medial)) * 28 +
              _finals.indexOf(_final ?? '');
      return String.fromCharCode(0xAC00 + index);
    }
    return initial ?? medial ?? '';
  }

  bool get isComposing => marked.isNotEmpty;
  static bool isVowel(String jamo) => _medials.contains(jamo);

  String input(String jamo) =>
      isVowel(jamo) ? _inputVowel(jamo) : _inputConsonant(jamo);

  String _inputConsonant(String consonant) {
    if (_initial != null && _medial != null) {
      final current = _final;
      if (current == null && _finals.contains(consonant)) {
        _final = consonant;
        return '';
      }
      final compound =
          current == null ? null : _compoundFinals[current + consonant];
      if (compound != null) {
        _final = compound;
        return '';
      }
    } else if (_initial == null && _medial == null) {
      _initial = consonant;
      return '';
    }
    final committed = marked;
    reset();
    _initial = consonant;
    return committed;
  }

  String _inputVowel(String vowel) {
    if (_medial == null) {
      _medial = vowel;
      return '';
    }
    final carried = _final;
    if (carried != null) {
      final split = _splitFinal(carried);
      _final = split?.$1;
      final committed = marked;
      reset();
      _initial = split?.$2 ?? carried;
      _medial = vowel;
      return committed;
    }
    final compound = _compoundVowels[_medial! + vowel];
    if (compound != null) {
      _medial = compound;
      return '';
    }
    final committed = marked;
    reset();
    _medial = vowel;
    return committed;
  }

  void backspace() {
    final current = _final;
    if (current != null) {
      _final = _splitFinal(current)?.$1;
      return;
    }
    final medial = _medial;
    if (medial != null) {
      _medial = _splitVowel(medial);
      return;
    }
    _initial = null;
  }

  String flush() {
    final committed = marked;
    reset();
    return committed;
  }

  void reset() {
    _initial = null;
    _medial = null;
    _final = null;
  }

  static (String, String)? _splitFinal(String jamo) {
    for (final entry in _compoundFinals.entries) {
      if (entry.value == jamo) return (entry.key[0], entry.key[1]);
    }
    return null;
  }

  static String? _splitVowel(String jamo) {
    for (final entry in _compoundVowels.entries) {
      if (entry.value == jamo) return entry.key[0];
    }
    return null;
  }
}
