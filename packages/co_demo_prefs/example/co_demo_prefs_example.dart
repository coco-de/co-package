// A demo app's startup, without Flutter: read the first values from the URL,
// then follow the preview's parent. In a Flutter app, map DemoLocale to
// `Locale.fromSubtags(languageCode: l.languageCode, scriptCode: l.scriptCode)`
// and DemoTheme to `ThemeMode`.
import 'package:co_demo_prefs/co_demo_prefs.dart';

void main() {
  final initial = DemoPrefs.fromUri(
    Uri.parse('https://docs.cocode.im/demo/app/?lang=ar&theme=dark#/home'),
  );
  apply(initial);

  DemoEmbedSync().start(apply);

  // A sender builds the same URL from the visitor's choice.
  const choice = DemoPrefs(locale: DemoLocale.ja, theme: DemoTheme.light);
  // ignore: avoid_print
  print(choice.applyTo('https://docs.cocode.im/demo/app/#/home'));
}

/// Applies received values — a real app updates its locale and theme state.
void apply(DemoPrefs prefs) {
  final locale = prefs.locale;
  final theme = prefs.theme;
  if (locale != null) {
    // ignore: avoid_print
    print('locale ${locale.tag}${locale.isRtl ? ' (right to left)' : ''}');
  }
  if (theme != null) {
    // ignore: avoid_print
    print('theme ${theme.name}');
  }
}
