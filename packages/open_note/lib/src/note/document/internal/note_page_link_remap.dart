import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';

/// Points `pageid:` links at the copies when pages are copied under new ids.
/// Links to pages that are not in [pageIds] are left as they are.
abstract final class NotePageLinkRemap {
  /// [link] with its page id replaced, or [link] itself.
  static String link(String link, Map<String, String> pageIds) {
    if (!link.startsWith(NotePageIdLink.scheme)) return link;
    final id = pageIds[link.substring(NotePageIdLink.scheme.length)];

    return id == null ? link : NotePageIdLink(id).format();
  }

  /// [json] with every `pageid:` string replaced (a deep copy).
  static Object? json(Object? json, Map<String, String> pageIds) {
    if (json is String) return link(json, pageIds);
    if (json is Map) {
      return {
        for (final entry in json.entries)
          '${entry.key}': NotePageLinkRemap.json(entry.value, pageIds),
      };
    }
    if (json is List) {
      return [for (final item in json) NotePageLinkRemap.json(item, pageIds)];
    }

    return json;
  }

  /// [object] with its links remapped; the same instance when nothing changed.
  static NoteObject object(
    NoteObject object,
    Map<String, String> pageIds, {
    required NoteObjectRegistry registry,
  }) {
    final encoded = NoteJson.encode(object.toJson());
    if (!encoded.contains(NotePageIdLink.scheme)) return object;
    final remapped = NoteJson.encode(
      NoteJson.asMap(json(object.toJson(), pageIds))!,
    );
    if (remapped == encoded) return object;

    return registry.decode(NoteJson.decodeMap(remapped)) ?? object;
  }

  /// Remaps the link spans of the texts in [scribble], in place.
  static void scribble(Scribble scribble, Map<String, String> pageIds) {
    for (final text in scribble.textDrawables) {
      for (final span in text.linkSpans) {
        if (span.url.startsWith(NotePageIdLink.scheme)) {
          span.url = link(span.url, pageIds);
        }
      }
    }
  }
}
