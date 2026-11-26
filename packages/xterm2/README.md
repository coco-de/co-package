# co_xterm2

Cocode's MIT-licensed Flutter terminal emulator fork with desktop IME fixes.
See [FORK.md](FORK.md) for the upstream revision and compatibility history.

<p>
    <a href="https://pub.dev/packages/co_xterm2">
      <img alt="Package version" src="https://img.shields.io/pub/v/co_xterm2?color=blue&include_prereleases">
    </a>
</p>

`xterm2` is a maintained fork of the original
[`xterm`](https://pub.dev/packages/xterm) package from
[`TerminalStudio/xterm.dart`](https://github.com/TerminalStudio/xterm.dart).
The original package is no longer maintained, so this fork continues the package
under a new pub package name.

**xterm2** is a fast and fully-featured terminal emulator for Flutter applications, with support for mobile and desktop platforms.

> This package requires Flutter version >=3.19.0

## Screenshots

<table>
  <tr>
    <td>
		<img width="200px" src="https://raw.githubusercontent.com/SoFluffyOS/xterm2/master/media/demo-shell.png">
    </td>
    <td>
       <img width="200px" src="https://raw.githubusercontent.com/SoFluffyOS/xterm2/master/media/demo-vim.png">
    </td>
  <tr>
  </tr>
    <td>
       <img width="200px" src="https://raw.githubusercontent.com/SoFluffyOS/xterm2/master/media/demo-htop.png">
    </td>
    <td>
       <img width="200px" src="https://raw.githubusercontent.com/SoFluffyOS/xterm2/master/media/demo-dialog.png">
    </td>
  </tr>
</table>

## Features

- 📦 **Works out of the box** No special configuration required.
- 🚀 **Fast** Renders at 60fps.
- 😀 **Wide character support** Supports CJK and emojis.
- ✂️ **Customizable** 
- ✔ **Frontend independent**: The terminal core can work without flutter frontend.

**What's new in 3.0.0:**

- 📱 Enhanced support for **mobile** platforms.
- ⌨️ Integrates with Flutter's **shortcut** system.
- 🎨 Allows changing **theme** at runtime.
- 💪 Better **performance**. No tree rebuilds anymore.
- 🈂️ Works with **IMEs**.

## Getting Started

**1.** Add this to your package's pubspec.yaml file:

```yml
dependencies:
  co_xterm2: ^5.3.0
```

**2.** Create the terminal:

```dart
import 'package:co_xterm2/xterm.dart';
...
terminal = Terminal();
```

Listen to user interaction with the terminal by simply adding a `onOutput` callback:

```dart
terminal = Terminal();

terminal.onOutput = (output) {
  print('output: $output');
}
```

**3.** Create the view, attach the terminal to the view:

```dart
import 'package:co_xterm2/flutter.dart';
...
child: TerminalView(terminal),
```

**4.** Write something to the terminal:

```dart
terminal.write('Hello, world!');
```

**Done!**

To migrate from the Git release `xterm2-v5.3.0+cocode.1`, change the
dependency to `co_xterm2` and the import prefix to `package:co_xterm2/`.

## More examples

- Write a simple terminal in ~100 lines of code:
  https://github.com/SoFluffyOS/xterm2/blob/master/example/lib/main.dart

- Write a SSH client in ~100 lines of code with [dartssh2]:
  https://github.com/SoFluffyOS/xterm2/blob/master/example/lib/ssh.dart
  
  <img width="400px" src="https://raw.githubusercontent.com/SoFluffyOS/xterm2/master/media/example-ssh.png">

For the original package history, see [TerminalStudio/xterm.dart].

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/coco-de/co-package/issues).

Contributions are always welcome!

## License

This project is licensed under an MIT license.

[dartssh2]: https://pub.dev/packages/dartssh2
[TerminalStudio/xterm.dart]: https://github.com/TerminalStudio/xterm.dart
