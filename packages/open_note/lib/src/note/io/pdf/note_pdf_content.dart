// Private to the PDF writer library: content streams being built and the
// resources they share.
part of 'note_pdf_writer.dart';

/// The operators of one content stream (a page, or a transparency group) and
/// the document resources it refers to, by resource index.
class _ContentStream {
  /// The operators, one per line.
  final StringBuffer operators = StringBuffer();

  /// Indices into [_Resources.graphicsStates].
  final Set<int> graphicsStates = <int>{};

  /// Indices into [_Resources.images].
  final Set<int> images = <int>{};

  /// Indices into [_Resources.groups].
  final Set<int> groups = <int>{};

  /// Appends one operator line.
  void add(String line) => operators.writeln(line);
}

/// A transparency group: [content] drawn in the coordinates of a page of
/// `width x height`.
class _Group {
  /// A group holding [content].
  const _Group(this.content, this.width, this.height);

  /// The group's operators and resources.
  final _ContentStream content;

  /// Page width, the group's bounding box.
  final double width;

  /// Page height, the group's bounding box.
  final double height;
}

/// A fill and stroke alpha pair (an `ExtGState`).
typedef _Alpha = ({double fill, double stroke});

/// Every shared object of the document: graphics states (deduplicated), images
/// (deduplicated by identity) and transparency groups.
class _Resources {
  /// Alpha pairs, in resource order.
  final List<_Alpha> graphicsStates = [];

  /// Embedded images, in resource order.
  final List<NotePdfImage> images = [];

  /// Transparency groups, in resource order.
  final List<_Group> groups = [];

  final Map<_Alpha, int> _stateIndex = {};
  final Map<NotePdfImage, int> _imageIndex = Map.identity();

  /// The index of the graphics state with [alpha].
  int graphicsState(_Alpha alpha) => _stateIndex.putIfAbsent(alpha, () {
    graphicsStates.add(alpha);

    return graphicsStates.length - 1;
  });

  /// The index of [image], embedding it once however often it is drawn.
  int image(NotePdfImage image) => _imageIndex.putIfAbsent(image, () {
    images.add(image);

    return images.length - 1;
  });

  /// Registers [group] and returns its index.
  int group(_Group group) {
    groups.add(group);

    return groups.length - 1;
  }
}
