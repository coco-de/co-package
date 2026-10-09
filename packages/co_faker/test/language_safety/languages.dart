import 'ar.dart';
import 'de.dart';
import 'en.dart';
import 'es.dart';
import 'fr.dart';
import 'it.dart';
import 'ja.dart';
import 'ko.dart';
import 'language_safety.dart';
import 'pt.dart';
import 'ru.dart';
import 'zh.dart';

/// The safety declaration of every language that co_faker registers, by
/// language code. Each language has its own entry, separated by a blank line,
/// and the Story that localizes a language edits only its own file in this
/// directory, never this list.
const Map<String, LanguageSafety> languageSafety = <String, LanguageSafety>{
  'ko': koSafety,

  'en': enSafety,

  'zh': zhSafety,

  'ja': jaSafety,

  'de': deSafety,

  'fr': frSafety,

  'ru': ruSafety,

  'it': itSafety,

  'pt': ptSafety,

  'es': esSafety,

  'ar': arSafety,
};
