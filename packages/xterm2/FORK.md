# Cocode의 MIT xterm2 포크

## 원천과 고지

- 원천: `leynier/xterm2@6775995f1e09d7b1e01f2a5a4ee87895b5905da8`.
- 라이선스: MIT, © 2020 xuty. 원천 `LICENSE`를 그대로 보존한다.
- 원 포크의 변경·회귀 목록: 함께 포함한 `ALERA_PATCHES.md`.
- 소비 경로: `coco-de/co-package`, `packages/xterm2`.
- 고정 태그: `xterm2-v5.3.0+cocode.1`.

## 데스크톱 IME 수정

Cocode #984의 클린룸 스파이크 패치
`scripts/spike/xterm2/desktop-ime-composition.patch`를 재사용한다.
AGPL xterm3의 구현·포크 파일은 읽거나 복사하지 않았다.

1. 입력 연결이 열린 macOS·Windows·Linux에서 인쇄 가능한 키를 입력기에 맡긴다.
2. 확정 직후 상태 초기화가 다음 음절 조합을 중단하지 않도록 다음 키까지 미룬다.
3. Enter가 조합을 종료하면 표시 중인 텍스트를 PTY 동작보다 먼저 전달한다.

모바일·웹 경로는 그대로 유지한다. 시험은 `test/src/ui/ime/`에 있으며,
데스크톱 입력기 대역의 결과를 실제 OS 입력기 측정으로 보고하지 않는다.

```sh
flutter pub get
flutter test test/src/ui/ime/
flutter test --exclude-tags platform-golden
```

Flutter 3.47.6 · macOS arm64에서 전체 시험은 912건 통과하고 원천 기준선과
같은 `htop golden test` 1건이 2픽셀 차이로 실패한다. 이 Mac 전용 골든의
원본을 갱신하거나 실패를 숨기지 않는다. `platform-golden` 태그로 제외하는
별도 시험 2건과 이 골든은 다르다. CI의 Linux에서는 원천의 플랫폼 조건에
따라 Mac 전용 골든이 실행되지 않는다.

Linux 컨테이너(Flutter 3.47.3)의 동일 회귀 명령은 911건 통과·Mac 전용
골든 2건 skip으로 종료 0이다. 변경된 입력 경로의 포맷·분석도 통과했다.

공개 설치 파일은 소비 앱의 OSS 보고서에서 AGPL이 제거되고, 터미널·앱 회귀와
Mac 서명·공증·Gatekeeper·실행 검증이 통과한 빌드만 게시한다.
