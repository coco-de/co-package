# UI example copy

`faker.ui` supplies authored component text for canvases, documentation previews,
Widgetbook, and fixture screens. It includes 252 `component.slot` keys and 418
texts per language. Korean follows [CoUI #6010's approved table](https://github.com/coco-de/coui/issues/6010#issuecomment-6759151296)
and its [final implementation record](https://github.com/coco-de/coui/issues/6010#issuecomment-6762684567)
(2026-11-10). English is a semantic counterpart of those final examples, rather
than a copy of the old `Label` / `Placeholder` slot names.

```dart
import 'package:co_faker/co_faker.dart';

final faker = CoFaker(locale: 'ko', seed: 6010);
final header = faker.ui.text('card.header'); // 프로젝트 요약
final hint = faker.ui.text('textField.placeholder'); // 이메일을 입력해 주세요
final assignees = faker.ui.list('itemPicker.options'); // 김코드, 이코드, 박코드
final toast = faker.ui.text('toast.message'); // 저장했어요
```

These are fixture keys, not CoUI property names or runtime translation keys.
Apply the value to an exposed text property or the corresponding application
slot. Keep component, property, variant, layer, enum, and token names unchanged.
The catalog does not change CoUI defaults or an application's chrome locale.

| Read | Behavior |
|---|---|
| `text(key)` | A single text; throws `StateError` for a list |
| `list(key)` | An immutable list in authored order |
| `pick(key)` | A seeded random choice, using the parent's stream |
| `pickBalanced(key, index)` | Cycles by index without drawing random values |
| `CoFakerUi.keys` | Every available key in catalog order |

Unknown keys throw `ArgumentError`. `text`, `list`, and `pickBalanced` draw no
random values, so reading copy does not change names, IDs, or other fixture data.
The same seed selects corresponding rows in English and Korean. Parallel lists
(table columns, timeline fields, and Autocomplete fragments) share a row index;
read them with the same index rather than making separate random picks.

`ko`, `ko_KR`, `ko-KR`, and `CoFaker.forLanguage('ko')` select Korean. Other
languages currently return English; `faker.ui.language` reports the actual copy
language. `localized` and `derive` follow the parent generator's selected locale.
The UI catalog is separate from domain bundles: it does not claim UI translations
for the other domain-pack languages, or alter their existing coverage results.

## Use with a design script

From a Dart project that depends on the updated `co_faker`, export the exact
catalog without Flutter or a network request:

```sh
dart run co_faker:ui_copy --locale ko > ui-copy.ko.json
```

The object contains `source`, final `decisions`, `revision`, requested `locale`, actual `language`,
and `texts` (every key maps to an array, including single texts). A Figma script
can read `texts['textField.placeholder'][0]`, apply the value, then read back
the rendered text property. Keep the source/revision/key in the design handoff.
Check `language` before treating a fallback export as translated copy.

Useful families include `card`, `alert`, `banner`, `textField`, `phoneInput`,
`itemPicker`, `command`, `calendar`, `timePicker`, `emptyState`, `stat`, `timeline`,
`listing`, `table`, `resizableTable`, `footer`, `tabs`, and `navigationBar`.
Enumerate `CoFakerUi.keys` or inspect the JSON for the complete key list.

## Approved details and review

- Notices, errors, and empty states use Korean 해요체. The consent example
  `이용약관에 동의합니다` remains as approved. Do not mechanically rewrite every
  sentence ending. Catalog examples such as `버튼`, `좋아요!`, and `항목 추가`
  retain their approved text; a product's copy and voice guide take precedence.
- Final fictional names are `김코드`, `이코드`, `박코드`; Avatar initials are
  `코드`. The initial table's `김민준` / `민준` examples were superseded.
  Registration examples use `000-00-00000` and `000000-0000000`.
- `phoneInput.placeholder` is `전화번호`, `itemPicker.placeholder` is `검색`.
  Their parent TextField's email hint must not leak into these slots.
- Autocomplete follows the later decision: query `과`, rows `과자`, `사과잼`,
  `사과`. Zip `before`, `match`, and `after` by index. Empty before/after
  fragments are intentional. Do not discard them or choose fragments randomly.
- Stat's `1,248만` and `원` belong together. TimePicker reads `오후 02:30`.
  MockupDevice's separate `meridiem` value does not change the tablet layout;
  repositioning it was explicitly deferred by the issue.
- Keep codes, shortcuts, counters, URLs, and literal code unchanged. The
  approved filename is `2분기 보고서.pdf`, and Footer keeps
  `© 2026 코코드. All rights reserved.`.
- SCREEN system prompts (BiometricAlert, Passkey, PermissionAlert,
  SystemBarPhone) and redesign copies are excluded. The designer owns those
  prompts; use official platform Korean, including its formal speech.

Inspect the final rendered canvas as well as text-property defaults. Look inside
composed instances (buttons, pickers, menu rows, table rows) for English that the
parent did not overwrite. Check Avatar at xs, SwipeActions at its narrow width,
and TextArea wrapping. A catalog test verifies text data, not font fit or layout.
Compare shared chrome text to the app's Korean locale; this fixture catalog is
not a replacement for runtime localization.

In product screens, choose real service-specific content and varied lengths with
the domain generators. An example revenue value is not evidence of a product
metric. Use this catalog as a starting point and for component previews, while
preserving approved product requirements and the product's translation pipeline.
