// Domain Entity — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.4.

/// EPUB OPF의 <metadata> 추출 결과.
class EpubMetadata {
  const EpubMetadata({
    required this.title,
    required this.epubVersion,
    this.language,
    this.author,
    this.identifier,
    this.renditionLayout = 'reflowable',
    this.renditionSpread = 'auto',
  });

  final String title;
  final String epubVersion; // "2.0" | "3.0" | "3.3"
  final String? language;
  final String? author;
  final String? identifier;
  final String renditionLayout; // "reflowable" | "pre-paginated"
  final String renditionSpread; // "none" | "both" | "auto"
}
