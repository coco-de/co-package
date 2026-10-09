# Italian (`it`)

status: localized

Native name: italiano. National locale: `it_IT`. Currency: euro (`EUR`, `€`).

The status line above is read by the tests of the package. `localized` means
that the three data sets of the language are written: the domain text bundle
(`lib/src/l10n/it/it_bundle.dart`), the clinic data (`it_clinic.dart`), and the
SaaS data (`it_saas.dart`). The language passes its gate:

```sh
dart run co_faker:coverage --language it --strict
```

**The translation is a draft written with an AI assistant. A native speaker of
Italian has to review it** (see the checklist at the end of this file) before an
application ships it as its own text. See [README.md](README.md) for the work,
the gate, and the format of this file.

`it`, `it_IT`, `it-IT`, and `CoFaker.forLanguage('it')` all read the same
Italian domain text, clinic data, and SaaS data, and the same names, phone
numbers, and addresses of Italy.

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
| Coupon | buono | coupon | One word for every coupon of a campaign, a visit, a deal, or a delivery (`Buono di compleanno`, `buono per spedizione gratuita`). |
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
| Medical director | direzione sanitaria | direttore medico | The function that Italian law gives to the head of a private clinic, written as a function and not as a title in the masculine. |
| Physician | medico | dottore | The title of the profession, which is used for a woman and a man. `dottore` is a title of any graduate. |
| Registered nurse | personale infermieristico | nurse | A function and not a title in the masculine or the feminine, because the sex of a staff member is drawn at random. |
| Nurse assistant | personale socio-sanitario | assistente infermieristico | A function, as the label of the nurses is. |
| Care coordinator | coordinamento assistenza | - | A function, as the label of the nurses is. |
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
| Register: `Lei` or `tu` | `Lei` in every text that speaks to a patient or a customer, with the pronouns in capitals (`Lei`, `La`, `Le`, `Suo`, `Sua`). A notice that speaks to nobody in particular uses `si prega di` and the infinitive, and the drafts of a support agent use the imperative of `Lei` (`Controlli`, `Annoti`). A note between colleagues uses `Lei` too, and the label of an action of the console is a noun (`Approvazione struttura`), which is neither. A first-person line of a patient uses `io`. |
| Gender and plural in a template that a value fills | A template avoids the agreement: `Tavolo per {n}` (no plural), `Nuovi pazienti registrati: {n}` (the count after the label), `{category}, livello {level}` (the level follows `livello`), `{name1} (genitore o tutore)`, and `Insegnante {name1}` (the noun is the same for both sexes). A status label is in the masculine, which is the form of the singular for a noun of any gender (`Prenotato`, `Annullato`), and a role label is a function or a noun for both sexes. |
| Articles, contractions, and elision with a value that a template fills | No template puts `il`, `lo`, `la`, `i`, `gli`, `le`, `l’`, or a preposition that contracts with them (`del`, `al`, `nel`, `dal`, `sul`, `dell’`, `all’`) right before a value, because the gender, the number, and the first letter of the value decide them. A value stands first in the sentence (`{target}: iscrizione approvata.`), after a colon, a comma, or in parentheses, or after `per`, `di`, `in`, `da`, `a`, or `presso` that never take an article. A number (`{n}`, `{sessions}`) may follow `di`. |
| The marker of a fictional name and of a sample | `(di fantasia)` after a fictional name and `(esempio)` after a sample label: one marker for each, whatever the gender and the number of the noun. A sentence says `di fantasia`, and an English text that begins with `Example` begins with `Esempio di`. |
| A clinic name | The kind of place first, then the name: `Studio dermatologico dell’Acero`, `Ambulatorio pediatrico Demo` (`clinicNameFormat: '{suffix} {prefix}'`). |
| Names, places, and brands | No real brand, person, or institution: the places are invented (`Aurelvia`, `Rivosereno`, `Fraxinia`, `Pinelume`), the creators are `Giardino della Clessidra` and `Venatura del Cielo`, and the insurers, the bank, the publishers, and the businesses are invented names. The card networks of the English data stay (`Visa`, `Mastercard`, `Amex`), and `Bancomat`, the domestic debit network, replaces `Discover`, which Italy does not use. |

## Differences from the English data

- The Instagram channel of the English data is `Pubblicità sui social media`,
  so that no brand of a platform is written; its code (`instagramAd`) is
  unchanged.
- A paper cup of 12 oz is written `350 ml`, the unit of an Italian trader.
- `Discover`, a card network that Italy does not use, is `Bancomat`, the
  domestic one.
- The insurance codes of the Korean data become coverages that exist in Italy
  and name no institution: `Copertura sanitaria pubblica` for `nhis`, and
  `Esenzione ticket (tipo 1)` and `(tipo 2)` for the two medical aids.
- The long-term care grades of the Korean data become `Livello di assistenza 1`
  to `5` and `Livello di supporto cognitivo`. They name no Italian scale.
- The ID of a patient is masked in the shape of an Italian tax code
  (`************003*`: sixteen characters, with the three digits of the code of
  the place), and the business number of a tenant is eleven digits, as the VAT
  number of a company is. Both are random digits.
- A plate is masked as `AB 12●●34 CD`: two letters, digits, and two letters,
  with `●●` hiding two digits.
- A role of the staff is a function (`Direzione sanitaria`, `Personale
  infermieristico`, `Personale socio-sanitario`, `Coordinamento assistenza`) or
  a noun that serves a woman and a man (`Estetista`, `Consulente per i
  pazienti`, `Medico`), and not a title in the masculine: the generator draws
  the sex of a staff member at random.
- The invented stems of the drug names are not the English ones. A web search
  for each of the English stems found names too near to products that exist
  (`Dioclin` is one letter from the acne gel `Duoclin`, and `Lumisol` is the
  name of a skin gel sold in Argentina), so Italian has `Pelnovax`, `Cutarel`,
  `Lenidar`, `Ravexil`, `Belvanex`, `Corelmin`, `Velanor`, and `Cheravil`, for
  each of which the search found no medicine of that name. A pharmacist should
  still check them against the database of AIFA before an application ships
  them.
- The fictional places (`Aurelvia`, `Rivosereno`, `Fraxinia`, `Pinelume`,
  `Pianalba`) and the invented names of the bank (`Lumivale`) and of the
  creators (`Giardino della Clessidra`, `Venatura del Cielo`) were searched for
  on the web too: a first candidate for a place that is a real residence
  (`Rivachiara`) was dropped.
- A date label has the number of the month only (`mercoledì 25/11`): the
  generators give a template no month name, so a notice cannot say `25
  novembre`.

## Known limits

What the gate cannot see, and the generators write the same in every language:

- `clinic.approvalNo`, the role `saas.recipient`, and the fields `rrnMasked` of
  `clinic.patient` and `businessNumber` of `saas.tenant` that `schema.entity`
  infers to the Korean resident and business registration numbers follow the
  Korean number formats in Italian as in every language. Italian data cannot
  change them with its own files.
- When the `korea` pack is registered beside the others, a field such as
  `phone` or `address1` of an entity is inferred to a Korean role (`010-…`, a
  road-name address), in Italian as in every language; the gate runs the
  entities without that pack.
- `CoClinicHours`, the default opening hours of the schedule and the heatmap,
  are those of a Korean dermatology clinic (Sunday closed). They are numbers.
- `clinic.inquiry()` and `messengerHandle()` do not follow the locale: they are
  threads of a Korean inbox, written in Korean, English, Japanese, Chinese, and
  Vietnamese, and never in Italian.
- A generator writes a number as a plain number, so a temperature or a decimal
  that a vitals note carries has a point and not a comma (`36.8 °C`), a
  four-digit count has no full stop, and the glucose is in `mg/dL`, which an
  Italian laboratory writes in the same unit.
- A four-digit amount is written with the full stop (`1.234,56 €`), as the
  issue of the language asks; some style guides leave a number of four digits
  without a separator (`1234,56 €`), which a reviewer may prefer.
- The shared test `domain_helpers_test.dart` compares the explanation of an
  exam question with its correct choice in the same case, while the gate
  ignores the case, so an explanation starts with its choice (`Funzione di
  hash: calcola …`) and cannot use it in the middle of a sentence.

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text: `Lei` with
      the pronouns in capitals (`La`, `Le`, `Sua`), `si prega di` with the
      infinitive in a notice, and the imperative of `Lei` (`Controlli`,
      `Annoti`) in the drafts of a support agent. A note to a colleague
      (`per favore riduca di un livello …`) is in `Lei` too: a reviewer may
      prefer `tu` between colleagues.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
- [ ] Medical terms: `visita`, `procedura`, `trattamento`, `terapia`, and
      `cura`, the five words for `consultation`, `procedure`, `treatment`,
      `therapy`, and `care`; `consulenza` for counseling; `Detartrasi`;
      `terapia canalare`; `Cloasma` (the name of `Chloasma` in ICD-10);
      `Copertura sanitaria pubblica` and `Esenzione ticket`, which stand in for
      the Korean insurance and medical aid; the findings and plans of the SOAP
      notes (`Macchie brune dai contorni sfumati su entrambe le regioni
      zigomatiche`, `Rughe frontali dinamiche, grado 2`); `Febbricola`, `PA`,
      `FC`; the results of the eligibility, interaction, and claim checks
      (`Copertura verificata`, `Copertura cessata`, `Nessun iscritto
      corrispondente`).
- [ ] Legal texts: the consent forms and their disclaimer, which no lawyer has
      read, and `Consenso al trattamento dei dati personali`, which a reviewer
      may want to align with the vocabulary of the GDPR in an Italian notice.
- [ ] Financial terms: `margine` for the exchange spread (`Sconto dell’80% sul
      margine USD`), `bonifico`, `saldo prepagato`, `addebito automatico`,
      `tariffario di riferimento`, `richiesta di rimborso`, `Insoluto` for an
      unpaid invoice, the 22% VAT, the plan prices (69, 139, 249, and 479 €),
      and the scale of the prepaid wallet.
- [ ] The role labels are functions and nouns for both sexes (`Direzione
      sanitaria`, `Personale infermieristico`, `Medico`, `Estetista`). A
      reviewer may prefer a title in the masculine, a double form
      (`Infermiere/a`), or another function.
- [ ] The gender-neutral choices: `Insegnante {name1}`, `{name1} (genitore o
      tutore)`, `Sé stesso`, `Figlio o figlia`, `Nonno o nonna`, and the one
      marker `(di fantasia)` after a name of any gender and number.
- [ ] The fictional places and names (`Aurelvia`, `Rivosereno`, `Fraxinia`,
      `Pinelume`, `Pianalba`, `Lumivale`, `Terzovento`, `Lunagrano`,
      `Giardino della Clessidra`, `Venatura del Cielo`, and the shops, banks,
      insurers, and publishers) and the invented drug names do not name a real
      place, brand, person, or medicine.
- [ ] The Pilates terms (`Tappetino`, `Reformer`, `Sedia`), the daycare
      vocabulary (`Sezione Sole`, `genitore o tutore`), and the logistics terms
      (`centro di smistamento`, `mittente`, `vettore`, `portineria`, `sponda
      idraulica`).
- [ ] The loanwords that Italian keeps: `Wi-Fi`, `Reformer`, `Yoga`, `Fantasy`,
      `Podcast`, `Backlog`, `Sprint`, `Leadership`, `Router`, `Account`,
      `Laser`, `Lifting`, `Acne`, `Tablet`, `Online`, `App`, `team`, `post`,
      `filler`, `minibar`. A reviewer may prefer an Italian word for some.
- [ ] The plate pattern `AB 12●●34 CD`, the masked tax code
      `************003*`, and the notification templates, whose variables are
      `#{nome}`, `#{struttura}`, `#{data_ora}`, `#{ora}`, and `#{link}`.
