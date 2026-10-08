# Italian (`it`)

status: planned

Native name: italiano. National locale: `it_IT`.

The status line above is read by the tests of the package:

- `planned`: the language has no data yet. Its domain text bundle, clinic data,
  and SaaS data are empty stubs, and the language reads English.
- `localized`: all three are written. Change the line to `localized` in the same
  pull request that writes them: the tests compare it with the registries.

Everything below is for the Story that localizes the language, and the
translation is a draft until a native speaker has reviewed it. See
[README.md](README.md) for the work, the gate, and the format of this file.

## Glossary

One row for each term that the texts use for the same thing, in English. A term
has one translation, and it is the only one that the texts of the language
write; the forbidden forms are the spellings that must not appear anywhere in
them (another variant, an English loanword, a term of another region). The
rationale says why. Separate forbidden forms with `;` or the full-width
`；`, and write each form in backticks if you like (a comma does not
separate them).

| Source term (English) | Translation | Forbidden forms | Rationale |
| --- | --- | --- | --- |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`1.234,00 €`) | |
| Dates and times | |
| Numbers: separators and units | |
| Punctuation and quotation marks | |
| Register: `Lei` or `tu` | |
| Gender and plural in a template that a value fills | |
| Elision and articles with a value that a template fills | |

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
