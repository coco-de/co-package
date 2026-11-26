import 'package:co_xterm3/xterm.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

void main() {
  final terminal = Terminal()..write('Hello from co_xterm3!\r\n');
  runApp(MaterialApp(home: Scaffold(body: TerminalView(terminal))));
}
