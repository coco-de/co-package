#!/usr/bin/env bash
#
# install.sh — ARC 컨트롤러 + Dart 러너 스케일 세트 설치
#
# 사전 준비: kubectl 컨텍스트가 대상 클러스터를 가리키고 있어야 하며,
#            arc-runners 네임스페이스에 arc-github-secret 시크릿이 있어야 합니다.
#            (없으면 arc/README.md 2단계 참고)
#
set -euo pipefail

cd "$(dirname "$0")"

command -v helm >/dev/null || { echo "error: helm이 필요합니다" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "error: kubectl이 필요합니다" >&2; exit 1; }

echo "==> 현재 컨텍스트: $(kubectl config current-context)"
read -r -p "이 클러스터에 설치할까요? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || exit 1

echo "==> 1/3 컨트롤러 설치 (namespace: arc-systems)"
helm upgrade --install arc \
  --namespace arc-systems --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
  -f values/controller.yaml

echo "==> 2/3 시크릿 확인 (namespace: arc-runners)"
kubectl get namespace arc-runners >/dev/null 2>&1 || kubectl create namespace arc-runners
if ! kubectl get secret arc-github-secret -n arc-runners >/dev/null 2>&1; then
  echo "error: arc-runners 네임스페이스에 arc-github-secret 시크릿이 없습니다." >&2
  echo "       arc/README.md의 2단계(시크릿 생성)를 먼저 실행하세요." >&2
  exit 1
fi

echo "==> 3/3 러너 스케일 세트 설치 (runs-on: arc-dart)"
helm upgrade --install arc-dart \
  --namespace arc-runners \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
  -f values/runner-set-dart.yaml

echo
echo "완료. 상태 확인:"
echo "  kubectl get pods -n arc-systems"
echo "  helm list -A"
echo "워크플로우에서:  runs-on: arc-dart"
