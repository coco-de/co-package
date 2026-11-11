## 요약

<!-- 무엇을 왜 바꾸나요? 관련 이슈가 있으면 번호를 적어 주세요. -->

## 변경

<!-- 바뀌는 패키지 · 파일과 핵심 변경점 -->

## 검증

<!-- 실행한 검증과 결과를 적어 주세요. 돌리지 못한 것은 이유와 함께. -->

- [ ] `melos run verify` (format · analyze · license-check · test)
- [ ] 바뀐 동작의 테스트를 더하거나 갱신했다

## 체크리스트

- [ ] 커밋 · PR 제목이 Conventional Commits 형식이다 (`feat` · `fix` 는 `release-please` 가 릴리스 버전을 올린다)
- [ ] 코드 · 로그 · 스크린샷 · 설명에 비밀 값(토큰 · 키 · 비밀번호)과 개인 정보를 넣지 않았다
- [ ] 워크플로를 바꿨다면 외부 `uses:` 는 40자리 커밋 SHA 로 고정하고 줄 끝에 릴리스 주석(`# vX.Y.Z`)을 남겼다
- [ ] 이식 · 포크한 코드를 더했다면 출처와 라이선스 고지를 `THIRD_PARTY_LICENSES` 에 반영했다

> 보안 취약점은 PR · 이슈로 공개하지 말고 [SECURITY.md](https://github.com/coco-de/co-package/blob/main/SECURITY.md) 의 절차대로 비공개로 알려 주세요.
