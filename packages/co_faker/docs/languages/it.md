# Italian (`it`)

status: planned

Native name: italiano. National locale: `it_IT`. Currency: euro (`EUR`, `€`).

The status line above is read by the tests of the package:

- `planned`: the language has no data yet. Its domain text bundle, clinic data,
  and SaaS data are empty stubs, and the language reads English.
- `localized`: all three are written. Change the line to `localized` in the same
  pull request that writes them: the tests compare it with the registries.

The translation is a draft written with an AI assistant, and a native speaker
of Italian has to review it (see the checklist at the end of this file) before
an application ships it as its own text. See [README.md](README.md) for the
work, the gate, and the format of this file.

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
| Patient | paziente | malato; ammalato | The word of a record, a notice, and a consent form; `malato` is the colloquial one. |
| Appointment | appuntamento | appointment | A visit that is scheduled at the clinic. A space, a stay, a table, or a class is `prenotato`. |
| Booking, reservation | prenotazione | booking; reservation | The booking of a space, a stay, a table, a class, or a visit online. |
| Consultation | visita | consultazione | The visit of a patient to a physician. `consultazione` is the act of consulting a source: a false friend. |
| Counseling | consulenza | counseling; counselling | One word for the stage of the visit, the room, the counselor (`Consulente pazienti`), and AI counseling (`consulenza con IA`), and for the advice of the brokerage pack. |
| Procedure (medical) | procedura | procedimento | What a physician performs (injectables, laser, lifting). `procedimento` is a legal or administrative proceeding. |
| Treatment | trattamento | - | The treatment of acne, a skin condition, or warts. |
| Therapy | terapia | - | `terapia canalare` (root canal) and `Terapia LED`. |
| Care (of the skin) | cura | - | A facial care or a soothing care: `Cura del viso`, `Cura lenitiva`. |
| Session | seduta | sessione | A session of a package or a treatment. `sessione` is a software or an exam session. It is plural in a package name (3, 5, or 10), so no template needs to agree. |
| Package (of sessions) | pacchetto | forfait | The Italian word for a package of sessions; the French word is not used. |
| Prepaid balance | saldo prepagato | credito prepagato | A balance paid in advance and used later. |
| Credit (message credit) | credito | - | A unit that a customer buys and spends: message credits, quote credits. |
| Quote (estimate) | preventivo | quotazione | The estimate of a price before the work. |
| Invoice | fattura | invoice | The document that asks a customer to pay. |
| Refund | rimborso | refund | The same word for a refund of a payment and for the reimbursement of a claim. |
| Insurance claim | richiesta di rimborso | claim | A request for payment sent to an insurer. |
| Coupon | buono sconto | coupon | One word for every coupon of a campaign, a visit, or a delivery. |
| Subscription plan | piano | - | The offer a customer subscribes to: `Base`, `Standard`, `Pro`, `Aziendale`. |
| Subscription | abbonamento | - | The contract of a plan, and the pass of a studio. |
| Tenant (customer of the vendor) | struttura | locatario | The clinic that holds an account of the software. `locatario` is the tenant of a flat. |
| Claim master | tariffario di riferimento | claim master | The reference tables of fees, drugs, materials, and diagnoses that claims are checked against. |
| Electronic medical record | cartella clinica elettronica | - | The usual Italian name of the software, written in full in a title. |
| Electronic prescription | ricetta elettronica | prescrizione elettronica; e-prescription | The document that a physician sends to a pharmacy. `prescrizione` is the time-bar of a right: a false friend. |
| Release (of software) | rilascio | release | The title of a release is `Note di rilascio`. |
| Notification template | modello di notifica | template | A message with variables; the variables are written in Italian (`#{nome}`). |
| Customer support | assistenza clienti | supporto clienti | The team and the role. |
| Autopay | addebito automatico | autopay | The payment that a card or an account makes by itself each month. |
| Maintenance | manutenzione | - | The scheduled interruption of a service or an equipment check. |
| Delivery | consegna | delivery | The same word for a delivery of a parcel and a delivery date. |
| Shipping | spedizione | shipping | The cost and the benefit of shipping an order (`spedizione gratuita`). |
| Hub (logistics) | centro di smistamento | hub | The place where parcels are sorted and sent on. |
| Cargo owner (shipper) | mittente | shipper | The party that sends the goods. |
| Carrier (logistics) | vettore | carrier | The company that transports the goods. |
| Spread (exchange margin) | margine | spread | The margin of an exchange office on an exchange rate. |
| Bank transfer | bonifico bancario | trasferimento bancario | `trasferimento` is not used for money that moves between accounts. |
| Cancellation | annullamento | cancellazione | The act of cancelling an appointment, a booking, or a class. `cancellazione` is a deletion. |
| No-show | assente | no-show; no show | A status that qualifies an appointment or a class, so it is written in the masculine, which is the form of the singular for both genders. |
| Check-in | accettazione | check-in | The first stage of a visit, and the check-in on a kiosk or a tablet. |
| Front desk | accoglienza | reception | The staff role, the sender line, and the source of a check-in. |
| Medical director | direttore sanitario | direttore medico | The title that Italian law gives to the head of a private clinic. |
| Physician | medico | dottore | The title of the profession, written in the masculine. `dottore` is a title of any graduate. |
| Registered nurse | infermiere | nurse | The title of the profession, written in the masculine as a role label of a form is. |
| Nurse assistant | operatore socio-sanitario | assistente infermieristico | The title of the profession in the masculine. |
| Aesthetician | estetista | - | The profession of skin care; the noun is the same for a woman and a man. |
| Guardian | genitore o tutore | - | One term for the daycare, the consent text, and the relation label. |
| Legal guardian | tutore legale | rappresentante legale | A person appointed to act for a patient. |
| Teacher | insegnante | maestro; maestra | The noun is the same for a woman and a man, and the name that follows is drawn without a sex. |
| Medical certificate | certificato medico | - | The document that a physician issues. |
| Fictional | di fantasia | fittizio; finto | The marker is the one tag `(di fantasia)` after every fictional name: it never changes with the gender or the number of the noun before it. |
| Example | esempio | campione; sample | `(esempio)` after a sample label, `Esempio di …` where English begins with `Example`. |
| Demo | demo | demonstration | `demo` follows a noun or stands in parentheses; a sentence says `dimostrativo`. |
| Weekend | fine settimana | weekend; week-end | The Italian words, as a notice writes them. |
| E-mail | e-mail | email | The hyphenated spelling of the dictionaries. |
| Parking | parcheggio | parking | The place for a car. |
| Episode | episodio | - | An episode of a series, a chapter of a story. |
| Solbit (fictional district) | Aurelvia | Solbit | The fictional places of Italian are invented names that sound Italian, not the Korean ones of the English data. |
| Garam (fictional district) | Rivosereno | Garam | A fictional place; it follows `di` or `quartiere`. |
| Mulpare (fictional district) | Fraxinia | Mulpare | A fictional place that follows `di` or `quartiere`. |
| Solnae (fictional district) | Pinelume | Solnae | A fictional place that follows `di` or `quartiere`. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`1.234,00 €`) | `1.234,56 €`: a full stop between thousands, a comma before the two cents, and a no-break space (U+00A0) before `€`. `CoCurrencyFormat(code: 'EUR', symbol: '€', pattern: '{amount} {symbol}', groupSeparator: '.', decimalSeparator: ',', fractionDigits: 2)`. |
| Dates and times | A date in prose is `8 ottobre 2026` (the month in lower case, no ordinal). A closure notice writes `mercoledì 25/11` (`{weekday} {day}/{month}`) and a range `da lunedì 24/11 a giovedì 27/11`; the names of the weekdays are lower case. The clock is of 24 hours with a colon (`18:00`), and a range of hours is `08:00–21:00`. |
| Numbers: separators and units | A decimal comma and a full stop between thousands (`1.000`). A space between a number and a unit (`500 g`, `10 mg`, `350 ml`); `%` follows its number (`20%`). A number of a device or a gate is `n.` and a no-break space. |
| Punctuation and quotation marks | No space before `:`, `;`, `?`, `!`, `,`, and `.`, and one after. The apostrophe is the typographic `’` (U+2019), never `'`. A quotation is `«…»`, and a range is written with an en dash. |
| Register: `Lei` or `tu` | `Lei` in every text that speaks to a patient or a customer, with the pronouns in capitals (`Lei`, `La`, `Le`, `Suo`, `Sua`). A notice that speaks to nobody in particular uses `si prega di` and the infinitive. A first-person line of a patient uses `io`. |
| Gender and plural in a template that a value fills | A template avoids the agreement: `Tavolo per {n}` (no plural), `Nuovi pazienti registrati: {n}` (the count after the label), `{category}, livello {level}` (the level follows `livello`), `{name1} (genitore o tutore)`, and `Insegnante {name1}` (the noun is the same for both sexes). A status label is in the masculine, like a role title. |
| Articles, contractions, and elision with a value that a template fills | No template puts `il`, `lo`, `la`, `i`, `gli`, `le`, `l’`, or a preposition that contracts with them (`del`, `al`, `nel`, `dal`, `sul`, `dell’`, `all’`) right before a value, because the gender, the number, and the first letter of the value decide them. A value stands first in the sentence (`{target}: iscrizione approvata.`), after a colon, a comma, or in parentheses, or after `per`, `di`, `in`, `da`, `a`, or `presso` that never take an article. A number (`{n}`, `{sessions}`) may follow `di`. |
| The marker of a fictional name and of a sample | `(di fantasia)` after a fictional name and `(esempio)` after a sample label: one marker for each, whatever the gender and the number of the noun. A sentence says `di fantasia`, and an English text that begins with `Example` begins with `Esempio di`. |
| A clinic name | The kind of place first, then the name: `Studio dermatologico dell’Acero`, `Ambulatorio pediatrico Demo` (`clinicNameFormat: '{suffix} {prefix}'`). |
| Names, places, and brands | No real brand, person, or institution: the places are invented (`Aurelvia`, `Rivosereno`, `Fraxinia`, `Pinelume`), the creators are `Giardino della Clessidra` and `Venatura del Cielo`, and the insurers, the bank, the publishers, and the businesses are invented names. The card networks of the English data stay (`Visa`, `Mastercard`, `Amex`), and `Bancomat`, the domestic debit network, replaces `Discover`, which Italy does not use. |

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
