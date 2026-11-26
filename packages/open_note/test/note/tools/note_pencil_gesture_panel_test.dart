import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/tools/tools.dart';

import '../support/note_test_host.dart';

void main() {
  testWidgets('chooses an action for each gesture', (tester) async {
    var map = const NotePencilGestureMap();
    await tester.pumpWidget(
      noteTestHost(
        StatefulBuilder(
          builder: (context, setState) => NotePencilGesturePanel(
            map: map,
            onChanged: (next) => setState(() => map = next),
          ),
        ),
      ),
    );

    bool selected(NotePencilGesture gesture, NotePencilAction action) => tester
        .getSemantics(
          find.byKey(NotePencilGesturePanel.optionKey(gesture, action)),
        )
        .flagsCollection
        .isSelected
        .toBoolOrNull()!;

    expect(selected(NotePencilGesture.doubleTap, map.doubleTap), isTrue);

    await tester.tap(
      find.byKey(
        NotePencilGesturePanel.optionKey(
          NotePencilGesture.squeeze,
          NotePencilAction.undo,
        ),
      ),
    );
    await tester.pump();

    expect(map.squeeze, NotePencilAction.undo);
    expect(map.doubleTap, NotePencilGestureMap.defaultDoubleTap);
    expect(selected(NotePencilGesture.squeeze, NotePencilAction.undo), isTrue);
    expect(find.text('Double tap'), findsOneWidget);
    expect(find.text('Squeeze'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
