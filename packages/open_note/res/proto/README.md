## 코드 생성
### Swift
`swift-protobuf`을 설치 후 `protobuf` 코드 생성을 진행 합니다
```terminal
brew install swift-protobuf
cd res/proto
protoc --swift_out=../../ios/Classes scribble.proto
```

### Dart
`protoc_plugin`을 설치 후 `protobuf` 코드 생성을 진행 합니다
실행 기준은 res/proto 폴더 기준으로 작성되었습니다.
protoc가 없다면 `brew install protobuf`를 통해 먼저 설치해야합니다.
```termianl
dart pub global activate protoc_plugin
protoc --proto_path=. --plugin=protoc-gen-dart=$HOME/.pub-cache/bin/protoc-gen-dart --dart_out=../../lib/src/data/model/protobuf scribble.proto
```