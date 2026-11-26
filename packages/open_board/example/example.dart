// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:open_board/open_board.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: SimpleScribbleWidget(
          allowedPointersMode: ScribblePointerMode.all,
          child: ColoredBox(
            color: Colors.white,
            child: Center(child: Text('Draw here')),
          ),
        ),
      ),
    ),
  );
}
