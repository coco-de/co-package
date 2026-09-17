import 'dart:io';
import 'dart:math';

/// 이름 미지정 등록 시 붙일 영어 공룡 이름 풀. 전부 소문자·파일시스템 안전.
const dinosaurNames = <String>[
  'raptor',
  'trex',
  'stego',
  'triceratops',
  'brachio',
  'ankylo',
  'velociraptor',
  'diplodocus',
  'allosaurus',
  'spinosaurus',
  'pterodactyl',
  'brontosaurus',
  'compsognathus',
  'gallimimus',
  'iguanodon',
  'megalosaurus',
  'ornithomimus',
  'parasaurolophus',
  'protoceratops',
  'utahraptor',
  'carnotaurus',
  'dilophosaurus',
  'giganotosaurus',
  'maiasaura',
  'pachycephalosaurus',
  'plateosaurus',
  'therizinosaurus',
  'troodon',
  'archaeopteryx',
  'baryonyx',
  'coelophysis',
  'deinonychus',
  'edmontosaurus',
  'kentrosaurus',
  'ceratosaurus',
  'oviraptor',
  'styracosaurus',
  'apatosaurus',
  'nodosaurus',
  'gorgosaurus',
];

/// 이 머신의 컴퓨터 이름을 러너/디렉토리 이름에 쓸 수 있게 정규화한다.
/// 소문자화 · 끝의 `.local` 제거 · 영문/숫자 외 문자는 `-`로 치환.
String hostSlug([String? raw]) {
  var h = (raw ?? Platform.localHostname).trim().toLowerCase();
  if (h.endsWith('.local')) h = h.substring(0, h.length - '.local'.length);
  h = h
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-+)|(-+$)'), '');
  return h.isEmpty ? 'runner' : h;
}

/// `{호스트}-{랜덤 공룡}` 형식으로 [taken]에 없는 유일한 러너 이름을 만든다.
///
/// 공룡 풀을 섞어 [taken](기존 GitHub 러너 이름 등)과 겹치지 않는 첫 후보를
/// 고른다. 모든 공룡이 이미 쓰였으면 `-2`, `-3` … 접미사를 붙여 유일화한다.
/// [rng]를 주입하면 결정적으로 테스트할 수 있다.
String generateRunnerName(String host, Set<String> taken, {Random? rng}) {
  final r = rng ?? Random();
  final pool = [...dinosaurNames]..shuffle(r);
  for (final d in pool) {
    final name = '$host-$d';
    if (!taken.contains(name)) return name;
  }
  final base = '$host-${pool.first}';
  var n = 2;
  while (taken.contains('$base-$n')) {
    n++;
  }
  return '$base-$n';
}
