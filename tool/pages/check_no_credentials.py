#!/usr/bin/env python3
"""Pages 산출물에 자격 증명이 섞이지 않았는지 본다 (S-16).

    python3 tool/pages/check_no_credentials.py _site

공개 사이트로 나가는 파일 전부(텍스트)를 훑어 GitHub 토큰 모양 · `x-access-token:` ·
`사용자:비밀@github.com` 꼴의 URL 을 찾는다. 하나라도 있으면 위치를 가린 채 출력하고
1 로 끝낸다 — 업로드 전에 멈춘다. 찾은 값은 절대 그대로 찍지 않는다(로그도 공개된다).

레퍼런스: coco-de/clinic-emr `tool/pages/check_no_credentials.py`.
"""

import re
import sys
from pathlib import Path

# 바이너리(이미지 · 글꼴 · wasm)는 건너뛴다. 확장자가 없는 파일도 텍스트로 읽어 본다.
_BINARY = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".otf", ".ttf", ".woff", ".woff2",
    ".wasm", ".bin", ".symbols", ".zip", ".gz", ".br", ".pdf", ".epub",
}

_PATTERNS = (
    ("GitHub fine-grained PAT", re.compile(r"github_pat_[A-Za-z0-9_]{20,}")),
    ("GitHub 토큰(ghp_ · gho_ · ghu_ · ghs_ · ghr_)", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}")),
    ("x-access-token 자격 증명", re.compile(r"x-access-token:", re.I)),
    # 반복 길이를 묶어 둔다 — 묶지 않은 레퍼런스 식은 한 줄이 수만 자인 main.dart.js 에서
    # 되추적으로 파일당 ~20초가 걸린다(같은 입력 13건에 결과 동일, ~100배 빠름).
    ("URL 에 박힌 자격 증명", re.compile(
        r"[a-z][a-z0-9+.-]{0,30}://[^/\s\"'<>@]{1,512}@(?:[\w-]+\.)*github(?:usercontent)?\.com",
        re.I,
    )),
)


def _mask(text: str) -> str:
    return text[:6] + "***" if len(text) > 6 else "***"


def main() -> int:
    if len(sys.argv) != 2:
        print("사용법: check_no_credentials.py <산출 디렉터리>", file=sys.stderr)
        return 2
    root = Path(sys.argv[1])
    if not root.is_dir():
        print(f"❌ 산출 디렉터리가 없다: {root}", file=sys.stderr)
        return 2

    findings = []
    scanned = 0
    for path in sorted(p for p in root.rglob("*") if p.is_file()):
        if path.suffix.lower() in _BINARY:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        scanned += 1
        for no, line in enumerate(text.splitlines(), 1):
            for label, pattern in _PATTERNS:
                for match in pattern.finditer(line):
                    rel = path.relative_to(root)
                    findings.append(f"{rel}:{no}:{match.start() + 1}: {label} — {_mask(match.group(0))}")

    if findings:
        print("❌ Pages 산출물에 자격 증명이 있다 — 배포하지 않는다:", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        print(
            "  산출물에 저장소 주소가 필요하면 GITHUB_REPOSITORY 로만 만든다"
            "(`git remote get-url` 금지 — insteadOf 의 토큰이 풀린다).",
            file=sys.stderr,
        )
        return 1
    if scanned == 0:
        print(f"❌ 검사할 텍스트 파일이 없다: {root}", file=sys.stderr)
        return 2
    print(f"✅ 자격 증명 없음 — 텍스트 파일 {scanned}개")
    return 0


if __name__ == "__main__":
    sys.exit(main())
