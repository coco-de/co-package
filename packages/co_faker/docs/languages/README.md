# Languages

co_faker writes the text of its domain mock data (the domain packs, the
dedicated generators, `faker.clinic`, and `faker.saas`) in the languages of
this directory. English is the reference that every language follows, and
Korean is the language the data was first written in. Chinese, Japanese,
German, French, Russian, Italian, and Portuguese are localized one language at
a time, each in its own pull request.

The names, addresses, and other basic data of a language are separate: they
come with `CoFaker.forLanguage` and do not depend on this work.

## Which languages are supported

The table of languages is computed from the registries. It is never written by
hand, so it cannot go stale:

```sh
dart run co_faker:coverage --languages                  # a Markdown table
dart run co_faker:coverage --languages --format json    # for tools
```

For each language it shows the writing system, whether the basic modules have
its names and addresses, how many keys of the domain text bundle it has
written, whether its clinic and SaaS data are written, and its level:

| Level | Meaning |
| --- | --- |
| `base` | No domain data is registered. The basic modules speak the language and the domain packs read English. |
| `planned` | Registered with empty stubs. Nothing is written yet. |
| `partial` | Some of the domain text bundle, the clinic data, and the SaaS data are written, not all. |
| `localized` | All three are written. |

## The gate of a language

```sh
dart run co_faker:coverage --language ja --strict
```

reads the shipped data of the language, compares it with English text by text,
runs every generator of the language, and fails with a non-zero exit code and a
list of what is wrong (the slot, the row, and the text). It takes a few
seconds, and a test of the package (`test/coverage_gate_test.dart`) runs it for
every language that has domain text, so the check of a pull request is this
gate. A language is finished when it passes. The checks:

| Check | What fails |
| --- | --- |
| (a) Hangul | A language other than Korean has a Hangul character in a text (half-width and circled Hangul too), or a generator writes one. |
| (b) Writing system | Japanese texts without kana or han, Chinese without han, Russian without Cyrillic (95% of the texts must have it). Han characters alone are Chinese: at least 20% of the Japanese texts have a kana, and at most 5% of the Chinese ones. |
| (c) Same as English | More than 5% of the texts (10% for German, French, Italian, and Portuguese, which share many words with English) read exactly like the English ones, or a whole list does. `allowSameAsEnglish` may cover at most 10% of the texts. |
| (d) List length | A list has another length than the English list, or a map has other keys, or the same keys in another order: the same seed must pick the same record in every language, and a generator picks an entry by its position, so a list and a map keep the English length and order. |
| (e) Not registered | A key of the English bundle, or the clinic or SaaS data, is still a stub. English is used for it. |

It also checks, for every text of the three data sets:

- **fields.** A translation keeps the `{name}` fields of its English text: each
  one, under the English name, as often as English has it, in any order. A
  generator fills the English names only, so a renamed field (`{回数}`) stays in
  the output as it is, and a dropped one loses its value. The same holds for a
  pattern (`{month}/{day}`, `{kind} #{number}`); there a number sign before a
  field is part of the pattern, and a language may write the number its own
  way (`{kind} {number}号機`, `{kind} Nr. {number}`). A `#{variable}` of a
  notification template is the one marker that a language may rename, as many
  times as English has it. Three templates choose among the names that the
  generator offers, so they take the names from this list instead:
  `common.maskedName` (`{lastName}`, `{firstName}`, `{initial}`) and the two
  daycare templates `daycare.guardianLabel` and `daycare.teacherName`
  (`{name1}`, `{name2}`; write `{name1}`). Two patterns may use fields besides
  the English ones, because their generator offers them: the address line of a
  patient (`clinic.addressLineFormat`: `{region}` and `{regionCode}`, so that
  Japanese and Chinese write `{region}{city}{line1}`) and the date format of
  the clinic (`clinic.ops.dateFormat`: `{weekday}`).
- **codes.** A code (`CONS01`, `nhis`) is the English one.
- **empty text.** No text is empty.
- **data rules.** The questions of `exam_prep` keep their pairs: the four
  choices differ, and the explanation contains the correct choice, whatever
  its case (`Clé primaire` in `La clé primaire identifie…`). The clinic data
  and the SaaS data say `koreanValues: CoKoreanValues.none`, or the
  generators keep writing Korean phone numbers, addresses, and registration
  numbers, which hold no Hangul and no other check would see.

The generators are held to the same rules on what they write: no Hangul, no
placeholder left unfilled (`{n}`, and a `#{variable}` anywhere but in a
notification template), no exception, and the writing system of the language
for the texts that a role or a generator returns, and for each string of a
record. A text that reads the same in English and Korean is a code or a
literal that carries no language and is left out.

A text that is the same as English on purpose (a unit, an acronym, a loanword,
a proper name) is listed in `allowSameAsEnglish` of the bundle, with the name
of its slot and its value, and an entry that no text needs any more is
reported. The list is short by design: it may cover 10% of the texts at most
(Korean needs 3.3%), and a list that covers more leaves texts in English.

```dart
const CoL10nBundle jaBundle = CoL10nBundle(
  language: 'ja',
  texts: {/* ... */},
  allowSameAsEnglish: {
    'catalog.groceryUnit': ['*'],        // every text of the slot is a unit
    'exam_prep.correctChoice': ['TCP'],  // an acronym
  },
);
```

Do not list a text that can be translated.

### Reading what the gate says

The report lists every problem under the name of its check, and each line says
where (a slot and a row such as `clinic.cardIssuers[3]`, or the generator that
wrote the text such as `role dental.dentalProcedure` and `clinic.payment`), what
is wrong, and the text at fault. `--format json` gives the same lines as
`check`, `where`, `message`, and `value`, and `--strict` makes the exit code 1.
`Notes` are texts worth a look that stay within a limit; they do not fail.

| In the report | What to do |
| --- | --- |
| `planned` | The language has no data yet, or only some of the three data sets: write all three. |
| `(a) Hangul` | A text still has Korean in it: translate it. Under `role ...` or a call name, a generator writes it: tell the maintainers, it is not a file of the language. |
| `(b) writing system` | A text has no kana or han (Japanese), no han (Chinese), or no Cyrillic (Russian): it is English, or a Latin transcription. Japanese needs kana in a fifth of its texts, and Chinese almost none. |
| `(c) same as English` | The texts listed read like English. Translate them; list a unit, an acronym, or a name in `allowSameAsEnglish` with the slot and the text, as the line says (`'slot': ['text']`). A slot where every text equals English is English throughout: translate it, or allow it with `'*'` if all of them are units, acronyms, or names. |
| `(d) list length` | A list has another number of texts than English, or a map has other keys or the same keys in another order. Keep the English count and order. |
| `(e) not registered` | A key, or the clinic or SaaS data, is still a stub: write it. |
| `unknown key` | A key that English does not have: check the name. |
| `code` | A code that has to be the English one is not: copy it. |
| `placeholder` | A field is lost, renamed, repeated, or added (`lacks {n}`, `has {回数}`), or the `#{variable}` markers of a template are not as many as English has: keep the fields of the English text under their English names. Under a generator, a field was left unfilled. |
| `empty text` | A text is empty. |
| `data rules` | The explanation of an exam question lacks its correct choice, two choices are the same, or `koreanValues` is not `CoKoreanValues.none`. |
| `allowSameAsEnglish` | An entry names no slot, allows a text that no text needs any more, or the list covers more than 10% of the texts: remove the entry, or translate. |
| `generator error` | A generator threw with the data of the language: the data is incomplete or inconsistent (an empty list, a missing key). |

## Localizing a language

A language Story fills only the files of its own language. It does not touch
the registries, the shared tests, `CHANGELOG.md`, the README, or the files of
the coverage tool; the gate and the shared tests read the registries, so that a
language that is filled is checked with no edit elsewhere.

| File | What to write |
| --- | --- |
| `lib/src/l10n/<language>/<language>_bundle.dart` | The domain text bundle: every key of `lib/src/l10n/en/en_bundle.dart`, with the same number of texts in the same order, and `allowSameAsEnglish`. |
| `lib/src/l10n/<language>/<language>_clinic.dart` | The clinic data, a `const CoFakerClinicData` that follows the English data: lists of the same lengths, the currency and price scale, `koreanValues: CoKoreanValues.none`. |
| `lib/src/l10n/<language>/<language>_saas.dart` | The SaaS data, a `const CoFakerSaasData`, in the same way. |
| `docs/languages/<language>.md` | The status line (`status: localized`), the glossary, the format conventions, and the review checklist. |
| `test/language_safety/<language>.dart` | The safety conventions of the language: how it marks a fictional name, how general-information texts begin, the phrases that promise a result, and the spellings of real brands in its writing system. |
| `test/languages/<language>_localization_test.dart` | A new test of what is particular to the language (a new file). |

The three data files are filled together, in one pull request: a language that
has some of them is `partial` and fails the gate.

The safety scan (`test/authored_data_safety_test.dart`) reads every language
that has domain text and asks of its texts, besides the declaration in
`test/language_safety/<language>.dart`:

- every text of `vet.vetDrug`, `vet.preventiveProduct`, and `daycare.drugLabel`
  carries the `fictionalMarker` of the language, and none names a real brand;
- every text of `brokerage.qnaAnswerGeneric` and `brokerage.consultNoteGeneric`
  starts with the `generalInfoPrefix` and promises no result;
- `fandom.creatorName` has exactly two texts, which are two fictional names of
  the language (never the Korean names);
- a masked name keeps a mask character (`homecare.recipientName`,
  `hospitality.guestName`), and the plate of `logistics.vehiclePlate` keeps its
  `●●`.

The translation of a Story is a draft written with an AI assistant, and a
native speaker has to review it. Write the terms that are medical, legal, or
financial, and every text that you are not sure about, in the review checklist
of the language file, and say in the pull request that the translation is a
draft that needs a native speaker.

## The glossary and the status line

`status: planned` or `status: localized` is the first line of a language file
that starts with `status:`. A test compares it with the registries: `localized`
only for a language whose bundle, clinic data, and SaaS data are all written,
and `planned` only for a language whose three are stubs.

The glossary is a table with exactly these columns:

```markdown
| Source term (English) | Translation | Forbidden forms | Rationale |
| --- | --- | --- | --- |
| Patient | 患者 | 患者さん; 病人 | The notice register says 患者, never the English loanword. |
```

One row for each term, with one translation. The forbidden forms are spellings
separated by `;` or by the full-width `；` that a Japanese or Chinese keyboard
types, each form written plainly or in a pair of backticks (`患者さん`；`病人`);
`-` says there is none. A comma does not separate them. A test of the package
reads every language file and fails when:

- a row is not four cells, or has an empty term, translation, or rationale;
- the forbidden forms of a row cannot be read: a backtick without its pair, or
  a comma where a `;` belongs (a form that no text could contain would be a
  rule that never fires);
- a term appears twice (the same term must have one translation);
- a forbidden form appears in the translation of the same row, or in the
  translation of another term (the texts could not avoid it);
- a forbidden form appears in any text of the language: the bundle, the clinic
  data, or the SaaS data (case is ignored);
- a localized language has no glossary row.

The test does not ask that a translation appears in the texts: a language with
inflection (Russian, German, French) writes a term in several forms, and the
check would reject correct text.

## What the gate does not cover

The gate reads what the data and the generators write. It does not judge the
quality of a translation, which a native speaker reviews, and a few assumptions
of the generators are still Korean:

- `CoClinicHours` (the defaults of `businessSlots`, `appointmentSlot`, and
  `visitHeatmap`) are the opening hours of a Korean dermatology clinic, with
  the Sunday closed. They are numbers, not text, and are the same in every
  language.
- `clinic.inquiry()` and `messengerHandle()` do not follow the locale: one
  Korean clinic inbox receives messages in several languages, each thread with
  its Korean translation. The gate calls them with a language and does not look
  for Hangul in `inquiry()`.
- The `korea` pack (`korea.mobilePhone`, `korea.rrn`, ...) asks for Korean
  values by name, so the gate skips its roles. The entities of the clinic and
  SaaS packs run without it: with the `korea` pack registered, a field such as
  `phone` or `address1` is inferred to a Korean role.
- English keeps the Korean plate pattern of `logistics.vehiclePlate` and the
  Korean names of the two approved creators, byte for byte, so the gate does
  not look for Hangul in English.
- The gate cannot see a word that a generator writes in English when it equals
  the English and Korean text (a code or a token). It does see the texts that
  differ between English and Korean, and the data of the language. A test of
  the package reads a sample whose every text is rewritten, and holds every
  text to the writing system with nothing left out: it found the literal
  `5 rows` of `saas.masterChecks()`, which is a field of the data now. What the
  generators write in English by design is named in the call table with its
  reason (`englishReason`): the brands and model codes of a device, the
  English name of a diagnosis, a user agent.
- Some values that the packs generate follow the Korean number formats in every
  language, and hold no Hangul, so the gate does not see them, and a language
  cannot change them with its own files: the roles `clinic.approvalNo` and
  `saas.recipient`, and the fields `rrnMasked` of `clinic.patient` and
  `businessNumber` of `saas.tenant` that `schema.entity` infers to the Korean
  resident and business registration numbers. `faker.clinic` and `faker.saas`
  follow `koreanValues`; these roles and entities do not yet.
- The gate runs the generators of `CoFaker.forLanguage(code)`, which has the
  national locale of the language; `CoFaker(locale: code)` reads the same data
  but has no country, so the address of a patient is the one that the basic
  modules write.
