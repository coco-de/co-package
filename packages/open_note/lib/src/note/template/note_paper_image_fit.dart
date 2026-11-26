import 'package:flutter/painting.dart';

/// How the image of an `image` paper fills the page. The names are persisted.
enum NotePaperImageFit {
  /// The whole image, centred, letterboxed on the paper colour.
  contain,

  /// Fills the page, cropping the image evenly on both sides.
  cover,

  /// Stretched to the page, ignoring the aspect ratio.
  fill;

  /// The matching framework fit.
  BoxFit get boxFit => switch (this) {
    contain => BoxFit.contain,
    cover => BoxFit.cover,
    fill => BoxFit.fill,
  };
}
