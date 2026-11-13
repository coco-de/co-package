#!/usr/bin/env bash
#
# seed-runner-tools.sh — 새 러너의 도구 캐시(_work/_tool)를 같은 맥의 기존 러너에서 '복제'해 시작
#
# 사용법:
#   ./seed-runner-tools.sh --from ~/actions/<기존 러너> --to ~/actions/<새 러너>
#   ./seed-runner-tools.sh --from <기존> --to <새> --dry-run     # 무엇을 가져올지만 출력
#
# 보통은 직접 부르지 않고 등록 스크립트의 옵션으로 씁니다:
#   ./register-runner.sh --org coco-de --seed-from ~/actions/<기존 러너> --service
#
# 왜 필요한가:
#   러너는 서로의 캐시를 덮어쓰지 않도록 도구 캐시(Flutter SDK · Dart · Node · JDK 등)를 러너마다 따로 둡니다.
#   새 러너를 하나 등록하면 첫 잡들이 SDK 를 처음부터 받고(Flutter 는 5~25분, 느린 날은 시간 제한 초과),
#   그 사본이 러너 수만큼 디스크에 쌓입니다(Flutter SDK 한 벌이 ~4GB). 이 스크립트는 기존 러너의 도구 폴더를
#   APFS 복제(clonefile)로 가져옵니다 — 새 러너는 처음부터 SDK 가 있는 채로 시작하고, 디스크는 한 벌 크기
#   그대로입니다(복제본은 원본과 블록을 나눠 쓰다가 한쪽이 바뀐 부분만 따로 둡니다).
#
# 가져오는 것 / 안 가져오는 것:
#   · 이식해도 안전한 도구 폴더만 가져옵니다: flutter · dart · node · Java_* · uv · dcm
#     (기본값. SEED_TOOLS="이름1 이름2*" 로 바꿀 수 있음). Python 처럼 스크립트에 설치 경로가 박히는 도구는
#     기본에서 뺐습니다 — 원본 러너의 경로를 가리키는 채로 복제되면 그 러너를 지울 때 같이 깨집니다.
#   · 이름 끝이 '-<원본 러너 이름>' 인 폴더(flutter-<러너> · pub-cache-<러너>)는 원본 러너 이름으로 만들어진
#     것이라 새 러너가 쓰지 않으므로 가져오지 않습니다.
#   · 새 러너에 이미 있는 항목은 덮어쓰지 않고 건너뜁니다(멱등). _work/<저장소> 체크아웃은 절대 가져오지 않습니다.
#
# 안전:
#   · macOS(APFS) 에서만 동작하고, 두 러너 폴더가 같은 APFS 볼륨에 있을 때만 복제합니다. 복제가 안 되는 환경
#     에서 일반 복사로 바꾸면 디스크를 수십 GB 더 쓰므로, 그럴 땐 아무것도 하지 않고 이유를 알려 줍니다(종료코드 0).
#   · 원본 러너의 파일은 읽기만 합니다. 원본이 잡을 돌리는 중이어도 안전합니다 — 설치 중이던 도구는 완료
#     표시(.complete)가 없어 새 러너가 처음부터 다시 받습니다.
#
set -euo pipefail

FROM="" TO="" DRY=false
# 패턴은 배열로 읽는다 — 따옴표 없는 $TOOLS 를 그대로 돌리면 Java_* 가 현재 폴더의 파일 이름으로 풀릴 수 있다
IFS=' ' read -r -a TOOL_PATTERNS <<< "${SEED_TOOLS:-flutter dart node Java_* uv dcm}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)    FROM="$2"; shift 2 ;;
    --to)      TO="$2"; shift 2 ;;
    --dry-run) DRY=true; shift ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$FROM" || -z "$TO" ]]; then
  echo "usage: $0 --from <기존 러너 폴더> --to <새 러너 폴더> [--dry-run]" >&2
  exit 1
fi

# 경로를 정규화한다 (끝의 / 제거, 심볼릭 링크 해석)
FROM="$(cd "$FROM" 2>/dev/null && pwd -P)" || { echo "error: 기존 러너 폴더가 없습니다: $FROM" >&2; exit 1; }
mkdir -p "$TO"
TO="$(cd "$TO" && pwd -P)"

[[ "$FROM" != "$TO" ]] || { echo "error: --from 과 --to 가 같은 폴더입니다" >&2; exit 1; }
[[ -d "$FROM/_work/_tool" ]] || { echo "==> 기존 러너에 _work/_tool 이 없어 가져올 것이 없습니다 ($FROM)"; exit 0; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "==> APFS 복제는 macOS 에만 있어 도구 캐시 시드를 건너뜁니다 (러너는 빈 캐시로 시작합니다)"
  exit 0
fi

# 같은 볼륨 + APFS 인지 — 아니면 clonefile 이 실패하고 cp 가 일반 복사로 바뀌어 디스크를 크게 쓴다
fs_type() { mount | awk -v dev="$(df -P "$1" | awk 'NR==2{print $1}')" '$1 == dev {gsub(/[(,]/, "", $4); print $4; exit}'; }
if [[ "$(stat -f %d "$FROM")" != "$(stat -f %d "$TO")" ]]; then
  echo "==> 두 러너 폴더가 서로 다른 볼륨에 있어 복제할 수 없습니다 — 도구 캐시 시드를 건너뜁니다 (실제 복사는 디스크를 크게 써서 하지 않습니다)"
  exit 0
fi
if [[ "$(fs_type "$FROM")" != "apfs" ]]; then
  echo "==> APFS 볼륨이 아니라 복제할 수 없습니다 — 도구 캐시 시드를 건너뜁니다 (실제 복사는 디스크를 크게 써서 하지 않습니다)"
  exit 0
fi

SRC_TOOL="$FROM/_work/_tool"
DST_TOOL="$TO/_work/_tool"
SRC_NAME="$(basename "$FROM")"
seeded=0 skipped=0

for entry in "$SRC_TOOL"/*; do
  [[ -d "$entry" ]] || continue
  name="$(basename "$entry")"

  allowed=false
  for pat in "${TOOL_PATTERNS[@]}"; do
    # shellcheck disable=SC2254
    case "$name" in $pat) allowed=true; break ;; esac
  done
  $allowed || continue
  case "$name" in *-"$SRC_NAME") continue ;; esac            # 원본 러너 이름이 붙은 폴더는 가져오지 않는다

  if [[ -e "$DST_TOOL/$name" ]]; then
    echo "  · $name — 새 러너에 이미 있어 건너뜀"
    skipped=$((skipped + 1))
    continue
  fi
  if $DRY; then
    echo "  [dry] $name ($(du -sk "$entry" 2>/dev/null | awk '{printf "%.1f GB 논리", $1/1048576}'))"
    seeded=$((seeded + 1))
    continue
  fi
  mkdir -p "$DST_TOOL"
  # -c: clonefile(2) — 블록을 새로 쓰지 않는다. 같은 APFS 볼륨임을 위에서 확인했다.
  if cp -cR "$entry" "$DST_TOOL/$name"; then
    echo "  ✓ $name 복제"
    seeded=$((seeded + 1))
  else
    echo "  ⚠ $name 복제 실패 — 일부만 만들어졌다면 지워 두고 넘어갑니다" >&2
    rm -rf "${DST_TOOL:?}/$name"
  fi
done

if $DRY; then
  echo "==> [dry] 가져올 도구 폴더 ${seeded}개 · 이미 있어 건너뜀 ${skipped}개 (실제로는 아무것도 바꾸지 않았습니다)"
else
  echo "==> 도구 캐시 시드 완료: ${seeded}개 복제 · ${skipped}개 건너뜀 (디스크 추가 사용 ≈ 0)"
fi
