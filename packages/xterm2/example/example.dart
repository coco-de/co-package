import 'package:co_xterm2/xterm.dart';
import 'package:flutter/material.dart';

void main() {
  final terminal = Terminal()..write('Hello from co_xterm2!\r\n');
  runApp(MaterialApp(home: Scaffold(body: TerminalView(terminal))));
}
