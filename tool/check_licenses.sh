#!/usr/bin/env bash
# ADR-005 라이선스 고지 검증 — 이식 코드의 attribution 누락을 CI에서 차단한다.
#
# 검증 불변식:
#  1) 루트 THIRD_PARTY_LICENSES 존재 + epub_pro/MIT 고지 포함
#  2) 이식된 CFI 프리미티브(cfi/core, cfi/dom)의 모든 .dart 파일이
#     attribution 헤더("Ported from epub_pro" + THIRD_PARTY_LICENSES 참조)를 보유
#     (자작 어댑터 epub_cfi_mapper.dart는 이식물이 아니므로 제외)
#
# 실행: bash tool/check_licenses.sh   (repo root 기준)
set -uo pipefail

LICENSE_FILE="THIRD_PARTY_LICENSES"
PORTED_DIRS=(
  "packages/open_epub_engine/lib/src/cfi/core"
  "packages/open_epub_engine/lib/src/cfi/dom"
)

errors=()

# 1) 고지 파일 존재 + 필수 문구
if [[ ! -f "$LICENSE_FILE" ]]; then
  errors+=("${LICENSE_FILE} 파일이 repo root에 없습니다.")
else
  for needle in "epub_pro" "MIT License"; do
    if ! grep -qF "$needle" "$LICENSE_FILE"; then
      errors+=("${LICENSE_FILE}에 \"${needle}\" 고지가 없습니다.")
    fi
  done
fi

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

# 결과
if [[ ${#errors[@]} -eq 0 ]]; then
  echo "✓ license-check 통과 — 이식 코드 ${checked}개 attribution + THIRD_PARTY_LICENSES 고지 정상."
  exit 0
fi

echo "✗ license-check 실패 (ADR-005):" >&2
for e in "${errors[@]}"; do
  echo "  - $e" >&2
done
exit 1
