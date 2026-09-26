import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// One file of the cocode favicon set that every gallery page links.
///
/// The files are written next to `index.html` and linked with relative URLs,
/// so a gallery served below a path — GitHub Pages serves
/// `https://<owner>.github.io/<repo>/` — still finds them.
@immutable
final class GalleryFavicon {
  const GalleryFavicon._(this.fileName, this._attributes, this._base64);

  /// File name next to `index.html`, which is also the URL the page links.
  final String fileName;

  /// `rel` and the other attributes of the link, without `href`.
  final String _attributes;

  final String _base64;

  /// The `<link>` element for the page head.
  String get link => '<link $_attributes href="$fileName">';

  /// File contents.
  Uint8List get bytes => base64Decode(_base64);
}

/// The cocode favicon set, in the order the page links it.
///
/// These are the files https://cocode.im serves, byte for byte: an SVG of the
/// "CO." mark that follows the browser theme (dark ink on light tabs, white on
/// dark tabs), a 32 × 32 PNG for browsers without SVG favicons — named
/// `favicon.ico` as on cocode.im — and a 180 × 180 Apple touch icon, which
/// iOS accepts only as a PNG file. None of them is a data URI: Safari does not
/// show data URI favicons (WebKit bug 236616).
///
/// The icons do not follow the page's `brandColor`; the mark is the same on
/// every gallery.
const List<GalleryFavicon> galleryFavicons = [
  GalleryFavicon._('favicon.svg', 'rel="icon" type="image/svg+xml"', _svg),
  GalleryFavicon._('favicon.ico', 'rel="icon" sizes="32x32"', _raster32),
  GalleryFavicon._(
    'apple-touch-icon.png',
    'rel="apple-touch-icon"',
    _appleTouch180,
  ),
];

// Base64 copies of coco-de/cocode-home `site/web/favicon.svg`, `favicon.ico`
// and `apple-touch-icon.png` (commit 5f05629e). Replace all three together and
// update the sha256 values in test/favicon_test.dart with them.

const String _svg =
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9Ii00IC0x'
    'NCA4NiA4NiI+CiAgPCEtLSBDTy4g66eI7YGsICjsgqzsmqnsnpAg7KCc6rO1IOybkOuzuCBM'
    'b2dvIENvbnRhaW5lci5zdmcg4oCUIDIwMjYtMDgtMTkg6rWQ7LK07YyQKS4KICAgICAgIOu4'
    'jOudvOyasOyggCDthYzrp4jrpbwg65Sw65286rCE64ukIOKAlCDrnbzsnbTtirgg7YOtIOuo'
    'ueyDiSwg64uk7YGsIO2DrSDtnbDsg4kuCiAgICAgICDrnpjsiqTthLAg7Y+067Cx7J2AIHFs'
    'bWFuYWdlIOugjOuNlCArIHNpcHMg66as7IKs7J207KaI66GcIOyDneyEsS4gLS0+CiAgPHN0'
    'eWxlPgogICAgcGF0aCB7IGZpbGw6ICMxMTExMTM7IH0KICAgIEBtZWRpYSAocHJlZmVycy1j'
    'b2xvci1zY2hlbWU6IGRhcmspIHsgcGF0aCB7IGZpbGw6ICNmZmZmZmY7IH0gfQogIDwvc3R5'
    'bGU+CiAgPHBhdGggZD0iTTI4LjIxNDIgNDYuMTgzM0MyNy45NjY3IDQ1Ljg5NzQgMjcuNzI1'
    'MyA0NS42MDY2IDI3LjQ5MTQgNDUuMzEwOEMyNi4xNjk2IDQ1LjY0MzcgMjQuNzg1OSA0NS44'
    'MjA3IDIzLjM2MDEgNDUuODIwN0MxNC4wNzAzIDQ1LjgyMDcgNi41MzkyMiAzOC4yOTA4IDYu'
    'NTM5MjIgMjguOTk5OEM2LjUzOTIyIDE5LjcwODcgMTQuMDcwMyAxMi4xNzg5IDIzLjM2MDEg'
    'MTIuMTc4OUMyNC43ODcxIDEyLjE3ODkgMjYuMTcwOCAxMi4zNTU5IDI3LjQ5MjYgMTIuNjkx'
    'M0MyNy43MjY2IDEyLjM5NTUgMjcuOTY3OSAxMi4xMDM0IDI4LjIxNTQgMTEuODE3NUMyOS41'
    'NzU2IDEwLjI0MzIgMzEuMTE0IDguODM5NjkgMzIuODAyMiA3LjYzMDVDMjkuOTE2IDYuMzUy'
    'MDEgMjYuNzIwMyA1LjY0MTYgMjMuMzYxNCA1LjY0MTZDMTAuNDYxMyA1LjY0MTYgMC4wMDE5'
    'NTMxMiAxNi4xMDEgMC4wMDE5NTMxMiAyOS4wMDFDMC4wMDE5NTMxMiA0MS45MDEgMTAuNDYx'
    'MyA1Mi4zNjA0IDIzLjM2MTQgNTIuMzYwNEMyNi43MjI4IDUyLjM2MDQgMjkuOTE3MiA1MS42'
    'NSAzMi44MDQ2IDUwLjM3MjhDMzEuMTE1MiA0OS4xNjM2IDI5LjU3NjggNDcuNzU4OCAyOC4y'
    'MTQyIDQ2LjE4MzNaIi8+CiAgPHBhdGggZD0iTTQ4LjA5NyA1LjY0MjEzQzQzLjU1NiA1LjY0'
    'MjEzIDM5LjMxNTkgNi45Mzc5NSAzNS43Mjc5IDkuMTgwNTdDMzMuNzM5IDEwLjQyNDQgMzEu'
    'OTQ5NCAxMS45NjAzIDMwLjQyMDkgMTMuNzI3N0MyNi44Nzc1IDE3LjgyMzEgMjQuNzM2MyAy'
    'My4xNjExIDI0LjczNjMgMjkuMDAwM0MyNC43MzYzIDM0LjgzOTUgMjYuODc3NSA0MC4xNzc1'
    'IDMwLjQyMDkgNDQuMjcyOUMzMS45NDk0IDQ2LjA0MDMgMzMuNzM3OCA0Ny41NzYyIDM1Ljcy'
    'NzkgNDguODJDMzkuMzE1OSA1MS4wNjI3IDQzLjU1NDggNTIuMzU4NSA0OC4wOTcgNTIuMzU4'
    'NUM2MC45OTcgNTIuMzU4NSA3MS40NTY0IDQxLjg5OTEgNzEuNDU2NCAyOC45OTkxQzcxLjQ1'
    'NjQgMTYuMDk5IDYwLjk5NyA1LjYzOTY1IDQ4LjA5NyA1LjYzOTY1VjUuNjQyMTNaTTQ4LjA5'
    'NyA0NS44MjI0QzQ1LjU3NTkgNDUuODIyNCA0My4xODM1IDQ1LjI2OCA0MS4wMzQ5IDQ0LjI3'
    'NTRDMzkuMDE4OCA0My4zNDEgMzcuMjE4IDQyLjAxNzkgMzUuNzI3OSA0MC40MDRDMzIuOTY0'
    'MiAzNy40MDY0IDMxLjI3MzYgMzMuNDAyNiAzMS4yNzM2IDI5LjAwMjhDMzEuMjczNiAyNC42'
    'MDI5IDMyLjk2MyAyMC41OTkxIDM1LjcyNzkgMTcuNjAxNUMzNy4yMTY4IDE1Ljk4NzYgMzku'
    'MDE3NiAxNC42NjQ2IDQxLjAzNDkgMTMuNzMwMkM0My4xODM1IDEyLjczNzYgNDUuNTc1OSAx'
    'Mi4xODMxIDQ4LjA5NyAxMi4xODMxQzU3LjM4NjggMTIuMTgzMSA2NC45MTc5IDE5LjcxMyA2'
    'NC45MTc5IDI5LjAwNEM2NC45MTc5IDM4LjI5NTEgNTcuMzg2OCA0NS44MjQ5IDQ4LjA5NyA0'
    'NS44MjQ5VjQ1LjgyMjRaIi8+CiAgPHBhdGggZD0iTTc0LjcyODkgNTIuMzU5MUM3Ni41MzQ4'
    'IDUyLjM1OTEgNzcuOTk4NyA1MC44OTUxIDc3Ljk5ODcgNDkuMDg5MkM3Ny45OTg3IDQ3LjI4'
    'MzMgNzYuNTM0OCA0NS44MTkzIDc0LjcyODkgNDUuODE5M0M3Mi45MjMgNDUuODE5MyA3MS40'
    'NTkgNDcuMjgzMyA3MS40NTkgNDkuMDg5MkM3MS40NTkgNTAuODk1MSA3Mi45MjMgNTIuMzU5'
    'MSA3NC43Mjg5IDUyLjM1OTFaIi8+Cjwvc3ZnPgo=';

const String _raster32 =
    'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABGdBTUEAALGPC/xhBQAAACBj'
    'SFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAARGVYSWZNTQAqAAAA'
    'CAABh2kABAAAAAEAAAAaAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAgoAMABAAAAAEA'
    'AAAgAAAAAKyGYvMAAAGdaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHht'
    'bG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxy'
    'ZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3lu'
    'dGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAg'
    'ICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIj4KICAgICAg'
    'ICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjUxMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAg'
    'ICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj41MTI8L2V4aWY6UGl4ZWxZRGltZW5zaW9u'
    'PgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4K'
    'uC9IVwAABCNJREFUWAntVltPU1kUXr23p5Rph1BaqImRFok41AwxTnjQGS/PrYo6URPBFzXz'
    'oP4FmSf9DTXRxNEnCInz6IXgEE0siAmXGsAANdzLLRRabNfstfTUs2lhSEblhZ2cntN9vr3X'
    'd9Ze61tLpyhFCNs49Ntom03vENjxgHGzIMxms7C2tgaZTIZhOp0ODAYDmEwmoGcahTBGoxHo'
    'UjEM3OCnIAEymEqlwO12QzBYC36/HxRFgUQiAf39/TA0NAwLCwuQTq+B1+sRmCBUVu4Bq9UK'
    'MzMz0NvbB319fbCysgI2m20D05+nSQe0l8FgQrfbg7duNePw8DCuH6urqxgKnUSPx4u3b9/B'
    '0dHR9RBMpdL44sU/eO7c72gyWdBisUk2tPbEl30hoNcbsa7uIPb0vJU2nZycwpGRUZyensEr'
    'V67ioUO/YCwWkzATE5OMWVxclOYjkQgWFzs3JJEjYDSacf/+n3BsbIw3EGeLDx78hceOnUCf'
    'bxeWlpah11vOBKemphgj4gMjkbt45MhvWFHhY0wgsBcbGy9jd3d3jsjDh4/QalXQZrPneYIJ'
    '0Au73YHt7e28aHl5GS9dakSdzoDkFXKh2WxFh+MHjEa7GDM/P48NDWeEjOuQjo0M0EU4mnM6'
    'f8R79+7nSNy4cVPspy9MgAydP38hB75+/SbVBwlMi69d+4MxmUwWm5ou52G0x0lEFMWOT548'
    '5TXxeBzLy33iYxRpX/YAuf/x478Z+Pp1lAHr3UVe6OjoYMyzZ885uNZjtATombx3+PCvmE6n'
    'eZ3qVS1OT3lcUlICBw4EOS/a2togmVyWcpjS0uv1Qk1NDWNaWlqEPqQlzOekkm4WiwWi0Sin'
    'Jb2or68HwUTCMAGXywVOp5NfDAwMiI1lhVZJOhwOxsRi74QgFZQQaXMSomQyCYODgzzv81Ww'
    'kGlBsiXtm+/0rBcD5ubmQEQ1m6yurhZuykrmCTM7OwtLS0s8X1VVJeT5o4Qp9IfcTQpKSkoj'
    'Hv+Qk3UVzwRo8zdvenguFAqJRXbprEj/x8fHxVn2Mub06VOiHpgljLqh9k5yXlf3s4idfTzd'
    '2dmZHzcUkZ/S8CJHKv1QzooVUrrIaZjZUhpSlmwpDb+nEJEtbfqyDpAX/q8Uk8iUlroxEKgS'
    'UtyEXV35UkziVFRUzARINclujgD9+e9iNL1JMZoQxWgENypG9IF+fwBfvnyFra2t6HKVMBGJ'
    'AJFQy3Fz85+iHL8XESEPKsfhsLYcfypeWpQIPi7HZ89+KccGgxmPHj3OMKENuHv3Hq4xOnaD'
    'NnTFs9qQlJW5obY2KNKokjMjkZgVDcmAaEiGuCGhbsnjKdSQ9IqGpD+vISFhCofDIu0TIIKT'
    'RakgAZUPKeDXbsmoSyJdIZmmsSkBlci3vG+/FH/Lr9vK3jse2HYP/Asf9deeqJ27JQAAAABJ'
    'RU5ErkJggg==';

const String _appleTouch180 =
    'iVBORw0KGgoAAAANSUhEUgAAALQAAAC0CAYAAAA9zQYyAAAABGdBTUEAALGPC/xhBQAAACBj'
    'SFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAARGVYSWZNTQAqAAAA'
    'CAABh2kABAAAAAEAAAAaAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAC0oAMABAAAAAEA'
    'AAC0AAAAAFbVlnkAAAGdaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHht'
    'bG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxy'
    'ZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3lu'
    'dGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAg'
    'ICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIj4KICAgICAg'
    'ICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjUxMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAg'
    'ICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj41MTI8L2V4aWY6UGl4ZWxZRGltZW5zaW9u'
    'PgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4K'
    'uC9IVwAAIrJJREFUeAHtnQecVLX2x0OXBRWVqvCkiLIIIohY8D2EpYugPFBYmiggPkEURUT9'
    'W1GaqIii4BPw6ROkuiCw8KSIooLSxEKRojQpUqRX//lmvTjMTruZuTN37ySfz+xOSW5yzvnl'
    '5OTkJMmVklL4D2GS4YBHOJDbI3QYMgwHFAcMoA0QPMUBA2hPidMQYwBtMOApDhhAe0qchhgD'
    'aIMBT3HAANpT4jTEGEAbDHiKAwbQnhKnIcYA2mDAUxwwgPaUOA0xBtAGA57igAG0p8RpiDGA'
    'NhjwFAcMoD0lTkOMAbTBgKc4YADtKXEaYgygDQY8xQEDaE+J0xBjAG0w4CkOGEB7SpyGGANo'
    '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'
    'jMmTJ6uz/datW3dmiTlQfie+w23HvIS9i6G0rVU3fLzzzjZq5AtnArkO0BYReEAIdGL3NFdb'
    'EMrZuHEjFW9dsmRJK5sj/9ECbFpgxTAzc45y3wFqgIl3I5SGCNYggMQLPzeLBZgwdevWVXEk'
    'TptYxEUQ58KCUWZmpgL0gQMH/wwHSMw5IoxgnMj05JNPBGPZme/ZcPvkk0+p9p75Msgb1wLa'
    't71obWsIJ0i+SpUqCtjXXltTHaPAd2x50kmAF4EDYPbBMbSxyZOtWNiSaAdAHIkmiaR+S2tT'
    'L/e10FmvuaaGcg+yUEOkIneY6A79aD/ik3/6ab0CMfSw84egLSZ52K2YQjqdMhL6Is0DH+BB'
    't27d1HFqHA/nn3AUAOa33hop20v0ZPiYkRwBaF9CYcKJEyelF+GUEgx2KTHY7ArBrUOUGQsj'
    'TMjQfAgvT57c6uwNAnsALwLfuXOnmsBxs+zmzZvlQslu9RsjA6ch5cuX13GzAKHSWXnxnuVk'
    'wAwNhApcckkptcsFeqCT32kbedH2gBc7GHoQPotAROvx4iAgFkUAbhYP3LdRFzqgoVy5cnL7'
    'XhNx/fXX/xmctE8qliVixoyZYsOGDcrTEmkHzHGA9gU37wEgL4DOf/8EI3gF+o28rPRh1mDT'
    'Rso0/zpi9RkB84IWXrz3T1Yb/X8jKxqMkYSXRbd/eTd+hlZGYBLttmijI9rxhKjysdqCpVpj'
    '/hgOJJgDCVlYSTDNpnoPc8AA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoeptkA2sPCTUbS'
    'DKCTUeoeptkA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoeptkA'
    '2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCT'
    'UeoeptkA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoeptkA2sPC'
    'TUbSDKCTUeoeptkA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoe'
    'ptkA2sPCTUbSDKCTUeoeptkA2sPCTUbSDKCTUeoepvn/AUsOba4tsR3CAAAAAElFTkSuQmCC';
