# Additional TextMate grammars

`syntax_highlight_lite 0.0.1` embeds only Dart. These JSON, YAML, and SQL
grammars preserve CodeSnippet's existing language support through
`Highlighter.addLanguage`, without depending on the Flutter-only
`syntax_highlight` package or its editor/clipboard plugins.

Source: `syntax_highlight 0.4.0`, `grammars/{json,yaml,sql}.json`
([upstream](https://github.com/serverpod/syntax_highlight)).
JSON and YAML are unchanged. SQL's leading `(?i)` flags in match patterns
are expanded to explicit ASCII case pairs (`select` → `[sS][eE][lL][eE][cC][tT]`,
`a-z` → `a-zA-Z`), preserving case-insensitive keywords with Dart's RegExp,
which rejects inline flags. Capture groups and scopes are preserved.

Copyright 2023 The Serverpod authors;
BSD-3-Clause terms are reproduced in `../../LICENSE` and included in the
package's generated Flutter license bundle.
