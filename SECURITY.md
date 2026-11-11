# Security Policy

## Supported versions

Security fixes are provided for the latest release of each package in this
repository (tags `<package>-v<version>`, see
[Depending on these packages](README.md#depending-on-these-packages)).

## Reporting a vulnerability

**Please do not report vulnerabilities in public issues, pull requests or
discussions.**

Report them privately to the repository administrators with GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately):
open the **Security** tab of this repository and choose **Report a
vulnerability**. If that option is not available, contact a repository
administrator through a private channel and ask for a private way to share the
details.

Please include:

- the affected package and version (or commit),
- steps to reproduce, or a minimal proof of concept,
- the impact you expect.

We will acknowledge the report, investigate it, and coordinate a fix and its
disclosure with you. Please give us a reasonable amount of time to release a fix
before disclosing the issue publicly.

## Scope

This policy covers the packages in this repository. Some packages contain code
forked from upstream projects (`packages/xterm2`, `packages/xterm3`,
`packages/co_storage`); if an issue originates in the upstream code, please also
report it to the upstream project.

---

# 보안 정책

## 지원 버전

보안 수정은 이 저장소 각 패키지의 최신 릴리스에 제공합니다(태그
`<패키지>-v<버전>`, [Depending on these packages](README.md#depending-on-these-packages) 참고).

## 취약점 신고

**보안 취약점은 공개 이슈 · PR · 토론으로 알리지 마세요.**

GitHub 의
[비공개 보안 권고](https://docs.github.com/ko/code-security/how-tos/report-and-fix-vulnerabilities/report-privately)로
저장소 관리자에게 비공개로 알려 주세요. 이 저장소의 **Security** 탭에서
**Report a vulnerability** 를 선택합니다. 해당 메뉴가 보이지 않으면 저장소 관리자에게
비공개 경로로 연락해 세부 내용을 전달할 방법을 요청해 주세요.

신고에는 다음을 적어 주세요.

- 영향받는 패키지와 버전(또는 커밋)
- 재현 절차 또는 최소한의 개념 증명
- 예상되는 영향

신고를 확인하고 조사한 뒤, 수정과 공개 시점을 신고자와 함께 조율합니다. 수정을 낼 때까지
공개를 미뤄 주세요.

## 범위

이 정책은 이 저장소의 패키지에 적용됩니다. 일부 패키지(`packages/xterm2`,
`packages/xterm3`, `packages/co_storage`)는 업스트림 프로젝트를 포크한 코드를 담고 있으니,
업스트림 코드에서 비롯된 문제라면 업스트림 프로젝트에도 알려 주세요.
