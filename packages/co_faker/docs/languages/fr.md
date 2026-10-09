# French (`fr`)

status: localized

Native name: français. National locale: `fr_FR`. Currency: euro (`EUR`, `€`).

The status line above is read by the tests of the package. `localized` means
that the three data sets of the language are written: the domain text bundle
(`lib/src/l10n/fr/fr_bundle.dart`), the clinic data (`fr_clinic.dart`), and the
SaaS data (`fr_saas.dart`). The language passes its gate:

```sh
dart run co_faker:coverage --language fr --strict
```

**The translation is a draft written with an AI assistant. A native speaker of
French has to review it** (see the checklist at the end of this file) before an
application ships it as its own text. See [README.md](README.md) for the work,
the gate, and the format of this file.

`fr`, `fr_FR`, `fr-FR`, and `CoFaker.forLanguage('fr')` all read the same
French domain text, clinic data, and SaaS data.

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
| Patient | patient | malade | The word of a record, a notice, and a consent form; `malade` is the colloquial one. |
| Appointment | rendez-vous | rdv; appointment | Written in full and never abbreviated; a visit to the clinic is a `rendez-vous`, whatever its kind. |
| Booking, reservation | réservation | booking | A space, a stay, a table, or a class is `réservé`; a visit to a physician is a `rendez-vous`. |
| Consultation | consultation | - | The same word as English: the visit of a patient to a physician. |
| Procedure (medical) | acte | procédure | `procédure` is an administrative or legal procedure, a false friend. What a physician performs is an `acte`. |
| Care (of the skin) | soin | - | A facial or a soothing care; an `acte` is what a physician performs, a `soin` what a care professional does. |
| Counseling | conseil | counseling | One word for the stage of the visit, the room (`Espace conseil`), the counselor (`Conseiller patient`), and AI counseling (`conseil par IA`). |
| Session | séance | - | A session of a package or a treatment. It is plural in a package name (3, 5, or 10), so no template needs to agree. |
| Package (of sessions) | forfait | - | The French word for a package of sessions and for a fixed-price offer; the English word is not used. |
| Prepaid balance | solde prépayé | prepaid | A balance paid in advance and used later. |
| Medical certificate | certificat médical | - | The document that a physician issues. |
| Physician | médecin | docteur | An epicene noun. `docteur` is a title and not a role. |
| Nurse | infirmier diplômé d’État | nurse; infirmière | The title of the profession, written in the masculine as a role label of a form is. |
| Nurse assistant | aide-soignant | aide-soignante | The role label, in the masculine as the other role labels. |
| Aesthetician | esthéticien | esthéticienne | The role label, in the masculine as the other role labels. |
| Guardian | responsable légal | tuteur; représentant légal | One term for the daycare, the consent text, and the relation label. `tuteur` is a guardianship ordered by a court. |
| Teacher | enseignant(e) | professeur | Both genders are written, because the name that follows is drawn without a sex. |
| Invoice | facture | invoice | The document that asks a customer to pay. |
| Refund | remboursement | refund | The same word for a refund of a payment and for the reimbursement of a claim. |
| Insurance claim | demande de remboursement | claim | A request for payment sent to an insurer. |
| Quote (estimate) | devis | quote | The estimate of a price before the work. |
| Coupon | bon | coupon | One word for every coupon of a campaign, a visit, or a delivery (`Bon d’anniversaire`). |
| Credit (message credit) | crédit | credits | A unit that a customer buys and spends: message credits, quote credits. |
| Subscription plan | formule | plan tarifaire | The offer a customer subscribes to: `Essentiel`, `Standard`, `Pro`, `Entreprise`. |
| Subscription | abonnement | - | The contract of a plan, and the pass of a studio. |
| Tenant (customer of the vendor) | établissement | locataire | The clinic that holds an account of the software. `locataire` is a renter of a flat. |
| Claim master | référentiel de facturation | claim master | The reference tables of fees, drugs, materials, and diagnoses that claims are checked against. |
| EMR (electronic medical record) | DPI (dossier patient informatisé) | EMR | The usual French abbreviation of the software. |
| Electronic prescription | ordonnance électronique | e-prescription | The document that a physician sends to a pharmacy. |
| Release (of software) | version | release | The title of a release is `Notes de version`. |
| Notification template | modèle de notification | template | A message with variables; the variables are written in French (`#{nom}`). |
| Support (customer support) | support client | assistance | The team and the role; `assistance` is not used for it. |
| Autopay | prélèvement automatique | autopay | The payment that a card or an account makes by itself each month. |
| Maintenance | maintenance | - | The same word as English. |
| Delivery | livraison | delivery | The same word for a delivery and a shipping benefit. |
| Hub (logistics) | plateforme logistique | hub | The place where parcels are sorted and sent on. |
| Cargo owner (shipper) | chargeur | - | The freight term for the party that ships the goods. |
| Carrier (logistics) | transporteur | carrier | The company that transports the goods. |
| Spread (exchange margin) | marge | spread | The margin of a bank on an exchange rate. |
| Bank transfer | virement bancaire | transfert bancaire | `transfert` is not used for money that moves between accounts. |
| Cancellation | annulation | - | The act of cancelling an appointment, a booking, or a class. |
| No-show | absent | no-show | A status that qualifies a `rendez-vous`, so it is written in the masculine. |
| Check-in | enregistrement | check-in | The first stage of a visit, and the check-in on a kiosk or a tablet. |
| Front desk | accueil | guichet | The staff role, the sender line, and the source of a check-in; a `guichet` is the window of a bank or a post office. |
| Fictional | fictif | fictional; (fictive) | The marker is the one tag `(fictif)` after every fictional name, whatever the gender of the noun. A sentence agrees (`Ville fictive`). |
| Example | exemple | example; sample | `(exemple)` after a sample label, `Exemple de …` where English begins with `Example`. |
| Demo | démo (a label); de démonstration (a sentence) | demo | `démo` follows a noun or stands in parentheses; a sentence says `de démonstration`. |
| Weekend | week-end | weekend | The hyphenated spelling of the Académie française. |
| E-mail | e-mail | email; courriel | `courriel` is the Quebec word; the label is written with a hyphen. |
| Parking | parking | stationnement | The place for a car, in the same word as a customer says it. |
| Episode | épisode | - | An episode of a series, a chapter of a story. |
| Solbit (fictional district) | Clairval | Solbit | The fictional places of French are invented names that sound French, not the Korean ones of the English data. |
| Garam (fictional district) | Rivebleue | Garam | A fictional place; it follows `de` or `quartier`. |
| Mulpare (fictional district) | Frênaie | Mulpare | A fictional place that starts with a consonant, so that `de Frênaie` needs no elision. |
| Solnae (fictional district) | Aulnaie | Solnae | A fictional place that starts with a vowel, so it follows `quartier` or `zone` and never `de`. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`1 234,00 €`, no-break space) | `1 234,56 €`: a narrow no-break space (U+202F) between thousands, a comma before the two cents, and a no-break space (U+00A0) before `€`. `CoCurrencyFormat(code: 'EUR', symbol: '€', pattern: '{amount} {symbol}', groupSeparator: ' ', decimalSeparator: ',', fractionDigits: 2)`. The price bands are in euros (a consultation 70 to 180 €, a laser session 180 to 450 €) and the units are those of a euro price: 5 € for a price, 10 € for a package, 1 € for an adjustment and a point, a card payment in installments from 400 €. The VAT of an invoice is 20%. |
| Dates and times | A date in prose is `8 octobre 2026`. A closure notice writes `mercredi 25/11` (`{weekday} {day}/{month}`) and a range `du mercredi 25/11 au jeudi 26/11`; the names of the months and of the weekdays are lower case. An hour is `18 h` and a range of hours `De 8 h à 21 h`, with a no-break space before `h`. |
| Numbers: separators and units | A decimal comma and a narrow no-break space between thousands (`1 000`). A no-break space before a unit (`500 g`, `10 mg`, `35 cl`, `2 mL`), before `%` (`20 %`), and before `°C`; `n°` is followed by a no-break space (`Entrée commune n° ••••`). |
| Punctuation: the space before `:` `;` `?` `!`, and quotation marks | A no-break space before `:`, `;`, `?`, and `!`, and inside the guillemets (`« {target} »`); none before `,` and `.`. The apostrophe is the typographic `’` (U+2019), never `'`. |
| Register: `vous` or `tu` | `vous` in every text that speaks to a patient or a customer (`Bonjour, qu’est-ce qui vous amène aujourd’hui ?`). A notice or an instruction that speaks to nobody in particular uses `merci de` and the infinitive, which is neither `vous` nor `tu`; a first-person line of a patient uses `je`. |
| Gender and plural in a template that a value fills | A template avoids the agreement: `Table pour {n}` (no plural), `Rendez-vous réservés : {n}` (the count after the label), `{n} ligne(s)`, `{category}, niveau {level}` (the level follows `niveau`), `{name1} (responsable légal)`, and `Enseignant(e) {name1}` (the name is drawn without a sex). A status label is in the masculine, like a role title. |
| Elision and contractions with a value that a template fills | No template puts `de`, `à`, `le`, or `la` right before a value, because the elision (`d’Inès`) and the contraction (`du`, `au`) depend on it. A value stands first in the sentence (`{target} : inscription approuvée.`), after a colon, a comma, or in parentheses, or after `pour` or `à` (which never change). The fixed fictional names that follow `de` start with a consonant (`de Clairval`, `de Rivebleue`, `de Frênaie`), and `Aulnaie` follows `quartier` and `zone` only. |
| The marker of a fictional name and of a sample | `(fictif)` after a fictional name and `(exemple)` after a sample label: one marker for each, whatever the gender of the noun. A sentence says `fictif` or `fictive`, and an English text that begins with `Example` begins with `Exemple de`. |
| A clinic name | The kind of place first, then the name: `Cabinet de pédiatrie des Érables`, `Clinique de chirurgie plastique de démonstration` (`clinicNameFormat: '{suffix} {prefix}'`). |
| Names, places, and brands | No real brand, person, or institution: the places are invented (`Clairval`, `Rivebleue`, `Frênaie`, `Aulnaie`), the creators are `Jardin du Sablier` and `Ciel de Lin`, and the insurers, the bank, and the businesses are invented names. The card networks of the English data stay (`Visa`, `Mastercard`, `Amex`) and `CB` replaces the fourth. |

## Differences from the English data

- The Instagram channel of the English data is `Publicité sur les réseaux
  sociaux`, so that no brand of a platform is written; its code
  (`instagramAd`) is unchanged.
- A paper cup of 12 oz is written `35 cl`, the unit of a French trader.
- `Discover`, a card network that France does not use, is `CB`, the domestic one.
- The long-term care grades of the Korean data become `Niveau de prise en
  charge 1` to `5` and `Niveau d’accompagnement cognitif`. They name no French
  scale.
- The ID of a patient is masked in the shape of a French social security
  number (`* ** ** ** *** *** 42`), and the business number of a tenant is nine
  digits in groups of three (`123 456 789`). Both are random digits.
- A plate is masked as `42●● AB 17`: digits, letters, and the number of the
  department of the old French plate, with `●●` hiding two digits.

## Known limits

What the gate cannot see, and the generators write the same in every language:

- `clinic.approvalNo`, the role `saas.recipient`, and the fields `rrnMasked` of
  `clinic.patient` and `businessNumber` of `saas.tenant` that `schema.entity`
  infers to the Korean resident and business registration numbers follow the
  Korean number formats in French as in every language. French data cannot
  change them with its own files.
- `CoClinicHours`, the default opening hours of the schedule and the heatmap,
  are those of a Korean dermatology clinic (Sunday closed). They are numbers.
- `clinic.inquiry()` and `messengerHandle()` do not follow the locale: they are
  threads of a Korean inbox, written in Korean, English, Japanese, Chinese, and
  Vietnamese, and never in French.
- The gate runs `CoFaker.forLanguage('fr')`. `CoFaker(locale: 'fr')` reads the
  same French data but has no country, so the address of a patient there is the
  one that the basic modules write.
- A generator writes a number as a plain number, so a temperature or a
  decimal that a vitals note carries has a point and not a comma (`36.8 °C`),
  and the glucose is in `mg/dL`, which a French laboratory writes in `g/L` or
  `mmol/L`.
- A date label (`mercredi 25/11`) has the number of the month only: the
  generators give a template no month name, so a notice cannot say
  `25 novembre`.

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text: `vous`, and
      `merci de` with the infinitive in a notice.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
- [ ] Medical terms: `acte` (procedure) against `soin` (care) and
      `intervention`; `conseil` for counseling; `Assurance maladie obligatoire`
      and `Aide médicale (type 1)` and `(type 2)`, which stand in for the Korean
      insurance and medical aid; the French names of the diagnoses of ICD-10
      (`Mélasma` for `Chloasma`); the findings and plans of the SOAP notes
      (`Macules brunes mal délimitées sur les deux régions malaires`,
      `Rides dynamiques du front, grade 2`); `Fébricule`, `TA`, `FC`; the
      results of the eligibility, interaction, and claim checks
      (`Droits vérifiés`, `Couverture résiliée`, `Aucun assuré correspondant`).
- [ ] Legal texts: the consent forms and their disclaimer, which no lawyer has
      read, and `Consentement relatif aux données personnelles`, which a
      reviewer may want to align with the vocabulary of the GDPR in a French
      notice.
- [ ] Financial terms: `marge` for the exchange spread (`Remise de 80 % sur la
      marge USD`), `encours disponible`, `prélèvement automatique`,
      `référentiel de facturation`, the 20% VAT, the plan prices (69, 149, 259,
      and 499 €), and the scale of the prepaid wallet.
- [ ] Role titles are written in the masculine (`Infirmier diplômé d’État`,
      `Aide-soignant`, `Esthéticien`, `Conseiller patient`, `Coordinateur de
      soins`, `Collaborateur`). A reviewer may prefer a double form or an
      epicene title.
- [ ] The marker `(fictif)` stays masculine after a feminine noun (`Zone de
      culture de Clairval (fictif)`). It is one tag, so that the safety scan
      can test one string; a reviewer may prefer an agreeing form.
- [ ] `Enseignant(e) {name1}` and `{name1} (responsable légal)`, which avoid a
      gender and a preposition that the drawn name would break.
- [ ] The fictional places and names (`Clairval`, `Rivebleue`, `Frênaie`,
      `Aulnaie`, `Jardin du Sablier`, `Ciel de Lin`, and the shops, banks,
      insurers, and publishers) do not name a real place, brand, or person.
- [ ] The Pilates terms (`Tapis`, `Reformer`, `Chaise`), the daycare
      vocabulary (`Classe du Soleil`, `responsable légal`), and the logistics
      terms (`chargeur`, `plateforme logistique`, `loge du gardien`).
- [ ] The plate pattern `42●● AB 17`, and the notification templates, whose
      variables are `#{nom}`, `#{clinique}`, `#{date_heure}`, `#{heure}`, and
      `#{lien}`.
