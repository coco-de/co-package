# Arabic (Saudi Arabia) (`ar`)

status: localized

العربية. The national locale is `ar_SA`. Modern Standard Arabic as written in Saudi Arabia (`ar_SA`), right to left, with the digits 0 to 9.

The status line above is read by the tests of the package:

- `planned`: the language has no data yet. Its domain text bundle, clinic data,
  and SaaS data are empty stubs, and the language reads English.
- `localized`: all three are written. Change the line to `localized` in the same
  pull request that writes them: the tests compare it with the registries.

The domain text bundle, the clinic data, and the SaaS data were written for
co-package#71. **The translation is an AI draft that a native speaker has
not reviewed yet**: the checklist at the end lists what a reviewer has to look
at first. See
[README.md](README.md) for the work, the gate, and the format of this file.

## Glossary

One row for each term that the texts use for the same thing, in English. A term
has one translation, and it is the only one that the texts of the language
write; the forbidden forms are the spellings that must not appear anywhere in
them (another variant, an English loanword, a term of another region). The
rationale says why. Separate forbidden forms with `;`.

| Source term (English) | Translation | Forbidden forms | Rationale |
| --- | --- | --- | --- |
| Patient chart | الملف الطبي | - | One term for the chart of a patient; the EMR product is `السجل الطبي الإلكتروني`. |
| Doctor | طبيب | دكتور | Formal Arabic; `دكتور` is a colloquial title. |
| Milligram | ملجم | ملليغرام; مليغرام | The Saudi abbreviation on drug labels. |
| Gram | جم | غرام | The Saudi abbreviation (`500 جم`, `1 كجم`). |
| Computer | حاسوب | كمبيوتر | Formal Arabic instead of the loanword. |
| Mobile phone | جوال | موبايل; هاتف خلوي | The Saudi word for a mobile phone. |
| Email | البريد الإلكتروني | إيميل | Formal Arabic instead of the loanword. |
| Voucher | قسيمة | كوبون | Formal Arabic instead of the loanword. |
| Parking | موقف سيارات | باركنج | Formal Arabic instead of the loanword. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`1,234.00 ر.س`) | `CoCurrencyFormat(code: 'SAR', symbol: 'ر.س', pattern: '{amount}\u00A0{symbol}', groupSeparator: ',', decimalSeparator: '.', fractionDigits: 2)`; prices about four times the euro amounts of the French data; SaaS adds 15 % VAT. |
| Dates and times (Gregorian calendar) | Day before month (`{weekday} {day}/{month}`), the week starts on Monday, ranges `من {from} إلى {to}`, the 24-hour clock (`18:00`). |
| Numbers: digits 0–9, separators, and units | The digits 0–9 (never `٠`–`٩`), a no-break space (`\u00A0` in the source) between a number and its unit (`10\u00A0ملجم`). |
| Punctuation (`،` `؛` `؟`) and direction (right to left) | Arabic comma, semicolon, and question mark; text is stored in logical order and shown right to left; coined names in `«»`. |
| Register: formal address | `يُرجى` and the respectful plural in every patient and customer text. |
| Gender and number in a template that a value fills | A value follows a colon or ends the phrase (`{category} – مستوى {level}`), so no word agrees with it; persons as `معلّم/ة الفصل: {name1}`. |
| Latin codes and units inside right-to-left text | Codes stay Latin (`CONS01`), and an acronym is named with an Arabic word (`بروتوكول TCP`, `صيغة JPEG`). |

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
- [ ] Medical: حب الشباب الشائع، الكلف، التهاب الجلد التأتبي، الوردية، حطاطات، حمامى، وذمة، الجدرة، ملم زئبق، ملجم/دسل، توكسين عصبي، فيلر هيالورونيك، ليزر البيكو، الموجات فوق الصوتية المركزة، أخصائي تمريض، مراجعة الوصفات الدوائية (DUR).
- [ ] Veterinary and dental: داء الكلب، لقاح مركّب، الديدان القلبية، الطفيليات الخارجية، شراب خافض للحرارة، مرطّب موضعي، علاج قناة الجذر، حشوة راتنجية، تنظيف الجير، زركونيا.
- [ ] Care: `درجة الرعاية` and `درجة الدعم المعرفي` translate Korean care grades.
- [ ] Insurance, legal, and financial: التأمين الصحي الإلزامي (`nhis`)، إعانة طبية (الفئة 1/2)، المؤمَّن عليه، المطالبة التأمينية، الولي القانوني، the consent-form clauses and the disclaimer، كشف رقم الهوية، مختص قانوني / مختص شؤون عمل / مختص ضرائب، both `معلومات عامة:` texts، فارق سعر (FX spread)، الحد الائتماني المتاح، رصيد الشحن، باطل (`void`)، متأخر السداد، البنك المُصدر، حساب بنكي افتراضي، the 15 % VAT، the ten-digit masked ID and commercial registration، `مدى` as the fourth card network، a minimum of 1,500 ر.س for instalments.
- [ ] Word choices: السبرنت {n}، فحص التراجع، الموجه (router)، ريفورمر، إضافة الرافعة الخلفية، the plate `أ ب ج {n}●●{m}`، the notification variables `#{الاسم}` and `#{التاريخ_والوقت}`، the package format `{name} ×{sessions}`.
- [ ] Invented names are not real brands or places: «سنا»، «الغدير»، «موجة»، «نسيم»، «نوران»، «مِلدام»، «علّية الكود»، the clinic, insurer, and drug names of the clinic data, and the two creators of `fandom.creatorName`.
