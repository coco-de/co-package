import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

export 'hand_drawn_shape_factories.dart';
export 'protobuf_factories.dart';

/// 테스트에서 ValueNotifier의 값 변경을 추적하는 헬퍼
class ValueChangeTracker<T> {
  final List<T> values = [];
  late final VoidCallback _listener;

  ValueChangeTracker(ValueNotifier<T> notifier) {
    _listener = () => values.add(notifier.value);
    notifier.addListener(_listener);
  }

  void dispose(ValueNotifier notifier) {
    notifier.removeListener(_listener);
  }

  int get changeCount => values.length;
  T get lastValue => values.last;
  bool get hasChanged => values.isNotEmpty;
}

/// Offset 비교 시 허용 오차를 포함하는 matcher
Matcher closeTo2D(double x, double y, {double delta = 0.01}) {
  return predicate<Offset>(
    (offset) => (offset.dx - x).abs() < delta && (offset.dy - y).abs() < delta,
    'is close to Offset($x, $y) within $delta',
  );
}

/// double 비교용 허용 오차 matcher (protobuf double 정밀도)
Matcher roughlyEquals(double expected, {double epsilon = 1e-6}) {
  return closeTo(expected, epsilon);
}
