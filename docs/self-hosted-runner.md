# Self-hosted Runner 세팅 가이드

GitHub Actions 잡을 내 컴퓨터에서 직접 돌리기 위한 등록 가이드입니다. `gh` CLI로 등록 토큰을 발급하고, 러너 에이전트를 붙이는 순서까지 그대로 따라오면 됩니다.

> macOS · Apple Silicon 기준 / org: coco-de / **private repo 전용**

세팅이 끝나면 러너 터미널이 아래처럼 잡을 대기하는 상태가 됩니다.

```
√ Connected to GitHub
2026-07-15 Runner cody-macbook-local registered
Labels: self-hosted, macos, flutter

● Listening for Jobs
```

> **자동화** — 아래 1~4단계는 [`../scripts/register-runner.sh`](../scripts/register-runner.sh) 한 번 실행으로 끝낼 수 있습니다. 이 문서는 스크립트가 하는 일의 수동 절차입니다.

## 사전 준비

Self-hosted 러너에는 아무 도구도 깔려있지 않습니다. 워크플로우가 쓰는 빌드 환경이 로컬에 미리 세팅돼 있어야 잡이 통과합니다.

- **gh CLI** — 설치 후 `gh auth login`으로 로그인. 등록 토큰 발급에 필요합니다.
- **권한 스코프** — repo 러너는 `repo`, org 러너는 `admin:org` 스코프가 있어야 합니다.
- **Dart 스택** — Flutter SDK · Melos · (iOS 빌드 시) Xcode + CocoaPods.
- **Serverpod 테스트** — 서버 테스트를 돌린다면 Postgres · Redis 로컬 구동 준비.

## 등록 절차

아래 명령에서 `{repo}`는 대상 레포 이름으로, 러너 버전은 최신으로 바꿔서 실행하세요.

### 01 — 러너 폴더 만들고 에이전트 받기

홈 디렉토리에 러너 폴더를 만들고 **Apple Silicon용(arm64)** 에이전트를 내려받습니다. Intel 맥이면 `osx-x64`로 받으세요.

```bash
mkdir ~/actions-runner && cd ~/actions-runner
curl -o actions-runner.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.xxx.x/actions-runner-osx-arm64-2.xxx.x.tar.gz
tar xzf actions-runner.tar.gz
```

최신 버전은 [actions/runner releases](https://github.com/actions/runner/releases)에서 확인하세요.

### 02 — 등록 토큰 발급

`gh`로 등록 토큰용 REST API를 바로 호출합니다. 이 토큰은 **1시간 동안만** 유효합니다.

```bash
# repo 레벨
gh api -X POST \
  repos/coco-de/{repo}/actions/runners/registration-token --jq .token

# org 레벨 (여러 레포 공용)
gh api -X POST \
  orgs/coco-de/actions/runners/registration-token --jq .token
```

### 03 — 러너 구성

`config.sh`에 발급받은 토큰을 넘겨 구성합니다. **라벨**은 워크플로우의 `runs-on`과 매칭되는 값이니 용도에 맞게 지정하세요.

```bash
# 02의 토큰을 변수로 받아 바로 사용
TOKEN=$(gh api -X POST repos/coco-de/{repo}/actions/runners/registration-token --jq .token)
./config.sh \
  --url https://github.com/coco-de/{repo} \
  --token "$TOKEN" \
  --name "$(hostname)-local" \
  --labels self-hosted,macos,flutter \
  --unattended
```

### 04 — 실행하기

두 가지 방식이 있습니다. 처음엔 **포그라운드**로 붙는지 확인하고, 잘 되면 **서비스**로 전환하세요.

```bash
# 테스트용 — 터미널 세션 동안만
./run.sh   # 터미널 닫으면 러너도 종료
```

```bash
# 실사용 — launchd 서비스 (재부팅 후 자동 실행)
./svc.sh install
./svc.sh start
./svc.sh status   # 중지는 ./svc.sh stop
```

### 05 — 워크플로우에서 사용

구성 때 넣은 라벨을 `runs-on`에 적으면 해당 러너로 잡이 배정됩니다.

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    runs-on: [self-hosted, macos, flutter]
    steps:
      - uses: actions/checkout@v4
      - run: melos bootstrap
      - run: melos run test
```

## 공유 전에 알아둘 것

- **보안** — 퍼블릭 레포에는 붙이지 마세요. 외부 기여자의 PR이 러너에서 임의 코드를 실행할 수 있습니다. coco-de의 private 레포에서만 사용하세요.
- **디스크** — `_work` 폴더가 계속 쌓입니다. 체크아웃·빌드 산출물이 누적되니 주기적으로 정리하거나 잡 종료 시 클린업 스텝을 넣으세요. (→ [`../scripts/cleanup-work.sh`](../scripts/cleanup-work.sh))
- **가용성** — 켜져 있을 때만 잡을 받습니다. 노트북은 절전/종료 시 잡이 대기에 걸립니다. 상시 구동할 맥미니 같은 전용기가 있으면 훨씬 안정적입니다.
- **환경** — 빌드 도구는 각자 로컬에 설치돼 있어야 합니다. 팀원마다 Flutter·Xcode 버전이 다르면 결과가 달라질 수 있으니, 라벨로 환경을 구분하는 걸 권장합니다.

## 러너 해제

머신을 러너에서 빼거나 다시 등록할 때는 제거 토큰으로 깔끔하게 해제합니다.

```bash
RM=$(gh api -X POST repos/coco-de/{repo}/actions/runners/remove-token --jq .token)
./config.sh remove --token "$RM"
```

서비스로 돌리고 있었다면 먼저 `./svc.sh stop && ./svc.sh uninstall` 후 해제하세요. (→ [`../scripts/remove-runner.sh`](../scripts/remove-runner.sh))
