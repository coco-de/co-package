import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/template/note_paper_kind.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// The user-visible texts of the paper widgets, in English by default.
@immutable
class NotePaperStrings {
  const NotePaperStrings({
    this.blank = 'Blank',
    this.lined = 'Lined',
    this.grid = 'Grid',
    this.dotted = 'Dotted',
    this.cornell = 'Cornell',
    this.music = 'Music',
    this.image = 'Image',
    this.lineSpacing = 'Line spacing',
    this.lineWidth = 'Line width',
    this.pointUnit = 'pt',
    this.empty = 'No templates',
  });

  /// Name of the blank kind.
  final String blank;

  /// Name of the lined kind.
  final String lined;

  /// Name of the grid kind.
  final String grid;

  /// Name of the dotted kind.
  final String dotted;

  /// Name of the Cornell kind.
  final String cornell;

  /// Name of the music kind.
  final String music;

  /// Name of the image kind.
  final String image;

  /// Label of the spacing slider.
  final String lineSpacing;

  /// Label of the line width slider.
  final String lineWidth;

  /// Unit written after lengths.
  final String pointUnit;

  /// Shown by the picker when there is no template.
  final String empty;

  /// The name of [kind].
  String kindName(NotePaperKind kind) => switch (kind) {
    NotePaperKind.blank => blank,
    NotePaperKind.lined => lined,
    NotePaperKind.grid => grid,
    NotePaperKind.dotted => dotted,
    NotePaperKind.cornell => cornell,
    NotePaperKind.music => music,
    NotePaperKind.image => image,
  };

  /// What to call [template]: the translated kind name while it has no name or
  /// still has the default English one, otherwise its own name.
  String templateName(NotePaperTemplate template) {
    final name = template.name;
    if (name.isEmpty || name == NotePaperTemplate.defaultName(template.kind)) {
      return kindName(template.kind);
    }

    return name;
  }

  /// A length such as `28 pt` or `0.6 pt`.
  String formatLength(double value) {
    final number = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

    return '$number $pointUnit';
  }
}
