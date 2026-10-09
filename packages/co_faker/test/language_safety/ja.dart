import 'language_safety.dart';

/// Japanese: a fictional name carries `（架空）`, an example carries `（例）`,
/// both in full-width brackets, and consultation text starts with
/// `一般情報の例`.
///
/// The brands are the katakana, kanji, and hiragana spellings of real
/// medicines, works, companies, and services. The Latin spellings of the
/// brands are the ones that every language is scanned for (`languages.dart`).
const LanguageSafety jaSafety = LanguageSafety(
  fictionalMarker: '（架空）',
  generalInfoPrefix: '一般情報の例',
  deniedPromises: <String>[
    '100%',
    '100 %',
    '１００％',
    '必ず',
    '絶対',
    '確実に',
    '間違いなく',
    '保証します',
    '約束します',
    '勝訴',
    '節税できます',
    '全額戻',
  ],
  deniedBrands: <String>[
    // Medicines and veterinary products.
    'ネクスガード',
    'ブラベクト',
    'ハートガード',
    'レボリューション',
    'フロントライン',
    'タイレノール',
    'ロキソニン',
    'バファリン',
    'ボルタレン',
    'カロナール',
    // Works, companies, and services.
    'ハリー・ポッター',
    'ハリーポッター',
    'ワンピース',
    '進撃の巨人',
    '鬼滅の刃',
    'ドラえもん',
    'ポケットモンスター',
    'ポケモン',
    '任天堂',
    'ソニー',
    'トヨタ',
    'ユニクロ',
    '楽天',
    'スターバックス',
    'セブン-イレブン',
    'セブンイレブン',
    'ローソン',
    'ファミリーマート',
    'ネットフリックス',
    'ディズニー',
    'マーベル',
    'アマゾン',
    'グーグル',
  ],
);
