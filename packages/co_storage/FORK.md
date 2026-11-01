# Cocode의 dox_storage 포크

## 원천과 고지

- 원천: [`dartondox/dox-storage`](https://github.com/dartondox/dox-storage), pub.dev `dox_storage` **3.0.1**.
- 라이선스: MIT. 원천 `LICENSE`가 "Copyright 2022"로 시작하고 보유자 이름을 적지 않았다 — 본문을
  `THIRD_PARTY_LICENSES`에 글자 그대로 옮겼다.
- 소비 경로: `coco-de/co-package`, `packages/co_storage`.
- 이 패키지 자체의 `LICENSE`는 저장소와 같은 BSD-3(Cocode)이다. 이식 코드의 MIT 고지는
  `THIRD_PARTY_LICENSES`에 있고, 발행 tarball이 패키지 디렉터리 안 파일만 담으므로 루트와 패키지에
  둘 다 둔다(`open_epub_engine`과 같은 방식).

## 가져온 것

디스크 · 드라이버 계층 전부: `Disk`, `DriveManager`, `DriverContract`, 키 정규화, 예외,
S3 드라이버(SigV4 서명 · 멀티파트 · XML), 로컬 · 메모리 드라이버. 원천 `lib/src` 18개 파일 가운데
14개는 출처 헤더 두 줄을 빼면 **원천과 바이트 단위로 같다**. 테스트(`drive_manager` ·
`key_normalizer` · `local_driver` · `memory_driver` · `s3_driver` · `sigv4_signer` · MinIO 통합 ·
`support/disk_contract` · SigV4 벡터)도 import 이름만 바꿔 그대로 옮겼다.

## 뺀 것

- `lib/src/dox/*` (Dox 앱 글루: `Storage()`, `StorageProvider`, `Storage.route()`,
  `StorageFileController`)와 그 테스트 `test/dox/`. 이것들만 `dox_core`(서버 프레임워크)를 쓰므로
  `dox_core` 의존이 사라진다.
- 원천 `README` · `CHANGELOG` · `example/` — Dox 기준이다. 이 패키지의 변경 기록은 release-please가 쓴다.

## 바꾼 것 (네 파일, 전부 작다)

| 파일 | 변경 |
| --- | --- |
| `lib/src/types.dart` | `SignedUrlOptions.contentLength` 추가 |
| `lib/src/drivers/s3/s3_driver.dart` | `getSignedUploadUrl`이 `contentLength`가 있으면 `content-length`를 서명 헤더로 넣는다 |
| `lib/src/exceptions.dart` · `lib/src/constants/storage_constants.dart` | 문서 주석의 패키지 이름 |

**왜 `contentLength`인가.** presigned `PUT`이 올라오는 파일 크기를 제한하는 수단은 서명된
`content-length` 하나뿐이다. 서명하지 않으면 클라이언트가 10 KiB로 슬롯을 받고 10 GiB를 올릴 수
있다. 서명 구성은 SigV4 규칙 그대로이고, MinIO 통합 테스트가 서명된 크기와 다른 본문이 거부되고
(`403`) 서명하지 않으면 통과하는 것을 둘 다 보인다.

모든 포크 파일 맨 위에 출처 헤더 두 줄을 붙였다(`tool/check_licenses.sh`가 확인한다).

## 더한 것 (원천에 없음)

- `lib/client.dart`, `lib/src/uploads/upload_slot.dart` — 클라이언트 쪽. `package:http`만 쓰므로 웹에서
  컴파일된다. 서버의 `dart:io`(`Disk`가 `PathNotFoundException`을 쓴다)와 갈라 둔 이유다.
- `lib/src/uploads/direct_uploads.dart` — 서버 쪽. 키를 서버가 정하고, 타입 · 크기를 검사하고,
  서명하고, 주소에서 키를 안전하게 되찾아 지운다.
- 테스트 `upload_slot_test` · `direct_uploads_test` · `direct_uploads_minio_test`.

## 분석 설정

`analysis_options.yaml`은 **원천의 것**이고 워크스페이스 루트를 include하지 않는다. 원천이 쓰는
`always_specify_types` · `unnecessary_final`이 루트의 `prefer_final_locals` · `public_member_api_docs`와
충돌하기 때문이다. 새 코드도 같은 설정 아래 같은 스타일로 썼다.

`environment.sdk`는 원천과 같은 `>=3.13.0`이다 — 이 포크를 실행해 본 가장 낮은 SDK다.

## 원천을 따라가는 법

원천을 새로 받아 `lib/src`를 같은 방식으로 비교한다(헤더 두 줄과 위 표의 네 파일 차이만 남아야 한다).

```sh
curl -sL https://pub.dev/api/archives/dox_storage-<버전>.tar.gz | tar -xz -C <빈 디렉터리>
```

## 검증

```sh
dart analyze --fatal-infos
dart test                     # 단위: S3 드라이버는 가짜 HTTP로
dart test -t integration      # 실제 MinIO (docker 명령은 test/s3_minio_integration_test.dart 위쪽)
```

원천 통합 테스트 32개와 `DirectUploads` 통합 테스트는 MinIO에서만 돌렸다. AWS S3 · R2에는 같은
SigV4 규칙이 적용되지만 이 저장소의 어떤 테스트도 그 서버들에 대해 돌지 않는다.
