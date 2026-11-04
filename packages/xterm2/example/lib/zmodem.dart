import 'package:co_example_ui/co_example_ui.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, Brightness;
import 'package:path/path.dart' as path;
import 'package:xterm2/xterm.dart';

const host = 'localhost';
const port = 22;
const username = '<your username>';
const password = '<your password>';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'xterm2 demo',
      theme: exampleMaterialTheme(Brightness.light),
      darkTheme: exampleMaterialTheme(Brightness.dark),
      builder: (context, child) => ExampleThemeScope(child: child!),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final terminal = Terminal();

  var title = host;

  @override
  void initState() {
    super.initState();
    initTerminal();
  }

  Future<void> initTerminal() async {
    terminal.write('Connecting...\r\n');

    final client = SSHClient(
      await SSHSocket.connect(host, port),
      username: username,
      onPasswordRequest: () => password,
      printTrace: print,
    );

    terminal.write('Connected\r\n');

    final session = await client.shell(
      pty: SSHPtyConfig(width: terminal.viewWidth, height: terminal.viewHeight),
    );

    terminal.buffer.clear();
    terminal.buffer.setCursor(0, 0);

    terminal.onTitleChange = (title) {
      setState(() => this.title = title);
    };

    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      session.resizeTerminal(width, height, pixelWidth, pixelHeight);
    };

    final mux = ZModemMux(stdin: session.stdin, stdout: session.stdout);

    mux.onTerminalInput = terminal.write;
    mux.onFileOffer = _handleFileOffer;
    mux.onFileRequest = _handleFileRequest;

    terminal.onOutput = mux.terminalWrite;
  }

  void _handleFileOffer(ZModemOffer offer) async {
    print(offer.info);

    final outputDir = await FilePicker.getDirectoryPath();

    if (outputDir == null) {
      offer.skip();
      return;
    }

    final file = File(path.join(outputDir, offer.info.pathname));

    void updateProgress(int received) {
      final length = offer.info.length;
      if (length != null) {
        terminal.write('\r');
        terminal.write('\x1b[K');
        terminal.write('${offer.info.pathname}: ');
        terminal.write((received / length * 100).toStringAsFixed(1));
        terminal.write('%');
      }
    }

    await offer
        .accept(0)
        .cast<List<int>>()
        .transform(WithProgress(onProgress: updateProgress))
        .pipe(file.openWrite());

    terminal.write('\r\n');
    terminal.write('Received ${offer.info.pathname}');
  }

  Future<Iterable<ZModemOffer>> _handleFileRequest() async {
    final result = await FilePicker.pickFiles();

    if (result.isEmpty) {
      return [];
    }

    final sizes = {for (final file in result) file: await file.length()};

    void updateProgress(PlatformFile file, int received) {
      terminal.write('\r');
      terminal.write('\x1b[K');
      terminal.write('${file.name}: ');
      terminal.write(
        (received / (sizes[file]! > 0 ? sizes[file]! : 1) * 100)
            .toStringAsFixed(1),
      );
      terminal.write('%');
    }

    return result.map(
      (file) => ZModemCallbackOffer(
        ZModemFileInfo(
          pathname: path.basename(file.path!),
          length: sizes[file]!,
          mode: '100644',
          filesRemaining: 1,
          bytesRemaining: sizes[file]!,
        ),
        onAccept: (offset) => file.xFile
            .openRead(offset)
            .cast<List<int>>()
            .transform(
              WithProgress(onProgress: (bytes) => updateProgress(file, bytes)),
            )
            .cast<Uint8List>(),
        onSkip: () {
          terminal.write('\r\n');
          terminal.write('Rejected ${file.name}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        backgroundColor: CupertinoTheme.of(
          context,
        ).barBackgroundColor.withValues(alpha: 0.5),
      ),
      child: TerminalView(terminal),
    );
  }
}

class WithProgress<T> extends StreamTransformerBase<List<T>, List<T>> {
  WithProgress({this.onProgress});

  void Function(int progress)? onProgress;

  var _progress = 0;

  int get progress => _progress;

  @override
  Stream<List<T>> bind(Stream<List<T>> stream) {
    return stream.transform(
      StreamTransformer<List<T>, List<T>>.fromHandlers(
        handleData: (List<T> data, EventSink<List<T>> sink) {
          _progress += data.length;
          onProgress?.call(_progress);
          sink.add(data);
        },
      ),
    );
  }
}
