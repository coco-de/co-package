# co-arc

**Cocode Actions Runner Cluster** — coco-de 조직의 Flutter · Dart 풀스택 서비스(Flutter / Jaspr / Serverpod)를 배포·테스트하기 위한 self-hosted 러너 인프라 레포입니다.

서비스 코드는 각자의 레포에 두고, 이 레포는 다음만 담당합니다.

| 영역 | 내용 | 위치 |
|---|---|---|
| 러너 등록 | 로컬 머신(macOS)을 self-hosted 러너로 등록/해제하는 스크립트 | [`scripts/`](scripts/) |
| ARC | Kubernetes 기반 러너 오토스케일링 (Actions Runner Controller) | [`arc/`](arc/) |
| 재사용 워크플로우 | 서비스 레포들이 `workflow_call`로 가져다 쓰는 공용 CI | [`.github/workflows/`](.github/workflows/) |
| 문서 | 러너 세팅 런북 | [`docs/`](docs/) |

## 빠른 시작

### 1. 내 Mac을 러너로 등록

```bash
# repo 레벨 러너 (특정 레포 전용)
./scripts/register-runner.sh --repo coco-de/<repo>

# org 레벨 러너 (coco-de 전체 레포 공용, admin:org 스코프 필요)
./scripts/register-runner.sh --org coco-de
```

사전 준비물과 상세 절차는 [docs/self-hosted-runner.md](docs/self-hosted-runner.md) 런북을 따르세요.

### 2. 러너 연결 확인

레포의 **Actions → Runner Smoke Test → Run workflow** 를 실행하면 러너에 잡이 배정되고 Dart 스택 버전이 출력됩니다.

### 3. 서비스 레포에서 공용 CI 사용

서비스 레포의 `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]

jobs:
  ci:
    uses: coco-de/co-arc/.github/workflows/melos-ci.yml@main
    with:
      runs-on: '["self-hosted", "macos", "flutter"]'
```

전체 예시는 [`templates/caller-example.yml`](templates/caller-example.yml) 참고.

> **참고** — private 레포끼리 재사용 워크플로우를 호출하려면 조직 설정에서 허용이 필요합니다:
> `co-arc → Settings → Actions → General → Access → "Accessible from repositories in the coco-de organization"`

## 재사용 워크플로우 목록

| 워크플로우 | 용도 | 주요 입력 |
|---|---|---|
| [`melos-ci.yml`](.github/workflows/melos-ci.yml) | melos 모노레포 공용 CI (bootstrap → analyze → test) | `runs-on`, `flutter-channel` |
| [`flutter-ci.yml`](.github/workflows/flutter-ci.yml) | 단일 Flutter 앱 CI + 선택적 빌드(apk/ios/web) | `runs-on`, `build-targets` |
| [`serverpod-ci.yml`](.github/workflows/serverpod-ci.yml) | Serverpod 서버 테스트 (Postgres·Redis 서비스 컨테이너) | `runs-on`, `server-directory` |
| [`jaspr-ci.yml`](.github/workflows/jaspr-ci.yml) | Jaspr 웹 빌드/테스트 | `runs-on`, `project-directory` |
| [`runner-smoke.yml`](.github/workflows/runner-smoke.yml) | 러너 연결/환경 확인 (수동 실행) | `runs-on` |

## 러너 전략

```
┌─────────────────────────────────────────────────────┐
│  macOS self-hosted (scripts/)                       │
│  · iOS/macOS 빌드는 반드시 여기 (Xcode 필요)          │
│  · 라벨: [self-hosted, macos, flutter]              │
├─────────────────────────────────────────────────────┤
│  ARC on Kubernetes (arc/)                           │
│  · Linux 컨테이너 러너 오토스케일링                    │
│  · analyze/test/web·server 빌드, 병렬 잡에 적합       │
│  · runs-on: arc-dart (러너 스케일 세트 이름)          │
└─────────────────────────────────────────────────────┘
```

- **지금**: Mac 1대를 등록해서 시작 (`scripts/`)
- **확장**: 잡이 밀리기 시작하면 ARC로 Linux 잡을 분리 (`arc/`)
- iOS 빌드는 ARC(Linux)에서 불가능하므로 macOS 러너는 계속 유지

## 보안 수칙

- self-hosted 러너는 **coco-de의 private 레포에만** 연결합니다. 퍼블릭 레포는 외부 PR이 러너에서 임의 코드를 실행할 수 있습니다.
- 등록 토큰은 1시간만 유효하며 스크립트가 매번 새로 발급합니다. 토큰을 파일/채팅에 남기지 마세요.
- `_work` 디렉토리는 주기적으로 정리하세요: `./scripts/cleanup-work.sh`
