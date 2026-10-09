import '../co_l10n_bundle.dart';

/// Japanese domain text: the Japanese counterpart of every English key, with
/// the same number of texts in the same order.
///
/// The register is です・ます for everything a patient, a customer, or a
/// member reads, and the narration of a story paragraph is plain form. A
/// fictional name carries `（架空）` and an example carries `（例）`, in
/// full-width brackets. Digits are half-width, katakana is full-width, and a
/// counter is `回` for a time, `名` for a person, and `件` for a record.
///
/// The translation is a draft written with an AI assistant: the terms that a
/// native speaker has to look at are in `docs/languages/ja.md`. See
/// [CoL10nBundle].
const CoL10nBundle jaBundle = CoL10nBundle(
  language: 'ja',
  texts: <String, List<String>>{
    // common
    // A masked name. {lastName} is a family name, {firstName} a given name, and
    // {initial} the first letter of a given name; only the placeholders a
    // template contains are drawn, so a language chooses which name it masks.
    'common.maskedName': ['{lastName}○○'],
    // The name of a child under a taxonomy root: {root} is the root name and {n}
    // the child number.
    'common.taxonomyChild': ['{root}・小項目{n}'],

    // fx
    'fx.currencyName.USD': ['米ドル'],
    'fx.currencyName.JPY': ['日本円'],
    'fx.currencyName.EUR': ['ユーロ'],
    'fx.currencyName.CNY': ['中国元'],
    'fx.currencyName.THB': ['タイバーツ'],
    'fx.currencyName.VND': ['ベトナムドン'],
    'fx.currencyName.PHP': ['フィリピンペソ'],
    'fx.currencyName.NPR': ['ネパールルピー'],
    // Same order as the branch kinds in CoFxDomain: airport, downtown, airport,
    // downtown, downtown.
    'fx.branchName': [
      'ひだまり両替 空港T1店（架空）',
      'ひだまり両替 ひなたが丘店（架空）',
      'ひだまり両替 空港T2店（架空）',
      'ひだまり両替 せせらぎ台店（架空）',
      'ひだまり両替 とねりこ町店（架空）',
    ],
    'fx.couponName': ['USD為替手数料80%優遇（例）', 'JPY為替手数料70%優遇（例）', '初回両替優遇（例）'],
    'fx.tierName': ['ブロンズ', 'シルバー', 'ゴールド'],

    // remit
    'remit.countryName.VN': ['ベトナム'],
    'remit.countryName.PH': ['フィリピン'],
    'remit.countryName.NP': ['ネパール'],
    'remit.countryName.US': ['アメリカ'],
    'remit.countryName.CN': ['中国'],
    'remit.bankName': ['はるかぜ提携銀行（架空）'],
    'remit.flagRule': ['高額送金（デモ基準）', '追加書類の確認（デモ基準）', '繰り返し依頼の確認（デモ基準）'],

    // vet
    'vet.petName': ['むぎ', 'ちょうちょ', 'とうふ', 'まめ', 'くも'],
    // Same order as the weight ranges of CoFakerVet.
    'vet.breed.dog': ['マルチーズ', 'プードル', 'ミックス犬'],
    'vet.breed.cat': ['日本猫（短毛）', 'ミックス猫'],
    'vet.breed.small_mammal': ['ウサギ', 'ハムスター'],
    'vet.breed.bird': ['小型インコ'],
    'vet.breed.reptile': ['リクガメ'],
    'vet.coatColor': ['白', '茶', '黒', '三毛', 'グレー'],
    'vet.vaccineName': ['混合ワクチン（例）', '狂犬病予防接種（例）', '猫の混合ワクチン（例）'],
    'vet.preventiveProduct': ['フィラリア予防薬の例（架空）', '外部寄生虫予防薬の例（架空）'],
    'vet.vetDiagnosis': ['皮膚の経過観察（例）', '消化器の経過観察（例）', '定期健康チェック（例）'],
    'vet.vetDrug': ['皮膚ケア用の薬の例（架空）', '消化ケア用の薬の例（架空）', '目のケア用の薬の例（架空）'],
    'vet.clinicRoom': ['診察室1', '診察室2', '予防接種室'],

    // grocery
    'grocery.originRegion': [
      'ひなたが丘栽培エリア（架空）',
      'せせらぎ台生産エリア（架空）',
      'のはら栽培エリア（架空）',
    ],
    'grocery.harvestNote': ['収穫日と梱包日は例です。', '鮮度に関する表示は架空の商品の説明です。'],
    'grocery.deliveryZone': ['ひなたが丘Aエリア（架空）', 'せせらぎ台Bエリア（架空）', 'のはらCエリア（架空）'],
    'grocery.slotLabel': ['早朝 6:00〜7:00', '夕方 18:00〜20:00'],
    'grocery.substitutionNote': ['似た重さの商品に代替した例です。', '代替せず、該当の品目を返金した例です。'],
    'grocery.doorNote': ['共用玄関で呼び出してください。', '玄関前への置き配はせず、手渡しでお願いします。'],
    'grocery.categoryName': ['果物', '野菜', '惣菜', '穀物', '精肉', '魚介', '乳製品'],

    // catalog
    // Same order as the grocery catalog: category, storage, and price stay in
    // code.
    'catalog.groceryName': [
      'いちご',
      'ほうれん草',
      '手作り餃子',
      '玄米',
      '鶏ささみ',
      '冷凍サバ',
      '牛乳',
    ],
    // Korean and English output have always shown the same unit labels.
    'catalog.groceryUnit': ['500g', '200g', '1kg', '2kg', '500g', '600g', '1L'],
    'catalog.commerceName': [
      'ワイヤレスイヤホン',
      '折りたたみ収納ボックス',
      '綿タオルセット',
      '陶器のカップ',
      '雑穀スナック',
    ],
    'catalog.commerceUnit': ['1組', '1箱', '3枚', '1個', '200g'],

    // booking
    'booking.cancelReason': ['日程の変更（例）', '別の時間を選択（例）', '個人的な都合（例）'],

    // dental
    'dental.dentalProcedure': ['歯石除去', '根管治療（例）', 'レジン充填（例）', 'クラウン治療計画（例）'],
    'dental.dentalMaterial': ['コンポジットレジン（例）', 'ジルコニア（例）', 'セラミック（例）'],
    'dental.chairName': ['診療台1', '診療台2', '診療台3'],
    'dental.hygieneNote': ['ブラッシング指導を記録した例です。', '口腔衛生の確認内容を記録した例です。'],

    // homecare
    'homecare.careGrade': ['要介護1', '要介護2', '要介護3', '要介護4', '要介護5', '要支援'],
    'homecare.careTaskLabel': [
      '食事介助',
      '服薬記録の確認',
      '清潔保持の介助',
      '移動介助',
      '排泄介助',
      '話し相手',
    ],

    // travel_wallet
    'travel_wallet.merchantNameFictional': [
      '路地裏のうどん店（架空）',
      '駅前コンビニ（架空）',
      '旅人の宿（架空）',
    ],
    'travel_wallet.cityName': ['大阪', '東京', 'バンコク', 'ハノイ'],
    'travel_wallet.cardAlias': ['おでかけトラベルカード（架空）', '旅行予算カード（架空）'],
    'travel_wallet.tripName': ['大阪3泊4日', 'バンコク週末旅行', 'ハノイ街歩き旅行'],

    // b2b_trade
    'b2b_trade.buyerCompany': ['カフェ ひだまり（架空）', 'パン工房 こむぎ（架空）', '食材店 松川（架空）'],
    // Same order as the wholesale items in CoB2bTradeDomain: CUP, FRZ, PKG, HYG.
    'b2b_trade.itemSpec': [
      '12oz紙コップ 1,000個入り',
      '冷凍ポテト 10kg',
      '紙袋 100枚入り',
      '無香料の衛生タオル 20枚入り',
    ],
    'b2b_trade.quoteTitle': [
      '月間梱包資材の見積もり（架空）',
      '週間食材の見積もり（架空）',
      '衛生用品の見積もり（架空）',
    ],
    'b2b_trade.holdReason': ['与信枠の確認待ち（例）', '納品日の確認待ち（例）', '品目規格の確認待ち（例）'],

    // group_deal
    'group_deal.dealTitle': ['冬のみかん共同購入', 'ワイヤレスイヤホン共同購入', '綿タオル共同購入'],
    'group_deal.optionLabel': ['通常サイズ', 'ギフト包装', '標準カラー'],
    'group_deal.rewardLabel': ['参加スタンプ', '還元ポイント（例）', '送料特典'],
    'group_deal.benefitTitle': ['送料無料クーポン（例）', '次回の共同購入クーポン（例）'],
    'group_deal.settleNote': ['成立した参加分を集計した例です。', 'キャンセルした参加分を除いて集計した例です。'],

    // fitness
    // A class name from the category label and the level label of the same
    // record.
    'fitness.className': ['{category} {level}'],
    'fitness.classCategoryLabel': ['マット', 'リフォーマー', 'チェア', 'ヨガ'],
    'fitness.classLevelLabel': ['初級', '中級', '上級'],
    'fitness.equipment': ['マット', 'リフォーマー', 'チェア', 'ヨガブロック'],
    'fitness.studioRoom': ['マットルーム', 'リフォーマールーム', 'チェアルーム', 'ヨガルーム'],
    'fitness.instructorSpecialty': ['マットレッスン', 'リフォーマーレッスン', 'ヨガレッスン'],
    'fitness.passName': ['マット10回券（例）', 'リフォーマー20回券（例）', '1か月パス（例）'],
    'fitness.cancelReason': ['日程の変更', 'レッスン時間の変更'],
    'fitness.noShowNote': ['出席の確認がない例の記録です。', '開始時刻を過ぎても出席がなく、欠席とした例です。'],

    // space_rental
    'space_rental.spaceName': [
      '午後4時のパーティールーム（架空）',
      'ひなたが丘の自習室（架空）',
      'せせらぎ台の練習スタジオ（架空）',
    ],
    'space_rental.districtName': ['架空市ひなたが丘', '架空市せせらぎ台', '架空市とねりこ町'],
    'space_rental.amenity': ['Wi-Fi', 'ホワイトボード', 'ウォーターサーバー'],
    'space_rental.equipmentOption': ['プロジェクター（例）', '音響機材（例）', '駐車場1台分（例）'],
    'space_rental.houseRule': ['ご利用後は備品を元の場所に戻してください。', 'ご予約の利用時間をお守りください。'],
    'space_rental.bookingPurpose': ['勉強会', '友人との集まり', 'バンドの練習'],
    'space_rental.guestMessage': ['備品の使い方を教えていただけますか？', '入室の案内をお願いします。'],
    'space_rental.hostReply': ['予約ページの備品案内をご確認ください。', '入室のご案内は予約の詳細に表示されます。'],

    // dining
    'dining.restaurantName': ['えごま油の麺処（架空）', '路地裏のパスタ店（架空）', 'ひなたが丘の茶房（架空）'],
    'dining.menuName': ['えごま油の和え麺', 'トマトパスタ', '野菜丼', '温かいお茶'],
    'dining.partyLabel': ['{n}名様'],
    'dining.noShowNote': ['来店の確認がない例の順番待ち記録です。', '案内した時刻を過ぎても来店がなかった例です。'],
    'dining.loyaltyBenefit': ['5回目のご来店でドリンク1杯（例）', '常連のお客様向けデザートクーポン（例）'],
    'dining.districtName': ['架空市ひなたが丘', '架空市せせらぎ台'],

    // daycare
    'daycare.childName': ['ひなた', 'そら', 'はると', 'みお', 'ゆい'],
    'daycare.className': ['おひさま組', 'おつきさま組', 'おほしさま組'],
    'daycare.ageLabel': ['1歳児', '2歳児', '3歳児', '4歳児', '5歳児'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.guardianLabel': ['{name1}さんの保護者'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.teacherName': ['{name1}先生'],
    'daycare.toiletNote': ['排泄の記録1回（例）', '排泄の記録2回（例）', '記録なし（例）'],
    'daycare.mealMenu': ['玄米ごはんと野菜シチュー', '豆腐のみそ汁とごはん', '野菜チャーハン'],
    'daycare.snackMenu': ['梨のスライス', 'ふかしいも', 'プレーンヨーグルト'],
    'daycare.allergenLabel': ['乳', '卵', '大豆', '小麦', '特になし（例）'],
    'daycare.activityTitle': ['冬の雪遊び', '紙の家づくり', 'カラーブロック遊び'],
    'daycare.albumCaption': ['友だちとブロックを積む架空のイラスト', '冬の遊びを描いた架空のイラスト'],
    'daycare.drugLabel': ['解熱シロップ（架空）', '咳止めシロップ（架空）', '保湿用の外用薬（架空）'],
    'daycare.dosageLabel': ['保護者記入の例：2mL', '保護者記入の例：3mL', '保護者記入の例：少量'],
    'daycare.noticeTitle': ['冬の遊びのお知らせ（例）', '献立変更のお知らせ（例）', '安全確認のお知らせ（例）'],

    // exam_prep
    'exam_prep.subjectName': [
      'データベース',
      'データベース',
      'ネットワーク',
      'ネットワーク',
      'ネットワーク',
      'プログラミング基礎',
      'プログラミング基礎',
      '情報セキュリティ',
      '情報セキュリティ',
    ],
    'exam_prep.unitName': [
      'データモデル',
      'SQL基礎',
      'トランスポート層',
      'ルーティング',
      'アプリケーション層',
      '変数',
      'データ構造',
      '暗号の基礎',
      'アクセス制御',
    ],
    'exam_prep.questionStem': [
      'テーブルの各行を区別するキーはどれですか？',
      '条件に合う行を選ぶSQLの句はどれですか？',
      '順序の制御と再送を行うトランスポート層のプロトコルはどれですか？',
      'パケットの次の経路を選ぶ機器はどれですか？',
      'Webのリクエストとレスポンスをやり取りするプロトコルはどれですか？',
      'プログラムの中で値に名前を付けて保持するものはどれですか？',
      '最後に入れた値から先に取り出すデータ構造はどれですか？',
      '入力から固定長の要約値を計算する関数はどれですか？',
      '業務に必要な権限だけを与える原則はどれですか？',
    ],
    // Every question has four choices, and the first one is the correct answer:
    // the generator shuffles them.
    'exam_prep.correctChoice': [
      '主キー',
      'WHERE',
      'TCP',
      'ルーター',
      'HTTP',
      '変数',
      'スタック',
      'ハッシュ関数',
      '最小権限',
    ],
    'exam_prep.wrongChoice1': [
      'フォント',
      'フォント',
      'JPEG',
      'スピーカー',
      'PNG',
      '枠線',
      '先入れ先出しキュー',
      'フォント選択',
      '全体公開',
    ],
    'exam_prep.wrongChoice2': [
      '背景色',
      '余白',
      'CSS',
      'キーボード',
      'MP3',
      'ページの余白',
      '画像',
      '画面の拡大',
      '共有パスワード',
    ],
    'exam_prep.wrongChoice3': [
      '画面の幅',
      'アイコン',
      'SVG',
      'モニター',
      'TTF',
      '背景画像',
      '音声ファイル',
      '背景の塗りつぶし',
      '確認の省略',
    ],
    // Each explanation contains the text of its correct choice, and the four
    // choices of a question are different from one another: tests check both.
    'exam_prep.explanation': [
      '主キーは、テーブルの各行を識別するためのキーです。',
      'WHERE句は、取得する行の条件を指定します。',
      'TCPは、バイトストリームの順序の制御と再送を担当します。',
      'ルーターは、宛先アドレスをもとに次の経路を選択します。',
      'HTTPは、Webのリクエストとレスポンスを表すプロトコルです。',
      '変数を使うと、プログラムの中で値を名前で参照できます。',
      'スタックは、最後に入れた値を最初に取り出すデータ構造です。',
      'ハッシュ関数は、入力から固定長の要約値を計算します。',
      '最小権限は、業務に必要な権限だけを与える原則です。',
    ],
    'exam_prep.examPaperTitle': ['模擬試験 第1回（架空）', '模擬試験 第2回（架空）', '単元確認テスト（架空）'],
    'exam_prep.studyTaskTitle': [
      'トランスポート層の問題を10問解く',
      'アクセス制御の間違いを復習する',
      'SQL基礎を確認する',
    ],
    'exam_prep.taxonomyName': ['データベース', 'ネットワーク', 'プログラミング基礎', '情報セキュリティ'],

    // hrd
    'hrd.departmentName': ['営業部', '生産部', '研究開発部', 'サポート部', '管理部', '物流部'],
    'hrd.jobTitle': ['社員', 'マネージャー', 'チームリーダー'],
    'hrd.courseTitle': [
      '個人情報の取り扱い 2026（架空）',
      'みんなで安全に働くために（架空）',
      '業務記録の整理の基本（架空）',
    ],
    'hrd.courseKind': ['必須', '職務', 'リーダーシップ'],
    'hrd.lessonTitle': ['基本の考え方を知る', '業務の事例を見る', '記録を確認する'],
    'hrd.chapterTitle': ['はじめに', '事例の確認', 'まとめ'],
    'hrd.nudgeTitle': ['研修の期限リマインド（例）', '未完了のレッスンのリマインド（例）'],
    'hrd.exemptionReason': ['外部での修了証明の提出（例）', '休職期間の確認（例）', '代替研修の確認（例）'],
    'hrd.classroomPlace': ['ひなたが丘の研修室（架空）', 'せせらぎ台のセミナールーム（架空）'],

    // neighborhood
    'neighborhood.neighborhoodName': ['ひなたが丘（架空）', 'いちょう町（架空）', 'とねりこ町（架空）'],
    'neighborhood.districtName': ['架空市せせらぎ区', '架空市松川区'],
    'neighborhood.nickname': ['ひなたまめ（架空）', 'とねりこぼし（架空）', 'ろじぐも（架空）'],
    'neighborhood.postTitle': [
      '公園で青い手袋を見つけました（例）',
      '近所の散歩コースを一緒に探しませんか（例）',
      '小さな植木鉢をおすそ分けします（例）',
    ],
    'neighborhood.postBody': [
      '架空の地域のお知らせです。詳しくはこの投稿をご確認ください。',
      'ご近所さんと共有するための例の投稿です。電話番号や実在の住所は含まれていません。',
    ],
    'neighborhood.commentBody': [
      '情報を教えてくださってありがとうございます。',
      '確認して、投稿に返信します。',
      '夕方に確認できます。',
    ],
    'neighborhood.placeName': [
      'ひなたが丘ベーカリー（架空）',
      'せせらぎ公園の休憩所（架空）',
      'とねりこ町の小さな図書館（架空）',
    ],
    'neighborhood.openHours': ['8:00〜21:00', '9:00〜18:00', '10:00〜20:00'],
    'neighborhood.bannedWord': ['広告例', '暴言例', '禁止語例'],
    'neighborhood.keyword': ['手袋', '散歩', 'おすそ分け', '地域のお知らせ'],

    // meetup
    'meetup.clubName': ['ひなたが丘朝ランの会（架空）', 'せせらぎ台読書会（架空）', 'とねりこボードゲーム会（架空）'],
    'meetup.interestTag': ['ランニング', '読書', 'ボードゲーム', '写真', '料理', '登山'],
    'meetup.clubIntro': [
      '初めて参加するご近所さんも歓迎する架空のサークルです。',
      'ささやかな活動を一緒に楽しむ例のサークルです。',
    ],
    'meetup.gatheringTitle': ['1月第3週の定例会（架空）', '週末の本のおしゃべり会（架空）', '冬の散歩会（架空）'],
    'meetup.venueName': [
      'せせらぎ台の遊歩道入口（架空）',
      'ひなたが丘の小さな集会室（架空）',
      'とねりこ町の休憩所（架空）',
    ],
    'meetup.nickname': ['あかつきまめ（架空）', 'ほんのくも（架空）', 'ちいさなほし（架空）'],
    'meetup.duesItem': ['定例会の参加費（例）', '飲み物代の割り勘（例）', '備品レンタル代の割り勘（例）'],
    'meetup.joinAnswer': ['今月から一緒に活動したいです。', '週末の午前なら参加できます。'],
    'meetup.ruleText': [
      'お互いの時間を尊重しましょう。',
      '連絡先は公開せず、グループ内でやり取りしてください。',
      'キャンセルする場合はグループに連絡してください。',
    ],
    'meetup.cadenceLabel': ['毎週土曜 7:00', '隔週日曜 10:00', '毎月第1土曜 14:00'],

    // fandom
    // The two approved fictional creators of the fandom pack: stage names that
    // no real artist, work, or company has.
    'fandom.creatorName': ['砂時計の庭園', '空ゆらぎ'],
    'fandom.fanNickname': ['おほしさま', 'ふたば', 'つきまめ', 'ひかりのしずく'],
    'fandom.benefitTitle': ['メンバー限定の写真（例）', '模擬イベント応募（例）', '架空クリップの先行公開'],
    'fandom.postCaption': ['冬のアトリエを描いた架空のイラスト', 'リハーサルの時間を記録した例の投稿'],
    'fandom.clipTitle': ['30秒のリハーサル（架空）', 'アトリエからのごあいさつ（架空）', '冬の音のメモ（架空）'],
    'fandom.letterBody': [
      '今日の例の投稿を楽しく読みました。次の更新も楽しみにしています。',
      '冬のアトリエのイラストが温かく感じました。応援しています。',
    ],
    'fandom.eventTitle': ['冬のファンミーティング（架空）', 'アトリエのお話イベント（架空）'],
    'fandom.agendaTitle': ['冬の小劇場の日程（架空）', '架空の配信トーク', '新しい投稿の公開予定'],
    'fandom.venueLabel': ['冬の小劇場（架空）', 'ひなたが丘のアトリエ（架空）', 'オンライン会場（例）'],

    // content
    'content.seriesTitle': ['紙の灯台と郵便の島（架空）', '雲の池の小さな地図（架空）', 'ゆっくり時計の花園（架空）'],
    'content.penName': ['ことばまめ（架空）', 'かみぼし（架空）', 'くものペン（架空）'],
    'content.synopsisLine': [
      '小さな島で手紙を整理する架空の人物たちの物語です。',
      '地図にない池を一緒に描く、架空のお話です。',
    ],
    'content.genreName': ['ファンタジー', '日常', '冒険', '科学の話', 'エッセイ'],
    'content.episodeTitle': ['はじめての紙の舟（架空）', '池の小さな点（架空）', '時計のない午後（架空）'],
    'content.cutAltText': ['架空の人物が紙の舟を折るイラスト', '池のそばにいる架空の人物2人のイラスト'],
    'content.commentLine': ['紙の舟の場面が心に残りました。', '次の例のエピソードも読んでみたいです。'],
    // Narration, so the paragraphs are in plain form, not です・ます.
    'content.chapterParagraph': [
      '島の郵便受けには、白紙が一枚入っていた。子どもはその紙を半分に折り、池に似た小さな舟を作った。この段落はデモのために書き下ろした架空の文章である。',
      'ゆっくり時計の隣には、小さな植木鉢があった。二人の友だちは、鉢に名前を付ける代わりに、その日に見た雲を絵に残した。この段落は書き下ろした架空の例文である。',
    ],
    'content.publisherName': ['紙の灯台出版（架空）', '雲の池出版（架空）'],
    'content.audioTitle': ['紙の舟を折る午後（架空）', '小さな池の音のメモ（架空）'],
    'content.newsletterName': ['紙の灯台 週刊メモ（架空）', '雲の池の小さな手紙（架空）'],
    'content.articleHeadline': [
      '日々のメモを小さなグループに整理する方法（架空）',
      '冬の散歩で見つけた色を記録するには（架空）',
    ],
    'content.topicName': ['日々のメモ', '冬の散歩', 'ちいさな科学', '読書の習慣'],
    'content.genreTaxonomy': ['ファンタジー', '日常', '冒険', '科学の話', 'エッセイ'],
    'content.audioTaxonomy': ['オーディオブック', 'ポッドキャスト'],
    'content.topicTaxonomy': ['日々のメモ', '冬の散歩', 'ちいさな科学', '読書の習慣', '暮らしの観察'],

    // helpdesk
    // Same order as the ticket categories in CoHelpdeskDomain.
    'helpdesk.ticketSubject': [
      'チーム招待の状況を確認したいです',
      '請求書の明細（例）についての質問',
      'CSVエクスポートのエラー（例）',
      '連携状況についての質問',
      '画面のボタン（例）についての質問',
      'ヘルプの場所についての質問',
    ],
    'helpdesk.ticketDescription': [
      '架空のサポートアカウントで、招待が保留中と表示されています。',
      '架空の請求書の明細と期間を確認したいです。',
      '例のデータをCSVにエクスポートすると、エラーが表示されます。',
      '架空の連携状況ページの文言を確認したいです。',
      '例の画面でボタンを押しても、同じ画面のままです。',
      '架空のサポートヘルプのページはどこにありますか？',
    ],
    'helpdesk.macroName': ['受付確認（例）', '追加情報の確認', '対応状況のご案内'],
    'helpdesk.helpArticleTitle': [
      '招待のご案内（例）',
      '架空の請求書の見方',
      'CSVデータのエクスポート方法（例）',
    ],
    'helpdesk.csatComment': [
      '説明の内容を確認しました。',
      '例の案内が分かりやすかったです。',
      '追加で確認したい点があります。',
    ],
    // Same order as the draft categories in CoFakerHelpdesk.
    'helpdesk.draftBody': [
      'アカウント設定で招待の状況をご確認ください。これは模擬のAI下書きで、担当者の確認が必要です。',
      'ログイン方法と表示された例のエラーを併せて記録してください。模擬のAI下書きのため、実際のアカウント変更は行いません。',
      '請求書の例の期間と明細をご確認ください。これは架空の料金を説明する模擬のAI下書きです。',
      '請求書の例の番号をサポートの記録に残してください。実際の支払いのご案内ではなく、模擬のAI下書きです。',
      'エクスポート画面で選択した期間と形式をご確認ください。個人情報を含まない例のエラー内容を記録する、模擬のAI下書きです。',
      '例のCSVの列名とファイルの状態をご確認ください。担当者が内容を確認する、模擬のAI下書きです。',
      '連携設定に表示された例の状態と確認時刻を記録してください。外部への呼び出しを行わない、模擬のAI下書きです。',
      '問題が表示された画面と再現手順を記録してください。結果を約束しない、模擬のAI下書きです。',
    ],
    'helpdesk.topicName': ['アカウント', '請求', 'データ', '連携'],

    // campaign
    'campaign.brandName': ['はるひかりベーカリー（架空）', '月あかり書房（架空）', 'みどりの庭カフェ（架空）'],
    'campaign.campaignTitle': ['冬の特典のご案内（例）', '初回ご来店のお知らせ（例）', '週末のお知らせ（例）'],
    'campaign.offerCopy': [
      '（広告）架空の冬メニューの例のクーポンです。配信停止はデモの設定でご確認ください。',
      '（広告）架空の商品の例の特典をご案内します。配信停止はデモの設定にあります。',
    ],
    'campaign.couponTitle': ['冬の20%割引クーポン（例）', '初回来店10%割引クーポン（例）'],
    'campaign.segmentName': [
      '直近30日の購入者（例）',
      '広告配信に同意したグループ（例）',
      '週末のお知らせ希望グループ（例）',
    ],
    'campaign.failReason': ['受信番号なし（例）', '広告配信の同意なし（例）', '夜間配信の同意なし（例）'],

    // workplace
    'workplace.department': [
      'フロントエンドチーム',
      'バックエンドチーム',
      'デザインチーム',
      'カスタマーサポート',
      '人事チーム',
    ],
    'workplace.position': ['社員', 'マネージャー', 'チームリーダー'],
    'workplace.workPlace': ['ひなたが丘オフィス（架空）', 'せせらぎ台ワークセンター（架空）', '在宅勤務'],
    'workplace.shiftName': ['日勤', '午前勤務', '週末当番'],
    'workplace.approvalComment': [
      '添付された記録（例）を確認しました。',
      '理由（例）について、追加の確認が必要です。',
    ],
    'workplace.projectName': [
      '顧客ポータルの刷新（架空）',
      '社内Wikiの整理（架空）',
      'アクセシビリティの改善（例）',
    ],
    'workplace.workItemTitle': [
      'ログインエラーの文言を改善する',
      '表（例）の並べ替えを確認する',
      '通知状態の表示を整理する',
    ],
    'workplace.labelName': ['文言', 'アクセシビリティ', 'バックログ', '要確認'],
    'workplace.milestoneTitle': ['初回レビューのマイルストーン', '画面（例）の完成', 'リグレッション確認'],
    'workplace.sprintName': ['スプリント{n}'],
    'workplace.commentBody': [
      '画面（例）を確認したうえで、フィードバックを残します。',
      '次の作業の前に、文言を確認してください。',
    ],
    'workplace.merchantName': ['野の花食堂（架空）', '路地裏の甘味処（架空）', 'ひなたが丘文具店（架空）'],
    'workplace.accountName': [
      '飲食費（例）',
      '交通費（例）',
      '会議費（例）',
      '消耗品費（例）',
      '出張費（例）',
      'その他（例）',
    ],
    'workplace.rejectReasonText': [
      '領収書（例）の添付漏れ',
      '費目の分類に確認が必要です',
      '規定（例）の上限に確認が必要です',
    ],

    // brokerage
    'brokerage.projectTitle': ['顧客ポータルの制作（例）', '架空サービスの画面刷新', '予約画面の制作（例）'],
    'brokerage.serviceCategory': ['Web画面制作', 'アプリ画面制作', '業務デザイン', '生活サービス'],
    'brokerage.providerName': [
      'コード屋根裏スタジオ（架空）',
      'ひなたが丘画面工房（架空）',
      'せせらぎ台暮らし工房（架空）',
    ],
    'brokerage.providerHeadline': [
      '例の画面と作業記録を紹介する架空のパートナーです。',
      '架空のプロジェクトの範囲を一緒に確認する例のプロフィールです。',
    ],
    'brokerage.skillTag': ['Dart', '画面設計', 'データ整理', '文章作成'],
    'brokerage.proposalMessage': [
      '作業範囲と日程の確認項目を整理しました（例）。',
      '架空のプロジェクトの段階ごとの確認項目をご提案します。',
    ],
    'brokerage.portfolioTitle': ['架空の顧客ポータルの例', '予約画面の制作記録（例）', '架空の業務表の改善'],
    'brokerage.milestoneLabel': ['範囲の確認', '画面案の確認', '機能の確認（例）', '引き渡しの記録'],
    'brokerage.homeServiceName': [
      'エアコンクリーニング（例）',
      '小さな引っ越し（例）',
      '水栓の点検（例）',
      '初心者向け楽器レッスン（例）',
    ],
    'brokerage.requestAnswer': ['訪問の前に作業範囲を確認したいです。', '日程の例は週末の午前です。'],
    'brokerage.regionDong': ['架空市ひなたが丘', '架空市せせらぎ台', '架空市とねりこ町'],
    'brokerage.reviewText': ['作業記録（例）と案内を確認しました。', '日程の案内（例）が分かりやすかったです。'],
    'brokerage.creditLabel': [
      '見積もり送信クレジット（例）',
      '未閲覧の見積もりの返金クレジット（例）',
      'チャージクレジット（例）',
    ],
    'brokerage.advisorTitle': ['架空の税務専門家', '架空の法律専門家', '架空の労務専門家'],
    'brokerage.consultTopic': ['制度用語の説明（例）', '相談前の確認項目（例）', '書類一覧の説明（例）'],
    'brokerage.qnaQuestion': [
      '制度の用語はどういう意味ですか？（架空の質問）',
      '相談記録にはどんな項目がありますか？（架空の質問）',
    ],
    // Each text starts with the general-information prefix that the safety
    // declaration of the language names, and promises no result.
    'brokerage.qnaAnswerGeneric': [
      '一般情報の例です。制度の案内には、用語、対象範囲、確認資料などの項目があります。個別の事案についての判断は含まれていません。',
      '一般情報の例です。相談記録は、質問と確認資料を分けて記入する形式で構成されます。特定の結果や対応方法をお示しするものではありません。',
    ],
    'brokerage.consultNoteGeneric': [
      '一般情報の例の記録：質問の主題と制度の用語を紹介しました。資料の一覧は、説明のための架空の項目です。',
      '一般情報の例の記録：相談画面の記録形式を確認しました。個別の案件についての結論や助言はありません。',
    ],
    'brokerage.officeName': ['ひなたが丘相談事務所（架空）', 'せせらぎ台記録事務所（架空）'],
    'brokerage.serviceTypeName': ['清掃', '引っ越し', '修理', 'レッスン'],

    // logistics
    'logistics.zoneName': ['松川町第1エリア（架空）', '松川町第2エリア（架空）', 'せせらぎ台エリア（架空）'],
    'logistics.hubName': ['ひなたが丘拠点（架空）', 'せせらぎ台拠点（架空）'],
    // A masked plate: {n} is a two-digit number and {m} the last two digits.
    // The Japanese plate keeps a hiragana and masks the serial number.
    'logistics.vehiclePlate': ['{n}あ ●●-{m}'],
    'logistics.deliveryNote': [
      '置き配はせず、直接お渡しください。',
      '共用玄関で呼び出してください。',
      '管理人室で確認のうえ、お渡しください。',
    ],
    'logistics.entranceHint': ['共用玄関 #••••・管理人室を呼び出し', '入口の呼び出しボタンを利用（暗証番号なし）'],
    'logistics.scanEvent': ['拠点到着', '幹線輸送へ積み込み', '配達に出発', '配達完了', '配達未完了'],
    'logistics.carrierLabel': ['配送会社A（架空）', '配送会社B（架空）', '運送会社C（架空）'],
    'logistics.freightType': ['梱包資材', '食材', '建築資材', '電子部品', '日用品'],
    'logistics.routeSummary': [
      '架空市ひなたが丘エリア → せせらぎ台エリア',
      '架空市とねりこ町エリア → 松川町エリア',
    ],
    'logistics.fareItem': ['基本運賃（例）', 'パワーゲートの追加（例）', '手荷役の追加（例）', '待機時間（例）'],
    // Same order as the items in CoLogisticsDomain: BOX-S-200, TAPE-OPP-48,
    // TOWEL-COT-03, RICE-BRN-02.
    'logistics.itemName': ['小サイズの紙箱', '梱包用テープ 48mm', '綿タオル 3枚', '玄米 2kg'],
    'logistics.ownerLabel': ['荷主A（架空）', '荷主B（架空）', '荷主C（架空）'],

    // hospitality
    'hospitality.propertyName': [
      '松林のキャンプ場（架空）',
      'せせらぎ台 憩いのホテル（架空）',
      'とねりこ町の小さな宿（架空）',
    ],
    'hospitality.siteName': ['松風サイトA（架空）', '松の香サイトB（架空）', '松ぼっくりサイトC（架空）'],
    'hospitality.amenity': ['専用バーベキュースペース', '共用シャワールーム', 'Wi-Fi'],
    'hospitality.stayOption': ['バーベキューグリルセット（例）', '薪ひと束（例）', 'アーリーチェックイン（例）'],
    'hospitality.seasonName': ['通常期', '連休のハイシーズン（例）', '平日特価期間（例）'],
    'hospitality.ratePlan': ['基本プラン（例）', '朝食付きプラン（例）', '平日プラン（例）'],
    'hospitality.houseRule': [
      '夜間は共用スペースでお静かにお過ごしください。',
      'チェックアウトの際は、確認リスト（例）をご覧ください。',
    ],
    'hospitality.reviewSnippet': [
      '客室の案内（例）が見やすかったです。',
      '架空の施設のご利用案内が整理されています。',
    ],
    'hospitality.hkCheckItem': ['寝具の交換', '浴室の清掃', 'アメニティの確認', 'ミニバーの確認'],
    'hospitality.maintenanceIssue': [
      '浴室の水漏れ確認（例）',
      '照明の点検依頼（例）',
      '冷暖房の表示確認（例）',
      '家具の破損確認（例）',
    ],
    'hospitality.lostItemName': ['青い傘', 'グレーのマフラー', '本1冊', '水筒'],
    'hospitality.specialRequest': ['高層階・禁煙（例）', '枕の追加希望（例）', '静かな部屋の希望（例）'],
    'hospitality.menuItem': ['わかめスープの定食', '野菜パスタ', 'フルーツヨーグルト', '温かいお茶'],
    'hospitality.menuOption': ['ごはん少なめ', 'ごはん普通', 'おかず追加（例）', '氷なし'],
    'hospitality.amenityName': ['タオル', 'ミネラルウォーター', '歯ブラシ', '枕'],
    'hospitality.localSpot': ['朝ごはんの食堂（架空）', '路地裏のカフェ（架空）', 'ひなたが丘の遊歩道（架空）'],
    'hospitality.conciergeReply': [
      '架空の施設のご利用案内は、宿泊の詳細に表示されます。',
      'ご要望を台帳（例）に記録しました。',
      '周辺の場所はすべてデモ用の架空の場所です。',
    ],
    'hospitality.folioItem': ['宿泊料（例）', 'ルームサービス（例）', '追加オプション（例）'],
  },
  // The texts that Japanese writes as English does: units, acronyms, and the
  // name of a programming language. The language coverage gate reads this list.
  allowSameAsEnglish: <String, List<String>>{
    // The weight and the volume of a grocery item are written alike.
    'catalog.groceryUnit': ['*'],
    // A weight written with its unit symbol reads the same in Japanese.
    'catalog.commerceUnit': ['200g'],
    // Acronyms and file formats of the exam questions.
    'exam_prep.correctChoice': ['WHERE', 'TCP', 'HTTP'],
    'exam_prep.wrongChoice1': ['JPEG', 'PNG'],
    'exam_prep.wrongChoice2': ['CSS', 'MP3'],
    'exam_prep.wrongChoice3': ['SVG', 'TTF'],
    // The name of a programming language.
    'brokerage.skillTag': ['Dart'],
    // Japanese writes the name of the wireless network in Latin letters too.
    'space_rental.amenity': ['Wi-Fi'],
    'hospitality.amenity': ['Wi-Fi'],
  },
);
