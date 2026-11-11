#!/usr/bin/env python3
"""워크플로의 외부 `uses:` 참조가 커밋 SHA 로 고정돼 있는지 본다.

    python3 tool/check_action_pins.py [저장소 루트]

검사 1 — `.github/workflows/` 와 `.github/actions/` 의 YAML 에서 `owner/repo@ref` 꼴의 외부
참조(재사용 워크플로 `owner/repo/.github/workflows/x.yml@ref` 포함)를 모두 읽어, ref 가 40자리
커밋 SHA 가 아닌 것을 나열하고 1 로 끝낸다. 로컬 참조(`./…`)와 `@sha256:` 다이제스트로 고정한
`docker://` 이미지는 통과한다.

검사 2 — 호출자 안내(README · `packages/co_arc/templates/` · 워크플로 머리 주석)가 이 저장소의
재사용 워크플로를 `@main` · `@master` 같은 이동 ref 로 부르라고 안내하지 않는지 본다
(커밋 SHA · 태그 · `<자리표시자>` 는 통과).

새 액션을 쓸 때는 릴리스 태그가 가리키는 커밋을 확인해 `@<40자리 SHA> # vX.Y.Z` 로 적는다.
줄 끝 주석은 어느 릴리스인지 알려 주는 표지이고, Dependabot 이 SHA 와 함께 갱신한다.

    gh api repos/<owner>/<repo>/commits/<tag> --jq .sha

표준 라이브러리만 쓴다(러너에 PyYAML 이 없다) — YAML 을 파싱하지 않고 줄 단위로 읽는다.
종료 코드: 0 통과 · 1 위반 있음 · 2 검사할 파일이 없음.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

SCAN_DIRS = (".github/workflows", ".github/actions")
SUFFIXES = {".yml", ".yaml"}
# 검사 2 대상 — 호출 예시가 적힌 문서 · 템플릿. 워크플로 파일은 검사 1 의 목록을 그대로 쓴다.
GUIDE_GLOBS = (
    "README.md",
    "packages/co_arc/README.md",
    "packages/co_arc/templates/*.yml",
    "packages/co_arc/templates/*.yaml",
)

_SHA = re.compile(r"[0-9a-fA-F]{40}")
_DIGEST = re.compile(r"@sha256:[0-9a-fA-F]{64}$")
# 이 저장소의 재사용 워크플로를 브랜치 이동 ref 로 부르는 호출.
_MOVING_CALL = re.compile(
    r"coco-de/co-package/\.github/workflows/[A-Za-z0-9_.-]+\.ya?ml@(?:main|master)(?![A-Za-z0-9_.-])"
)
# `uses:` 키 줄 — `uses: …` 또는 `- uses: …`.
_USES = re.compile(r"^(?P<indent> *)(?:- +)?uses:(?P<rest>.*)$")
# 블록 스칼라 머리줄(`run: |` · `- run: >-` · `- |`). 그 본문은 YAML 이 아니라 셸 스크립트 같은
# 텍스트라서 안에 든 `uses: …` 를 참조로 읽지 않는다.
_BLOCK_HEADER = re.compile(
    r"^(?P<indent> *)(?P<seq>(?:- +)*)"
    r"(?P<key>(?:[^\s#'\"][^#]*?|\"[^\"]*\"|'[^']*') *: +)?"
    r"[|>][-+0-9]* *(?:#.*)?$"
)


def _value(rest: str) -> str:
    """`uses:` 뒤 나머지에서 값만 뽑는다 — 따옴표와 줄 끝 주석을 걷어 낸다."""
    rest = rest.strip()
    if rest[:1] in ("'", '"'):
        end = rest.find(rest[0], 1)
        return rest[1:end] if end != -1 else rest[1:]
    return re.split(r"\s+#", rest, maxsplit=1)[0].strip()


def _problem(value: str) -> str | None:
    """고정되지 않은 이유. 통과면 None."""
    if not value:
        return "`uses:` 값이 같은 줄에 없다"
    if value.startswith(("./", "../")):
        return None
    if value.startswith("docker://"):
        if _DIGEST.search(value):
            return None
        return "docker 이미지가 `@sha256:<다이제스트>` 로 고정되지 않았다"
    if "${{" in value:
        return "`uses:` 에는 표현식을 쓸 수 없다"
    _, at, ref = value.rpartition("@")
    if not at:
        return "`@<ref>` 가 없다"
    if not _SHA.fullmatch(ref):
        return f"`@{ref}` 는 40자리 커밋 SHA 가 아니다"
    return None


def scan(text: str) -> list[tuple[int, str]]:
    """(줄 번호, `uses:` 값) 목록 — 주석 줄과 블록 스칼라 본문은 건너뛴다."""
    found: list[tuple[int, str]] = []
    block_parent: int | None = None
    for number, raw in enumerate(text.split("\n"), start=1):
        line = raw.rstrip("\r")
        indent = len(line) - len(line.lstrip(" "))
        if block_parent is not None:
            if not line.strip() or indent > block_parent:
                continue
            block_parent = None
        if line.lstrip().startswith("#"):
            continue
        header = _BLOCK_HEADER.match(line)
        if header:
            column = len(header.group("indent")) + len(header.group("seq"))
            # `- |` 는 부모가 마지막 `-` 가 있는 열이다.
            block_parent = column if header.group("key") else column - 2
            continue
        match = _USES.match(line)
        if match:
            found.append((number, _value(match.group("rest"))))
    return found


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    workflows = sorted(
        path
        for scan_dir in SCAN_DIRS
        if (root / scan_dir).is_dir()
        for path in (root / scan_dir).rglob("*")
        if path.is_file() and path.suffix in SUFFIXES
    )
    if not workflows:
        print(f"❌ 검사할 워크플로 파일이 없다: {root}", file=sys.stderr)
        return 2

    external = 0
    pins: list[str] = []
    for path in workflows:
        rel = path.relative_to(root).as_posix()
        for number, value in scan(path.read_text(encoding="utf-8")):
            if not value.startswith(("./", "../")):
                external += 1
            reason = _problem(value)
            if reason:
                pins.append(f"  {rel}:{number}: {value or '(빈 값)'} — {reason}")

    guides = [*workflows, *(path for pattern in GUIDE_GLOBS for path in sorted(root.glob(pattern)))]
    moving: list[str] = []
    for path in guides:
        rel = path.relative_to(root).as_posix()
        for number, line in enumerate(path.read_text(encoding="utf-8").split("\n"), start=1):
            if _MOVING_CALL.search(line):
                moving.append(f"  {rel}:{number}: {line.strip()}")

    if pins:
        print(f"❌ 커밋 SHA 로 고정되지 않은 외부 uses: 참조 {len(pins)}건", file=sys.stderr)
        print("\n".join(pins), file=sys.stderr)
        print(
            "  → `uses: owner/repo@<40자리 SHA> # vX.Y.Z` 로 고정한다."
            " SHA 는 `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha` 로 확인한다.",
            file=sys.stderr,
        )
    if moving:
        print(f"❌ 재사용 워크플로를 이동 ref 로 부르라고 안내하는 곳 {len(moving)}건", file=sys.stderr)
        print("\n".join(moving), file=sys.stderr)
        print("  → `@main` 대신 태그 또는 `@<커밋 SHA>` 로 고정해 호출하도록 적는다.", file=sys.stderr)
    if pins or moving:
        return 1
    print(
        f"✅ 외부 uses: 참조 {external}건 모두 커밋 SHA 로 고정,"
        f" 호출 안내에 이동 ref 없음 — 파일 {len(workflows)}+{len(guides) - len(workflows)}개"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
