# Portuguese (Brazil) (`pt`)

status: localized

Native name: português. National locale: `pt_BR`. Brazilian Portuguese (`pt_BR`). Currency: real (`BRL`, `R$`).

The status line above is read by the tests of the package. `localized` means
that the three data sets of the language are written: the domain text bundle
(`lib/src/l10n/pt/pt_bundle.dart`), the clinic data (`pt_clinic.dart`), and the
SaaS data (`pt_saas.dart`). The language passes its gate:

```sh
dart run co_faker:coverage --language pt --strict
```

**The translation is a draft written with an AI assistant. A native speaker of
Brazilian Portuguese has to review it** (see the checklist at the end of this
file) before an application ships it as its own text. See [README.md](README.md)
for the work, the gate, and the format of this file.

`pt`, `pt_BR`, `pt-BR`, and `CoFaker.forLanguage('pt')` all read the same
Portuguese domain text, clinic data, and SaaS data. The data is Brazilian: the
language setting `pt-PT` resolves to the same language, so it reads this data
and not a European one.

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
| Patient | paciente | utente | The word of a record and a notice in Brazil; `utente` is the European one. |
| Appointment, booking (a visit to the clinic or a service) | agendamento | compromisso | The booked visit of a patient or a customer: `Agendamento confirmado`, `Encontrar meu agendamento`. |
| Booking, reservation (a space, a table, or a stay) | reserva | booking | A space, a table, a stay, or a class is `reservado`; a visit to a physician is an `agendamento`. |
| Consultation | consulta | consultation | The visit of a patient to a physician, and the word of a status (`Consulta`). |
| Follow-up visit | consulta de retorno | consulta de seguimento; follow-up | `Retorno` is the Brazilian word for a return visit; `seguimento` is European. |
| Procedure (medical) | procedimento | - | What a physician performs; a `tratamento` is a course of care and a `cuidado` is a care of the skin. |
| Treatment | tratamento | - | The visit purpose and the course of care of a skin condition. |
| Care (of the skin) | cuidado | - | A facial or a soothing care that a care professional does. |
| Counseling | orientação | aconselhamento; counseling | One word for the stage of the visit (`Orientação`), the room (`Sala de orientação 1`), the counselor (`Orientador(a) de pacientes`), and AI counseling (`orientação por IA`). `Aconselhamento` is psychological counseling. |
| Session | sessão | seção | A session of a package or a treatment. It is plural in a package name (3, 5, or 10), so no template needs to agree. `Seção` is a section, a spelling that is easy to mistake. |
| Package (of sessions) | pacote | - | The Portuguese word for a package of sessions and for a fixed-price offer. |
| Prepaid balance | saldo pré-pago | saldo antecipado; prepago; pré pago | A balance paid in advance and used later; `pré-pago` has its hyphen. |
| Medical certificate | atestado médico | certificado médico | The document that a physician issues; `certificado` is a diploma. |
| Physician | médico(a) | doutor; médico/a | A title with both genders is written with `(a)`, as a form does. |
| Nurse | enfermeiro(a) | enfermeiro/a | The title of the profession, with `(a)`. |
| Nurse assistant | auxiliar de enfermagem | assistente de enfermagem | The role label of the staff that helps a nurse. |
| Aesthetician | esteticista | estetista | The role label; the word is epicene. |
| Front desk | recepção | receção | The staff role, the sender line, and the room; `receção` is the European spelling. |
| Care coordinator | coordenador(a) de cuidados | coordenador/a | The role label of the person who follows a patient across the visit. |
| Guardian | responsável | tutor; guardião; encarregado de educação | One term for the daycare, the consent text, and the relation label. `Tutor` is a guardianship ordered by a court; `encarregado de educação` is the European school term. |
| Teacher | professor(a) | professor/a | The name that follows is drawn without a sex, so both genders are written. |
| Insurance claim | guia de cobrança | sinistro; claim | The document that asks a health plan to pay for a procedure; `sinistro` is the claim of an accident. |
| Health plan | plano de saúde | seguro de saúde; seguro nacional | The coverage that most patients of the data have. The national scheme of Korea has no Brazilian equivalent, and no public institution is named. |
| Self-pay | particular | autopagamento | A private patient of a clinic. |
| Quote (estimate) | orçamento | cotação | The estimate of a price before the work, in the clinic and in a trade. |
| Refund | reembolso | refund | The same word for a refund of a payment and for the return of a credit. |
| Coupon | cupom | cupão; coupon | `Cupão` is the European form. |
| Tenant (customer of the vendor) | clínica | locatário; tenant | The clinic that holds an account of the software. `Locatário` is a renter of a flat. |
| Claim master | tabelas de referência de cobrança | claim master | The reference tables of fees, drugs, materials, and diagnoses that claims are checked against. |
| Fee schedule | tabela de honorários | - | The table of the fees of a physician. |
| Medical record, chart | prontuário | processo clínico | The Brazilian word for the record of a patient; `processo clínico` is European. |
| EMR (electronic medical record) | PEP | - | The usual Brazilian abbreviation of the software (`prontuário eletrônico do paciente`). |
| Electronic prescription | receita eletrônica | e-prescription; prescrição eletrônica | The document that a physician sends to a pharmacy. |
| Release (of software) | versão | release | The title of a release is `Notas da versão`. |
| Notification template | modelo | template | A message with variables; the variables are written in Portuguese (`#{nome}`). |
| Support (customer support) | suporte | - | The team, the role, and the department. |
| Autopay | cobrança automática | autopay; débito automático | The payment that a card makes by itself each month. |
| Delivery | entrega | delivery | The same word for a delivery and a shipping benefit. |
| Hub (logistics) | centro de distribuição | hub | The place where parcels are sorted and sent on. |
| Cargo owner (shipper) | embarcador | expedidor | The freight term for the party that ships the goods. |
| Carrier (transport company) | transportadora | carrier | The company that transports the goods. |
| Carrier (mobile network) | operadora | - | The telephone company that delivers a message. |
| Spread (exchange margin) | spread | margem cambial | The word that a currency exchange uses for its margin. |
| Cancellation | cancelamento | - | The act of cancelling an appointment, a booking, or a class. |
| No-show | faltou | no-show; não comparecimento | A status that qualifies an `agendamento`, so it is a verb; the noun of a note is `falta`. |
| Check-in (stage of a visit) | recepção | - | The first stage of a visit, in the clinic. |
| Checked in | chegou | - | The status of a patient that has arrived. |
| Desk (a source of a check-in) | balcão | - | The counter where a patient checks in. |
| Fictional | fictício | fictional; (fictícia); ficticio | The marker is the one tag `(fictício)` after every fictional name, whatever the gender of the noun. A sentence agrees (`Cidade fictícia`). |
| Example | exemplo | example; sample | `(exemplo)` after a sample label, `Exemplo de …` where English begins with `Example`. |
| Demo | demo (a label); de demonstração (a sentence) | - | `demo` follows a noun or stands in parentheses; a sentence says `de demonstração`. |
| Weekend | fim de semana | weekend; fim-de-semana | The spelling of Brazil, with no hyphen. |
| E-mail | e-mail | email; correio eletrónico | The label is written with a hyphen. |
| Online | on-line | online | The spelling of the Brazilian orthography, with a hyphen. |
| Team | equipe | equipa de; da equipa; a equipa | `Equipa` is the European spelling. |
| Screen | tela | ecrã | `Ecrã` is the European word. |
| File | arquivo | ficheiro | `Ficheiro` is the European word. |
| Bathroom | banheiro | casa de banho | `Casa de banho` is the European phrase. |
| Breakfast | café da manhã | pequeno-almoço; pequeno almoço | `Pequeno-almoço` is the European word. |
| Minibar | frigobar | minibar | The Brazilian word of a hotel. |
| Refrigerator | geladeira | frigorífico | `Frigorífico` is the European word. |
| Invoice | fatura | invoice; nota fiscal | The bill that asks a customer to pay. A `nota fiscal` is the tax document, which no text writes. |
| Billing (a topic of support) | cobrança | billing | The topic of the payments and the invoices of a customer. |
| Top-up (of a balance or credits) | recarga | top-up | The credit that a customer buys and adds to a balance. |
| Message credit | crédito de mensagens | - | A unit that a customer buys and spends: message credits and quote credits. |
| Plan (Starter) | Inicial | starter | The first plan: `Inicial`, `Padrão`, `Profissional`, `Empresarial`. |
| Plan (Standard) | Padrão | standard | The second plan. |
| Plan (Enterprise) | Empresarial | enterprise | The fourth plan. |
| Outage | interrupção | outage; queda de serviço | The incident kind and the status of a service. |
| Sign-in | login | iniciar sessão; início de sessão | `Início de sessão` is the European phrase. |
| Sign-up, registration of an account | cadastro | registo | `Registo` is the European spelling of `registro`. |
| Record (a row of data) | registro | registo | The Brazilian spelling. |
| Fictional drug stems of the English data | Brolivex, Quenadil, Tarmovin, Selquira, Pimorel, Corvelin, Olvetrix, Avelmora | Adermex; Lumisol; Keraphen; Dioclin; Navirox; Seraton; Minobel; Acrozine | The stems are invented names that were each searched for and not found as a medicine; `Lumisol` of the English data is the name of a marketed product, so it is not used. |
| Solbit (fictional district) | Luzvale | Solbit | The fictional places of Portuguese are invented names that sound Brazilian, not the Korean ones of the English data. |
| Garam (fictional district) | Ribazul | Garam | A fictional place; it follows `bairro`, `zona`, or `de`. |
| Mulpare (fictional district) | Jacarandal | Mulpare | A fictional place. |
| Solnae (fictional district) | Solriacho | Solnae | A fictional place. |
| Field (fictional growing zone) | Campoalvo | - | A fictional place that stands for the fields of a farm. |
| Nuri (fictional partner bank) | Lumarante | Nuri | The invented bank name; it names no real bank. |
| Onsae (fictional cafe) | Brisa Mansa | Onsae | The invented name of a buyer. |
| Mildam (fictional bakery) | Farinha Fina | Mildam | The invented name of a buyer. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`R$ 1.234,56`) | `R$ 1.234,56`: the symbol first, a no-break space (U+00A0) after it, a dot between thousands, and a comma before the two centavos. `CoCurrencyFormat(code: 'BRL', symbol: r'R$', pattern: '{symbol}\u00A0{amount}', groupSeparator: '.', decimalSeparator: ',', fractionDigits: 2)`. A negative amount is `-R$ 80,00`. The price bands are in reais at about four and a half times the dollar bands (a first consultation R$ 400 to 900, a picosecond laser session R$ 900 to 2.200) and the units are those of a Brazilian price tag: R$ 10 for a price, R$ 50 for a package and a prepaid step, R$ 5 for a discount, a point, and a share of a split payment. A card payment in installments (`parcelado`) starts at R$ 600, and a split payment at R$ 250. The tax of an invoice is the 5% that is the highest rate of the ISS, the municipal tax on services (the municipalities charge from 2% to 5%). |
| Dates and times | A date in prose is `8 de outubro de 2026` and its numeric form is `08/10/2026`, with the day first. A closure notice writes `quinta-feira (8/10)` (`{weekday} ({day}/{month})`) and a range `de quarta-feira (25/11) a quinta-feira (26/11)`; the names of the weekdays are lower case. The clock has 24 hours, written `18h` (`18h30` with minutes): a range of hours is `8h às 21h`, and a delivery slot `Noite, 18h às 20h`. |
| Numbers: separators and units | A decimal comma and a dot between thousands (`1.000`). A no-break space between a number and its unit (`500 g`, `10 mg`, `2 mL`, `360 ml`, `48 mm`); the percent sign follows the number with no space (`10%`). `nº` (with the masculine ordinal sign) stands for a number and is followed by a no-break space (`Fototerapia LED nº 2`); `n.º` is European. |
| Punctuation and quotation marks | No space before `:`, `;`, `?`, and `!`. A quotation is written in curly double quotation marks (`Aviso “{target}” publicado.`), never in straight ones or in guillemets. A fictional name ends with `(fictício)` and a sample label with `(exemplo)`. A list of two roles of a person uses `·` (`@Ana Souza · Enfermeiro(a)`). |
| Register: `você`, `o senhor`, or `tu` | `você` in every text that speaks to a patient or a customer (`Você pode voltar ao trabalho logo em seguida.`). A notice or an instruction says `Por favor,` and the imperative of `você` (`devolva`, `confira`, `preencha`), which is the form of the subjunctive; a first-person line of a customer says `gostaria de` or `poderia` (`Poderia enviar as instruções de acesso?`). No text says `tu`, `teu`, or `vós`. |
| Gender and plural in a template that a value fills | A template avoids the agreement: `Mesa para {n}` (no plural), `{category}, nível {level}` (the level follows `nível`, which is masculine), `Responsável por {name1}`, `Professor(a) {name1}` (the name is drawn without a sex), `Agendamentos realizados: {n}` (the count follows the label), and `{n} linha(s)`. A status label is in the masculine, like a role title, or a verb (`Chegou`, `Faltou`). |
| Contractions with a value that a template fills | No template puts `de`, `do`, `da`, `dos`, `das`, `em`, `no`, `na`, `nos`, `nas`, `a`, `ao`, `à`, `por`, `pelo`, or `pela` right before a value that is not a number, because the contraction with the article (`de` + `a` = `da`, `em` + `o` = `no`) depends on the gender of the value. A value stands first in the sentence (`{target}: cadastro aprovado.`), after a colon (`Motivo: {reason}`), after `para` or `por` (which never contract with a name), or in parentheses. A number (`{n}`, `{sessions}`, a price) may follow `de` and `por`, and a date label follows `para`. The fixed fictional names that follow `de` are the names of places (`Corrida matinal de Luzvale`), written by hand and not by a template. |
| The marker of a fictional name and of a sample | `(fictício)` after a fictional name and `(exemplo)` after a sample label: one marker for each, whatever the gender of the noun. A sentence says `fictício` or `fictícia`, and an English text that begins with `Example` begins with `Exemplo de`. |
| A clinic name | The kind of place first, then the name: `Clínica de Pediatria Ipê`, `Clínica Médica de Demonstração` (`clinicNameFormat: '{suffix} {prefix}'`). Internal medicine is `Clínica Médica`, as in Brazil. |
| An address, a phone, and an ID | A street line and the city and state: `Rua das Flores, 123 - São Paulo - SP`, a postal code `01234-567`, a phone `(11) 91234-5678`. The ID of a patient is masked as a CPF (`***.123.456-**`) and the business number of a tenant is shaped as a CNPJ (`12.345.678/0001-90`). Both are random digits, and the CNPJ branch is random, so a number is very unlikely to be a registered one. |
| Names, places, and brands | No real brand, person, or institution: the places are invented (`Luzvale`, `Ribazul`, `Jacarandal`, `Solriacho`, `Campoalvo`), the creators are `Jardim da Ampulheta` and `Brisa de Linho`, and the insurers, the bank, and the businesses are invented names. The card networks of the English data stay (`Visa`, `Mastercard`, `Amex`) and `Elo` replaces the fourth, a network that Brazil has. |

## Differences from the English data

- The Instagram channel of the English data is `Anúncio em rede social`, so that
  no brand of a platform is written; its code (`instagramAd`) is unchanged.
- A paper cup of 12 oz is written `360 ml`, the size of a Brazilian trader.
- `Discover`, a card network that Brazil does not use, is `Elo`, a domestic one.
- The long-term care grades of the Korean data become `Nível de cuidado 1` to
  `5` and `Nível de apoio cognitivo`. They name no Brazilian scale.
- The national insurance of the English data is `Plano de saúde`; no public
  institution of Brazil is named, and the labels of the two medical aid types
  stay generic (`Assistência pública (tipo 1)`).
- The plate of a vehicle is masked as `●●C-1007`: two letters hidden by `●●`
  and the last letter and four digits of a Brazilian plate, so that a plate is
  never complete.
- The drug stems are eight invented names (`Brolivex`, `Quenadil`, …) and not
  the stems of the English data, because `Lumisol` of that data is the name of
  a marketed product.

## Known limits

What the gate cannot see, and the generators write the same in every language:

- `clinic.approvalNo`, the role `saas.recipient`, and the fields `rrnMasked` of
  `clinic.patient` and `businessNumber` of `saas.tenant` that `schema.entity`
  infers to the Korean resident and business registration numbers follow the
  Korean number formats in Portuguese as in every language. Portuguese data
  cannot change them with its own files.
- When the `korea` pack is registered beside the others, a field such as
  `phone` or `address1` of an entity is inferred to a Korean role (`010-…`, a
  road-name address), in Portuguese as in every language; the gate runs the
  entities without that pack.
- `CoClinicHours`, the default opening hours of the schedule and the heatmap,
  are those of a Korean dermatology clinic (Sunday closed). They are numbers.
- `clinic.inquiry()` and `messengerHandle()` do not follow the locale: they are
  threads of a Korean inbox, written in Korean, English, Japanese, Chinese, and
  Vietnamese, and never in Portuguese.
- The gate runs `CoFaker.forLanguage('pt')`. `CoFaker(locale: 'pt')` reads the
  same Portuguese data, and `CoFaker.forLanguage` and `locale: 'pt'` both give a
  Brazilian patient; only the national locale `pt_BR` has the postal address
  of a Brazilian city and state.
- A generator writes a number as a plain number, so a temperature or a
  decimal that a vitals note carries has a point and not a comma (`36.4 °C`).
- A date label (`quinta-feira (8/10)`) has the day and the month without a
  leading zero and no year, which is how the generators fill it, so a notice
  cannot say `08/10/2026`.
- The payment methods of the clinic and the SaaS are the codes `card`, `cash`,
  `transfer`, `prepaid`, and `virtualAccount`: Brazil's instant payment and its
  bank slip have no code, and the virtual account of Korea is `Conta virtual`.
- The weights of the insurance types are those of the English data (80% of the
  patients have the `nhis` code), so most patients read `Plano de saúde`.

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text: `você`, and
      `Por favor,` with the imperative in a notice.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
- [ ] Medical terms: `procedimento` against `tratamento` and `cuidado`;
      `orientação` for counseling (a reviewer may prefer `consulta de
      avaliação`, which aesthetic clinics use); `Cloasma` for the ICD-10 name
      of `Chloasma` (people say `melasma`); the findings and plans of the SOAP
      notes (`Máculas acastanhadas mal delimitadas nas duas regiões malares`,
      `Rugas dinâmicas da testa, grau 2`); `Febrícula`, `PA`, `FC`; the results
      of the eligibility, interaction, and claim checks (`Cobertura
      verificada`, `Cobertura encerrada`, `Nenhum beneficiário correspondente`).
- [ ] Insurance terms: `Plano de saúde` for the national insurance of the
      English data, `Assistência pública (tipo 1)` and `(tipo 2)` for the two
      medical aid types, `Particular` for self-pay, and `guia de cobrança` for
      an insurance claim (the term of the Brazilian billing guides, which the
      texts do not name).
- [ ] Legal texts: the consent forms and their disclaimer, which no lawyer has
      read, and `Consentimento para tratamento de dados pessoais`, which a
      reviewer may want to align with the vocabulary of the LGPD.
- [ ] Financial terms: `spread` for the exchange margin (`Desconto de 80% no
      spread do USD`), `cobrança automática`, `tabelas de referência de
      cobrança`, the 5% tax (ISS) that is the highest rate of the law, the plan
      prices (R$ 299, 599, 1.099, and 2.199), the scale of the prepaid wallet,
      and `Conta virtual` for the virtual account.
- [ ] Role titles are written with `(a)` for both genders (`Enfermeiro(a)`,
      `Médico(a)`, `Diretor(a) clínico(a)`, `Coordenador(a) de cuidados`,
      `Orientador(a) de pacientes`). A reviewer may prefer the masculine title
      or a double form, and `Auxiliar de enfermagem` against `Técnico de
      enfermagem`.
- [ ] The marker `(fictício)` stays masculine after a feminine noun (`Pousada do
      viajante (fictício)`). It is one tag, so that the safety scan can test
      one string; a reviewer may prefer an agreeing form.
- [ ] `Professor(a) {name1}` and `Responsável por {name1}`, which avoid a gender
      and a contraction that the drawn name would break.
- [ ] The fictional places and names (`Luzvale`, `Ribazul`, `Jacarandal`,
      `Solriacho`, `Campoalvo`, `Jardim da Ampulheta`, `Brisa de Linho`, and
      the shops, banks, insurers, and publishers) do not name a real place,
      brand, or person: each coined name was searched for, and a generic name
      such as `Padaria Farinha Fina` may still be the name of a small business.
- [ ] The Pilates terms (`Solo`, `Reformer`, `Cadeira`, `Colchonete`), the
      daycare vocabulary (`Turma do Sol`, `responsável`), and the logistics
      terms (`embarcador`, `centro de distribuição`, `portaria`,
      `Saiu para entrega`).
- [ ] The plate pattern `●●C-1007`, and the notification templates, whose
      variables are `#{nome}`, `#{clinica}`, `#{data_hora}`, `#{hora}`, and
      `#{link}`.
- [ ] `Mudança de pequeno porte`, `Compra coletiva`, `Simulado`, `Raspagem`, and
      the regional words that the texts choose (`interfone`, `portaria`,
      `cardápio`, `plantão`).
