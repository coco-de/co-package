import '../domain.dart';
import 'authored_roles.dart';

/// Authored fictional works and prose, shared by comics, audio and newsletters.
class CoContentDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoContentDomain();
  @override
  String get name => 'content';

  /// The roots of the genre, audio genre, and topic taxonomies: each parent
  /// role points at them and the matching `content.*Taxonomy` key names them.
  static const _genreRoots = 5;
  static const _audioGenreRoots = 2;
  static const _topicRoots = 5;
  @override
  Map<String, CoDomainRole> get roles => {
    'seriesTitle': textRole('content.seriesTitle'),
    'penName': textRole('content.penName'),
    'synopsisLine': textRole('content.synopsisLine'),
    'genreName': textRole('content.genreName'),
    'episodeTitle': textRole('content.episodeTitle'),
    'cutAltText': textRole('content.cutAltText'),
    'commentLine': textRole('content.commentLine'),
    'chapterParagraph': textRole('content.chapterParagraph'),
    'publisherName': textRole('content.publisherName'),
    'narratorName': firstNameRole(),
    'audioTitle': textRole('content.audioTitle'),
    'newsletterName': textRole('content.newsletterName'),
    'articleHeadline': textRole('content.articleHeadline'),
    'topicName': textRole('content.topicName'),
    'genreParent': parentRole(_genreRoots),
    'audioGenreParent': parentRole(_audioGenreRoots),
    'topicParent': parentRole(_topicRoots),
    'genreTaxonomy': taxonomyRole('content.genreTaxonomy', roots: _genreRoots),
    'audioTaxonomy': taxonomyRole(
      'content.audioTaxonomy',
      roots: _audioGenreRoots,
    ),
    'topicTaxonomy': taxonomyRole('content.topicTaxonomy', roots: _topicRoots),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'series': {
      'id': 'int',
      'title': 'String',
      'authorName': 'String',
      'synopsis': 'String',
      'genre': 'String',
    },
    'episode': {
      'id': 'int',
      'seriesId': 'int',
      'title': 'String',
      'status': 'String',
    },
    'audiobook': {'id': 'int', 'title': 'String', 'narratorName': 'String'},
    'letter_article': {
      'id': 'int',
      'authorId': 'int',
      'title': 'String',
      'body': 'String',
    },
    'series_genre': {'id': 'int', 'name': 'String', 'parentId': 'int'},
    'audio_genre': {'id': 'int', 'name': 'String', 'parentId': 'int'},
    'letter_topic': {'id': 'int', 'name': 'String', 'parentId': 'int'},
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'series': {
      'title': 'seriesTitle',
      'authorName': 'penName',
      'synopsis': 'synopsisLine',
      'genre': 'genreName',
    },
    'episode': {'title': 'episodeTitle'},
    'audiobook': {'title': 'audioTitle', 'narratorName': 'narratorName'},
    'letter_article': {'title': 'articleHeadline', 'body': 'chapterParagraph'},
    'series_genre': {'name': 'genreTaxonomy', 'parentId': 'genreParent'},
    'audio_genre': {'name': 'audioTaxonomy', 'parentId': 'audioGenreParent'},
    'letter_topic': {'name': 'topicTaxonomy', 'parentId': 'topicParent'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'episode': {
      'status': ['draft', 'in_review', 'published', 'archived'],
    },
  };
}
