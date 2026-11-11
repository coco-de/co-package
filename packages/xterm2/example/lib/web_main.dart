import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:co_example_ui/co_example_ui.dart';
import 'package:coui_flutter/coui_flutter.dart' as co;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:xterm2/xterm.dart';

final _themeMode = ValueNotifier(ThemeMode.system);
final _locale = ValueNotifier<DemoLocale>(DemoLocale.en);

void _apply(DemoPrefs prefs) {
  if (prefs.locale case final locale?) _locale.value = locale;
  if (prefs.theme case final theme?) {
    _themeMode.value = theme == DemoTheme.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _apply(DemoPrefs.fromUri(Uri.base));
  DemoEmbedSync(allowLocalhost: kDebugMode).start(_apply);
  runApp(const TerminalExampleApp());
}

class TerminalExampleApp extends StatelessWidget {
  const TerminalExampleApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_themeMode, _locale]),
    builder: (context, _) => MaterialApp(
      title: 'xterm2 · Cocode playground',
      debugShowCheckedModeBanner: false,
      theme: exampleMaterialTheme(Brightness.light),
      darkTheme: exampleMaterialTheme(Brightness.dark),
      themeMode: _themeMode.value,
      locale: Locale.fromSubtags(
        languageCode: _locale.value.languageCode,
        scriptCode: _locale.value.scriptCode,
      ),
      supportedLocales: [
        for (final locale in DemoLocale.values)
          Locale.fromSubtags(
            languageCode: locale.languageCode,
            scriptCode: locale.scriptCode,
          ),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => ExampleThemeScope(child: child!),
      home: const TerminalPlayground(),
    ),
  );
}

class TerminalPlayground extends StatefulWidget {
  const TerminalPlayground({super.key});
  @override
  State<TerminalPlayground> createState() => _TerminalPlaygroundState();
}

class _TerminalPlaygroundState extends State<TerminalPlayground> {
  final _terminal = Terminal(maxLines: 2000);
  final _controller = TerminalController();
  final _focus = FocusNode();
  late final DemoShell _shell;
  double _fontSize = 14;

  @override
  void initState() {
    super.initState();
    _shell = DemoShell(_terminal.write);
    _terminal.onOutput = _shell.write;
  }

  @override
  void dispose() {
    _terminal.onOutput = null;
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _run(String command) {
    _shell.run(command);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('xterm2 / Playground'),
        actions: [
          ExampleSettings(
            themeMode: _themeMode,
            locale: _locale.value,
            onLocaleChanged: (value) => _locale.value = value,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Your terminal. In the browser.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const co.Badge(
                    tone: co.CoreBadgeTone.success,
                    showDot: true,
                    child: Text('Interactive demo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Type a command below, or choose one to explore ANSI colors and Unicode rendering.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final command in ['help', 'colors', 'unicode', 'clear'])
                    co.Button(
                      variant: co.CoreButtonVariant.secondary,
                      size: co.CoreComponentSize.sm,
                      onPressed: () => _run(command),
                      child: Text(command),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: ColoredBox(
                      color: const Color(0xff17191e),
                      child: Column(
                        children: [
                          Container(
                            color: const Color(0xff22252d),
                            padding: const EdgeInsetsDirectional.only(
                              start: 16,
                              end: 6,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.terminal_rounded,
                                  size: 16,
                                  color: Color(0xffa7b0c2),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'playground ~',
                                    style: TextStyle(
                                      color: Color(0xffc4cbd8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Smaller text',
                                  onPressed: _fontSize > 10
                                      ? () => setState(() => _fontSize--)
                                      : null,
                                  icon: const Icon(
                                    Icons.text_decrease,
                                    color: Color(0xffc4cbd8),
                                    size: 18,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Larger text',
                                  onPressed: _fontSize < 24
                                      ? () => setState(() => _fontSize++)
                                      : null,
                                  icon: const Icon(
                                    Icons.text_increase,
                                    color: Color(0xffc4cbd8),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TerminalView(
                              _terminal,
                              key: const ValueKey('terminal-view'),
                              controller: _controller,
                              focusNode: _focus,
                              autofocus: false,
                              padding: const EdgeInsets.all(16),
                              textStyle: TerminalStyle(
                                fontSize: _fontSize,
                                height: 1.5,
                                fontFamily: 'Cascadia Mono',
                                fontFamilyFallback: const [
                                  'packages/co_example_ui/Pretendard',
                                ],
                              ),
                              onSecondaryTapDown: (details, offset) async {
                                final selection = _controller.selection;
                                if (selection == null) return;
                                await Clipboard.setData(
                                  ClipboardData(
                                    text: _terminal.buffer.getText(selection),
                                  ),
                                );
                                _controller.clearSelection();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Local demo shell · help, colors, unicode, echo, date, clear',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A browser-only shell with bounded local commands; no network or native PTY.
class DemoShell {
  DemoShell(this.output) {
    output('\x1b[1;36mxterm2\x1b[0m  /  Cocode playground\r\n\r\n');
    output('Welcome! Try \x1b[33mhelp\x1b[0m to get started.\r\n');
    _prompt();
  }
  final ValueChanged<String> output;
  String _input = '';
  bool _escape = false;

  void _prompt() => output('\r\n\x1b[32mvisitor\x1b[0m \x1b[34m~\x1b[0m \$ ');

  void write(String data) {
    for (final rune in data.runes) {
      if (_escape) {
        if (rune >= 0x40 && rune <= 0x7e && rune != 0x5b) _escape = false;
        continue;
      }
      if (rune == 27) {
        _escape = true;
      } else if (rune == 13 || rune == 10) {
        output('\r\n');
        final command = _input;
        _input = '';
        _execute(command);
        _prompt();
      } else if (rune == 127 || rune == 8) {
        if (_input.isNotEmpty) {
          final runes = _input.runes.toList()..removeLast();
          _input = String.fromCharCodes(runes);
          output('\b \b');
        }
      } else if (rune == 3) {
        _input = '';
        output('^C');
        _prompt();
      } else if (rune == 12) {
        _input = '';
        output('\x1b[2J\x1b[H');
        _prompt();
      } else if (rune >= 32) {
        final character = String.fromCharCode(rune);
        _input += character;
        output(character);
      }
    }
  }

  void run(String command) {
    output('\x1b[2K\r\x1b[32mvisitor\x1b[0m \x1b[34m~\x1b[0m \$ $command\r\n');
    _input = '';
    _execute(command);
    _prompt();
  }

  void _execute(String input) {
    final command = input.trim();
    if (command.isEmpty) return;
    switch (command) {
      case 'help':
        output(
          'help     Show available commands\r\ncolors   Explore the ANSI palette\r\nunicode  Render international text\r\necho …   Print your text\r\ndate     Show the current date\r\nclear    Start with a clean terminal\r\n',
        );
      case 'colors':
        for (var row = 0; row < 4; row++) {
          for (var column = 0; column < 8; column++) {
            output('\x1b[48;5;${16 + row * 8 + column}m   \x1b[0m');
          }
          output('\r\n');
        }
        output(
          '\r\n\x1b[1mBold\x1b[0m  \x1b[3mItalic\x1b[0m  \x1b[4mUnderline\x1b[0m\r\n',
        );
      case 'unicode':
        output(
          'Hello, world!\r\n안녕하세요 · こんにちは · 你好\r\nBonjour · Olá · Привет\r\n',
        );
      case 'clear':
        output('\x1b[2J\x1b[H');
      case 'date':
        output('${DateTime.now().toLocal()}\r\n');
      default:
        output(
          command.startsWith('echo ')
              ? '${command.substring(5)}\r\n'
              : 'Unknown command: $command. Type help.\r\n',
        );
    }
  }
}
