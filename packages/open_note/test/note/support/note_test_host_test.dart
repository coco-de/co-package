import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'note_test_host.dart';

void main() {
  testWidgets('noteTestHost provides an Overlay, MediaQuery and direction', (
    tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      noteTestHost(
        Builder(
          builder: (context) {
            captured = context;

            return const Text('hi');
          },
        ),
      ),
    );

    expect(find.text('hi'), findsOneWidget);
    expect(Overlay.maybeOf(captured), isNotNull);
    expect(MediaQuery.maybeOf(captured), isNotNull);
    expect(Directionality.of(captured), TextDirection.ltr);
    expect(MediaQuery.sizeOf(captured), const Size(800, 600));
  });
}
