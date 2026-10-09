# Chinese (Simplified) (`zh`)

status: planned

Native name: 简体中文. National locale: `zh_CN`. Simplified Chinese only. Traditional Chinese (`zh_TW`, `zh_HK`, `zh_MO`, `zh-Hant`) is not supported and reads English.

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

The terms are the ones of mainland China (the standard of the national
medical, banking, and logistics vocabularies). A Taiwan, Hong Kong, or Korean
form of the same thing is forbidden, so that one text never mixes regions.

| Source term (English) | Translation | Forbidden forms | Rationale |
| --- | --- | --- | --- |
| Clinic | 诊所 | 医务室；门诊部 | A small medical practice is a 诊所 on the mainland. 门诊部 is the outpatient department of a larger institution and 医务室 an infirmary inside a company. |
| Patient | 患者 | 病人；病患 | 患者 is the register of an EMR and of a notice. 病人 is colloquial and 病患 is the Taiwan and Hong Kong form. |
| Doctor (physician) | 医生 | 医师；大夫 | One word for the staff role and for running text. 医师 is the licence title and 大夫 is northern colloquial. |
| Clinic head (medical director) | 院长 | - | The head of a clinic is its 院长. |
| Nurse | 护士 | 护理师 | 护理师 is the Taiwan title of a nurse. |
| Appointment, booking | 预约 | 预订；订位 | 预约 is the mainland word for booking a visit, a room, or a time. 预订 is for tickets and hotels, and 订位 is Taiwan usage. |
| No-show | 爽约 | - | The standard word for missing an appointment. |
| Procedure | 治疗 | 手术；术后 | A non-surgical procedure is a 治疗. 手术 means surgery and 术后 the period after it, which the data never describes. |
| Laser | 激光 | 雷射；镭射 | 激光 is the mainland term (雷射 is Taiwan and 镭射 is Hong Kong and older usage). |
| Hyaluronic acid | 透明质酸 | 玻尿酸 | 透明质酸 is the standard name. 玻尿酸 is the Taiwan trade name. |
| Neurotoxin (botulinum toxin) | 肉毒毒素 | 肉毒杆菌；肉毒素 | The toxin is 肉毒毒素. 肉毒杆菌 is the bacterium, and 肉毒素 the clipped trade form. |
| Acne | 痤疮 | 青春痘；暗疮 | 痤疮 is the medical name and the one of ICD-10 (寻常痤疮). 青春痘 and 暗疮 are Taiwan and Cantonese words. |
| Ultrasound | 超声 | 超音波 | 超声 is the mainland term. 超音波 is Taiwan. |
| Numbing cream | 表面麻醉膏 | 麻药膏；麻醉霜 | The topical anesthetic is a 表面麻醉膏 in a clinic. |
| Package (card of sessions) | 次卡 | 回数券；疗程卡 | A card for a number of visits is a 次卡 (a clinic sells 10次卡). 回数券 is the Japanese form. |
| Prepaid balance | 储值余额 | 预存款 | What a patient has stored in the clinic is a 储值余额. 预存款 is the accounting term. |
| Loyalty points | 积分 | 点数；點數 | 积分 is the mainland word. 点数 is Taiwan usage. |
| Coupon | 优惠券 | 折价券；优惠卷 | 优惠券 is standard, and 优惠卷 is a common wrong character (卷 is a roll). |
| Credit (usage allowance) | 额度 | - | What a tenant buys and spends on messages or quotes is an 额度. |
| Invoice (billing statement) | 账单 | 帐单；发票 | The monthly bill of a subscription is a 账单. 发票 is the tax invoice (fapiao), another document, and 帐 is the variant character. |
| Refund | 退款 | - | The usual word for returning a payment. |
| Insurance claim | 医保申报 | 保险理赔 | The claim of a clinic to the national medical insurance is a 医保申报. 理赔 is the claim of a policyholder to a private insurer. |
| Claim master | 申报主数据 | - | 主数据 is the standard term for master data in mainland IT. |
| Fee schedule | 收费标准 | - | The published list of fees. |
| Information | 信息 | 资讯；讯息 | 信息 is the mainland word. 资讯 and 讯息 are Taiwan words. |
| Data | 数据 | 资料；資料 | 数据 is the mainland word for data. 资料 is Taiwan usage for it. |
| Template | 模板 | 模版；范本 | 模板 is the standard written form. 范本 is Taiwan usage. |
| Notification talk (alimtalk) | 通知消息 | - | The Korean business messenger template channel has no Chinese name, so it is named for what it is. |
| SMS | 短信 | 简讯；簡訊 | 短信 is the mainland term. |
| Sign-in | 登录 | 登入 | 登录 is the mainland term. 登入 is Taiwan. |
| Integration | 集成 | 整合 | 集成 is the mainland term for connecting systems. |
| Customer support | 客户支持 | 支援；客服中心 | 支援 is Taiwan usage. |
| Network | 网络 | 网路 | 网络 is the mainland term. 网路 is Taiwan. |
| Tenant | 租户 | - | The standard SaaS term. |
| Impersonate | 模拟登录 | - | An operator who signs in as a tenant performs a 模拟登录. |
| Plan (subscription) | 套餐 | - | A subscription plan is a 套餐, and the editions are 入门版, 标准版, 专业版, and 企业版. |
| Delivery (parcel) | 派送 | 宅配 | The last leg of a parcel is 派送. 宅配 is Taiwan. |
| Courier (express) | 快递 | 宅配；速递 | 快递 is the mainland word for a parcel service. |
| Hub | 转运中心 | - | A parcel hub is a 转运中心. |
| Cargo owner | 货主 | - | The party that owns the freight. |
| Currency exchange | 外币兑换 | - | The exchange of foreign banknotes. |
| Transfer (bank) | 转账 | - | The usual word for moving money between accounts. |
| Spread (FX) | 汇差 | - | The difference between the buy and sell rates. |
| Episode | 章节 | - | A part of a series, whether a chapter or a strip. |
| Fictional (marker) | （虚构） | (虚构)；（虚拟） | Fictional names are marked with 虚构 in full-width parentheses. 虚拟 means virtual. |
| Example (marker) | （示例） | (示例)；范例；样例 | Example texts are marked with 示例 in full-width parentheses. |
| Demo | 演示 | - | The word for a demonstration. |
| Sprint | 冲刺 | - | The Scrum term in the Chinese interface of common tools. |
| Backlog | 待办池 | - | The pool of work that is not scheduled. |
| Wi-Fi | 无线网络 | - | The plain word. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`¥`, decimals) | |
| Dates and times | |
| Numbers: separators and units | |
| Punctuation (full-width marks) and spacing around Latin text | |
| Register and the way to address a patient or a customer | |
| Measure words | |
| Simplified forms only: characters to avoid | |

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
