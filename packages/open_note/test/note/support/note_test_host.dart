import 'package:flutter/widgets.dart';

/// Hosts [child] in a [WidgetsApp] (no Material): a Navigator and Overlay,
/// MediaQuery, left-to-right text and default localizations — everything the
/// note widgets need — without depending on a design system.
///
/// The test surface is the flutter_test default (800 x 600 logical pixels);
/// change it with `tester.view.physicalSize` when a test needs another size.
Widget noteTestHost(Widget child, {Color color = const Color(0xFFFFFFFF)}) =>
    WidgetsApp(
      color: color,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
      ),
      home: child,
    );
