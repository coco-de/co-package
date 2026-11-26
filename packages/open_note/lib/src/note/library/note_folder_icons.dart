/// The folder icons the package can draw (see `NoteFolderIconView`).
///
/// The keys are persisted in `NoteFolder.iconKey`; they never change meaning.
abstract final class NoteFolderIcons {
  /// A plain folder, the default.
  static const String folder = 'folder';

  /// A five-pointed star.
  static const String star = 'star';

  /// A heart.
  static const String heart = 'heart';

  /// An open book.
  static const String book = 'book';

  /// A bookmark ribbon.
  static const String bookmark = 'bookmark';

  /// A briefcase.
  static const String briefcase = 'briefcase';

  /// A graduation cap.
  static const String school = 'school';

  /// A house.
  static const String home = 'home';

  /// A flag.
  static const String flag = 'flag';

  /// A light bulb.
  static const String lightbulb = 'lightbulb';

  /// A pair of music notes.
  static const String music = 'music';

  /// Angle brackets and a slash.
  static const String code = 'code';

  /// A laboratory flask.
  static const String flask = 'flask';

  /// A camera.
  static const String camera = 'camera';

  /// A calendar.
  static const String calendar = 'calendar';

  /// Every key, in the order a picker should show them.
  static const List<String> keys = [
    folder,
    star,
    heart,
    book,
    bookmark,
    briefcase,
    school,
    home,
    flag,
    lightbulb,
    music,
    code,
    flask,
    camera,
    calendar,
  ];

  /// Whether [key] is one of [keys].
  static bool contains(String key) => keys.contains(key);
}
