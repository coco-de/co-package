# co_example_ui

Shared presentation for Flutter example apps using CoUI and Material. The package
provides the light and dark themes, a responsive demo catalog, and language and
theme controls that integrate with `co_demo_prefs`.

```sh
flutter pub add co_example_ui
```

```dart
import 'package:co_example_ui/co_example_ui.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    theme: exampleMaterialTheme(Brightness.light),
    darkTheme: exampleMaterialTheme(Brightness.dark),
    builder: (context, child) => ExampleThemeScope(child: child!),
    home: const Scaffold(body: Center(child: Text('Example app'))),
  ));
}
```

See the [Open Board example](https://github.com/coco-de/co-package/tree/main/packages/open_board/example)
for a catalog with locale and theme settings. The bundled Pretendard and Noto Sans
Arabic fonts have their own SIL Open Font License notices in `fonts/`.
