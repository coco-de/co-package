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
| (a) Hangul | A language other than Korean has a Hangul character in a text, or a generator writes one. |
| (b) Writing system | Japanese texts without kana or han, Chinese without han, Russian without Cyrillic (95% of the texts must have it). |
| (c) Same as English | More than 5% of the texts (10% for German, French, Italian, and Portuguese, which share many words with English) read exactly like the English ones, or a whole list does. |
| (d) List length | A list has another length than the English list: the same seed must pick the same record in every language, so a list keeps the English length and order. |
| (e) Not registered | A key of the English bundle, or the clinic or SaaS data, is still a stub. English is used for it. |

It also checks that a code (`CONS01`, `nhis`) is the English one, that a
translation keeps the placeholders (`{n}`, `#{variable}`) of its English text,
that no text is empty, and that the questions of `exam_prep` keep their
pairs: the four choices differ, and the explanation contains the correct
choice. The generators are held to the same rules on what they write: no
Hangul, no placeholder left unfilled (`{n}`), no exception, and the writing
system of the language.

A text that is the same as English on purpose (a unit, an acronym, a loanword,
a proper name) is listed in `allowSameAsEnglish` of the bundle, with the name
of its slot and its value, and an entry that no text needs any more is
reported:

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

One row for each term, with one translation. A test of the package reads every
language file and fails when:

- a row is not four cells, or has an empty term, translation, or rationale;
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
  differ between English and Korean, and the data of the language.
