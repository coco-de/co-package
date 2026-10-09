# Russian (`ru`)

status: localized

Native name: русский. National locale: `ru_RU`. Currency: ruble (`RUB`, `₽`).

The status line above is read by the tests of the package. `localized` means
that the three data sets of the language are written: the domain text bundle
(`lib/src/l10n/ru/ru_bundle.dart`), the clinic data (`ru_clinic.dart`), and the
SaaS data (`ru_saas.dart`). The language passes its gate:

```sh
dart run co_faker:coverage --language ru --strict
```

**The translation is a draft written with an AI assistant. A native speaker of
Russian has to review it** (see the checklist at the end of this file) before an
application ships it as its own text. See [README.md](README.md) for the work,
the gate, and the format of this file.

`ru`, `ru_RU`, `ru-RU`, and `CoFaker.forLanguage('ru')` all read the same
Russian domain text, clinic data, and SaaS data.

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
| Patient | пациент | `больной` | The word of a record, a notice, and a consent form; `больной` is the colloquial one and reads as a patient who is ill, not as a person of a clinic. |
| Appointment (a booked place) | запись | `аппойнтмент` | A booking of a visit is a `запись` (`Запись оформлена`, `Запись отменена`); the English word is not used. |
| Visit (to a clinic) | приём | `визит к врачу` | The visit of a patient to a physician is a `приём` (`Первичный приём`, `Повторный приём`, `Приём возобновится`). |
| Visit (to a venue or a home) | визит | - | A first visit to a shop, a restaurant, or a home service is a `визит`; a clinic visit is a `приём`. |
| Consultation | консультация | `консилиум` | The visit purpose and the stage of a visit with a physician. A `консилиум` is a meeting of several physicians. |
| Counseling | консультирование | `каунселинг` | One word for the stage of the visit, the room (`Кабинет консультирования 1`), and AI counseling (`ИИ-консультирование`); the counselor is a `консультант`. |
| Procedure (medical) | процедура | `манипуляция` | What a clinic does to a patient (`Процедура`, `Процедурный кабинет 1`); the catalog entries keep their own names (`Экстракция комедонов`). |
| Care (of the skin) | уход | - | A facial or a soothing care (`Уход за лицом`), and the long-term care of a person at home (`Уровень ухода 1`). |
| Session | сеанс | `сессия` | A session of a package or a treatment (`сеансов в курсе`); `сессия` is an exam period or a working meeting. |
| Class (a lesson of a studio) | занятие | - | A class of Pilates or yoga is a `занятие`; a session of a treatment is a `сеанс`. |
| Package (of sessions) | курс | - | A package of sessions is a `курс` (`Курс`, `С курсом процедур`); a pass of a studio is an `абонемент`. |
| Pass (of a studio) | абонемент | - | The pass of a studio or a month (`Абонемент на 10 занятий`, `Месячный абонемент`). |
| Prepaid balance | предоплаченный остаток | `аванс` | A balance paid in advance and used later; `аванс` is an advance on a salary or a contract. |
| Medical certificate | медицинская справка | - | The document that a physician issues. |
| Physician | врач | `доктор` | The role and the title; `доктор` is a form of address and a degree. |
| Medical Director | главный врач | - | The head of a clinic and the first role of the staff list. |
| Nurse | медсестра / медбрат | `медицинская сестра` | The role is written with both forms, because the staff name that goes with it is drawn without a sex. |
| Aesthetician | косметолог | `эстетист` | The usual title of the person who does skin care in a clinic. |
| Front desk | ресепшен | `рецепция`; `стойка регистрации` | The place, the source of a check-in, and the line of a sender; the staff role is `Администратор ресепшена`. |
| Check-in | регистрация | `чекин`; `чек-ин` | The first stage of a visit, and the check-in on a tablet or a terminal. |
| Guardian (legal) | законный представитель | `опекун` | One term for the daycare, the consent text, and the relation label; an `опекун` is a guardian that a court appoints. |
| Teacher (of a daycare) | воспитатель | `учитель` | The title for a woman and for a man in a daycare group; an `учитель` teaches at school. |
| Invoice | счёт | `инвойс` | The document that asks a customer to pay. |
| Payment (a stage) | оплата | - | The stage of a visit, the label of a status, and the name of a topic (`Оплата`). |
| Payment (a transaction) | платёж | - | A card payment that is approved or declined (`Платёж по карте одобрен.`), and the payment gateway (`Платёжный шлюз`). |
| Refund | возврат | `рефанд` | The same word for a refund of a payment, of a credit, and of an invoice. |
| Insurance claim | заявка на возмещение | `клейм` | A request for payment sent to an insurer; the short form is `заявка`. |
| Quote (a price offer) | предложение | `котировка` | The offer of a price before the work (`Кредит на отправку предложения`); a `котировка` is a price on a market. |
| Coupon | купон | `промокод` | One word for every coupon of a campaign, a visit, or a delivery. |
| Credit (message credit) | кредит | `ссуда` | A unit that a customer buys and spends (`кредитов на сообщения`), never a loan; a reviewer may prefer `сообщения` or `баллы`. |
| Subscription plan | тариф | `тарифный план` | The offer a customer subscribes to: `Старт`, `Стандарт`, `Профи`, `Корпоративный`. |
| Tenant (customer of the vendor) | клиника | `арендатор`; `тенант` | The clinic that holds an account of the software; an `арендатор` is a renter of a flat. |
| Claim master | справочник заявок | `мастер-справочник` | The reference tables of fees, drugs, materials, and diagnoses that claims are checked against. |
| EMR (electronic medical record) | ЭМК (электронная медицинская карта) | `ЭМР` | The usual Russian abbreviation of the software, and the chart of a patient is a `карта`. |
| Electronic prescription | электронный рецепт | `е-рецепт` | The document that a physician sends to a pharmacy. |
| Release (of software) | релиз | `билд` | The title of a release is `Заметки о релизе`. |
| Notification template | шаблон | `темплейт` | A message with variables; the variables are written in Russian (`#{имя}`). |
| Support (customer support) | поддержка | `саппорт` | The team and the role (`Поддержка клиентов`, `Поддержка`). |
| Autopay | автоплатёж | `автопей` | The payment that a card makes by itself each month. |
| Maintenance | техническое обслуживание | - | The notice says `техническое обслуживание` and a label the short `Техобслуживание`: one term, written in full in a sentence. |
| Delivery | доставка | `деливери` | The same word for a delivery and a shipping benefit. |
| Hub (logistics) | хаб | - | The place where parcels are sorted and sent on (`Логистический хаб`). |
| Cargo owner (shipper) | грузовладелец | - | The freight term for the party that owns the goods. |
| Carrier (logistics) | перевозчик | `кэрриер` | The company that transports the goods. |
| Spread (exchange margin) | спред | - | The margin of a bank on an exchange rate (`Скидка 80 % на спред`). |
| Bank transfer | банковский перевод | `трансфер` | `трансфер` is a transfer of a passenger or of a player, not of money. |
| Cancellation | отмена | - | The act of cancelling an appointment, a booking, or a class (`Отменено`). |
| No-show | неявка | `ноу-шоу` | A status of a visit (`Неявка`) and the note of a class or a queue. |
| Fictional | вымышленный | `фиктивный`; `выдуманный` | The marker is the one tag `(вымышленное название)` after every fictional name, whatever the gender of the noun. A sentence agrees (`Вымышленный город`). `фиктивный` means sham, a false friend. |
| Example | пример | - | `(пример)` after a sample label, `Пример …` where English begins with `Example`. |
| Sample (a word of a clinic name) | образец | - | A clinic is called `Образец` or `Демо` in the list of names, as English has `Sample` and `Demo`. |
| Demo | демо | - | `(демо)` after a place and `демо-правило` for a rule; a sentence says `демонстрационный`. |
| Weekend | выходные | `уикенд`; `викенд` | The plural noun (`Выходные в Бангкоке`, `в выходные`). |
| E-mail | электронная почта | `имейл`; `емейл` | The label of a channel. |
| Wi-Fi | Wi-Fi | `вай-фай`; `вайфай` | The name of a technology, written in Latin letters as Russian does. |
| Parking | парковка | `стоянка` | The place for a car, in the word that a customer says. |
| Kiosk | терминал | `киоск` | A self-service terminal of the clinic; a `киоск` is a street stall. |
| Router | маршрутизатор | `роутер` | The term of the exam question; `роутер` is the colloquial one. |
| Hash function | хеш-функция | `хэш` | The spelling `хеш`, written the same in every text. |
| Neurotoxin | ботулотоксин | `ботокс` | The name of the substance, not the trademark of a product. |
| Acne | акне | `прыщи`; `угри` | The term of a dermatologist (`Акне вульгарное`). |
| Laser toning | лазерный тонинг | - | The usual name of the procedure in a Russian clinic. |
| Hyaluronic filler | гиалуроновый филлер | - | The material of a lip procedure. |
| Brown rice | бурый рис | `коричневый рис` | The usual name of the grain; a coat colour is `Коричневый`. |
| Group deal | совместная закупка | `групповая покупка` | The Russian name of buying together. |
| Booking (of a space, a stay, a table) | бронирование | `букинг` | A space, a stay, a table, or a class is `забронировано`; a visit to a physician is a `запись`. |
| Neighborhood (a small area) | микрорайон | - | The smaller unit of a city, under a `район`. |
| District | район | - | The larger unit of a city. |
| Solbit (fictional district) | Светлоборье | `Солбит` | The fictional places of Russian are invented names that sound Russian, in guillemets after a noun, not the Korean ones of the English data. |
| Garam (fictional district) | Ясноречье | `Гарам` | A fictional place, written in guillemets after a noun. |
| Mulpare (fictional district) | Ясеневая Заводь | `Мульпаре` | A fictional place, written in guillemets after a noun. |
| Solnae (fictional district) | Сосноручье | `Солнэ` | A fictional place, written in guillemets after a noun. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`1 234,00 ₽`, no-break space) | `1 234,56 ₽`: a no-break space (U+00A0) between thousands, a comma before the two kopecks, and a no-break space before `₽`. `CoCurrencyFormat(code: 'RUB', symbol: '₽', pattern: '{amount} {symbol}', groupSeparator: ' ', decimalSeparator: ',', fractionDigits: 2)`, with U+00A0 for each space. The price bands are what a private clinic charges in rubles (a first visit 3 000 to 8 000 ₽, a laser session 6 000 to 18 000 ₽, a HIFU session 30 000 to 110 000 ₽), not the dollars of the English data multiplied, and the units are those of a ruble price: 100 ₽ for a price, 500 ₽ for a package, 100 ₽ for an adjustment, 10 ₽ for a point, a card payment in installments from 30 000 ₽. The plans cost 4 900, 9 900, 17 900, and 34 900 ₽ a month, the prepaid wallet is topped up from 1 000 to 50 000 ₽ with a bonus from 3 000 ₽, and the VAT of an invoice is 22%, the rate of Russia since 1 January 2026 (Federal Law No. 425-FZ; 20% before). |
| Dates and times | A numeric date is `08.10.2026` (day, month, and year with dots and two digits for the day and the month). In prose a long date is `8 октября 2026 г.`, with the month in the genitive; no text of the language writes one, because a generator gives a template no month name. A closure notice writes `25.11 (ср)` (`{day}.{month} ({weekday})`) and a range `с 25.11 (ср) по 26.11 (чт)`; the weekdays are the two-letter lower-case `пн`, `вт`, `ср`, `чт`, `пт`, `сб`, `вс`. The time is the 24-hour clock `18:00`, a range of hours is `06:00–07:00` with an en dash, and a time after a preposition is `в 18:00`. |
| Numbers: separators and units | A decimal comma and a no-break space between thousands (`1 000`, `2 400 000`). A no-break space stands between a number and its unit (`500 г`, `10 мг`, `2 кг`, `350 мл`, `24 часа`), before `%` (`20 %`), and before `°C`; `№` is followed by a no-break space (`Пикосекундный лазер № 2`), and `мм рт. ст.` has no-break spaces. |
| Punctuation and quotation marks | Guillemets `«…»` for a name and for a title; no other quotation mark is written. An em dash with spaces `—` between clauses, and an en dash without spaces for a range (`06:00–07:00`, `шесть–двенадцать`). A sentence ends with a full stop and a label does not. |
| Register: `вы` or `ты` | `вы` in every text that speaks to a patient or a customer. A sentence that speaks to a person uses the plural imperative with `Пожалуйста,` (`Пожалуйста, позвоните в домофон у общего входа.`); a notice or an instruction that says nobody in particular uses the impersonal form (`Передать лично в руки.`); and a first-person line of a patient or a customer is in the present or the future tense (`Хочу присоединиться к занятиям.`, `Я подумаю и свяжусь с вами.`) or has no verb, because the past tense of the first person has a gender. `ты` is never written. |
| Case, gender, and number agreement in a template that a value fills | A template puts no case ending on a value: a name stands first (`{target}: регистрация одобрена.`), after a colon (`Пациент: {patient}.`), in parentheses (`{name1} (законный представитель)`), or after a title that fits any name (`Воспитатель {name1}`). A count never stands before a noun that would have to agree with it: it follows its label (`Гостей: {n}`, `Заявок отправлено: {n}`, `Строк: {n}`, `Подтема {n}`, `Спринт {n}`) or it is a sign (`×5`). A text with a fixed number writes the form that it needs by hand: `1 год`, `2 года`, `5 лет`; `1 пара`, `3 шт.`; `у 3 клиник`, `по 7 счетам`, `1 000 кредитов`. A status is a noun, a neuter, or a verb without gender (`Неявка`, `Забронировано`, `Действует`), and a title of a role that has two forms writes both (`Медсестра / медбрат`, `Супруг / супруга`). A level is an adjective before `уровень` (`Пилатес на реформере, начальный уровень`). |
| The letter `ё` | Always written (`всё`, `неуточнённая`, `Тёплый`, `Звёздочка`, `отёка`), as the Russian data of the basic modules does (`Артём`, `Фёдоров`). |
| Transliteration of names and loanwords | A loanword is written in Cyrillic by its usual spelling (`лазер`, `филлер`, `хаб`, `спред`, `бэклог`, `снек`), and the acronyms and names that Russian writes in Latin letters stay (`Wi-Fi`, `HTTP`, `TCP`, `SQL`, `CSV`, `HIFU`, `SMS`, `Visa`). A coined name is a Russian word or compound in guillemets after a common noun (`Пекарня «Светлоборье»`), never a transliteration of the Korean name of the English data. |
| The marker of a fictional name, a sample, and a demo | `(вымышленное название)` after a fictional name, `(пример)` after a sample label, `(демо)` after a demo place, and `(демо-правило)` after a demo rule: one invariant tag for each, whatever the gender of the noun before it. A sentence says `вымышленный` or `вымышленная` and agrees; an English text that begins with `Example` begins with `Пример …`. |
| A clinic name | The kind of place first, then the name in guillemets: `Детская клиника «Образец»` (`clinicNameFormat: '{suffix} «{prefix}»'`). |
| Names, places, and brands | No real brand, person, or institution: the places are invented (`Светлоборье`, `Ясноречье`, `Ясеневая Заводь`, `Сосноручье`), the creators are `Сад песочных часов` and `Небесная нить`, the insurers, the bank, and the businesses are invented names, and the drug names are invented stems (`Адермекс`, `Люмисол`, `Кераплен`, `Диоклин`, `Навирокс`, `Сератон`, `Минобел`, `Акрозин`) that a web search found on no registered product. The card networks of the English data stay (`Visa`, `Mastercard`, `Amex`) and `Мир` replaces the fourth. |

## Differences from the English data

- The Instagram channel of the English data is `Реклама в соцсетях`, so that no
  brand of a platform is written; its code (`instagramAd`) is unchanged.
- A paper cup of 12 oz is written `350 мл`, the unit of a Russian trader.
- `Discover`, a card network that Russia does not use, is `Мир`, the domestic
  one.
- The insurance of the Korean data is `Обязательное медицинское страхование`
  (the code `nhis`), and the medical aid is `Льготное обслуживание (тип 1)` and
  `(тип 2)`; they name no Russian scale.
- The long-term care grades of the Korean data become `Уровень ухода 1` to `5`
  and `Уровень когнитивной поддержки`. They name no Russian scale.
- The ID of a patient is masked in the shape of a Russian insurance account
  number (`***-***-482 19`), and the business number of a tenant is ten digits,
  as the INN of a company is. Both are random digits.
- A plate is masked as `АВ 42●● 17`: two letters of the set that a Russian plate
  uses, a number with `●●` hiding two digits, and a region code.
- An address goes from the city to the street (`Омск, ул. Школьная, д. 5`), and
  a clinic name from the kind of place to the name (`Детская клиника «Клён»`).

## Known limits

What the gate cannot see, and the generators write the same in every language:

- In `ru_RU`, `clinic.patient()`, `clinic.staff()`, and `saas.operator()` compose
  the name from a given name and a surname that they draw one after the other,
  so a woman's given name comes with the masculine form of a surname
  (`Анна Кузнецов`), as it has since 0.11.0. The role `clinic.patientName`,
  `clinic.guardian()`, `saas.tenant().ownerName`, and `person.fullName()` pick
  the surname that agrees. The data of the language cannot change it.
- `clinic.approvalNo`, the role `saas.recipient`, and the fields `rrnMasked` of
  `clinic.patient` and `businessNumber` of `saas.tenant` that `schema.entity`
  infers to the Korean resident and business registration numbers follow the
  Korean number formats in Russian as in every language. Russian data cannot
  change them with its own files.
- When the `korea` pack is registered beside the others, a field such as
  `phone` or `address1` of an entity is inferred to a Korean role (`010-…`, a
  road-name address), in Russian as in every language; the gate runs the
  entities without that pack.
- `CoClinicHours`, the default opening hours of the schedule and the heatmap,
  are those of a Korean dermatology clinic (Sunday closed). They are numbers.
- `clinic.inquiry()` and `messengerHandle()` do not follow the locale: they are
  threads of a Korean inbox, written in Korean, English, Japanese, Chinese, and
  Vietnamese, and never in Russian.
- The gate runs `CoFaker.forLanguage('ru')`. `CoFaker(locale: 'ru')` reads the
  same Russian data but has no country, so the address of a patient there is
  the one that the basic modules write.
- A generator writes a number as a plain number, so a temperature that a vitals
  note carries has a point and not a comma (`36.6 °C`), and the glucose is in
  `мг/дл`, which a Russian laboratory writes in `ммоль/л`.
- A date label has the number of the month and of the day only, without a zero
  (`25.9 (пт)`, not `25.09 (пт)`), and the generators give a template no month
  name, so a notice cannot say `25 сентября`.
- The data of a language that is not Korean has no public holiday, so a closure
  notice gives a reason; the `holiday` template is written for a custom data
  set that has a calendar.
- The wallet of `saas.prepaidLedger` reads the top-ups and the bonus tiers of
  the data (rubles), while the static `CoFakerSaas.prepaidBonusTiers` and
  `prepaidBonus(amount)` stay the Korean tiers in every language.

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text: `вы`,
      `Пожалуйста,` and the plural imperative, and no past tense of the first
      person.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
- [ ] Medical terms: `приём`, `консультация`, and `консультирование`, which are
      three words for the visit, the consultation with a physician, and the
      talk with a counselor; `процедура` against `уход` and `сеанс`;
      `Обязательное медицинское страхование` and `Льготное обслуживание (тип 1)`
      and `(тип 2)`, which stand in for the Korean insurance and medical aid;
      `Уровень ухода 1` to `5`, which stand in for the Korean care grades; the
      Russian names of the diagnoses of ICD-10 (`Акне вульгарное` for `Угри
      обыкновенные`, `Хлоазма`, `Розацеа неуточнённая`); the findings and plans
      of the SOAP notes (`Нечётко очерченные коричневые пятна в обеих скуловых
      областях`, `Динамические морщины лба, степень 2`, `Лёгкая эритема, отёка
      нет`); `АД`, `ЧСС`, `Субфебрильная температура`; the procedure names
      (`Ботулотоксин, лоб`, `Гиалуроновый филлер, губы, 1 мл`, `Экстракция
      комедонов`); the results of the eligibility, interaction, and claim checks
      (`Страховое покрытие подтверждено`, `Застрахованное лицо не найдено`,
      `Заявка скорректирована при проверке`).
- [ ] Legal texts: the consent forms and their disclaimer, which no lawyer has
      read, and `Согласие на обработку персональных данных`, which a reviewer
      may want to align with the vocabulary of Federal Law No. 152-FZ; the
      labels `Специальные категории данных` and `Передача третьим лицам`; the
      word `Реклама.` that an advertising message starts with; and
      `законный представитель`.
- [ ] Financial terms: `спред` for the exchange spread (`Скидка 80 % на спред по
      USD`), `предоплаченный остаток`, `автоплатёж`, `Прейскурант`,
      `справочник заявок` for the claim master, `заявка на возмещение` for the
      insurance claim, the 22% VAT, the plan prices (4 900, 9 900, 17 900, and
      34 900 ₽), the price bands of the procedures, and the scale of the prepaid
      wallet; `кредит` for a prepaid unit, which a reader may take for a loan.
- [ ] Role titles with two forms (`Медсестра / медбрат`, `Супруг / супруга`,
      `Брат / сестра`, `Бабушка / дедушка`, `Внук / внучка`) and the title
      `Воспитатель {name1}`, which fit a name that is drawn without a sex. A
      reviewer may prefer one form.
- [ ] The marker `(вымышленное название)` stays the same after every noun,
      including a nickname and a title. It is one tag, so that the safety scan
      can test one string; a reviewer may prefer an agreeing form.
- [ ] The templates that a value fills: `Гостей: {n}`, `Подтема {n}`,
      `Заявок отправлено: {n}`, `Строк: {n}`, `{name} ×{sessions}`,
      `{target}: …`, `{service}: …`, `{name1} (законный представитель)`, the
      closure notice (`Закрыто: 25.11 (ср)`, `с 25.11 (ср) по 26.11 (чт)`,
      `Причина: …`), and the counsel summary (`курс (сеансов: 3) — …`).
- [ ] The fictional places and names (`Светлоборье`, `Ясноречье`,
      `Ясеневая Заводь`, `Сосноручье`, `Колосья`, `Гинкго`, `Сад песочных
      часов`, `Небесная нить`, `Миродар`, and the shops, studios, insurers, and
      publishers) and the invented drug stems do not name a real place, brand,
      person, or product.
- [ ] The Pilates terms (`Мат-пилатес`, `Пилатес на реформере`, `Пилатес на
      стуле`), the daycare vocabulary (`Группа «Солнышко»`, `1 год`, `2 года`,
      `5 лет`), the logistics terms (`Грузовладелец`, `Логистический хаб`,
      `гидроборт`), and the dishes that the Korean data names (`Обед с супом из
      морской капусты`).
- [ ] The plate pattern `АВ 42●● 17`, the masked ID `***-***-482 19`, and the
      notification templates, whose variables are `#{имя}`, `#{клиника}`,
      `#{дата_время}`, `#{время}`, and `#{ссылка}`.
