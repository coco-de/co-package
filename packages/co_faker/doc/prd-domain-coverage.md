# PRD domain-supply coverage — #638 F-6

Scope: reusable `co_faker` packs demanded by section 10 of
coco-de/cocode PRDs #653–#688, based on the captured complete original PRDs and
section-10 extracts. Baseline: `co_faker-v0.9.0`,
`ad2342389570e98be2680d8119db08b280fb5ead`.

## Result and evidence

- **27 new packs**; original clinic/saas/korea precedence and seeded defaults
  are regression-checked.
- **524 source role requests**, **374 unique qualified roles**: 335 requested
  new contracts + 39 reused existing contracts. All 524 resolve with the
  declared primitive type; zero unsupported rows in the role checker.
- **383 registered new/helper roles**, **96 illustrative registered schemas**.
  Extra bindings provide coherent catalog fields, arithmetic, dates, taxonomies
  and aliases; they are not presented as additional source requests.
- Exact names/types/seeds per source are in
  [`prd_domain_inventory.json`](prd_domain_inventory.json). It is independent
  of the implementation and records common-role naming choices and conditional
  reuse explicitly. `roleEnums` records source enum vocabulary, including the
  dental imaging, remittance, HR and hotel codes from the full PRD recipe blocks.
- Checks cover seeded twins, unrelated-field stability, meaningful typed
  histories/questions/catalogs, numeric bounds, complete registered enum sets,
  bounded integer references, taxonomy parents, English fallback, negative
  lookup/type cases, scoped authored-data denylists and offline image URIs.

The role checker's `supported` means **role lookup + declared adapter type**,
not a certification of an entire app, FSM, fixed tour, release or PRD. Typed and
semantic assertions are separate regression tests; publication is a parent-run
PR/CI/release step.

## Source-linked role inventory

Each link is the original PRD; column counts include reused contracts. Full
qualified-role arrays are in the JSON inventory rather than copied fixture data.

| PRD | Recipe | Requested role checks |
|---|---|---:|
| [653](https://github.com/coco-de/cocode/issues/653) | healthcare_vet | 15 |
| [654](https://github.com/coco-de/cocode/issues/654) | healthcare_dental | 21 |
| [655](https://github.com/coco-de/cocode/issues/655) | healthcare_homecare | 17 |
| [656](https://github.com/coco-de/cocode/issues/656) | exchange_pickup | 16 |
| [657](https://github.com/coco-de/cocode/issues/657) | exchange_remittance | 20 |
| [658](https://github.com/coco-de/cocode/issues/658) | exchange_wallet | 15 |
| [659](https://github.com/coco-de/cocode/issues/659) | ecommerce_grocery | 20 |
| [660](https://github.com/coco-de/cocode/issues/660) | ecommerce_b2b | 19 |
| [661](https://github.com/coco-de/cocode/issues/661) | ecommerce_groupbuy | 13 |
| [662](https://github.com/coco-de/cocode/issues/662) | booking_fitness | 14 |
| [663](https://github.com/coco-de/cocode/issues/663) | booking_space | 15 |
| [664](https://github.com/coco-de/cocode/issues/664) | booking_restaurant | 13 |
| [665](https://github.com/coco-de/cocode/issues/665) | edu_daycare | 21 |
| [666](https://github.com/coco-de/cocode/issues/666) | edu_exam_prep | 12 |
| [667](https://github.com/coco-de/cocode/issues/667) | edu_corporate | 15 |
| [668](https://github.com/coco-de/cocode/issues/668) | community_local | 14 |
| [669](https://github.com/coco-de/cocode/issues/669) | community_meetup | 12 |
| [670](https://github.com/coco-de/cocode/issues/670) | community_fandom | 13 |
| [671](https://github.com/coco-de/cocode/issues/671) | content_webtoon | 15 |
| [672](https://github.com/coco-de/cocode/issues/672) | content_audio | 4 |
| [673](https://github.com/coco-de/cocode/issues/673) | content_newsletter | 5 |
| [674](https://github.com/coco-de/cocode/issues/674) | saas_helpdesk | 16 |
| [675](https://github.com/coco-de/cocode/issues/675) | saas_campaign | 17 |
| [676](https://github.com/coco-de/cocode/issues/676) | saas_billing | 22 |
| [677](https://github.com/coco-de/cocode/issues/677) | internal_hr | 16 |
| [678](https://github.com/coco-de/cocode/issues/678) | internal_pms | 11 |
| [679](https://github.com/coco-de/cocode/issues/679) | internal_expense | 13 |
| [680](https://github.com/coco-de/cocode/issues/680) | brokerage_services | 16 |
| [681](https://github.com/coco-de/cocode/issues/681) | brokerage_home_service | 16 |
| [682](https://github.com/coco-de/cocode/issues/682) | brokerage_consult | 11 |
| [683](https://github.com/coco-de/cocode/issues/683) | logistics_lastmile | 18 |
| [684](https://github.com/coco-de/cocode/issues/684) | logistics_freight | 11 |
| [685](https://github.com/coco-de/cocode/issues/685) | logistics_wms | 10 |
| [686](https://github.com/coco-de/cocode/issues/686) | hospitality_pension | 13 |
| [687](https://github.com/coco-de/cocode/issues/687) | hospitality_hotel_ops | 13 |
| [688](https://github.com/coco-de/cocode/issues/688) | hospitality_concierge | 12 |
| **Total** | **36 original sources** | **524** |

## Reproduce from `packages/co_faker`

Use the pinned Flutter 3.47.6 toolchain (Dart 3.13.5):

```sh
fvm dart run tool/prd_coverage.dart --summary
fvm dart run tool/prd_coverage.dart --markdown
fvm dart test
fvm dart analyze --fatal-infos
fvm dart format --output=none --set-exit-if-changed lib test tool bin example
```

The coverage tool returns a nonzero exit code for missing role/type contracts.
`test/prd_domain_inventory_test.dart` verifies the source set and exact enum
vocabulary; `domain_helpers_test.dart`, `fx_remit_test.dart`, and
`authored_data_safety_test.dart` verify semantics separately. Full legacy
co_faker tests remain part of the same suite.

### Local verification (2026-10-03)

| Check | Observed result |
|---|---|
| Full `fvm dart test` | **178 tests passed**, including all existing package tests |
| `fvm dart analyze --fatal-infos` | **No issues found** (zero errors, warnings or infos) |
| Format gate (`lib test tool bin example`) | **83 files, zero changes** on the check pass |
| PRD inventory coverage summary | **36 sources, 524/524 supported role requests, zero unsupported rows** |
| `git diff --check` | Passed |
| Graph cache | Refreshed with pinned Graft 0.18.0 after the implementation |

SDK selection is a local `.fvmrc`/`.fvm` setup for Flutter 3.47.6, not a package
version or release change. These local setup artifacts are outside the package
change list. DTD discovery found no running debug app; the requested hot-reload
attempt could not connect to an app. This pure-Dart package was validated by its
tests/analysis; consumer runtime reload and pin synchronization are parent-owned.

## Remaining boundaries / unsupported requests

1. **Full application datasets**: this is reusable data supply, not all section-8
   entity schemas or complete section-10 fixture worlds. The recipe assembles
   exact counts, weighted business distributions, fixed-tour IDs/overrides,
   owner-linked histories, totals, billing/limit decisions, prescribed grades
   and attendance/lottery results. The 96 schemas are explicitly illustrative.
2. **Cross-record reference graphs**: taxonomy parent ids/names and helper-linked
   recipients are coherent; schema integer references are bounded by caller
   `referenceCounts`. Complete code/name graphs are assembled by the recipe,
   rather than inventing links between independently sampled scalars.
3. **Question/content breadth**: the exam helper supplies nine original general
   IT templates (with deterministic choice permutations), not 120 unique exam
   questions or a copied question bank. Corporate evaluation scoring and paper
   assembly remain recipe-authored. Fictional prose/title pools are original
   examples, not full books, copyrighted works or narration assets.
4. **SaaS reuse mismatches**: old message channels/statuses/operator roles and
   subscription spelling retain their baseline values. #673's email/app/web
   reuse is conditional; use explicit recipe enums. `campaign` supplies its
   aligned alimtalk/sms/push and queued/delivered/failed/excluded codes. No broad
   changes to existing clinic/SaaS dictionaries are claimed.
5. **Non-scalar fields/media**: generic schema list/DTO support, app-owned webp
   bundles, silent audio files, signatures and illustration assets are not
   newly generated here. Typed rate/question/vital helpers and proper primitive
   adapters are provided; imagery uses the existing offline URI generator.
6. **Live/real-world semantics**: there are no network calls, real organizations,
   actual personal/bank/passport identities, medical product trademarks, live
   rates, advice, or legal/result guarantees in the new authored data. Curated
   denylist regressions do not imply universal name/trademark screening.
7. **Publication/consumer integration**: normal parent-owned PR/CI/release and
   synchronized generator/app pins are still required; no manual version/tag,
   verified-app marker or upstream integration state was created by this worker.
