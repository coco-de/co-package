import 'language_safety.dart';

/// Russian: a fictional name carries `(вымышленное название)`, a sample label
/// carries `(пример)`, and consultation text starts with
/// `Пример общей информации`.
///
/// The marker is one invariant tag after every name, whatever the gender of the
/// noun before it: it qualifies the name (`название`, neuter) and not the noun,
/// so it needs no agreement and the scan can test for one string. The promises
/// are the phrases in the register of the language (`вы`) that guarantee a
/// result or tell a person what to do, which an example of a consultation must
/// not write. The brands are the Russian spellings, in Cyrillic, of real
/// medicines, works, companies, and banks that the Latin ones of the English
/// list do not cover (`Нурофен`, `Яндекс`, `Сбербанк`); each one is a whole
/// name, never a short word that a text could contain by chance.
const LanguageSafety ruSafety = LanguageSafety(
  fictionalMarker: '(вымышленное название)',
  generalInfoPrefix: 'Пример общей информации',
  deniedPromises: <String>[
    '100%',
    '100 %',
    'гарантирую',
    'гарантируем',
    'гарантия',
    'гарантирован',
    'обязательно',
    'непременно',
    'наверняка',
    'без сомнения',
    'вы должны',
    'вам следует',
    'вам необходимо',
    'рекомендую',
    'рекомендуем',
    'выиграете',
    'сэкономите',
    'вернёте все',
  ],
  deniedBrands: <String>[
    // Medicines and veterinary products.
    'Нурофен',
    'Цитрамон',
    'Мирамистин',
    'Арбидол',
    'Ингавирин',
    'Кагоцел',
    'Анаферон',
    'Эффералган',
    'Нексгард',
    'Бравекто',
    'Фронтлайн',
    'Стронгхолд',
    // Works, companies, services, and banks.
    'Гарри Поттер',
    'Властелин колец',
    'Маша и Медведь',
    'Смешарики',
    'Самсунг',
    'Яндекс',
    'Сбербанк',
    'Тинькофф',
    'Газпром',
    'Лукойл',
    'Аэрофлот',
    'Пятёрочка',
    'Пятерочка',
    'ВкусВилл',
    'Вайлдберриз',
    'Макдоналдс',
    'Старбакс',
    'Нетфликс',
    'Дисней',
    'Марвел',
    'Покемон',
    'ВКонтакте',
    'Ростелеком',
    'Мегафон',
    'Билайн',
  ],
);
