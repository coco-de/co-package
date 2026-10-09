import '../../currency_format.dart';
import '../../korean_values.dart';
import '../../saas_data.dart';
import '../../saas_ops.dart';

/// Japanese (`ja`) SaaS data for `faker.saas`.
///
/// The back office of a clinic software vendor in yen, following
/// `CoFakerSaasData.english` list for list: the same lengths, in the same
/// order. The codes (`starter`, `RSV_CREATED`, `tenant.approve`) are the
/// English ones, and the `#{variable}` markers of a notification template keep
/// their English names and counts.
///
/// - Amounts are whole yen, written `¥12,000`. The plans cost ¥9,800 to
///   ¥69,800 a month, an invoice carries a 10% consumption tax, and the
///   prepaid wallet is topped up in amounts of ¥10,000 to ¥300,000.
/// - A tenant's business number has 13 digits, the shape of a corporate
///   number (`法人番号`), and no Korean-only value appears:
///   [CoKoreanValues.none].
///
/// `ja`, `ja_JP`, and `CoFaker.forLanguage('ja')` read it. The translation is a
/// draft; `docs/languages/ja.md` lists what a native speaker has to review.
const CoFakerSaasData jaSaas = CoFakerSaasData(
  plans: <CoPlanSpec>[
    (
      code: 'starter',
      name: 'スターター',
      monthlyPrice: 9800,
      seats: 3,
      messageCredits: 500,
    ),
    (
      code: 'standard',
      name: 'スタンダード',
      monthlyPrice: 19800,
      seats: 10,
      messageCredits: 2000,
    ),
    (
      code: 'pro',
      name: 'プロ',
      monthlyPrice: 34800,
      seats: 25,
      messageCredits: 5000,
    ),
    (
      code: 'enterprise',
      name: 'エンタープライズ',
      monthlyPrice: 69800,
      seats: 100,
      messageCredits: 20000,
    ),
  ],
  messageTemplates: <CoMessageTemplateSpec>[
    (
      code: 'RSV_CREATED',
      name: 'ご予約完了のお知らせ',
      body: '#{name}様、#{clinic}への#{dateTime}のご予約を承りました。',
    ),
    (
      code: 'RSV_CANCELLED',
      name: 'ご予約キャンセルのお知らせ',
      body: '#{name}様、#{dateTime}のご予約をキャンセルしました。',
    ),
    (
      code: 'RSV_REMIND_D1',
      name: 'リマインド',
      body: '#{name}様、明日#{time}に#{clinic}でお待ちしております。',
    ),
    (
      code: 'QUESTIONNAIRE',
      name: '事前問診票',
      body: '#{name}様、ご来院の前に問診票へのご記入をお願いします：#{link}',
    ),
    (
      code: 'SURVEY',
      name: '満足度アンケート',
      body: '#{name}様、#{clinic}へのご来院はいかがでしたか？ #{link}',
    ),
    (
      code: 'AD_EVENT',
      name: 'キャンペーンのご案内（広告）',
      body: '【広告】#{clinic} 今月のお得な情報：レーザートーニング10回券を特別価格でご案内します。配信停止：#{link}',
    ),
  ],
  notices: <CoNoticeSpec>[
    (
      category: 'maintenance',
      title: '定期メンテナンスのお知らせ',
      body: 'メンテナンスのため、午前2時から午前4時までサービスをご利用いただけません。',
    ),
    (
      category: 'release',
      title: '新機能のお知らせ',
      body: '予約画面で、順番待ちの番号を直接確認できるようになりました。',
    ),
    (category: 'notice', title: '料金改定のお知らせ', body: '新しいプランは、次回の請求日から適用されます。'),
    (
      category: 'notice',
      title: '通知の遅延について',
      body: '一部の通知に遅れが出ており、代わりにSMSで送信されます。',
    ),
  ],
  failureReasons: <String, String>{
    'INVALID_NUMBER': '受信者の番号が正しくありません',
    'NOT_FRIEND': '受信者がメッセンジャーを利用していません',
    'TEMPLATE_MISMATCH': 'テンプレートが一致しません',
    'NO_CREDIT': 'クレジットが不足しています',
    'CARRIER_TIMEOUT': '通信事業者でタイムアウトしました',
    'OPTED_OUT': '受信者が配信を停止しています',
  },
  labels: <String, String>{
    'trialing': 'トライアル中',
    'active': '有効',
    'pastDue': '支払い遅延',
    'paused': '一時停止中',
    'cancelled': '解約済み',
    'draft': '下書き',
    'open': '未入金',
    'paid': '入金済み',
    'overdue': '期限超過',
    'void': '無効',
    'refunded': '返金済み',
    'alimtalk': '通知トーク',
    'sms': 'SMS',
    'lms': '長文SMS',
    'queued': '送信待ち',
    'sent': '送信済み',
    'failed': '失敗',
    'fallbackSent': '代替送信済み',
    'approved': '承認済み',
    'reviewing': '審査中',
    'rejected': '却下',
    'pending': '保留中',
    'eligibility': '資格確認',
    'dur': '薬剤使用状況チェック（DUR）',
    'ePrescription': '電子処方箋',
    'insuranceClaim': '保険請求',
    'identityQr': '本人確認QR',
    'alimtalkGateway': 'メッセージゲートウェイ',
    'payment': '決済ゲートウェイ',
    'up': '正常稼働',
    'degraded': '性能低下',
    'down': '障害',
    'login': 'ログイン',
    'loginFailed': 'ログイン失敗',
    'view': '閲覧',
    'revealRrn': 'ID番号の表示',
    'create': '作成',
    'update': '更新',
    'delete': '削除',
    'print': '印刷',
    'exportData': 'エクスポート',
    'send': '送信',
    'roleChange': '権限変更',
    'notice': 'お知らせ',
    'maintenance': 'メンテナンス',
    'release': 'リリース',
    'fee': '診療報酬',
    'drug': '薬価',
    'material': '医療材料',
    'diagnosis': '傷病名',
    'current': '現行',
    'scheduled': '予定',
    'archived': 'アーカイブ済み',
    'purchase': '購入',
    'usage': '利用',
    'refund': '返金',
    'grant': '付与',
  },
  ops: CoFakerSaasOps(
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (label: 'テナントを承認', summary: '{target}の申し込みを承認しました。'),
      'tenant.suspend': (label: 'テナントを停止', summary: '{target}を停止しました（支払い遅延）。'),
      'tenant.resume': (label: 'テナントを再開', summary: '{target}の停止を解除しました。'),
      'plan.change': (label: 'プランを変更', summary: '{target}をスタンダードからプロに変更しました。'),
      'invoice.issue': (label: '請求書を発行', summary: '{target}の月次請求書を発行しました。'),
      'invoice.refund': (label: '請求書を返金', summary: '{target}の請求書を一部返金しました。'),
      'credit.grant': (
        label: 'クレジットを付与',
        summary: '{target}にメッセージクレジット1,000件分を付与しました。',
      ),
      'template.approve': (
        label: 'テンプレートを承認',
        summary: '{target}のテンプレートを承認しました。',
      ),
      'template.reject': (
        label: 'テンプレートを却下',
        summary: '{target}の広告テンプレートを却下しました。',
      ),
      'senderNumber.approve': (
        label: '発信番号を承認',
        summary: '{target}の発信番号を承認しました。',
      ),
      'master.publish': (
        label: '請求マスターを公開',
        summary: '新しい請求マスター（{target}）を公開しました。',
      ),
      'notice.publish': (label: 'お知らせを公開', summary: 'お知らせ「{target}」を公開しました。'),
      'operator.invite': (
        label: 'オペレーターを招待',
        summary: '{target}をオペレーターとして招待しました。',
      ),
      'operator.roleChange': (
        label: 'オペレーターの権限を変更',
        summary: '{target}の権限を管理者に変更しました。',
      ),
      'impersonate.start': (
        label: 'テナントとして代理ログイン',
        summary: '問題を調査するため、{target}として代理ログインしました。',
      ),
    },
    operatorRoles: <String, String>{
      'owner': 'オーナー',
      'admin': '管理者',
      'billing': '請求担当',
      'support': 'サポート',
      'viewer': '閲覧者',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': 'カードの利用限度額を超えています',
      'CARD_EXPIRED': 'カードの有効期限が切れています',
      'INSUFFICIENT_FUNDS': '残高が不足しています',
      'CARD_LOST': 'カードの紛失・盗難が届け出られています',
      'CARD_SUSPENDED': 'カードが利用停止中です',
      'ISSUER_TIMEOUT': 'カード会社でタイムアウトしました',
    },
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: '初診料', price: 2880),
        (name: '再診料', price: 720),
        (name: '凍結療法（1部位）', price: 1380),
      ],
      'drug': <CoMasterRowSpec>[
        (name: 'ルミソル錠 10mg', price: 18),
        (name: 'ケラフェン軟膏 15g', price: 260),
      ],
      'material': <CoMasterRowSpec>[
        (name: '滅菌ガーゼ（10枚）', price: 48),
        (name: 'シリンジ 1ml', price: 12),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: '尋常性ざ瘡', price: null),
        (name: 'ウイルス性疣贅', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': 'コードが重複していないこと',
      'NEGATIVE_PRICE': '価格に0以下の値がないこと',
      'EFFECTIVE_DATE': '適用開始日が正しい順序であること',
      'REQUIRED_COLUMNS': '必須の列に欠落がないこと',
      'ROW_DELTA': '行数の増減が前のバージョンの5%以内であること',
      'REMOVED_IN_USE': '削除したコードが処理中の請求で使われていないこと',
    },
    incidentTitles: <String, String>{
      'outage': '{service}の障害',
      'degraded': '{service}の応答遅延',
      'maintenance': '{service}の定期メンテナンス',
    },
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message: '3施設で、オフライン同期が15分以上遅れています。',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message: '今月、7件の請求で自動引き落としに失敗しました。',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: '5施設で、メッセージクレジットが100件を下回っています。',
      ),
      (level: 'info', code: 'BACKUP_DONE', message: '夜間バックアップが完了しました。'),
    ],
    releaseItems: <String>[
      '予約画面で順番待ちの番号を直接確認できます。',
      '複数の支払い方法の併用と前受金を、1つの画面で扱えます。',
      '送信に失敗した通知は、自動的にSMSで代替送信されます。',
      'カルテのメモで@を使って、チームメンバーにメンションできます。',
    ],
    regulationItems: <String>[
      '改定後の診療報酬を反映しました。',
      '更新後の薬価基準を反映しました。',
      '傷病名コードの対応表を更新しました。',
    ],
    releaseTitle: '電子カルテ {version} リリースノート',
    regulationTitle: '{month}の制度改定のお知らせ',
    tenantActivities: <String>[
      '新規患者{n}名を登録しました',
      '請求{n}件を送信しました',
      '通知{n}件を送信しました',
      '予約{n}件を登録しました',
      'スタッフアカウント{n}件を追加しました',
    ],
    templateRejectReason: '広告の内容が含まれています。マーケティング用のメッセージとして送信してください。',
    labels: <String, String>{
      'active': '有効',
      'invited': '招待中',
      'suspended': '停止中',
      'allTenants': 'すべてのクリニック',
      'proAndAbove': 'プロプラン以上',
      'dermatology': '皮膚科クリニック',
      'inApp': 'アプリ内',
      'email': 'メール',
      'alimtalk': '通知トーク',
      'outage': '障害',
      'degraded': '性能低下',
      'maintenance': 'メンテナンス',
      'info': '情報',
      'warning': '警告',
      'critical': '重大',
      'topUp': 'チャージ',
      'usage': '利用',
      'refund': '返金',
      'card': 'カード',
      'transfer': '銀行振込',
      'virtualAccount': 'バーチャル口座',
      'release': 'リリース',
      'regulation': '制度改定',
      'failed': '決済失敗',
      'added': '追加',
      'updated': '更新',
      'removed': '削除',
    },
    senderLabels: <String>['代表番号', '予約窓口', '受付'],
    healthMessages: <String, String>{
      'degraded': '応答が遅くなっています',
      'down': '接続がタイムアウトしました',
    },
    auditTargets: <String, String>{
      'login': 'アカウント',
      'loginFailed': 'アカウント',
      'roleChange': 'スタッフ権限',
      'send': '通知',
    },
    auditRecords: <String>['患者', 'カルテ', '請求書', '予約'],
    masterCheckDetail: '{n}行',
  ),
  currency: CoCurrencyFormat(code: 'JPY', symbol: '¥'),
  priceScale: CoSaasPriceScale(
    prepaidTopUps: <int>[10000, 30000, 50000, 100000, 300000],
    prepaidBonusTiers: <(int, int)>[
      (10000, 5),
      (30000, 8),
      (50000, 10),
      (100000, 15),
      (300000, 20),
    ],
    prepaidLowBalance: 5000,
    prepaidUsageMin: 1000,
    prepaidUsageRounding: 10,
    prepaidRefundMin: 100,
    prepaidRefundRounding: 10,
  ),
  koreanValues: CoKoreanValues.none,
  businessNumberFormat: '#############',
);
