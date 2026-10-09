# German (`de`)

status: localized

Native name: Deutsch. National locale: `de_DE`.

The status line above is read by the tests of the package:

- `planned`: the language has no data yet. Its domain text bundle, clinic data,
  and SaaS data are empty stubs, and the language reads English.
- `localized`: all three are written. Change the line to `localized` in the same
  pull request that writes them: the tests compare it with the registries.

The three data sets are written: `lib/src/l10n/de/de_bundle.dart` (252 keys, 810
texts), `de_clinic.dart`, and `de_saas.dart`. The translation is a draft written
with an AI assistant, and a native speaker has not reviewed it. See
[README.md](README.md) for the work, the gate, and the format of this file.

## Glossary

One row for each term that the texts use for the same thing, in English. A term
has one translation, and it is the only one that the texts of the language
write; the forbidden forms are the spellings that must not appear anywhere in
them (another variant, an English loanword, a term of another region). The
rationale says why. Separate forbidden forms with `;` or the full-width
`；`, and write each form in backticks if you like (a comma does not
separate them).

A forbidden form is matched anywhere in a text, whatever its case, so a short
form (`du`, `Plan`, `Pack`) would hit other words (`Produkt`, `Kronenplanung`,
`Packband`) and is not listed, and neither is an English word that is also the
name of a `{field}` (`clinic`, `procedure`, `sessions`, `packagePrice`); the
register is checked word by word in the test of the language.

| Source term (English) | Translation | Forbidden forms | Rationale |
| --- | --- | --- | --- |
| Gender policy for a person noun | Neutral wording; the gender colon where a person noun cannot be avoided (`Patient:in`) | `Patient*in`; `Patient/in`; `Patient(in)`; `PatientIn`; `Patientin`; `Ärztin`; `Ärzt*in`; `Arzt/Ärztin`; `Erzieherin`; `Erzieher*in`; `Ehepartnerin`; `Ehefrau`; `Ehemann` | One policy for the whole language: a neutral noun where German has one (`Pflegefachkraft`, `Ärztliche Leitung`, `Empfang`, `Teamleitung`, `Elternteil`), a compound with the plain stem (`Patientenberatung`, `Teamkonten`), and otherwise the gender colon, which reads aloud with a pause. No star, slash, capital I, bracket, or pair form (`Patientin oder Patient`). Mock text, so a team that prefers the generic masculine changes the data, not the code. |
| You (formal address) | Sie | - | Every text that speaks to a patient or a customer, or between colleagues, writes the formal `Sie` / `Ihr` (capitalized). The test of the language looks for `du`, `dich`, `dein`, `euch`, and `euer` word by word. |
| Clinic | Praxis | `Klinik` | An outpatient clinic is a `Praxis`; a `Klinik` is a hospital. A practice name reads `Praxis Ahorn – Dermatologie`. |
| Tenant (a clinic that uses the software) | Praxis | `Mandant`; `Tenant` | The customer of the SaaS vendor is a practice. |
| Patient | Patient:in | `Patientin`; `Patient*in`; `Patient/in`; `PatientIn` | Gender policy. Compounds keep the plain stem: `Patientenberatung`, `Patientendatensatz`. |
| Physician | Ärzt:in | `Ärztin`; `Ärzt*in`; `Arzt/Ärztin` | Gender policy. The head of a practice is `Ärztliche Leitung`, the neutral noun. |
| Nurse | Pflegefachkraft | `Krankenschwester`; `Krankenpfleger` | The neutral, official title since the reform of nursing training. |
| Nurse assistant | Pflegehilfskraft | `Pflegehelfer`; `Krankenpflegehelfer` | The neutral counterpart of the nurse title. |
| Front desk | Empfang | `Rezeption`; `Front Desk` | The usual word of a practice; `Rezeption` is a hotel word. |
| Appointment | Termin | `Appointment` | A visit that is booked is a `Termin`; the record is `Terminbuchung`. |
| Booking | Buchung | `Reservierung`; `Booking` | Online booking, space and stay bookings, and the booking screen. A table of a restaurant is not a booking: `Tisch für {n}`. |
| Counseling | Beratung | `Counseling`; `Konsultation` | The step in which a counselor explains and quotes; also the visit purpose and the exam topic. The doctor's step is `Untersuchung`. |
| Procedure | Eingriff | `Prozedur` | An aesthetic or minor medical intervention; the stage `Eingriff` and the room `Behandlungsraum`. |
| Treatment | Behandlung | `Treatment` | A medical treatment of a condition; a `Therapie` is the course of it. |
| Session | Sitzung | - | One visit of a treatment series (`Eine Sitzung kostet 120,00 €`). |
| Package (of sessions) | Paket | `Behandlungskarte` | A bundle of sessions: `{n}er-Paket`. The studio pass of the fitness pack is a `Karte` (`10er-Karte`), another concept. |
| Prepaid balance | Guthaben | `Prepaid`; `Vorauszahlung` | The money that a patient has paid in advance, and the wallet of a tenant. |
| Invoice | Rechnung | `Faktura`; `Invoice` | The usual word; the invoice number is `Rechnungsnummer`. |
| Claim (insurance billing) | Abrechnung | `Claim` | The billing of a service to an insurer; the claim master is `Abrechnungsstammdaten`, the fee schedule `Gebührenordnung`. |
| Billing | Abrechnung | `Billing` | The invoicing of a customer (the topic of a ticket, the role of an operator). |
| Insurance | Versicherung | `Insurance` | Statutory insurance is `Gesetzliche Krankenversicherung`; an insurer is a `Versicherung`. |
| Refund | Erstattung | `Rückzahlung`; `Refund` | Money that goes back to a payer; a reversed point is `zurückgebucht`. |
| Discount | Rabatt | `Ermäßigung`; `Discount` | The usual word; a percentage is written `10 %`. |
| Coupon | Gutschein | `Coupon`; `Kupon` | The usual word for a voucher. |
| Points | Punkte | `Points` | Loyalty points of the clinic and the bonus points of a deal. |
| Credits (message or quote credits) | Credits | `Kontingent`; `Nutzungseinheiten` | The unit of a message or a quote that a customer buys; German software keeps the English plural `Credits`. Money that is paid in is `Guthaben`. |
| Notification | Benachrichtigung | `Notification`; `Notifikation` | The message that the system sends to a person. |
| Message template | Vorlage | `Template`; `Schablone` | A template of a notification; the `#{variable}` markers keep their English names as identifiers. |
| Sign-in | Anmeldung | `Login`; `Log-in`; `Einloggen` | The usual word for signing in to an account. |
| Account | Konto | `Account` | A login account and a bank account are both `Konto`. |
| Integration | Anbindung | `Integration`; `Schnittstelle` | A connection to another system: its status and its check. |
| Outage | Störung | `Outage` | The state of a service that does not work; a slow service is `Eingeschränkt`. |
| Maintenance | Wartung | `Maintenance`; `Instandhaltung` | Planned work on a service. |
| Release | Veröffentlichung | `Release` | The publication of a version; the notes are `Versionshinweise`. |
| Delivery (of a parcel) | Zustellung | `Delivery`; `Auslieferung` | The last mile of a parcel: `In Zustellung`, `Zustellung abgeschlossen`. |
| Hub (logistics) | Verteilzentrum | `Hub`; `Umschlagplatz` | A sorting centre of a carrier. |
| Currency exchange | Geldwechsel | `Währungsumtausch`; `Exchange` | The exchange of cash: the office is a `Wechselstube`. |
| Episode | Folge | `Episode` | The unit of a series. |
| Publisher | Verlag | `Publisher` | A company that publishes books and audio. |
| Guardian | Erziehungsberechtigte | `Vormund`; `Sorgeberechtigte`; `Bezugsperson` | The people who are responsible for a child; written as the collective, so it is neutral and fits one person or two. |
| Teacher (daycare) | Erzieher:in | `Erzieherin`; `Erzieher*in`; `Lehrer` | The caregiver in a daycare centre; gender policy. |
| Spouse | Ehepartner:in | `Ehepartnerin`; `Ehegatte` | The relation of a contact to a patient; gender policy. |
| Fictional | fiktiv | `fiktional`; `Fake`; `erfunden` | The one marker of a fictional name, drug, product, place, or work: `(fiktiv)`. A sample or an illustration is `(Beispiel)`. |
| Example | Beispiel | `Example`; `Sample` | The marker of an example text: `(Beispiel)` after a label, `Beispiel…` in front of a compound. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`1.234,00 €`) | The euro, written `1.234,56 €`: a period between thousands, a comma before two decimals, the symbol after the number with a no-break space (` `). `faker.clinic.money` and `faker.saas.money` write it from the data (`CoCurrencyFormat`). Prices are rounded to €5 and packages to €10; a card payment can be paid in installments from €450. The VAT of an invoice is 19%. |
| Dates and times | `08.10.2026`: day, month, year with periods. A notice without a year writes `Mi, 30.9.` (the generator does not pad the numbers), a range `Mi, 30.9. – Fr, 2.10.`. Times are written in 24 hours with `Uhr` (`14:00 Uhr`, `08:00–21:00 Uhr`). The weekdays are `Mo`, `Di`, `Mi`, `Do`, `Fr`, `Sa`, `So`, without a period. |
| Numbers: separators and units | A comma for decimals and a period for thousands (`1.000 Stück`). A space between a number and its unit or its percent sign (`500 g`, `10 mg`, `350 ml`, `10 %`). A count of sessions is `{n}er-Paket`, `10er-Karte`. |
| Punctuation and quotation marks | The quotation marks are `„…“`. The en dash with spaces separates (`Praxis Ahorn – Dermatologie`, `{from} – {to}`); a time range has none (`08:00–21:00 Uhr`). The fictional marker and the example marker are in parentheses at the end of a label. |
| Register: `Sie` or `du` | `Sie` for every patient, customer, and colleague; the capitalized `Sie` and `Ihr`. No `du`. |
| Gender, case, and plural in a template that a value fills | Neutral wording first, the gender colon only where a person noun is needed (see the glossary). A template puts the value where no article, case, or plural follows: `Tisch für {n}`, `Zeilen: {n}`, `Neu registrierte Patient:innen: {n}`, `{sessions}er-Paket`, `Erziehungsberechtigte von {name1}`, `Erzieher:in {name1}` (the two daycare templates use `{name1}`). A date label never follows a preposition: `Geschlossen {dates}`. |
| Compound words: the spelling to use | Written together (`Zahnsteinentfernung`, `Kundenservice`, `Lasereinstellung`, `Beispielgutschein`). A hyphen joins an acronym, a number, or a loanword to a noun (`LED-Therapie`, `Beispiel-CSV-Export`, `Pikosekundenlaser-Toning`, `E-Rezept`, `E-Mail`). Every noun starts with a capital letter; `Praxis` is written in front of a practice name (`Praxis {prefix} – {suffix}`). |

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
- [ ] The gender policy (neutral wording, the gender colon for `Patient:in`,
      `Ärzt:in`, `Ehepartner:in`, `Erzieher:in`, `Operator:in`, `Eigentümer:in`,
      `Berater:in`, `Manager:in`, `Mitarbeiter:in`) is what the maintainers want
      for demo data; the alternative is the generic masculine.
- [ ] Insurance labels (`clinic.labels`): `nhis` is `Gesetzliche
      Krankenversicherung`, `uninsured` is `Selbstzahlung`. The codes
      `medicalAid1` and `medicalAid2` are Korean categories without an exact
      German counterpart; they read `Krankenhilfe (Typ 1)` and `(Typ 2)`.
- [ ] Care grades (`homecare.careGrade`): `Pflegegrad 1` to `5` is the German
      system; the sixth entry, `Kognitive Unterstützungsstufe`, is the
      translation of a Korean category and has no German name.
- [ ] Medical and aesthetic terms: `Botulinumtoxin`, `Hyaluron-Filler`,
      `Pikosekundenlaser-Toning` (`Toning` is the term of the Korean
      aesthetic market, and German clinics say it less), `Straffung` for
      lifting, `Ausreinigung`, the ICD-10-GM names of the six diagnoses
      (`Chloasma (Melasma)`, `Atopische Dermatitis, nicht näher bezeichnet`,
      `Rosazea, nicht näher bezeichnet`), and the vital-sign shorthand `RR`.
- [ ] Billing and legal terms: `Abrechnung`, `Kassenleistung`,
      `Abrechnungsstammdaten`, `Gebührenordnung`, `Anspruchsprüfung`,
      `Medikationsprüfung`, `E-Rezept`, `Einwilligung`, and `personenbezogene
      Daten`. The three consent forms are example text that is not legally
      reviewed.
- [ ] The prices: the procedure bands in euros (`Erstvorstellung` €70–180,
      `Hyaluron-Filler` €450–850, `HIFU` €800–2.700), the plans (€69, €139,
      €249, €499 a month), the top-ups of the wallet, and the claim master rows,
      which name a pack because one tablet costs cents.
- [ ] The names that German invents: the places (`Tannenlicht`, `Flussau`,
      `Eschenhain`, `Tannenbach`, `Feldmark`), the practice names
      (`Praxis Klarblick – Dermatologie`), the card issuers (`Beispielbank
      Nord`), the insurers (`Nordhafen Versicherung`, `Hafenblick Leben`,
      `Gipfellinie Assekuranz`, `Klarbach Gesundheit`), the creators
      (`Sanduhrgarten`, `Himmelsfaden`), and the drug stems (`Adermix`,
      `Lumisan`, `Zeravil`, `Orvelan`, `Brelvano`, `Seratan`, `Minobar`,
      `Akrozan`) must not be a real organization, person, or product.
- [ ] The exam questions (`exam_prep`): `Stapelspeicher`, `Wegewahl`,
      `Prinzip der minimalen Rechte`, and `Hashfunktion` are the terms of a
      German textbook.
- [ ] The messages of a notification template read `bei #{clinic}`, and the
      name of a practice already starts with `Praxis`: check that `Ihr Termin
      bei Praxis Ahorn – Dermatologie` reads right.
- [ ] The notification variables (`#{name}`, `#{clinic}`, `#{dateTime}`,
      `#{time}`, `#{link}`) keep their English names on purpose.

## Known limitations

What the gate does not see, and what no file of the language can change:

- `clinic.approvalNo`, the role `saas.recipient`, and the entity fields
  `rrnMasked` (of `clinic.patient`) and `businessNumber` (of `saas.tenant`) that
  `schema.entity` infers write Korean number formats in every language: they
  hold no Hangul. `faker.clinic` and `faker.saas` write a masked ID
  (`******1234`) and a business number (`DE123456789`) from the data of German.
- With the `korea` pack registered (`CoFakerDomains.all` has it), a field such
  as `phone`, `address1`, or `zipCode` of the entity `clinic.patient`, and the
  phone of `saas.tenant`, is inferred to a Korean role and writes a Korean value,
  Hangul included. The gate runs the entities without that pack, and
  `faker.clinic.patient()` writes a German address and phone.
- `logistics.timeWindow` writes `09:00~11:00` (a tilde, as Korean does) in every
  language, and a number that a generator puts into a text uses a decimal point:
  the vitals note reads `36.6 °C`, not `36,6 °C`. They are written in code, not
  in the data of a language.
- `CoClinicHours`, the default of `businessSlots`, `appointmentSlot`, and
  `visitHeatmap`, are the opening hours of a Korean dermatology clinic (closed
  on Sunday, a lunch break): numbers, not text, and the same in every language.
- `clinic.inquiry()` is independent of the locale by design: a clinic inbox
  receives messages in several languages, each with its Korean translation.
- The gate runs `CoFaker.forLanguage('de')`; the test of the language
  (`test/languages/de_localization_test.dart`) checks that `CoFaker(locale: 'de')`
  and `CoFaker(locale: 'de_DE')` read the same data.
- A closure notice has no public holidays: the holiday calendar is Korean, so
  a German notice always gives a reason (`Fachkongress`, `Umbauarbeiten`).
