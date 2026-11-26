# Chinese (Simplified) (`zh`)

status: localized

Native name: 简体中文. National locale: `zh_CN`. Simplified Chinese only. Traditional Chinese (`zh_TW`, `zh_HK`, `zh_MO`, `zh-Hant`) is not supported and reads English.

The status line above is read by the tests of the package:

- `planned`: the language has no data yet. Its domain text bundle, clinic data,
  and SaaS data are empty stubs, and the language reads English.
- `localized`: all three are written. Change the line to `localized` in the same
  pull request that writes them: the tests compare it with the registries.

Everything below is for the Story that localizes the language, and the
translation is a draft until a native speaker has reviewed it. See
[README.md](README.md) for the work, the gate, and the format of this file.

The files of the language are `lib/src/l10n/zh/zh_bundle.dart` (the domain
text, 252 keys), `zh_clinic.dart`, and `zh_saas.dart`; the safety declaration
is `test/language_safety/zh.dart` and the tests that are particular to the
language are `test/languages/zh_localization_test.dart`.

## Glossary

One row for each term that the texts use for the same thing, in English. A term
has one translation, and it is the only one that the texts of the language
write; the forbidden forms are the spellings that must not appear anywhere in
them (another variant, an English loanword, a term of another region). The
rationale says why. Separate forbidden forms with `;` or the full-width
`；`, and write each form in backticks if you like (a comma does not
separate them).

The terms are the ones of mainland China, and the rows are in the order of the
work: the clinic, billing and finance, the operations of the SaaS vendor,
logistics, booking, and content. A Taiwan, Hong Kong, or Korean form of the
same thing is forbidden, so that one text never mixes regions. Where English
has one word for two things, a row names the context in parentheses.

| Source term (English) | Translation | Forbidden forms | Rationale |
| --- | --- | --- | --- |
| Clinic | 诊所 | 医务室；门诊部 | A small medical practice is a 诊所 on the mainland. 门诊部 is the outpatient department of a larger institution and 医务室 an infirmary inside a company. |
| Patient | 患者 | 病人；病患 | 患者 is the register of an EMR and of a notice. 病人 is colloquial and 病患 is the Taiwan and Hong Kong form. |
| Doctor (physician) | 医生 | 医师；大夫 | One word for the staff role and for running text. 医师 is the licence title and 大夫 is northern colloquial. |
| Clinic head (medical director) | 院长 | - | The head of a clinic is its 院长. |
| Nurse | 护士 | 护理师 | 护理师 is the Taiwan title of a nurse. |
| Aesthetician | 皮肤管理师 | - | The title of the person who gives facial care in a skin clinic. |
| Consultation (visit purpose) | 咨询 | - | What a patient asks before a procedure. Counseling is 咨询 too. |
| Consultation (visit stage) | 就诊 | - | The stage in which the patient sees the doctor, as in a hospital flow (登记, 候诊, 就诊, 缴费). |
| Treatment (visit purpose) | 诊疗 | - | The medical care of a skin condition, as against a cosmetic procedure. |
| Procedure | 治疗 | 手术；术后 | A non-surgical procedure is a 治疗. 手术 means surgery and 术后 the period after it, which the data never describes. |
| Care (skin care) | 护理 | 保养 | 护理 is the word of a clinic for facial care. 保养 is the word of a salon. |
| Waiting (queue) | 候诊 | - | The standard word for waiting to see a doctor. |
| Check-in (reception) | 登记 | - | The registration of a patient at the desk or on a tablet. |
| Diagnosis | 诊断 | - | The name of a diagnosis and the document that states it (诊断证明书). |
| Medical record (chart) | 病历 | 病例；病案 | 病历 is the record of a patient. 病例 is a case and 病案 the archive. |
| Informed consent form | 知情同意书 | - | The standard name of the form that a patient signs before a procedure. |
| National health insurance | 医保 | 健保 | 医保 is the mainland word. 健保 is the Taiwan national insurance. |
| Self-pay | 自费 | - | The patient pays and no insurance does. |
| Laser | 激光 | 雷射；镭射 | 激光 is the mainland term (雷射 is Taiwan and 镭射 is Hong Kong and older usage). |
| Hyaluronic acid | 透明质酸 | 玻尿酸 | 透明质酸 is the standard name. 玻尿酸 is the Taiwan trade name. |
| Neurotoxin (botulinum toxin) | 肉毒毒素 | 肉毒杆菌；肉毒素 | The toxin is 肉毒毒素. 肉毒杆菌 is the bacterium, and 肉毒素 the clipped trade form. |
| Acne | 痤疮 | 青春痘；暗疮 | 痤疮 is the medical name and the one of ICD-10 (寻常痤疮). 青春痘 and 暗疮 are Taiwan and Cantonese words. |
| Ultrasound | 超声 | 超音波 | 超声 is the mainland term. 超音波 is Taiwan. |
| Numbing cream | 表面麻醉膏 | 麻药膏；麻醉霜 | The topical anesthetic is a 表面麻醉膏 in a clinic. |
| Guardian (of a patient) | 监护人 | - | The person who signs for a minor patient. |
| Guardian (daycare) | 家长 | - | A daycare writes 家长 for the parent or guardian of a child. |
| Package (card of sessions) | 次卡 | 回数券；疗程卡 | A card for a number of visits is a 次卡 (a clinic sells 10次卡). 回数券 is the Japanese form. |
| Payment (clinic checkout) | 缴费 | - | What a patient does at the checkout of a clinic. |
| Payment (online, subscription) | 支付 | 付款；付费 | The word of electronic payment (已支付, 支付网关, 支付失败). |
| Invoice (billing statement) | 账单 | 帐单；发票 | The monthly bill of a subscription is a 账单. 发票 is the tax invoice (fapiao), another document, and 帐 is the variant character. |
| Refund | 退款 | - | The usual word for returning a payment. |
| Discount (N% off) | 折扣 | - | A rate is written the Chinese way: 20% off is 8折 and 10% off is 9折. |
| Loyalty points | 积分 | 点数；點數 | 积分 is the mainland word. 点数 is Taiwan usage. |
| Coupon | 优惠券 | 折价券；优惠卷 | 优惠券 is standard, and 优惠卷 is a common wrong character (卷 is a roll). |
| Prepaid balance | 储值余额 | 预存款 | What a patient has stored in the clinic is a 储值余额. 预存款 is the accounting term. |
| Credit (usage allowance) | 额度 | - | What a tenant buys and spends on messages or quotes is an 额度. |
| Insurance claim | 医保申报 | 保险理赔 | The claim of a clinic to the national medical insurance is a 医保申报. 理赔 is the claim of a policyholder to a private insurer. |
| Claim master | 申报主数据 | - | 主数据 is the standard term for master data in mainland IT. |
| Fee schedule | 收费标准 | - | The published list of fees. |
| Quote | 报价 | - | The price that a seller gives a buyer (报价单). |
| Currency exchange (branch) | 兑换点 | - | A place where foreign banknotes are exchanged. |
| Spread (FX) | 汇差 | - | The difference between the buy and sell rates. |
| Transfer (bank) | 转账 | - | The usual word for moving money between accounts. |
| Bank card | 银行卡 | - | The card of a bank, whatever its network. |
| Account (sign-in) | 账号 | 帐号 | The login of a person. 帐 is the variant character. |
| Account (bank) | 账户 | 帐户 | An account that holds money (虚拟账户). |
| Tenant | 租户 | - | The standard SaaS term. |
| Plan (subscription) | 套餐 | - | A subscription plan is a 套餐, and the editions are 入门版, 标准版, 专业版, and 企业版. |
| Operator (vendor staff) | 运营人员 | 营运人员 | 运营 is the mainland word for operations. 营运 is Taiwan. |
| Role | 角色 | - | The role of a user. A permission is 权限, which only the security texts use (最小权限). |
| Template | 模板 | 模版；范本 | 模板 is the standard written form. 范本 is Taiwan usage. |
| Notification talk (alimtalk) | 通知消息 | - | The Korean business messenger template channel has no Chinese name, so it is named for what it is. |
| SMS | 短信 | 简讯；簡訊 | 短信 is the mainland term. |
| Sign-in | 登录 | 登入 | 登录 is the mainland term. 登入 is Taiwan. |
| Integration | 集成 | 整合 | 集成 is the mainland term for connecting systems. |
| Customer support | 客服 | 客户支持；支援 | 客服 is the short form that the mainland uses for the support team and its tools. 支援 is Taiwan usage. |
| Impersonate | 模拟登录 | - | An operator who signs in as a tenant performs a 模拟登录. |
| Outage | 故障 | - | The status of a service that is down. |
| Degraded | 性能下降 | - | The status of a service that answers slowly. |
| Gateway | 网关 | - | The standard term for the node between systems (消息网关, 支付网关). |
| Release | 版本更新 | - | A new version of the product. |
| Information | 信息 | 资讯；讯息 | 信息 is the mainland word. 资讯 and 讯息 are Taiwan words. |
| Data | 数据 | 资料；資料 | 数据 is the mainland word for data. 资料 is Taiwan usage for it. |
| Network | 网络 | 网路 | 网络 is the mainland term. 网路 is Taiwan. |
| Wi-Fi | 无线网络 | - | The plain word. |
| Delivery (parcel) | 派送 | 宅配 | The last leg of a parcel is 派送. 宅配 is Taiwan. |
| Courier (express) | 快递 | 宅配；速递 | 快递 is the mainland word for a parcel service. |
| Hub | 转运中心 | - | A parcel hub is a 转运中心. |
| Cargo owner | 货主 | - | The party that owns the freight. |
| Zone (delivery) | 片区 | - | A delivery zone is a 片区 in a route and in a grocery area. |
| Freight fare | 运费 | - | The charge for carrying goods (基础运费). |
| Hand delivery | 当面签收 | - | The parcel is handed over and signed for in person. |
| Appointment, booking | 预约 | 预订；订位 | 预约 is the mainland word for booking a visit, a room, or a time. 预订 is for tickets and hotels, and 订位 is Taiwan usage. |
| No-show | 爽约 | - | The standard word for missing an appointment. |
| Cancelled | 已取消 | - | The status of a booking that was called off. |
| Queue | 排队 | - | A waiting line of a restaurant or a clinic. |
| Episode | 章节 | - | A part of a series, whether a chapter or a strip. |
| Illustration | 插画 | - | A drawn picture. |
| Clip | 片段 | 影片 | A short piece of video. 影片 is Taiwan usage for a video. |
| Audiobook | 有声书 | - | A book that is read aloud. |
| Podcast | 播客 | - | The mainland name of a podcast. |
| Post | 帖子 | 贴文 | A message on a board. 贴文 is Taiwan usage. |
| Fan | 粉丝 | - | The admirer of a creator (粉丝见面会). |
| Fictional (marker) | （虚构） | (虚构)；（虚拟） | Fictional names are marked with 虚构 in full-width parentheses. 虚拟 means virtual. |
| Example (marker) | （示例） | (示例)；范例；样例 | Example texts are marked with 示例 in full-width parentheses. |
| Demo | 演示 | - | The word for a demonstration. |
| Sprint | 冲刺 | - | The Scrum term in the Chinese interface of common tools. |
| Backlog | 待办池 | - | The pool of work that is not scheduled. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`¥`, decimals) | Yuan: `¥1,234.00` (CNY, the symbol before the number, a comma between thousands, a dot and two decimals). `faker.clinic.money(1234)` and `faker.saas.money(1234)` write it. Prices are whole yuan: a procedure to ¥10, a package to ¥100, a prepaid balance in steps of ¥100, installments from ¥3,000. A discount of 20% is written `8折` and one of 10% `9折`; a rate that is not a discount keeps the percent sign (`3%`). The invoices carry a 6% VAT. |
| Dates and times | A date is `2026年10月8日`. The closure notice has no year, so it writes `10月8日（周四）`, a range `10月8日（周四）至10月10日（周六）`, and the weekdays are `周一` to `周日`. The clock has 24 hours: `18:00`. A range of times uses the dash `—` (`06:00—07:00`), and a part of the day comes before the time (`清晨06:00`). |
| Numbers: separators and units | Arabic digits with a comma between thousands (`1,000`) and a dot before decimals. A unit of measure is the symbol written next to its number: `500g`, `10kg`, `48mm`, `2mL`, `120/80mmHg`, `36.6°C`, `20%`. |
| Punctuation (full-width marks) and spacing around Latin text | The marks are full-width: `，。：；！？（）`, and `、` between the items of a list, `·` for a middle dot, and `“ ”` for a quotation. There is no space between a Chinese character and a digit or a Latin letter (`LED舒缓护理`, `SQL基础`, `10次卡`). A generator may write one where a pattern of code joins the parts (`鲁米索片 10mg`). |
| Register and the way to address a patient or a customer | `您` for a patient or a customer: the counselor, the notification templates, the replies of the clinic. An advertisement does not address a person. The consent clauses speak in the first person (`本人`), and a command is `请…`. The patient's own lines are plain (`我`, `你们`). |
| Measure words | `次` for a session or a visit (`10次卡`), `位` for a diner (`3位用餐`), `个` for a piece or a slot (`1个停车位`, `新增预约70个`), `家` for a clinic, `张` for an invoice, `条` for a message or a towel, `人` for a patient, `笔` for a claim, `岁` for an age, `级` for a grade, `道` for a question, `副` for a pair, `片` for a wipe or a gauze. `项` is part of 项目 and 事项. |
| Simplified forms only: characters to avoid | A text has no Traditional character (診, 療, 護, 預, 約, 費, 號, 線, 網, 價, 單, 隻, 體, 點, 臺, 後, 說, …): `test/languages/zh_localization_test.dart` holds a list of about 400 and fails on one. The Taiwan and Hong Kong words are forbidden in the glossary (雷射, 玻尿酸, 資訊, 資料, 登入, 網路, 簡訊, 健保, 宅配, …) and the Korean forms are not carried over. |

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.

Medical terms:

- [ ] 皮秒激光嫩肤 for the picosecond laser toning (`LT-01`), 聚焦超声提拉300线 for the focused ultrasound lift with 300 lines (`HIFU-300`), 痤疮清理 for the acne extraction, 额头肉毒毒素注射, and 透明质酸唇部填充1ml. Several of these have no single standard Chinese name.
- [ ] The names of the diagnoses: 寻常痤疮 (L70.0), 黄褐斑 (L81.1), 病毒性疣 (B07), 特应性皮炎，未特指 (L20.9), 皮炎，未特指 (L30.9), 玫瑰痤疮，未特指 (L71.9; the national edition may write 酒渣鼻).
- [ ] The eight invented drug stems (艾德美, 鲁米索, 克拉芬, 迪奥克, 纳维洛, 塞拉顿, 米诺贝, 阿克洛): none may be the name of a marketed product.
- [ ] 表面麻醉膏 and the answers of the counselor about pain, interval, and downtime.
- [ ] The consent clauses (治疗知情同意书, 个人信息处理同意书, 拍照同意书) are examples that no lawyer has reviewed.
- [ ] 护理等级1级 to 5级 and 认知障碍支持等级 for the care grades of the home care pack, which follow the Korean and Japanese systems and have no single Chinese equivalent.

Financial and legal terms:

- [ ] 医保申报 (insurance claim) and 申报主数据 (claim master) against 保险理赔 and 发票: the claim of a clinic to the national insurance has no standard English-to-Chinese pair.
- [ ] 账单 for the invoice of a subscription (not 发票, the tax invoice), 额度 for a credit, 储值余额 for a prepaid balance, 抹零 for the rounding of a bill, 医疗救助（1类）and（2类）for the medical aid types.
- [ ] The 6% VAT of the SaaS invoices (the rate on software and information technology services) and the shape of the business number (18 characters, `91` and sixteen digits).
- [ ] The discount of `8折` for 20% off and `9折` for 10% off.

Names and brands (all of them fictional; no real brand, person, or organization may be among them):

- [ ] The place names 松光, 清澜, 白蜡, 松溪, 银杏, 田野 and the city 虚构市.
- [ ] The fictional banks (澄湖银行, 远岫银行, 青禾银行, 星渡银行, 澄湖合作银行), the insurers (北风互助保险, 港湾人寿, 峰岭保险, 清溪健康险), the clinics, shops, and studios that the packs name, and the two creators (云隙花园, 晚星笺).
- [ ] The plate pattern `沪A·{n}●●{m}` writes the province mark of a real plate with its middle masked.

Words the author is not sure of:

- [ ] 核心床普拉提 and 垫上普拉提 (the reformer and the mat classes), 椅式普拉提, and the order of a class name (`初级瑜伽`, the level first).
- [ ] 无香卫生湿巾 for the English hygiene towels, 裙带菜汤套餐 for the seaweed soup meal, 预制菜 for prepared foods, 心丝虫 for the heartworm.
- [ ] 通知消息 for the notification talk, 模拟登录 for the impersonation of a tenant, 冲刺 against 迭代 for a sprint, 待办池 for a backlog, 申报, 转运中心, 尾板升降附加费, 当面签收.
- [ ] 客服 for the support team and its roles.
- [ ] The staff roles: 院长 for the medical director, 护理协调员 for the care coordinator, 皮肤管理师 for the aesthetician.

Templates:

- [ ] The package name `皮秒激光嫩肤（10次卡）` and the compound item `皮秒激光嫩肤×3次`: the sessions stand in parentheses and the multiplication sign, because a name may end in a number (`透明质酸唇部填充1ml（5次卡）`).
- [ ] `{name1}家长` and `{name1}老师` for the daycare, `{n}位用餐` for a party, and the closure notice (`…将于{dates}因{reason}停诊，{reopen}起恢复正常门诊。`) with its three reasons.

## What the gate does not cover

The gate reads the data and the generators, not the quality of a translation,
and it cannot see the following (all of them hold for every language, and none
can be fixed by a language file):

- The roles `clinic.approvalNo` and `saas.recipient`, and the entity fields
  `rrnMasked` of `clinic.patient` and `businessNumber` of `saas.tenant` that
  `schema.entity` infers to a Korean role (and `phone` and `address1` with the
  `korea` pack registered), write Korean number formats in Chinese too.
  `faker.clinic` and `faker.saas` follow the data (`maskedIdFormat`,
  `businessNumberFormat`), so `faker.clinic.patient().rrnMasked` is the masked
  Chinese resident ID (`110101********1234`).
- `CoClinicHours` is the opening hours of a Korean dermatology clinic with the
  Sunday closed, in every language.
- `clinic.inquiry()` and `messengerHandle()` do not follow the locale: a
  Korean clinic inbox receives messages in several languages.
- The gate runs `CoFaker.forLanguage('zh')`. `CoFaker(locale: 'zh')` reads the
  same data but has no country, so the address of a patient is the plain
  street address of the basic module. `zh_localization_test.dart` checks that
  both ways, the national locale `zh_CN`, and `CoFaker.forCountry('CN')` give
  the same domain data.
- Some patterns of code are not data: the drug name writes a space between the
  dosage form and the strength (`鲁米索片 10mg`), the assessment of a SOAP note
  writes `皮炎，未特指 (L30.9)` with half-width parentheses, an audit event
  writes `账单 #4888`, and a compound package joins its items with ` + `.
- The free text of the basic module (the `memo` of a reservation, the names of
  an operator) is generated from the word lists of the `zh_CN` locale and is
  not part of the domain text.
- There is no Chinese public holiday calendar: `koreanValues: none` means that
  a closure notice always gives a reason (a conference, a renovation, equipment
  maintenance) and never a holiday.
- The texts that read as in English are units and abbreviations only: the
  weight and volume labels of the grocery items (`500g`, `1kg`, `1L`), `200g`,
  `ml`, `mg`, `g`, the acronyms of the exam questions, `Dart`, and `VIP`.
