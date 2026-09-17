#!/usr/bin/env bash
#
# 로컬에서 example 웹 데모를 빌드해 gh-pages 브랜치로 배포한다.
#
# 왜 로컬 배포인가:
#   - GitHub Actions 자동 배포(루트 .github/workflows/open-board-pages.yml)는
#     (1) 조직 Actions 예산 소진, (2) PRIVATE_REPO_PAT 만료 시 동작하지 않는다.
#   - 이 스크립트는 로컬 git 자격증명으로 private 의존성(coco-de/open-epub)을
#     받으므로 예산/시크릿과 무관하게 항상 배포할 수 있다.
#
# gh-pages 는 단일 커밋으로 강제 갱신하여 배포 산출물이 히스토리에 누적되지 않게 한다.
# Pages 소스 = gh-pages 브랜치(legacy). 배포 후 약 30초 내 라이브 반영.
#
# 사용법:  packages/open_board/tool/deploy_web.sh (저장소 어디서든 실행 가능)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

REMOTE_URL="https://github.com/coco-de/co-package.git"
BASE_HREF="/co-package/"
SITE_URL="https://coco-de.github.io/co-package/"

HEAD_SHA="$(git rev-parse --short HEAD)"
HEAD_MSG="$(git log -1 --format=%s)"

echo "▶ [1/3] 의존성 설치 (example)…"
( cd example && flutter pub get )

echo "▶ [2/3] 웹 빌드 (WebAssembly, 실패 시 JS 폴백)…"
(
  cd example
  flutter build web --wasm --release --base-href "$BASE_HREF" \
    || flutter build web --release --base-href "$BASE_HREF"
)

echo "▶ [3/3] gh-pages 배포 (단일 커밋 강제 갱신)…"
(
  cd example/build/web
  touch .nojekyll
  rm -rf .git
  git init -q
  git checkout -q -b gh-pages
  git add -A
  git commit -qm "deploy: ${HEAD_SHA} 최신 빌드 (${HEAD_MSG})"
  git push -f "$REMOTE_URL" gh-pages
)

echo "✓ 배포 완료 → ${SITE_URL}  (반영까지 약 30초)"
