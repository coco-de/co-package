// 🎯 Dart imports:
import 'dart:math' hide Point;

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

Point add(Point A, Point B) {
  return Point(x: A.x + B.x, y: A.y + B.y, p: B.p);
}

Point sub(Point A, Point B) {
  return Point(x: A.x - B.x, y: A.y - B.y, p: A.p);
}

Point mul(Point A, double s) {
  return Point(x: A.x * s, y: A.y * s, p: A.p);
}

Point div(Point A, double s) {
  return Point(x: A.x / s, y: A.y / s, p: A.p);
}

Point per(Point A) {
  return Point(x: A.y, y: -A.x, p: A.p);
}

Point uni(Point A) {
  return div(A, len(A));
}

/// 두 벡터 사이를 선형 보간합니다.
Point lerp(Point A, Point B, double t) {
  return add(A, mul(sub(B, A), t));
}

/// 두 벡터 사이의 평균을 반환
Point med(Point A, Point B) {
  return lerp(A, B, .5);
}

/// 정규화된 벡터들에 대해서 이들이 정확히 같은 방향을 가리킨다면 도트 연산은 1을 반환합니다
/// 그들이 완전히 반대 방향을 가리킬 경우 -1을 반환합니다
/// 그리고 다른 경우엔 그 사이에 해당하는 수를 반환합니다. (예를 들어, 벡터가 수직일 때 도트 연산은 0을 반환합니다.)
///
/// 임의의 길이를 가지는 벡터에 대해서 도트 반환값은 유사합니다: 벡터 사이의 각도가 감소할 때 그들은 더 커집니다.
Point prj(Point A, Point B, double d) {
  return add(A, mul(B, d));
}

Point rotAround(Point A, Point C, double r) {
  final s = sin(r);
  final c = cos(r);
  final px = A.x - C.x;
  final py = A.y - C.y;
  final nx = px * c - py * s;
  final ny = px * s + py * c;
  return Point(x: nx + C.x, y: ny + C.y);
}

bool isEqual(Point A, Point B) {
  return A.x == B.x && A.y == B.y;
}

double len(Point A) {
  return sqrt(len2(A));
}

double len2(Point A) {
  return A.x * A.x + A.y * A.y;
}

double dist2(Point A, Point B) {
  return len2(sub(A, B));
}

double dist(Point A, Point B) {
  return len(sub(A, B));
}

double dpr(Point A, Point B) {
  return A.x * B.x + A.y * B.y;
}
