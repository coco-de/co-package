# Japanese (`ja`)

status: localized

Native name: 日本語. National locale: `ja_JP`.

The status line above is read by the tests of the package:

- `planned`: the language has no data yet. Its domain text bundle, clinic data,
  and SaaS data are empty stubs, and the language reads English.
- `localized`: all three are written. Change the line to `localized` in the same
  pull request that writes them: the tests compare it with the registries.

Japanese is `localized`: the domain text bundle (`lib/src/l10n/ja/ja_bundle.dart`,
252 keys), the clinic data (`ja_clinic.dart`), and the SaaS data (`ja_saas.dart`)
are written, and `dart run co_faker:coverage --language ja --strict` passes.
`CoFaker.forLanguage('ja')`, `CoFaker(locale: 'ja')`, and the national locale
`ja_JP` read the same data.

The translation is a draft written with an AI assistant, and it is not reviewed
by a native speaker yet: the checklist at the end of this file says what to look
at. See [README.md](README.md) for the work, the gate, and the format of this
file.

## Glossary

One row for each term that the texts use for the same thing, in English. A term
has one translation, and it is the only one that the texts of the language
write; the forbidden forms are the spellings that must not appear anywhere in
them (another variant, an English loanword, a term of another region). The
rationale says why. Separate forbidden forms with `;` or the full-width
`；`, and write each form in backticks if you like (a comma does not
separate them).

An English word that Japanese writes with two words, because it names two
things, has one row for each thing (`Consultation (medical exam)` and
`Consultation (advice)`).

| Source term (English) | Translation | Forbidden forms | Rationale |
| --- | --- | --- | --- |
| Clinic | クリニック | 診療所; 医院 | The facility in names, tags, and alerts (`皮膚科クリニック`, `3軒のクリニック`). The name of a clinic is a prefix and a specialty without a space. |
| Patient | 患者 | 患者さん; 患者さま; 病人 | Notices and labels say 患者. A text that names or addresses a person adds 様 in kanji (`{patient}様`, `患者様`). |
| Honorific for a customer | 様 | 殿 | The honorific of a patient or a customer is 様, written in kanji. Between colleagues the mention is `さん` (`@{name}さん`). |
| Customer | お客様 | お客さま; お客さん | The polite word of a shop, a restaurant, and a notice. |
| Staff | スタッフ | 職員; 従業員 | The word of a clinic and of a notice to the team. |
| Physician | 医師 | ドクター | The title of the role. A patient speaking of the doctor says 先生. |
| Medical director | 院長 | - | The head of the clinic, as Japanese clinics call the role. |
| Nurse | 看護師 | 看護婦; ナース | The official title since 2002, with no gender in it. |
| Counseling | カウンセリング | 面談 | The talk before an aesthetic procedure, as Japanese aesthetic clinics call it. |
| Consultation (medical exam) | 診察 | 受診 | The stage of the visit where the doctor sees the patient. |
| Consultation (advice) | 相談 | - | Tax, legal, and labor advice, and a consultation record. |
| Procedure | 施術 | 処置; 手術 | A cosmetic procedure of an aesthetic clinic. 手術 is surgery, which the data never means. |
| Treatment | 治療 | - | The medical treatment of a condition (acne, warts, a root canal). |
| Reception | 受付 | 受け付け; 受付け; うけつけ | The noun is 受付 with no okurigana. A verb avoids the okurigana form too (`承りました`, `受理しました`). |
| Appointment | 予約 | アポイント; アポ | The word of every booking screen. |
| Cancel (an appointment or a booking) | キャンセル | 取り消し; 取消; 取りやめ | One spelling for an appointment, a class, a group deal, and a card payment. |
| Cancelled (a subscription) | 解約済み | - | A contract is 解約, not キャンセル. |
| No-show | 無断キャンセル | ノーショー | The usual word of clinics and restaurants. |
| Package (a bundle of sessions) | 回数券 | パッケージ; コース | A bundle of sessions that is bought at once: `ピコレーザートーニング 5回券`. A course of lessons or a walk is not written コース in this data. |
| Prepaid balance | 前受金 | 預り金; プリペイド | The money that a patient paid before the procedure and that the clinic draws down. |
| Self-pay | 自費診療 | 自由診療 | The word that the clinic data uses for an uninsured visit. |
| Medical certificate | 診断書 | 診断証明書 | The document, with the usual short name. |
| Chart | カルテ | 診療録; チャート | The word of a Japanese clinic. |
| Medical records | 診療記録 | - | The records of the treatment, as the privacy consent lists them. |
| Drug (a system or a master) | 薬剤 | ドラッグ | The word of the drug interaction warning, the drug use check, and the claim master. A text for a patient says お薬. |
| Medication (said to a patient) | お薬 | - | The polite word of a questionnaire and a consent form (`お薬のアレルギー`). |
| Diagnosis (a disease name) | 傷病名 | 診断名 | The name of the disease in a claim and in the master. |
| Acne | ニキビ | にきび; 面皰 | Katakana, as the patient says it. The disease name is 尋常性ざ瘡. |
| Pigmentation | シミ | 染み | Katakana, as the patient says it. |
| Wrinkles | シワ | しわ; 皺 | Katakana, as the patient says it. |
| Neurotoxin | ボツリヌストキシン | ボトックス | The generic name: ボトックス is a trademark. |
| Insurance claim | 保険請求 | レセプト; 保険金請求 | The generic word. レセプト is the form that a claim is written on. |
| Claim master | 請求マスター | - | The master tables that a claim is checked against. |
| Fee schedule | 診療報酬 | - | The kind of master that holds the fees of the visits. |
| E-prescription | 電子処方箋 | 処方せん | 処方箋 in kanji. |
| Quote | 見積もり | 見積り; 御見積 | One spelling of the quote of a procedure, a trade, and a job. |
| Invoice | 請求書 | インボイス | インボイス is the tax invoice system, which the data does not mean. |
| Refund | 返金 | 払い戻し; 払戻し | One word for a payment, an invoice, and a credit. |
| Coupon | クーポン | 割引券 | The word of every promotion. |
| Discount | 割引 | 値引き | The word of a price list and a coupon. |
| Tenant | テナント | 契約者; 加盟店 | The customer of the SaaS, which is a clinic. |
| Role | 権限 | ロール | The permission of a staff member or an operator. |
| Operator | オペレーター | 運用者 | The person of the vendor who runs the back office. |
| Credit (message credit) | クレジット | 通数 | What a message uses up. |
| Notification | 通知 | プッシュ | A message that the app sends. |
| Notice | お知らせ | 告知 | A notice of the service or of a clinic. |
| Template | テンプレート | 雛形 | The text of a notification that has `#{variables}`. |
| Sender number | 発信番号 | 発信者番号; 送信者番号 | The number that a tenant sends from. |
| Fallback send | 代替送信 | フォールバック | Sending by SMS what the messenger could not send. |
| Outage | 障害 | 故障 | The word of a service status. |
| Maintenance | メンテナンス | 保守 | The word of a notice and an incident. |
| Integration | 連携 | 統合; インテグレーション | A service that the app is connected to. |
| Autopay | 自動引き落とし | 自動決済; 自動引落 | One spelling, with the okurigana. |
| Impersonate | 代理ログイン | なりすまし | An operator signs in as a tenant, with the consent of the vendor. |
| Hub | 拠点 | ハブ | The place where the parcels are gathered. |
| Zone | エリア | ゾーン; 区域 | A delivery area. |
| Cargo owner | 荷主 | 荷送人 | The company that sends the freight. |
| Parcel carrier | 配送会社 | 宅配業者 | The company of a parcel delivery. |
| Freight carrier | 運送会社 | 運送業者 | The company of a freight delivery. |
| Delivery | 配達 | デリバリー | The last mile to the door. |
| Line-haul | 幹線輸送 | - | The trunk transport between hubs. |
| Loading | 積み込み | 積込み; 積込 | One spelling, with the okurigana. |
| Currency exchange | 両替 | 為替交換 | The exchange of cash. |
| Bank transfer | 銀行振込 | 口座振替 | A payment by a transfer. |
| Pen name | ペンネーム | 筆名 | The name of a writer in a fictional work. |
| Episode | エピソード | - | One part of a series. |
| Month (counter) | か月 | ヶ月; ケ月; カ月; ヵ月 | One spelling for a period (`3か月`, `1か月パス`). |
| Handling | 取り扱い | 取扱い; 取扱 | One spelling of the noun (`個人情報の取り扱い`). |
| Handoff (between staff) | 申し送り | 申送り | The note that one staff member leaves for the next. |
| Handoff (of a deliverable) | 引き渡し | 引渡し; 引渡 | The hand-over of a piece of work, with the okurigana. |
| Cooked rice | ごはん | ご飯; 御飯 | Hiragana, as a menu and a nursery write it. |
| Sharing (giving a share) | おすそ分け | お裾分け | Hiragana for the first part. |
| All | すべて | 全て | Hiragana, as a public document writes it. |
| Web | Web | ウェブ; ウエブ | Latin letters, as the product names write it. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`¥`, no minor units) | `¥1,200`: the yen sign before the digits, a comma between thousands, no decimals (`CoCurrencyFormat(code: 'JPY', symbol: '¥')`), and the unit 円 is not written. A generated amount is a multiple of 10 yen: a procedure rounds to 500, a package and a prepaid balance to 1,000, and a discount, a split share, a rounding adjustment, and a point to 10. The prices of the catalog include the 10% consumption tax where the procedure is taxable. |
| Dates and times (era, weekday) | `10月8日（木）`: the month and the day without a leading zero, and the weekday in full-width brackets (`月火水木金土日`). A range is `10月8日（木）〜10月10日（土）`. The year is Gregorian and never an era name. A time is `9:00` and a range `9:00〜18:00`; in a sentence an hour is `午後3時`. |
| Numbers: separators and units | Digits are half-width ASCII with `,` between thousands (`1,000個入り`). A unit symbol follows the digits with no space (`10mg`, `37.5°C`, `2kg`); a product spec keeps the space before its piece count (`冷凍ポテト 10kg`, `紙袋 100枚入り`). |
| Punctuation (full-width marks, brackets) | `。` ends a sentence and `、` separates; `？` is full-width, and a label has no end mark. Brackets are full-width: `（例）` for an example, `（架空）` for a fictional name, `「…」` for a quotation, `【広告】` for an advertisement. `：` is full-width, the middle dot is `・`, and a range is `〜`. Latin letters and digits stay half-width, with no space between Japanese and Latin letters. |
| Register and honorifics (the style of a patient notice) | です・ます throughout, the narration of a story paragraph included (`content.chapterParagraph`). 様 follows a patient or a customer who is named or addressed (`{patient}様`, `{n}名様`), and さん follows a colleague (`@{name}さん`). A label or a list of findings is a noun phrase. |
| Counters | 回 for a time or a session (`3回`, `10回券`), 名 for a person in a notice (`3名様`), 件 for a record, a claim, or a notification (`7件`), 軒 for a clinic as a business, 枚 for a sheet or a towel, 個 for a piece, 通 for a certificate, and 部位 for a treated area. |
| Katakana for loanwords: the spelling to use | Full-width katakana only, never half-width. A word that ends in `-er`, `-or`, or `-ar` keeps the long-vowel mark (`プリンター`, `ルーター`, `コーディネーター`, `オペレーター`, `カウンセラー`), as the cabinet notice on loanwords recommends. `ヴ` is not used (`バーベキュー`, `レビュー`). |

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.

Medical, legal, and financial terms:

- [ ] `nhis` is `公的医療保険`, and `medicalAid1` and `medicalAid2` are
  `医療扶助（1種）` and `医療扶助（2種）`: Japan has no two types of medical aid,
  so these are the closest names of the Korean concepts. Check whether another
  label of a public insurance would read better.
- [ ] The integration results use the terms of a Japanese claim: `保険資格を確認`,
  `査定` for an adjusted claim, `返戻` for a returned one, `受理` for an accepted
  one. The claim master kinds are `診療報酬`, `薬価`, `医療材料`, and `傷病名`.
- [ ] `前受金` (prepaid balance) against `預り金`, and `回数券` (a package of
  sessions) against `コース`, which an aesthetic clinic may prefer.
- [ ] The consent forms and the privacy clauses (`個人情報の取り扱いに関する同意書`,
  `要配慮個人情報`, `第三者提供`) read as a Japanese consent form does; they are
  examples and not legally reviewed.
- [ ] `ボツリヌストキシン` is written for the generic name of the injectable, and
  `SNS広告` stands for the English `Instagram ad`, so that no trademark is in the
  text. The card networks `Visa`, `Mastercard`, `Amex`, and `JCB` are the names of
  real payment networks, as in the English data.
- [ ] The names of the diseases are the standard names of the master
  (`尋常性ざ瘡`, `肝斑`, `ウイルス性疣贅`, `酒さ`).
- [ ] `HIFUリフトアップ 300ショット` (English `300 lines`) and `ピコレーザートーニング`
  against the names that clinics use, and the price bands, which are written for
  a Japanese aesthetic clinic with tax included.
- [ ] The tax example of the SaaS data is a 10% consumption tax, the plan prices
  end in `800`, and a tenant's business number has 13 digits.

Fictional names and brands:

- [ ] The place names (`ひなたが丘`, `せせらぎ台`, `とねりこ町`, `松川町`, `いちょう町`,
  `のはら`) and the shop names are invented; check that none is the name of a real
  clinic chain, a real company, or a real artist. The two creators of the fandom
  pack are `砂時計の庭園` and `空ゆらぎ`.
- [ ] The clinic name prefixes (`あおぞら`, `ひだまり`, `かえで`, `みずべ`, `ときわ`,
  `きたぐち`) are common words, and the insurers (`ノースウィンド共済` and the
  three others) are invented names in katakana.

Register and templates:

- [ ] `{patient}様`, `{n}名様`, `{name1}さんの保護者`, `{name1}先生`, and
  `@{name}さん（{role}）` stay natural with every name that fills them
  (a given name of any kind, and the longest staff role).
- [ ] The closure notice (`{clinic}は{dates}、{reason}のため休診いたします。`) reads
  well with the three reasons and with a date such as `10月8日（木）〜10月10日（土）`.
- [ ] The card decline message and the vital sign notes keep the unit and the
  number in a natural order (`血圧 {sys}/{dia}mmHgと高めのため`).
- [ ] The story paragraphs are narrated in です・ます like everything else, as in a
  children's story; a reader may expect plain-form narration (`だ・である`) for
  a story.

Texts that the author is not sure about:

- [ ] `総合診療科` and `ファミリークリニック` for the English `Family Medicine`.
- [ ] `日本猫（短毛）` for `Domestic shorthair`, `ミックス犬`, `三毛` for `Tricolor`.
- [ ] `要介護1`〜`要介護5` and `要支援` for the five care grades and the cognitive
  support grade of the Korean data.
- [ ] `おひさま組`, `おつきさま組`, and `おほしさま組` for the three classes of the
  nursery, and the allergen labels `乳`, `卵`, `大豆`, `小麦`.
- [ ] `通知トーク` for the notification talk of the Korean messenger, and `長文SMS`
  for the long-message channel.
- [ ] `権限変更`, `代理ログイン`, `代替送信`, and `バーチャル口座` as the words of a
  SaaS back office.
- [ ] `3軒のクリニック` for `3 clinics`: another counter may read better.

## Known limits

What the gate of the language does not see, and what a language file cannot
change. They are assumptions of the generators and of the gate, and
`docs/languages/README.md` lists them too:

- The Korean number formats. `clinic.approvalNo` and the role `saas.recipient`,
  and the fields `rrnMasked` of `clinic.patient` and `businessNumber` of
  `saas.tenant` that `schema.entity` infers, write Korean-shaped numbers in every
  language (the approval number of a card, a recipient number, a resident
  registration number, and a business registration number). They hold no
  Hangul, so the gate does not see them, and the data of the language cannot
  change them: `faker.clinic` and `faker.saas` follow `koreanValues` and
  `businessNumberFormat`, but these roles and entities do not yet.
- With the `korea` pack registered, `schema.entity` infers a Korean role for the
  fields `phone`, `address1`, and `zipCode` of `clinic.patient`, and the entity
  writes a Korean address and phone number. The gate runs the entities without
  that pack.
- `CoClinicHours` (`businessSlots`, `appointmentSlot`, `visitHeatmap`) are the
  opening hours of a Korean dermatology clinic with the Sunday closed. They are
  numbers, so they are the same in Japanese.
- `clinic.inquiry()` and `messengerHandle()` do not follow the locale: a clinic
  inbox receives messages in several languages, each with its Korean
  translation.
- The gate runs `CoFaker.forLanguage('ja')`. `CoFaker(locale: 'ja')` reads the
  same data but has no country, so the address of a patient is the plain
  street address of the basic modules; `test/languages/ja_localization_test.dart`
  checks that the three ways in (`forLanguage`, `locale:`, and the national
  locale `ja_JP`) give the same domain data.
- A generator writes some punctuation of its own, which a language file cannot
  change: the assessment line of a SOAP note is `尋常性ざ瘡 (L70.0)` with ASCII
  brackets, and the target of an audit event is `請求書 #4888`.
