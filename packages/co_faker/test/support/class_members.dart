/// A member that a class declares: a method, a getter, or a field.
typedef ClassMember = ({String name, bool isStatic, bool isField});

/// Reads the members that the class [className] declares in the Dart
/// [source], without the constructors and the setters.
///
/// It is a small reader for the source of this package, which `dart format`
/// lays out: it understands comments, strings, nested brackets, and the
/// statements of a class body, and nothing else. A test uses it to find the
/// public members of a generator, or the fields of a data class, so that one
/// that is added later cannot go unnoticed.
List<ClassMember> classMembers(String source, String className) {
  final code = blankStringsAndComments(source);
  final header = RegExp('\\bclass\\s+$className\\b[^{]*\\{').firstMatch(code);
  if (header == null) {
    throw ArgumentError.value(className, 'className', 'no such class');
  }
  var depth = 1;
  var end = header.end;
  while (end < code.length && depth > 0) {
    final char = code[end];
    if (char == '{') depth++;
    if (char == '}') depth--;
    end++;
  }
  final body = code.substring(header.end, end - 1);
  final members = <ClassMember>[];
  for (final statement in classStatements(body)) {
    final member = _member(statement, className);
    if (member != null) members.add(member);
  }
  return members;
}

/// [source] with its comments removed and the inside of its strings blanked,
/// so that brackets and semicolons in them cannot be mistaken for code.
String blankStringsAndComments(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final char = source[i];
    final next = i + 1 < source.length ? source[i + 1] : '';
    if (char == '/' && next == '/') {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
    } else if (char == '/' && next == '*') {
      i += 2;
      while (i + 1 < source.length &&
          !(source[i] == '*' && source[i + 1] == '/')) {
        out.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      i += 2;
    } else if (char == "'" || char == '"') {
      final raw = i > 0 && source[i - 1] == 'r';
      final end = _stringEnd(source, i, raw: raw);
      out.write('$char$char');
      for (var k = i; k < end; k++) {
        if (source[k] == '\n') out.write('\n');
      }
      i = end;
    } else {
      out.write(char);
      i++;
    }
  }
  return out.toString();
}

/// The index after the string literal that starts at [start].
int _stringEnd(String source, int start, {required bool raw}) {
  final quote = source[start];
  final triple =
      source.startsWith(quote * 3, start) && start + 2 < source.length;
  var i = start + (triple ? 3 : 1);
  while (i < source.length) {
    final char = source[i];
    if (!raw && char == r'\') {
      i += 2;
      continue;
    }
    if (!raw && char == r'$' && i + 1 < source.length && source[i + 1] == '{') {
      i = _interpolationEnd(source, i + 2);
      continue;
    }
    if (triple ? source.startsWith(quote * 3, i) : char == quote) {
      return i + (triple ? 3 : 1);
    }
    if (!triple && char == '\n') return i;
    i++;
  }
  return i;
}

/// The index after the `${...}` interpolation whose code starts at [start].
int _interpolationEnd(String source, int start) {
  var depth = 1;
  var i = start;
  while (i < source.length && depth > 0) {
    final char = source[i];
    if (char == "'" || char == '"') {
      i = _stringEnd(source, i, raw: false);
      continue;
    }
    if (char == '{') depth++;
    if (char == '}') depth--;
    i++;
  }
  return i;
}

/// The statements at the top level of a class [body].
Iterable<String> classStatements(String body) sync* {
  var depth = 0;
  var start = 0;
  var sawAssign = false;
  for (var i = 0; i < body.length; i++) {
    final char = body[i];
    if (char == '(' || char == '[' || char == '{') {
      depth++;
    } else if (char == ')' || char == ']' || char == '}') {
      depth--;
      // A block that closes a method or a getter ends the statement; the
      // block of a value (`= {...}`, `=> {...}`) is followed by a semicolon.
      if (depth == 0 && char == '}' && !sawAssign) {
        yield body.substring(start, i + 1);
        start = i + 1;
      }
    } else if (depth == 0 && char == ';') {
      yield body.substring(start, i + 1);
      start = i + 1;
      sawAssign = false;
    } else if (depth == 0 &&
        char == '=' &&
        (i + 1 >= body.length || body[i + 1] != '=') &&
        (i == 0 || !'=!<>'.contains(body[i - 1]))) {
      sawAssign = true;
    }
  }
}

ClassMember? _member(String statement, String className) {
  var text = statement.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Annotations: `@override`, `@Deprecated('...')`.
  while (text.startsWith('@')) {
    final match = RegExp(r'^@\w+(\.\w+)?(\s*\([^)]*\))?\s*').firstMatch(text);
    text = match == null ? text.substring(1) : text.substring(match.end);
  }
  if (text.isEmpty) return null;
  final isStatic = RegExp(r'^static\b').hasMatch(text);
  if (RegExp('^(const |factory )?$className\\b').hasMatch(text) ||
      RegExp(r'^(const )?factory\b').hasMatch(text) ||
      RegExp(r'\bset \w+\s*\(').hasMatch(text) ||
      RegExp(r'^operator\b').hasMatch(text)) {
    return null;
  }
  // A getter: `get name` before its `=>` or its block.
  final getter = RegExp(r'^.*?\bget (\w+)\s*(=>|\{)').firstMatch(text);
  if (getter != null) {
    return (name: getter.group(1)!, isStatic: isStatic, isField: false);
  }
  // A method: the name before the first parameter list that a body follows.
  final method = _methodName(text);
  if (method != null) {
    return (name: method, isStatic: isStatic, isField: false);
  }
  // A field: the last name before an initializer, or before the semicolon.
  final declaration = text.split(RegExp(r'\s=\s|;')).first.trim();
  final field = RegExp(r'(\w+)\s*$').firstMatch(declaration);
  if (field == null) return null;
  return (name: field.group(1)!, isStatic: isStatic, isField: true);
}

/// The name of a method declared by [text], or `null`.
///
/// Every top-level parenthesis group is looked at; the one that is followed
/// by a body (`{`, `=>`, `async`, or `;` of an abstract method) is the
/// parameter list, and the identifier before it is the name. A record type
/// (`({String a}) name()`) is a group that an identifier follows instead.
String? _methodName(String text) {
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == '(') {
      final close = _closing(text, i);
      final after = text.substring(close + 1).trimLeft();
      final before = text.substring(0, i).trimRight();
      final name = RegExp(r'(\w+)(<[^()]*>)?$').firstMatch(before);
      final bodyFollows =
          after.startsWith('{') ||
          after.startsWith('=>') ||
          after.startsWith('async') ||
          after == ';' ||
          after.isEmpty;
      // A `=` before the group makes it the call of an initializer.
      if (name != null && bodyFollows && !before.contains('=')) {
        return name.group(1);
      }
      i = close;
    }
  }
  return null;
}

int _closing(String text, int open) {
  var depth = 0;
  for (var i = open; i < text.length; i++) {
    if (text[i] == '(') depth++;
    if (text[i] == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return text.length - 1;
}
