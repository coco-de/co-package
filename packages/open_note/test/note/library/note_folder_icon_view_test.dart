import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/library/library.dart';

import '../support/note_test_host.dart';

void main() {
  testWidgets('every icon builds at the requested size', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        Center(
          child: Wrap(
            children: [
              for (final key in [...NoteFolderIcons.keys, 'unknown'])
                NoteFolderIconView(iconKey: key, size: 32),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final element in find.byType(NoteFolderIconView).evaluate()) {
      expect(element.size, const Size(32, 32));
    }
  });

  testWidgets('defaults to 20 pixels and follows rebuilds', (tester) async {
    await tester.pumpWidget(
      noteTestHost(const Center(child: NoteFolderIconView(iconKey: 'star'))),
    );
    expect(tester.getSize(find.byType(NoteFolderIconView)), const Size(20, 20));

    await tester.pumpWidget(
      noteTestHost(
        const Center(
          child: NoteFolderIconView(iconKey: 'heart', color: Color(0xFFFF0000)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('has a semantic label when given one', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      noteTestHost(
        const Center(
          child: NoteFolderIconView(
            iconKey: 'school',
            semanticLabel: 'School folder',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('School folder'), findsOneWidget);
    handle.dispose();
  });
}
