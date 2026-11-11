#!/usr/bin/env bash
# ADR-005 라이선스 고지 검증 — 이식 코드의 attribution 누락을 CI에서 차단한다.
#
# 검증 불변식:
#  1) 루트 THIRD_PARTY_LICENSES 존재 + epub_pro/MIT 고지 포함
#  2) 이식된 CFI 프리미티브(cfi/core, cfi/dom)의 모든 .dart 파일이
#     attribution 헤더("Ported from epub_pro" + THIRD_PARTY_LICENSES 참조)를 보유
#     (자작 어댑터 epub_cfi_mapper.dart는 이식물이 아니므로 제외)
#  3) [발행 경계 — ADR-002-a] 이식 코드를 담아 pub.dev에 발행되는 open_epub_engine
#     패키지 디렉터리가 자체 LICENSE + THIRD_PARTY_LICENSES(epub_pro/MIT 포함)를 보유.
#     `dart pub publish`는 패키지 디렉터리 하위 파일만 tarball에 담으므로, 루트 고지만
#     있으면 발행 아티팩트에서 이식 코드 고지가 누락된다(MIT permission-notice 위반 소지).
#  4) co_storage(dox_storage 포크, MIT): 루트와 패키지의 THIRD_PARTY_LICENSES가 dox_storage
#     고지(+MIT 본문)를 담고, 패키지가 자체 LICENSE를 가지며, 포크한 lib/src 의 모든 .dart
#     파일(자작인 uploads/ 제외)이 attribution 헤더("dox_storage" + THIRD_PARTY_LICENSES)를
#     보유. 이 확인이 없으면 새 이식물이 이 가드를 조용히 통과한다.
#
# 실행: bash tool/check_licenses.sh   (repo root 기준)
set -uo pipefail

LICENSE_FILE="THIRD_PARTY_LICENSES"
# 이식 코드를 담아 발행되는 패키지 — 발행 경계에서 고지를 자체 보유해야 한다.
ENGINE_PKG="packages/open_epub_engine"
PORTED_DIRS=(
  "packages/open_epub_engine/lib/src/cfi/core"
  "packages/open_epub_engine/lib/src/cfi/dom"
)

errors=()

# 고지 파일 존재 + 필수 문구(epub_pro / MIT License) 검사 헬퍼.
check_notice_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    errors+=("${file} 고지 파일이 없습니다.")
    return
  fi
  local needle
  for needle in "epub_pro" "MIT License"; do
    if ! grep -qF "$needle" "$file"; then
      errors+=("${file}에 \"${needle}\" 고지가 없습니다.")
    fi
  done
}

# 1) 루트 고지 파일
check_notice_file "$LICENSE_FILE"

# 3) 발행 경계 — 엔진 패키지 자체 LICENSE + THIRD_PARTY_LICENSES
if [[ ! -f "${ENGINE_PKG}/LICENSE" ]]; then
  errors+=("${ENGINE_PKG}/LICENSE 가 없습니다 — 발행 tarball에 라이선스가 실리지 않아 pub.dev 컴플라이언스/점수 블로커.")
fi
check_notice_file "${ENGINE_PKG}/THIRD_PARTY_LICENSES"

# 2) 이식 파일별 attribution 헤더(상단 20줄)
checked=0
for dir in "${PORTED_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    errors+=("이식 디렉터리 없음: ${dir}")
    continue
  fi
  while IFS= read -r f; do
    checked=$((checked + 1))
    header="$(head -20 "$f")"
    if ! grep -qF "epub_pro" <<<"$header" ||
      ! grep -qF "THIRD_PARTY_LICENSES" <<<"$header"; then
      errors+=("${f}: 이식 attribution 헤더 누락(epub_pro + THIRD_PARTY_LICENSES 참조 필요).")
    fi
  done < <(find "$dir" -name '*.dart' | sort)
done

if [[ $checked -eq 0 ]]; then
  errors+=("이식 파일을 하나도 찾지 못했습니다(디렉터리 구조 변경?).")
fi

# 4) co_storage — dox_storage 포크 (MIT)
STORAGE_PKG="packages/co_storage"
# 고지 파일에서 제목이 $2 로 시작하는 절의 본문. 다른 절(epub_pro 등)의 MIT 문구가 이 절의
# 누락을 가려 주지 못하도록 절 안에서만 찾는다(파일 전체에서 찾으면 통과해 버린다).
section_body() {
  awk -v title="$2" '
    state == 0 && index($0, title) == 1 { state = 1; next }
    state == 1 { if ($0 ~ /^-+$/) state = 2; next }
    state == 2 { if ($0 ~ /^-+$/) exit; print }
  ' "$1" 2>/dev/null
}
for notice in "$LICENSE_FILE" "${STORAGE_PKG}/THIRD_PARTY_LICENSES"; do
  body="$(section_body "$notice" "dox_storage")"
  if [[ -z "$body" ]]; then
    errors+=("${notice}에 dox_storage 절이 없습니다.")
    continue
  fi
  # 저작권 줄은 줄 전체로, 허가 문단은 줄 머리로 찾는다 — 같은 절의 설명 문장이 두 문구를
  # 인용하므로 부분 일치로는 본문이 지워져도 설명 문장이 대신 통과시킨다.
  if ! grep -qxF "Copyright 2022" <<<"$body"; then
    errors+=("${notice}의 dox_storage 절에 저작권 줄(\"Copyright 2022\")이 없습니다.")
  fi
  if ! grep -q '^Permission is hereby granted' <<<"$body"; then
    errors+=("${notice}의 dox_storage 절에 MIT 허가 문단(\"Permission is hereby granted…\")이 없습니다.")
  fi
done
if [[ ! -f "${STORAGE_PKG}/LICENSE" ]]; then
  errors+=("${STORAGE_PKG}/LICENSE 가 없습니다.")
fi
storage_checked=0
while IFS= read -r f; do
  storage_checked=$((storage_checked + 1))
  header="$(head -20 "$f")"
  if ! grep -qF "dox_storage" <<<"$header" ||
    ! grep -qF "THIRD_PARTY_LICENSES" <<<"$header"; then
    errors+=("${f}: 포크 attribution 헤더 누락(dox_storage + THIRD_PARTY_LICENSES 참조 필요).")
  fi
done < <(find "${STORAGE_PKG}/lib/src" -name '*.dart' -not -path '*/uploads/*' 2>/dev/null | sort)
if [[ $storage_checked -eq 0 ]]; then
  errors+=("co_storage 의 포크 파일을 하나도 찾지 못했습니다(디렉터리 구조 변경?).")
fi

# 결과
if [[ ${#errors[@]} -eq 0 ]]; then
  echo "✓ license-check 통과 — 이식 코드 ${checked}개 attribution + 루트/엔진패키지 THIRD_PARTY_LICENSES + 엔진 LICENSE 고지 정상; co_storage 포크 ${storage_checked}개 헤더 + 고지 + LICENSE 정상."
  exit 0
fi

echo "✗ license-check 실패 (ADR-005):" >&2
for e in "${errors[@]}"; do
  echo "  - $e" >&2
done
exit 1
