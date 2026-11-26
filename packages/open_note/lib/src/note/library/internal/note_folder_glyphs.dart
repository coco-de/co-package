import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/library/note_folder_icons.dart';

/// The vector outlines of the folder icons, drawn as strokes in a
/// [designSize] square box.
abstract final class NoteFolderGlyphs {
  /// The side of the square box every path is designed in.
  static const double designSize = 24;

  /// The outline of [iconKey]; unknown keys get the plain folder.
  static Path pathFor(String iconKey) => switch (iconKey) {
    NoteFolderIcons.star => _star(),
    NoteFolderIcons.heart => _heart(),
    NoteFolderIcons.book => _book(),
    NoteFolderIcons.bookmark => _bookmark(),
    NoteFolderIcons.briefcase => _briefcase(),
    NoteFolderIcons.school => _school(),
    NoteFolderIcons.home => _home(),
    NoteFolderIcons.flag => _flag(),
    NoteFolderIcons.lightbulb => _lightbulb(),
    NoteFolderIcons.music => _music(),
    NoteFolderIcons.code => _code(),
    NoteFolderIcons.flask => _flask(),
    NoteFolderIcons.camera => _camera(),
    NoteFolderIcons.calendar => _calendar(),
    _ => _folder(),
  };

  static Path _folder() => Path()
    ..moveTo(3, 7)
    ..quadraticBezierTo(3, 5, 5, 5)
    ..lineTo(9, 5)
    ..lineTo(11, 7.5)
    ..lineTo(19, 7.5)
    ..quadraticBezierTo(21, 7.5, 21, 9.5)
    ..lineTo(21, 17)
    ..quadraticBezierTo(21, 19, 19, 19)
    ..lineTo(5, 19)
    ..quadraticBezierTo(3, 19, 3, 17)
    ..close();

  static Path _star() {
    const center = Offset(12, 12.8);
    final points = [
      for (var i = 0; i < 10; i++)
        center +
            Offset.fromDirection(
              -math.pi / 2 + i * math.pi / 5,
              i.isEven ? 9.2 : 4,
            ),
    ];

    return Path()..addPolygon(points, true);
  }

  static Path _heart() => Path()
    ..moveTo(12, 20)
    ..cubicTo(5, 15, 3, 11.5, 3, 8.5)
    ..cubicTo(3, 6, 5, 4.5, 7.5, 4.5)
    ..cubicTo(9.5, 4.5, 11, 5.6, 12, 7.2)
    ..cubicTo(13, 5.6, 14.5, 4.5, 16.5, 4.5)
    ..cubicTo(19, 4.5, 21, 6, 21, 8.5)
    ..cubicTo(21, 11.5, 19, 15, 12, 20)
    ..close();

  static Path _book() => Path()
    ..moveTo(12, 7)
    ..cubicTo(10, 5.5, 7, 5, 3, 5.5)
    ..lineTo(3, 18)
    ..cubicTo(7, 17.5, 10, 18, 12, 19.5)
    ..cubicTo(14, 18, 17, 17.5, 21, 18)
    ..lineTo(21, 5.5)
    ..cubicTo(17, 5, 14, 5.5, 12, 7)
    ..lineTo(12, 19.5);

  static Path _bookmark() => Path()
    ..addPolygon(const [
      Offset(7, 4),
      Offset(17, 4),
      Offset(17, 20),
      Offset(12, 16),
      Offset(7, 20),
    ], true);

  static Path _briefcase() => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(3, 8, 21, 20),
        const Radius.circular(2),
      ),
    )
    ..moveTo(9, 8)
    ..lineTo(9, 5)
    ..lineTo(15, 5)
    ..lineTo(15, 8)
    ..moveTo(3, 13)
    ..lineTo(21, 13);

  static Path _school() => Path()
    ..addPolygon(const [
      Offset(2, 9.5),
      Offset(12, 5),
      Offset(22, 9.5),
      Offset(12, 14),
    ], true)
    ..moveTo(6, 11.5)
    ..lineTo(6, 16)
    ..cubicTo(6, 17.5, 9, 19, 12, 19)
    ..cubicTo(15, 19, 18, 17.5, 18, 16)
    ..lineTo(18, 11.5)
    ..moveTo(22, 9.5)
    ..lineTo(22, 15);

  static Path _home() => Path()
    ..moveTo(3, 11.5)
    ..lineTo(12, 4)
    ..lineTo(21, 11.5)
    ..moveTo(5.5, 10)
    ..lineTo(5.5, 20)
    ..lineTo(18.5, 20)
    ..lineTo(18.5, 10)
    ..moveTo(10, 20)
    ..lineTo(10, 14)
    ..lineTo(14, 14)
    ..lineTo(14, 20);

  static Path _flag() => Path()
    ..moveTo(5, 21)
    ..lineTo(5, 4.5)
    ..cubicTo(8, 3, 10, 3, 13, 4.5)
    ..cubicTo(15.5, 5.8, 17, 5.8, 19, 5)
    ..lineTo(19, 13.5)
    ..cubicTo(17, 14.3, 15.5, 14.3, 13, 13)
    ..cubicTo(10, 11.5, 8, 11.5, 5, 13);

  static Path _lightbulb() => Path()
    ..moveTo(9, 16)
    ..cubicTo(9, 13.5, 6, 12.5, 6, 9)
    ..arcToPoint(const Offset(18, 9), radius: const Radius.circular(6))
    ..cubicTo(18, 12.5, 15, 13.5, 15, 16)
    ..close()
    ..moveTo(9.5, 18.5)
    ..lineTo(14.5, 18.5)
    ..moveTo(10.5, 21)
    ..lineTo(13.5, 21);

  static Path _music() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(6.5, 18), radius: 2.5))
    ..addOval(Rect.fromCircle(center: const Offset(16.5, 16), radius: 2.5))
    ..moveTo(9, 18)
    ..lineTo(9, 6)
    ..lineTo(19, 4)
    ..lineTo(19, 16)
    ..moveTo(9, 9.5)
    ..lineTo(19, 7.5);

  static Path _code() => Path()
    ..moveTo(8.5, 7)
    ..lineTo(3.5, 12)
    ..lineTo(8.5, 17)
    ..moveTo(15.5, 7)
    ..lineTo(20.5, 12)
    ..lineTo(15.5, 17)
    ..moveTo(13.5, 5)
    ..lineTo(10.5, 19);

  static Path _flask() => Path()
    ..moveTo(10, 3.5)
    ..lineTo(10, 9)
    ..lineTo(4.5, 18.5)
    ..quadraticBezierTo(3.8, 20.5, 6, 20.5)
    ..lineTo(18, 20.5)
    ..quadraticBezierTo(20.2, 20.5, 19.5, 18.5)
    ..lineTo(14, 9)
    ..lineTo(14, 3.5)
    ..moveTo(8.5, 3.5)
    ..lineTo(15.5, 3.5)
    ..moveTo(7.5, 14.5)
    ..lineTo(16.5, 14.5);

  static Path _camera() => Path()
    ..moveTo(3, 8.5)
    ..quadraticBezierTo(3, 7, 4.5, 7)
    ..lineTo(8, 7)
    ..lineTo(9.5, 4.5)
    ..lineTo(14.5, 4.5)
    ..lineTo(16, 7)
    ..lineTo(19.5, 7)
    ..quadraticBezierTo(21, 7, 21, 8.5)
    ..lineTo(21, 18)
    ..quadraticBezierTo(21, 19.5, 19.5, 19.5)
    ..lineTo(4.5, 19.5)
    ..quadraticBezierTo(3, 19.5, 3, 18)
    ..close()
    ..addOval(Rect.fromCircle(center: const Offset(12, 13), radius: 3.5));

  static Path _calendar() => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(3.5, 5, 20.5, 20.5),
        const Radius.circular(2),
      ),
    )
    ..moveTo(3.5, 10)
    ..lineTo(20.5, 10)
    ..moveTo(8, 3)
    ..lineTo(8, 7)
    ..moveTo(16, 3)
    ..lineTo(16, 7);
}
