import '../co_l10n_bundle.dart';

/// Simplified Chinese domain text: the Chinese counterpart of every English
/// key, with the same number of texts in the same order.
///
/// The texts are what the domain packs and the dedicated generators show for
/// `zh`, `zh_CN`, and `zh-Hans`. They follow the conventions of mainland China:
/// Simplified characters only, the terms of the glossary in
/// `docs/languages/zh.md`, full-width punctuation, no space between Chinese
/// characters and digits, and `您` for a patient or a customer. A fictional
/// name carries `（虚构）` and an example carries `（示例）`. The translation is a
/// draft that a native speaker has to review. See [CoL10nBundle].
const CoL10nBundle zhBundle = CoL10nBundle(
  language: 'zh',
  texts: <String, List<String>>{
    // common
    // A masked name. {lastName} is a family name, {firstName} a given name, and
    // {initial} the first letter of a given name; only the placeholders a
    // template contains are drawn, so a language chooses which name it masks.
    'common.maskedName': ['{lastName}**'],
    // The name of a child under a taxonomy root: {root} is the root name and {n}
    // the child number.
    'common.taxonomyChild': ['{root}·细分主题{n}'],

    // fx
    'fx.currencyName.USD': ['美元'],
    'fx.currencyName.JPY': ['日元'],
    'fx.currencyName.EUR': ['欧元'],
    'fx.currencyName.CNY': ['人民币'],
    'fx.currencyName.THB': ['泰铢'],
    'fx.currencyName.VND': ['越南盾'],
    'fx.currencyName.PHP': ['菲律宾比索'],
    'fx.currencyName.NPR': ['尼泊尔卢比'],
    // Same order as the branch kinds in CoFxDomain: airport, downtown, airport,
    // downtown, downtown.
    'fx.branchName': [
      '演示机场T1兑换点',
      '演示松光兑换点',
      '演示机场T2兑换点',
      '演示清澜兑换点',
      '演示白蜡兑换点',
    ],
    'fx.couponName': ['美元汇差减免80%（示例）', '日元汇差减免70%（示例）', '首次兑换优惠（示例）'],
    'fx.tierName': ['青铜', '白银', '黄金'],

    // remit
    'remit.countryName.VN': ['越南'],
    'remit.countryName.PH': ['菲律宾'],
    'remit.countryName.NP': ['尼泊尔'],
    'remit.countryName.US': ['美国'],
    'remit.countryName.CN': ['中国'],
    'remit.bankName': ['澄湖合作银行（虚构）'],
    'remit.flagRule': ['大额转账（演示规则）', '补充材料核验（演示规则）', '重复申请核查（演示规则）'],

    // vet
    'vet.petName': ['麦麦', '蝶蝶', '豆腐', '豆豆', '云朵'],
    // Same order as the weight ranges of CoFakerVet.
    'vet.breed.dog': ['马尔济斯犬', '贵宾犬', '混种犬'],
    'vet.breed.cat': ['家养短毛猫', '混种猫'],
    'vet.breed.small_mammal': ['兔子', '仓鼠'],
    'vet.breed.bird': ['小型鹦鹉'],
    'vet.breed.reptile': ['陆龟'],
    'vet.coatColor': ['白色', '棕色', '黑色', '三色', '灰色'],
    'vet.vaccineName': ['联合疫苗（示例）', '狂犬病疫苗接种（示例）', '猫用联合疫苗（示例）'],
    'vet.preventiveProduct': ['心丝虫预防示例药剂（虚构）', '体外驱虫预防示例药剂（虚构）'],
    'vet.vetDiagnosis': ['皮肤状况观察（示例）', '消化状况观察（示例）', '日常健康观察（示例）'],
    'vet.vetDrug': ['皮肤护理示例药剂（虚构）', '消化护理示例药剂（虚构）', '眼部护理示例药剂（虚构）'],
    'vet.clinicRoom': ['兽医诊室1', '兽医诊室2', '疫苗接种室'],

    // grocery
    'grocery.originRegion': ['松光种植区（虚构）', '清澜种植区（虚构）', '田野种植区（虚构）'],
    'grocery.harvestNote': ['采收日期和包装日期仅为示例。', '新鲜度说明针对的是虚构商品。'],
    'grocery.deliveryZone': ['演示松光A区', '演示清澜B区', '演示田野C区'],
    'grocery.slotLabel': ['清晨06:00—07:00', '傍晚18:00—20:00'],
    'grocery.substitutionNote': ['以重量相近的商品替换的示例。', '不替换商品，直接退款的示例。'],
    'grocery.doorNote': ['请通过单元门禁呼叫。', '不放门口，请当面签收。'],
    'grocery.categoryName': ['水果', '蔬菜', '预制菜', '谷物', '肉类', '水产', '乳制品'],

    // catalog
    // Same order as the grocery catalog: category, storage, and price stay in
    // code.
    'catalog.groceryName': ['草莓', '菠菜', '手工饺子', '糙米', '鸡里脊肉', '冷冻鲭鱼', '牛奶'],
    // The units of weight and volume are written with their symbols, as the
    // English and Korean labels are.
    'catalog.groceryUnit': ['500g', '200g', '1kg', '2kg', '500g', '600g', '1L'],
    'catalog.commerceName': ['无线耳机', '折叠收纳箱', '纯棉毛巾套装', '陶瓷杯', '谷物零食'],
    'catalog.commerceUnit': ['1副', '1个', '3条', '1个', '200g'],

    // booking
    'booking.cancelReason': ['日程有变（示例）', '改约其他时间（示例）', '个人原因（示例）'],

    // dental
    'dental.dentalProcedure': ['洁牙', '根管治疗（示例）', '树脂充填（示例）', '牙冠修复方案（示例）'],
    'dental.dentalMaterial': ['复合树脂（示例）', '氧化锆（示例）', '陶瓷（示例）'],
    'dental.chairName': ['牙椅1', '牙椅2', '牙椅3'],
    'dental.hygieneNote': ['刷牙方法讲解的记录示例。', '口腔卫生情况观察的记录示例。'],

    // homecare
    'homecare.careGrade': [
      '护理等级1级',
      '护理等级2级',
      '护理等级3级',
      '护理等级4级',
      '护理等级5级',
      '认知障碍支持等级',
    ],
    'homecare.careTaskLabel': [
      '协助进餐',
      '核对服药记录',
      '协助清洁',
      '协助行动',
      '协助如厕',
      '聊天陪伴',
    ],

    // travel_wallet
    'travel_wallet.merchantNameFictional': [
      '巷口面馆（虚构）',
      '车站便利店（虚构）',
      '旅人客栈（虚构）',
    ],
    'travel_wallet.cityName': ['大阪', '东京', '曼谷', '河内'],
    'travel_wallet.cardAlias': ['出游旅行卡（虚构）', '旅行预算卡（虚构）'],
    'travel_wallet.tripName': ['大阪四日游', '曼谷周末游', '河内漫步之旅'],

    // b2b_trade
    'b2b_trade.buyerCompany': ['温禾咖啡馆（虚构）', '麦语烘焙坊（虚构）', '松溪食材店（虚构）'],
    // Same order as the wholesale items in CoB2bTradeDomain: CUP, FRZ, PKG, HYG.
    'b2b_trade.itemSpec': [
      '12oz纸杯，1000个',
      '冷冻土豆，10kg',
      '纸袋，100个',
      '无香卫生湿巾，20片',
    ],
    'b2b_trade.quoteTitle': ['月度包装材料报价单（虚构）', '每周食材报价单（虚构）', '卫生用品报价单（虚构）'],
    'b2b_trade.holdReason': ['核对可用额度（示例）', '核对交货日期（示例）', '核对商品规格（示例）'],

    // group_deal
    'group_deal.dealTitle': ['冬季柑橘团购', '无线耳机团购', '纯棉毛巾团购'],
    'group_deal.optionLabel': ['常规尺寸', '礼品包装', '标准色'],
    'group_deal.rewardLabel': ['参团印章', '示例奖励积分', '运费优惠'],
    'group_deal.benefitTitle': ['示例包邮券', '示例下期团购券'],
    'group_deal.settleNote': ['汇总成功参团记录的示例。', '不含已取消参团记录的汇总示例。'],

    // fitness
    // A class name from the category label and the level label of the same
    // record: the level comes first in Chinese (初级瑜伽).
    'fitness.className': ['{level}{category}'],
    'fitness.classCategoryLabel': ['垫上普拉提', '核心床普拉提', '椅式普拉提', '瑜伽'],
    'fitness.classLevelLabel': ['初级', '中级', '高级'],
    'fitness.equipment': ['普拉提垫', '核心床', '普拉提椅', '瑜伽砖'],
    'fitness.studioRoom': ['垫上教室', '核心床教室', '椅式教室', '瑜伽教室'],
    'fitness.instructorSpecialty': ['垫上教学', '核心床教学', '瑜伽教学'],
    'fitness.passName': ['垫上课10次卡（示例）', '核心床课20次卡（示例）', '月卡（示例）'],
    'fitness.cancelReason': ['日程有变', '课程时间调整'],
    'fitness.noShowNote': ['无到课确认的记录示例。', '开课后标记为缺席的示例。'],

    // space_rental
    'space_rental.spaceName': ['午后四点派对房（虚构）', '松光自习室（虚构）', '清澜排练室（虚构）'],
    'space_rental.districtName': ['虚构市松光街道', '虚构市清澜街道', '虚构市白蜡街道'],
    'space_rental.amenity': ['无线网络', '白板', '饮水机'],
    'space_rental.equipmentOption': ['投影仪（示例）', '音响设备（示例）', '1个停车位（示例）'],
    'space_rental.houseRule': ['使用后请将设备归位。', '请遵守预约的使用时间。'],
    'space_rental.bookingPurpose': ['学习小组聚会', '朋友聚会', '乐队排练'],
    'space_rental.guestMessage': ['请问设备该怎么使用？', '麻烦您告知一下入场方式。'],
    'space_rental.hostReply': ['请查看预约页面中的设备使用说明。', '入场说明显示在预约详情中。'],

    // dining
    'dining.restaurantName': ['紫苏面馆（虚构）', '巷口意面馆（虚构）', '松光茶室（虚构）'],
    'dining.menuName': ['紫苏拌面', '番茄意面', '蔬菜盖饭', '热茶'],
    'dining.partyLabel': ['{n}位用餐'],
    'dining.noShowNote': ['未确认到店的排队记录示例。', '过了通知时间仍未到店的示例。'],
    'dining.loyaltyBenefit': ['第5次到店赠饮品（示例）', '老顾客甜品券（示例）'],
    'dining.districtName': ['虚构市松光街道', '虚构市清澜街道'],

    // daycare
    'daycare.childName': ['子墨', '小满', '安安', '朵朵', '乐乐'],
    'daycare.className': ['太阳班', '月亮班', '星星班'],
    'daycare.ageLabel': ['1岁', '2岁', '3岁', '4岁', '5岁'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.guardianLabel': ['{name1}家长'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.teacherName': ['{name1}老师'],
    'daycare.toiletNote': ['如厕记录1次（示例）', '如厕记录2次（示例）', '无记录（示例）'],
    'daycare.mealMenu': ['糙米饭配蔬菜炖菜', '豆腐汤配米饭', '蔬菜炒饭'],
    'daycare.snackMenu': ['梨片', '蒸红薯', '原味酸奶'],
    'daycare.allergenLabel': ['牛奶', '鸡蛋', '大豆', '小麦', '未标注（示例）'],
    'daycare.activityTitle': ['冬日雪地游戏', '制作纸房子', '彩色积木游戏'],
    'daycare.albumCaption': ['一起搭积木的虚构插画', '冬日游戏的虚构插画'],
    'daycare.drugLabel': ['退热糖浆（虚构）', '止咳糖浆（虚构）', '保湿外用药剂（虚构）'],
    'daycare.dosageLabel': ['家长填写示例：2mL', '家长填写示例：3mL', '家长填写示例：少量'],
    'daycare.noticeTitle': ['冬日游戏通知（示例）', '餐食调整通知（示例）', '安全检查通知（示例）'],

    // exam_prep
    'exam_prep.subjectName': [
      '数据库',
      '数据库',
      '计算机网络',
      '计算机网络',
      '计算机网络',
      '编程基础',
      '编程基础',
      '信息安全',
      '信息安全',
    ],
    'exam_prep.unitName': [
      '数据建模',
      'SQL基础',
      '传输层',
      '路由',
      '应用层',
      '变量',
      '数据结构',
      '密码学基础',
      '访问控制',
    ],
    'exam_prep.questionStem': [
      '表中用来区分每一行的键是什么？',
      '按条件筛选行的SQL子句是什么？',
      '负责保证顺序和重传的传输层协议是什么？',
      '用来选择数据包下一跳路径的设备是什么？',
      '用来表达网页请求和响应的协议是什么？',
      '在程序中以名称保存值的元素是什么？',
      '最后插入的值最先被取出的数据结构是什么？',
      '为输入计算固定长度摘要的函数是什么？',
      '只授予完成任务所需权限的原则是什么？',
    ],
    // Every question has four choices, and the first one is the correct answer:
    // the generator shuffles them.
    'exam_prep.correctChoice': [
      '主键',
      'WHERE',
      'TCP',
      '路由器',
      'HTTP',
      '变量',
      '栈',
      '哈希函数',
      '最小权限',
    ],
    'exam_prep.wrongChoice1': [
      '字体',
      '字体',
      'JPEG',
      '扬声器',
      'PNG',
      '边框',
      '先进先出队列',
      '字体选择',
      '完全公开',
    ],
    'exam_prep.wrongChoice2': [
      '背景色',
      '边距',
      'CSS',
      '键盘',
      'MP3',
      '页边距',
      '图片',
      '屏幕缩放',
      '共享密码',
    ],
    'exam_prep.wrongChoice3': [
      '屏幕宽度',
      '图标',
      'SVG',
      '显示器',
      'TTF',
      '背景图片',
      '音频文件',
      '背景填充',
      '跳过检查',
    ],
    // Each explanation contains the text of its correct choice, and the four
    // choices of a question are different from one another: tests check both.
    'exam_prep.explanation': [
      '主键用来标识表中的每一行。',
      'WHERE子句用来表达筛选行的条件。',
      'TCP负责字节流的顺序保证和重传。',
      '路由器根据目的地址选择下一跳路径。',
      'HTTP用来表达网页请求和响应。',
      '变量让程序可以通过名称引用某个值。',
      '栈会先取出最后插入的值。',
      '哈希函数可以为输入计算固定长度的摘要。',
      '最小权限原则只授予完成任务所需的权限。',
    ],
    'exam_prep.examPaperTitle': ['模拟试卷1（虚构）', '模拟试卷2（虚构）', '单元测验卷（虚构）'],
    'exam_prep.studyTaskTitle': ['完成10道传输层题目', '复习访问控制错题', '巩固SQL基础'],
    'exam_prep.taxonomyName': ['数据库', '计算机网络', '编程基础', '信息安全'],
  },
);
