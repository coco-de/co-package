# Changelog

## [0.1.0](https://github.com/coco-de/open-board/compare/v0.0.1...v0.1.0) (2026-09-05)


### 기능

* **lasso:** ✨ 신규 선택 진입 후보를 호스트가 판정하는 canSelectItem seam (kobic unibook[#12445](https://github.com/coco-de/open-board/issues/12445), UB-639) ([#276](https://github.com/coco-de/open-board/issues/276)) ([6257cf9](https://github.com/coco-de/open-board/commit/6257cf944833c764941a5867d8564bc61ccc1fb0))
* **scribble:** ✨ Stroke.id 도입 + 필드 열거 복사 유실 제거 (kobic [#12846](https://github.com/coco-de/open-board/issues/12846)) ([#279](https://github.com/coco-de/open-board/issues/279)) ([96b121e](https://github.com/coco-de/open-board/commit/96b121e944c26d297ae1e7274eb698559f10b4a8))


### 버그 수정

* **ci:** 💚 example pub get 의 private git 의존성 fetch 에 토큰 인증 주입 ([#267](https://github.com/coco-de/open-board/issues/267)) ([df4b563](https://github.com/coco-de/open-board/commit/df4b5634301c1cb2ad9ad4e9e115e4b9dcc0789e))
* **ci:** 💚 잡 타임아웃 15→30분 — cold Flutter SDK 다운로드가 취소 악순환을 만든다 ([#268](https://github.com/coco-de/open-board/issues/268)) ([1cac87d](https://github.com/coco-de/open-board/commit/1cac87d2dad52a81d6e699350691b0cd2b3efca2))
* **eraser:** 프레임 드롭으로 인한 지우개 현 관통(tunneling) 방지 ([#254](https://github.com/coco-de/open-board/issues/254)) ([#255](https://github.com/coco-de/open-board/issues/255)) ([4de9321](https://github.com/coco-de/open-board/commit/4de9321e08c5a4faefb98e8c26c062b6eb25a645))
* **scribble:** 🐛 onScribbleFinished 를 ScribbleNotifier 중앙 훅으로 재설계 ([#259](https://github.com/coco-de/open-board/issues/259) 대체) ([#260](https://github.com/coco-de/open-board/issues/260)) ([a57a494](https://github.com/coco-de/open-board/commit/a57a494062aefca84293c9ca0a6d1a831ca71ba1))
* **scribble:** 🐛 링크 위 짧은 탭 필기 잔상 제거 — 지연 시작(deferred start) API 도입 ([#258](https://github.com/coco-de/open-board/issues/258)) ([28be629](https://github.com/coco-de/open-board/commit/28be6291295029e2d431aabe3f0ffaa6683abde2))
* **scribble:** 🐛 올가미 이동/변형 완료 시 onScribbleFinished 미발화 수정 ([#259](https://github.com/coco-de/open-board/issues/259)) ([20f4a9d](https://github.com/coco-de/open-board/commit/20f4a9d551a2098a5eea1ba2e4e471b7aa8c95aa))
* **scribble:** 🐛 원본 보존용 저장 변환과 파일 작업 순서 보장 (unibook [#13174](https://github.com/coco-de/open-board/issues/13174)) ([d8c9c86](https://github.com/coco-de/open-board/commit/d8c9c860a845c00a86b517dd84eaf02154ccf86d))
* **scribble:** 🐛 자유 도형 인식 민감도 개선 — 손그림 정밀도 요구 완화 (kobic [#12152](https://github.com/coco-de/open-board/issues/12152)) ([#263](https://github.com/coco-de/open-board/issues/263)) ([ae5f7bf](https://github.com/coco-de/open-board/commit/ae5f7bfa46cb85813c93038a1150b718f0187489))
* **scribble:** 🐛 지터로 인한 코너 과다 검출 방지 — 삼각형·사각형 오각형/육각형 오분류 차단 (UB-555 3차) ([#265](https://github.com/coco-de/open-board/issues/265)) ([4ec2a0d](https://github.com/coco-de/open-board/commit/4ec2a0daba5a58b56ed9ce5839f0a6561099dc7e))
* **scribble:** 🐛 파일 저장 변환과 저장·삭제 순서 보장 ([#280](https://github.com/coco-de/open-board/issues/280)) ([a10fbb0](https://github.com/coco-de/open-board/commit/a10fbb05e98ba68d6d5be881f686991868caa0ea))
* **text:** 🐛 InlineTextEditor 오버레이 좌표가 조상 스케일 변환을 무시하던 결함 수정 (kobic UB-626, unibook[#12409](https://github.com/coco-de/open-board/issues/12409)) ([#278](https://github.com/coco-de/open-board/issues/278)) ([e4d38ba](https://github.com/coco-de/open-board/commit/e4d38ba236a0186c74149d23b3009e54d41c35c3))
* **text:** 🐛 다른 도구 모드에서 이미 선택된 텍스트박스 재드래그 시 이동 대신 선택 해제되던 결함 수정 (kobic UB-595 후속) ([#271](https://github.com/coco-de/open-board/issues/271)) ([72d190d](https://github.com/coco-de/open-board/commit/72d190d3b07eb8e6eb0444dbbea892c5f3246b6e))
* **text:** 🐛 무동작 링크 버튼 제거 + 선택 없이도 링크 추가 (kobic [#9838](https://github.com/coco-de/open-board/issues/9838)) ([#256](https://github.com/coco-de/open-board/issues/256)) ([6926c11](https://github.com/coco-de/open-board/commit/6926c11623dcdec6833314f02cca4e8fa09ceb41))
* **text:** 🐛 손가락 재드래그가 kTouchDelay(30ms) 안에 움직이면 선택이 풀리던 레이스 수정 (kobic UB-595 후속) ([#272](https://github.com/coco-de/open-board/issues/272)) ([26f5222](https://github.com/coco-de/open-board/commit/26f52222b493a3621f9d2f8d6b5ac8a921b894f7))
* **text:** 🐛 인라인 텍스트 에디터 — 가려지지 않는 터치 지점은 도킹하지 않음 ([#252](https://github.com/coco-de/open-board/issues/252)) ([cc8f6f6](https://github.com/coco-de/open-board/commit/cc8f6f6c2d47f0d533149e9a57ce4249dae232e3)), closes [#251](https://github.com/coco-de/open-board/issues/251)
* **text:** 🐛 인라인 텍스트박스 날짜 버튼 제거 — 완료 버튼으로 교체 (kobic UB-631) ([#275](https://github.com/coco-de/open-board/issues/275)) ([18a2f95](https://github.com/coco-de/open-board/commit/18a2f952337f9ee9e4b15d3615a1b5b6d5825ff8))
* **text:** 🐛 텍스트박스 변형 핸들이 스타일러스에서 완전 무반응이던 결함 수정 (kobic UB-595) ([#269](https://github.com/coco-de/open-board/issues/269)) ([54b6ebb](https://github.com/coco-de/open-board/commit/54b6ebb6077c5e21958878ab412318cfd45b44d5))
* **text:** 🐛 텍스트박스 선택 후 다른 도구로 전환하면 손가락 컨트롤 조작 불가 수정 (kobic UB-595 후속) ([#270](https://github.com/coco-de/open-board/issues/270)) ([5332614](https://github.com/coco-de/open-board/commit/5332614f7f2092f9402adcab86e20985210f81d8))
* **text:** 🐛 텍스트박스 입력 확정 시 소프트 줄바꿈 유지 — 커밋 폭 저장·반영 (kobic UB-627/UB-632) ([#277](https://github.com/coco-de/open-board/issues/277)) ([987121a](https://github.com/coco-de/open-board/commit/987121a5c3d260d1fe76a34e89acf4a4a1cc2567))

## 0.0.1

* TODO: Describe initial release.
