# Self-hosted Runner 세팅 가이드

GitHub Actions 잡을 내 컴퓨터에서 직접 돌리기 위한 등록 가이드입니다. `gh` CLI로 등록 토큰을 발급하고, 러너 에이전트를 붙이는 순서까지 그대로 따라오면 됩니다.

> macOS · Apple Silicon 기준 / org: coco-de / **private repo 전용**

세팅이 끝나면 러너 터미널이 아래처럼 잡을 대기하는 상태가 됩니다.

```
√ Connected to GitHub
2026-07-15 Runner cody-macbook-local registered
Labels: self-hosted, macOS, ARM64, flutter

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
VER=2.xxx.x   # 최신 버전은 https://github.com/actions/runner/releases 에서 확인
PKG="actions-runner-osx-arm64-${VER}.tar.gz"
mkdir ~/actions-runner && cd ~/actions-runner
curl -o "$PKG" -L "https://github.com/actions/runner/releases/download/v${VER}/${PKG}"
# 공식 릴리스가 게시한 SHA-256 과 대조한 뒤에만 푼다 ("OK" 가 나와야 함)
SHA=$(gh api "repos/actions/runner/releases/tags/v${VER}" \
  --jq ".assets[] | select(.name == \"${PKG}\") | .digest" | sed 's/^sha256://')
echo "${SHA}  ${PKG}" | shasum -a 256 -c - && tar xzf "$PKG"
```

위 SHA-256은 릴리스 자산 메타데이터의 `digest` 이고, 릴리스 노트의 **SHA-256 Checksums** 표와 같은
값입니다(`digest` 가 비어 있는 오래된 릴리스는 릴리스 노트의 표 값을 직접 넣으세요). 값이 다르면
압축을 풀지 말고 파일을 지운 뒤 다시 받으세요. `register-runner.sh`는 같은 검증을 자동으로
수행합니다 — 값을 구하지 못하면 내려받지 않고, 다르면 폐기하고 중단합니다.

> ⚠️ **아키텍처 확인** — Apple Silicon 맥이라도 터미널 앱이 Rosetta로 떠 있으면
> `uname -m`이 `x86_64`를 반환해서 자기도 모르게 x64 러너를 받게 됩니다.
> 다운로드 후 `lipo -archs ./bin/Runner.Listener`로 실제 바이너리 아키텍처를
> 확인하세요. x64로 잘못 등록되면 실제로 동작은 하지만 (Rosetta 에뮬레이션)
> Dart/Flutter 컴파일 같은 CPU 위주 작업이 눈에 띄게 느려집니다.

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
  --labels self-hosted,macOS,flutter \
  --unattended
```

### 04 — 실행하기

두 가지 방식이 있습니다. 처음엔 **포그라운드**로 붙는지 확인하고, 잘 되면 **서비스**로 전환하세요.

```bash
# 테스트용 — 터미널 세션 동안만
./run.sh   # 터미널 닫으면 러너도 종료
```

```bash
# 실사용 — launchd 서비스
./register-runner.sh --org coco-de --dir ~/actions/{러너이름} --service
./svc.sh status   # 중지는 ./svc.sh stop
```

> 상시 서비스는 `svc.sh install`을 직접 부르지 말고 `register-runner.sh --service`를
> 쓰세요. `svc.sh`만 실행하면 **크래시 자동 복구(`KeepAlive`)가 빠지고**, 재부팅 자동
> 복귀 점검도 건너뜁니다 — 아래 [재부팅 후에도 백그라운드로 유지하기](#재부팅-후에도-백그라운드로-유지하기) 참고.
> TUI를 쓴다면 `s` 키가 같은 처리를 해줍니다.

### 05 — 워크플로우에서 사용

구성 때 넣은 라벨을 `runs-on`에 적으면 해당 러너로 잡이 배정됩니다.

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    runs-on: [self-hosted, macOS, flutter]
    steps:
      - uses: actions/checkout@v4
      - run: melos bootstrap
      - run: melos run test
```

## 재부팅 후에도 백그라운드로 유지하기

"서비스로 켜뒀는데 왜 러너가 오프라인이지?"는 대부분 아래 넷 중 하나입니다. **①②는
`register-runner.sh --service`(TUI는 `s` 키)가 자동으로 처리하고, ③④는 sudo와 머신
정책이 걸린 일이라 자동으로 바꾸지 않고 서비스를 켤 때 점검 결과만 알려줍니다.**

| | 조건 | 자동? | 안 되면 생기는 일 |
|---|---|---|---|
| ① | launchd 서비스로 등록돼 있다 | ✅ 자동 | 터미널을 닫으면 러너도 죽는다 |
| ② | 프로세스가 죽어도 되살아난다 (`KeepAlive`) | ✅ 자동 | 크래시 한 번에 다음 로그인까지 오프라인 |
| ③ | 재부팅 후 **로그인 세션**이 생긴다 | ⚠️ 안내만 | 아무도 로그인 안 하면 러너가 안 뜬다 |
| ④ | 머신이 잠들지 않는다 | ⚠️ 안내만 | 잠든 동안 잡이 배정되지 않고 대기 |

### ① launchd 서비스 = "부팅 시"가 아니라 "로그인 시" 자동 실행

`svc.sh install`은 `~/Library/LaunchAgents/actions.runner.<스코프>.<러너이름>.plist`를
만듭니다. 이건 **LaunchAgent**이고, launchd는 이걸 부팅 시점이 아니라 **GUI 로그인
시점**에 로드합니다. plist에 `RunAtLoad=true`가 있으니 로드되면 바로 뜨지만, 그
"로드"가 로그인에 묶여 있다는 게 핵심입니다 → ③으로 이어집니다.

설치 시점의 plist 경로는 `<러너디렉토리>/.service`에 기록돼 있습니다.

### ② 크래시 자동 복구 — `KeepAlive`

GitHub이 만드는 기본 plist에는 `KeepAlive`가 **없습니다**. 러너 프로세스가 비정상
종료되면 그대로 죽어 있습니다. `register-runner.sh --service`와 TUI `s` 키는 서비스를
켤 때(정확히는 `launchctl load` 직전) 이 키를 자동으로 심습니다.

```xml
<key>KeepAlive</key>
<dict>
  <key>SuccessfulExit</key>
  <false/>
</dict>
```

**왜 그냥 `<true/>`가 아닌가** — 러너의 `bin/RunnerService.js`는 listener 종료코드를
직접 해석해서 재시작 여부를 스스로 정합니다.

| 종료코드 | 러너의 판단 |
|---|---|
| 2 (retryable), 3·4 (자체 업데이트) | **자기가** 5초 뒤 재기동 |
| 0 (정상), 1 (terminated), 5 (Session Conflict) | 서비스를 내리고 **exit 0** |

`KeepAlive: true`를 걸면 러너가 "멈춰야 한다"고 판단한 상황 — 특히 같은 등록을 두
프로세스가 동시에 잡은 **세션 충돌** — 에서 launchd가 무한 재기동시켜 정면 충돌합니다.
`SuccessfulExit: false`는 **비정상 종료(크래시·OOM·강제 kill)만** 되살리고 러너의 자체
판단은 존중합니다.

#### 이미 돌고 있는 러너에는 — TUI가 자동으로

**TUI(`coarc`)를 켜면 이 머신에 설치된 러너 전부의 plist를 훑어 KeepAlive가 빠진 것에
자동으로 심습니다.** 러너가 지금 잡을 돌리고 있어도 안전합니다 — **서비스를 껐다 켜지 않고
plist 파일만 고치기** 때문입니다.

launchd는 plist를 **로드 시점에** 읽으므로:

- 지금 떠 있는 러너의 동작은 **그대로**입니다 (잡이 끊기지 않습니다)
- 심어둔 KeepAlive는 **다음 로드부터** 유효합니다 — 재부팅, 로그인, `s`로 서비스 재시작

재부팅·크래시 이후의 복귀가 이 설정의 목적이라, 잡을 돌리는 중일지 모르는 서비스를 지금
당장 내렸다 올릴 이유가 없습니다. 무중단으로 적용해두고 효력은 다음 로드로 넘깁니다.

당장 유효하게 만들고 싶으면 서비스를 한 번 껐다 켜세요.

```bash
# 방법 1 — 등록 스크립트 재실행 (재등록 없이 재적용 + 재시작, 멱등)
./scripts/register-runner.sh --org coco-de --dir ~/actions/{러너이름} --service

# 방법 2 — TUI에서 s 두 번 (stop → start)
```

적용됐는지 확인:

```bash
/usr/libexec/PlistBuddy -c 'Print :KeepAlive' \
  ~/Library/LaunchAgents/actions.runner.coco-de.{러너이름}.plist
```

TUI 하단 `로컬:` 줄에 노란색 **`KeepAlive 없음`** 이 보인다면 자동 적용이 **실패한** 것입니다
(자동으로 걸리는 게 정상이라, 이 경고가 뜬다는 건 PlistBuddy 부재나 권한 문제라는 뜻입니다).

### ③ 재부팅 후 로그인 세션 확보 — FileVault 유지 + `fdesetup authrestart`

LaunchAgent가 로그인에 묶여 있으므로, **재부팅 후 아무도 로그인하지 않으면 러너는
계속 오프라인**입니다. 그렇다고 FileVault(디스크 암호화)를 끄고 자동 로그인을 켜지는
마세요 — **FileVault는 켠 채로 유지**하고, 계획된 재부팅만 `sudo fdesetup authrestart`로
처리합니다.

| 상황 | 재부팅하면 | 러너를 되살리려면 |
|---|---|---|
| 계획된 재부팅 (업데이트 · 점검) | 잠금해제 화면을 건너뛰고 그대로 로그인까지 이어져 러너가 뜬다 | `sudo fdesetup authrestart` — FileVault 사용자 암호를 입력하면 **이번 부팅 1회만** 잠금해제를 건너뛴다 |
| 정전 등 예기치 않은 재부팅 | 잠금해제 화면에서 멈춘다 | 사람이 잠금해제해야 한다. UPS 같은 전원 대책으로 빈도를 줄인다 |

- FileVault가 켜져 있으면 macOS가 자동 로그인을 허용하지 않습니다. 그래서 정전 뒤의 무인
  복귀는 FileVault를 유지하는 한 기대하지 않습니다.
- `authrestart`는 암호를 직접 묻습니다. 암호를 파일에 적어 두고 자동화하지 마세요. 또 인증
  재시작 동안에는 FileVault 보호가 낮아집니다 — `fdesetup` 매뉴얼의 경고대로 해제 키 사본이
  메모리와 SMC에 놓였다가 잠금해제 뒤에 지워집니다. 사람이 곁에 있는 계획된 재부팅에만
  쓰세요. 기종에 따라 동작하지 않을 수 있습니다(`fdesetup supportsauthrestart`).
- 이미 FileVault가 꺼진 머신이라면 먼저 켭니다(시스템 설정 > 개인정보 보호 및 보안 >
  FileVault). 켠 뒤에는 위 표의 방식으로 운영합니다.
- `register-runner.sh`는 FileVault를 끄지 않고 끄라고 권하지도 않습니다 — 서비스를 켤 때 위
  상황만 점검해서 알려 줍니다.

### ④ 잠들지 않게 — `pmset`

잠든 머신은 잡을 받지 않고 큐에 쌓입니다. 전용기라면:

```bash
sudo pmset -c sleep 0 disksleep 0   # 전원 연결 시 시스템/디스크 슬립 해제
sudo pmset -c autorestart 1         # 정전 후 자동 부팅 (지원 기종만)
sudo pmset -c womp 1                # 네트워크 접근 시 깨우기
```

`-c`는 "전원 연결 상태"에만 적용합니다. 노트북은 **뚜껑을 닫으면** 이 설정과 무관하게
잠듭니다 — 클램셸로 상시 운영하려면 외부 전원 + 외부 디스플레이가 필요합니다.

### 점검

`register-runner.sh --service`(TUI는 `s` 키)를 실행하면 마지막에 위 조건을 점검한
결과가 출력됩니다. 손으로 확인하려면:

```bash
launchctl list | grep actions.runner      # 로드돼 있는지 (PID가 있으면 실행 중)
defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser  # 자동 로그인 계정
fdesetup status                           # FileVault
pmset -g custom                           # AC Power 구간의 sleep 값
tail -f ~/Library/Logs/actions.runner.*/stdout.log   # 러너 로그
```

### 왜 LaunchDaemon을 쓰지 않는가

`/Library/LaunchDaemons`에 두면 로그인 없이 **부팅 시** 뜹니다. 그런데 GUI 세션과
로그인 키체인이 없어서, 이 레포가 러너에 맡기는 작업 중 상당수가 깨집니다 — iOS
코드사인(키체인 접근), 시뮬레이터, Xcode 툴체인 일부. macOS 러너를 유지하는 이유가
바로 그 iOS 빌드이므로 LaunchDaemon 전환은 이득보다 손해가 큽니다. Linux 잡을
로그인과 무관하게 돌리고 싶다면 그건 ARC(`arc/`)가 담당하는 영역입니다.

## 공유 전에 알아둘 것

- **보안** — 퍼블릭 레포에는 붙이지 마세요. 외부 기여자의 PR이 러너에서 임의 코드를 실행할 수 있습니다. coco-de의 private 레포에서만 사용하세요.
- **디스크** — `_work` 폴더가 계속 쌓입니다. 체크아웃·빌드 산출물이 누적되니 주기적으로 정리하거나 잡 종료 시 클린업 스텝을 넣으세요. (→ [`../scripts/cleanup-work.sh`](../scripts/cleanup-work.sh)) 러너를 여러 개 돌리면 SDK·패키지 사본이 러너 수만큼 쌓이고, 해제한 러너의 폴더도 남습니다. (→ [러너 사본과 디스크](#러너-사본과-디스크-격리를-유지하면서-사본-줄이기))
- **가용성** — 켜져 있을 때만 잡을 받습니다. 노트북은 절전/종료 시 잡이 대기에 걸립니다. 상시 구동할 맥미니 같은 전용기가 있으면 훨씬 안정적입니다. (→ [재부팅 후에도 백그라운드로 유지하기](#재부팅-후에도-백그라운드로-유지하기))
- **환경** — 빌드 도구는 각자 로컬에 설치돼 있어야 합니다. 팀원마다 Flutter·Xcode 버전이 다르면 결과가 달라질 수 있으니, 라벨로 환경을 구분하는 걸 권장합니다.

## 여러 인스턴스 운영 (멀티 러너 플릿)

Mac 1대에서 러너 여러 개를 동시에 띄우려면 인스턴스별로 디렉토리와 이름을 분리해 `register-runner.sh`를 반복 실행하세요.

```bash
for i in 01 02 03 04; do
  ./register-runner.sh --org coco-de \
    --dir "$HOME/actions-runner-${i}" \
    --name "action-${i}" \
    --tool-cache "$HOME/actions-runner-shared/_tool" \
    --service
done
```

각 인스턴스는 `svc.sh`가 `actions.runner.<org>.<name>` 형식의 고유한 launchd 서비스로 등록하므로 서로 충돌하지 않습니다.

`--name`을 생략하거나 실수로 같은 이름을 다시 쓰면(`config.sh --unattended`는 이름 충돌 시 프롬프트 없이 그냥 실패합니다), `register-runner.sh`가 등록 전에 해당 스코프의 기존 러너 이름 목록을 조회해 충돌을 감지하고 `-2`, `-3` ... 접미사를 자동으로 붙여 고유한 이름으로 등록합니다. TUI에서는 `A` 키로 이름/라벨을 직접 입력해 등록할 수 있습니다 (자세한 내용은 [`tui.md`](tui.md) 참고).

### 수동(`./run.sh`) 실행 중인 러너를 서비스로 전환

이미 등록은 돼 있고 터미널에서 `./run.sh`로 포그라운드 실행 중인 러너가 있다면, 같은 `--dir`/`--name`/`--org`(또는 `--repo`) 값으로 `--service`를 붙여 다시 실행하면 됩니다.

```bash
./register-runner.sh --org coco-de \
  --dir "$HOME/actions-runner-01" \
  --name action-01 \
  --service
```

`register-runner.sh`는 `$RUNNER_DIR/.runner` 파일이 이미 있으면 재등록(토큰 발급·`config.sh`)을 건너뛰고, 같은 디렉토리에서 실행 중인 `Runner.Listener` 프로세스를 먼저 종료한 뒤 `svc.sh install && svc.sh start`만 수행합니다. 즉 재등록 없이 "포그라운드 → launchd 서비스" 전환만 안전하게 적용됩니다.

> 러너 그룹을 조직 기본 그룹이 아닌 곳으로 새로 등록하려면 `--runner-group <name>`을 추가하세요. 이미 등록된 러너를 서비스로 전환하는 경우에는 재등록을 건너뛰므로 이 옵션은 무시됩니다 — 그룹은 최초 등록 시점에만 결정됩니다.

## 공유 tool-cache (`RUNNER_TOOL_CACHE`)

한 머신에 러너를 여러 개 띄우면 각 인스턴스가 `_work/_tool`에 Flutter SDK·JDK 등을 **따로따로** 캐싱합니다. 러너 8개가 같은 Flutter 버전을 각자 내려받으면 그만큼 디스크가 배로 나갑니다 — 실제로 러너 8개짜리 플릿에서 이 문제로 200GB 넘게 중복 캐싱된 적이 있습니다.

`@actions/tool-cache`(액션들이 SDK를 캐싱할 때 쓰는 표준 라이브러리, `subosito/flutter-action` 등이 사용)는 `RUNNER_TOOL_CACHE` 환경변수를 지원해서 캐시 위치를 지정할 수 있습니다. `register-runner.sh --tool-cache <경로>`를 쓰면 해당 러너의 `.env`에 이 값이 자동으로 기록됩니다 — 모든 인스턴스에 **같은 경로**를 주면 SDK를 한 번만 캐싱하고 전부 공유합니다.

```bash
# 이미 등록된 러너에 나중에 추가할 때도 .env에 한 줄만 넣으면 됩니다
echo "RUNNER_TOOL_CACHE=$HOME/actions-runner-shared/_tool" >> ~/actions-runner-01/.env
```

`.env`는 러너 프로세스 시작 시 읽히므로, 기존에 떠 있던 러너라면 **재시작**해야 적용됩니다. `_work/_tool`에 이미 쌓여있던 캐시를 옮기려면 같은 볼륨 안에서 `mv`(rename, 추가 디스크 공간 불필요)로 병합하고, 버전/아키텍처가 같은 항목이 이미 있으면 삭제하세요. `_work/<repo>` 체크아웃 디렉토리는 절대 공유하면 안 됩니다 — git 작업 트리를 여러 프로세스가 동시에 건드리면 깨집니다.

## 러너 사본과 디스크 (격리를 유지하면서 사본 줄이기)

러너마다 캐시를 따로 두면(위의 기본 동작) 서로 덮어쓰는 사고는 없지만 사본이 러너 수만큼 쌓입니다. 한 맥에서 러너 8개를 돌리는 팀 맥은 같은 Flutter SDK 가 8벌(벌당 ~4GB), 같은 pub·Gradle 패키지가 8벌 쌓였고, 2026-11-13 에 디스크 여유가 2.5GB 까지 떨어졌습니다. 사본을 줄이는 방법은 셋이고 함께 쓸 수 있습니다.

| 방법 | 효과 | 주의 |
|---|---|---|
| **공유 tool-cache** (바로 위 절) | SDK 사본 자체가 하나가 됩니다 | `@actions/tool-cache` 는 설치 전에 대상 폴더를 비웁니다. 같은 버전을 두 러너가 동시에 처음 설치하면 서로의 설치 폴더를 지울 수 있어, 러너별 격리를 유지하는 운영에서는 쓰지 않습니다. pub·Gradle 캐시에는 해당하지 않습니다 |
| **복제 중복 제거** | 내용이 같은 파일을 APFS 복제본으로 바꿔 디스크는 한 벌 크기가 되고, 각 러너는 완전한 사본을 그대로 가집니다 | [coco-de/desktop](https://github.com/coco-de/desktop/tree/main/macos/disk-cleanup) 의 `runner-cache-dedupe` 가 하루마다 합칩니다(`./mac-setup.sh --cleanup-only` 로 등록). 아무것도 지우지 않고, 쉬는 러너의 파일만 바꿉니다 |
| **새 러너를 복제로 시작** | 새 러너가 SDK 를 처음부터 받지 않아도 되고(5~25분), 디스크도 늘지 않습니다 | `register-runner.sh --seed-from <기존 러너 폴더>` |

```bash
# 새 러너를 같은 맥의 기존 러너 도구 캐시를 복제해서 시작
./register-runner.sh --org coco-de --seed-from ~/actions/<기존 러너> --service

# 무엇을 가져올지만 보기 (아무것도 바꾸지 않음)
./seed-runner-tools.sh --from ~/actions/<기존 러너> --to ~/actions/<새 러너> --dry-run
```

`--seed-from` 은 같은 APFS 볼륨에서 `_work/_tool` 의 이식해도 안전한 도구(`flutter` · `dart` · `node` · `Java_*` · `uv` · `dcm`)만 복제합니다. Python 처럼 스크립트에 설치 경로가 박히는 도구, 체크아웃(`_work/<저장소>`), 이름에 러너 이름이 붙은 폴더(`flutter-<러너>` · `pub-cache-<러너>`)는 가져오지 않습니다. 복제가 안 되는 환경(다른 볼륨 · APFS 가 아님)에서는 디스크를 크게 쓰는 일반 복사로 바꾸지 않고 시드를 건너뜁니다. 이미 `_work/_tool` 이 채워진 러너와 `--tool-cache` 를 쓰는 러너에도 적용하지 않습니다.

**한계:** 복제본은 만든 시점의 파일만 나눠 씁니다. 시드한 뒤 러너가 새로 받는 SDK·패키지는 다시 따로 저장되므로, 사본이 계속 늘지 않게 하려면 위의 복제 중복 제거가 함께 돌고 있어야 합니다.

## 러너 해제

머신을 러너에서 빼거나 다시 등록할 때는 제거 토큰으로 깔끔하게 해제합니다.

```bash
RM=$(gh api -X POST repos/coco-de/{repo}/actions/runners/remove-token --jq .token)
./config.sh remove --token "$RM"
```

서비스로 돌리고 있었다면 먼저 `./svc.sh stop && ./svc.sh uninstall` 후 해제하세요. (→ [`../scripts/remove-runner.sh`](../scripts/remove-runner.sh))

**해제만 하면 러너 폴더가 그대로 남습니다.** `_work` 의 도구 캐시·체크아웃이 디스크를 계속 쓰고, 등록 정보(`.runner`)가 없는 폴더는 팀 맥의 자동 정리 스크립트도 찾지 못합니다(2026-11-13 실측: 해제된 러너 폴더 하나가 29GB). `remove-runner.sh` 는 해제 뒤 남은 크기를 알려 주고, `--purge` 를 주면 폴더까지 지웁니다. 등록 정보가 남아 있거나 그 폴더를 쓰는 프로세스가 있으면 지우지 않습니다.

```bash
./remove-runner.sh --org coco-de --dir ~/actions/<러너> --purge
```
