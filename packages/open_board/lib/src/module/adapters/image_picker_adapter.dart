/// Picked image returned by an [ImagePickerAdapter].
///
/// `source` is opaque to open-board: it can be a remote URL, a local file
/// path, or any other identifier the host application knows how to resolve to
/// pixel bytes at render time. open-board only stores the string.
class PickedImage {
  const PickedImage({
    required this.source,
    this.naturalWidth = 0,
    this.naturalHeight = 0,
  });

  /// URL / file path / app-specific identifier for the image.
  final String source;

  /// Natural width of the source image in pixels. Used to preserve aspect
  /// ratio at insertion time. Zero means unknown.
  final double naturalWidth;

  /// Natural height of the source image in pixels.
  final double naturalHeight;
}

/// Host-supplied adapter that presents a system picker (gallery, camera,
/// drag-and-drop, etc.) and returns the chosen image.
///
/// open-board never depends on `image_picker`, `file_picker`, or any platform
/// channel directly — the host application provides the implementation and
/// wires platform-specific dependencies on its own side.
abstract class ImagePickerAdapter {
  /// Present the host picker and resolve to the chosen image, or `null` if the
  /// user cancelled.
  Future<PickedImage?> pickImage();
}
