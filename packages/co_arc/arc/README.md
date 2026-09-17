# ARC — Actions Runner Controller

Kubernetes 위에서 GitHub Actions 러너를 **오토스케일링**하는 세팅입니다. 잡이 큐에 쌓이면 러너 파드가 뜨고, 끝나면 사라집니다.

> 공식 문서: https://docs.github.com/en/actions/concepts/runners/actions-runner-controller

## 언제 ARC로 넘어가나

- Mac 러너 1~2대로 잡이 밀리기 시작할 때 (analyze/test 같은 Linux 가능 잡을 분리)
- PR마다 병렬 잡이 많이 필요할 때
- **주의**: iOS/macOS 빌드는 ARC(Linux 컨테이너)에서 불가 → macOS self-hosted 러너 유지

## 사전 준비

- Kubernetes 클러스터 (k3s, EKS, GKE, OrbStack k8s 등) + `kubectl`, `helm` v3.8+
- 인증 방식 (둘 중 하나):
  - **GitHub App (권장)** — org 전용 App 생성 후 App ID / Installation ID / private key
  - **PAT (classic)** — org 러너 기준 `admin:org` 스코프

## 설치 순서

### 1. 컨트롤러 설치

```bash
helm install arc \
  --namespace arc-systems --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
  -f values/controller.yaml
```

### 2. GitHub 인증 시크릿 생성

```bash
# GitHub App 방식 (권장)
kubectl create namespace arc-runners
kubectl create secret generic arc-github-secret \
  --namespace arc-runners \
  --from-literal=github_app_id=<APP_ID> \
  --from-literal=github_app_installation_id=<INSTALLATION_ID> \
  --from-file=github_app_private_key=<PRIVATE_KEY.pem>

# 또는 PAT 방식
kubectl create secret generic arc-github-secret \
  --namespace arc-runners \
  --from-literal=github_token=<PAT>
```

### 3. 러너 스케일 세트 설치

```bash
helm install arc-dart \
  --namespace arc-runners \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
  -f values/runner-set-dart.yaml
```

`install.sh`로 1~3을 한 번에 실행할 수도 있습니다.

### 4. 확인

```bash
helm list -A
kubectl get pods -n arc-systems
# 워크플로우에서:
#   runs-on: arc-dart
```

## 워크플로우에서 사용

`runs-on`에 **helm 릴리스 이름**(= 러너 스케일 세트 이름)을 그대로 씁니다. 라벨 배열이 아니라 단일 값입니다.

```yaml
jobs:
  test:
    runs-on: arc-dart
    container:
      image: ghcr.io/cirruslabs/flutter:stable   # Flutter/Dart 툴체인 이미지
    steps:
      - uses: actions/checkout@v4
      - run: dart pub global activate melos
      - run: melos bootstrap && melos run test
```

Serverpod 테스트처럼 `services:`(Postgres/Redis 컨테이너)가 필요한 잡은 러너에 Docker가 필요하므로, `runner-set-dart.yaml`에서 `containerMode.type: dind`를 사용합니다.

## 제거

```bash
helm uninstall arc-dart -n arc-runners
helm uninstall arc -n arc-systems
```
