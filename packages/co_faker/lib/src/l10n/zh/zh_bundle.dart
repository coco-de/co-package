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
    'grocery.deliveryZone': ['演示松光A片区', '演示清澜B片区', '演示田野C片区'],
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
    'catalog.groceryKindName': ['鸡蛋', '韩牛汤用牛肉', '芝麻菜'],
    'catalog.groceryPackLabel': ['{n}枚装'],
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
    'fitness.instructorCareer': [
      '垫上课教学经验5年',
      '核心床教学经验3年',
      '团体瑜伽教学经验8年',
      '小团体训练教学经验2年',
      '康复类课程教学经验6年',
    ],
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
    'daycare.medicationStorage': ['常温保存', '冷藏保存', '避光保存'],
    'daycare.symptom': ['流鼻涕', '轻微咳嗽', '低烧', '皮疹', '肠胃不适'],
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

    // hrd
    'hrd.departmentName': ['销售部', '生产部', '研发部', '客服部', '行政部', '物流部'],
    'hrd.jobTitle': ['专员', '经理', '团队负责人'],
    'hrd.courseTitle': ['个人信息处理规范2026（虚构）', '协同作业安全守则（虚构）', '工作记录整理（虚构）'],
    'hrd.courseKind': ['必修', '专业', '领导力'],
    'hrd.lessonTitle': ['了解基本原则', '回顾工作案例', '核对记录'],
    'hrd.chapterTitle': ['导言', '示例回顾', '小结'],
    'hrd.nudgeTitle': ['培训截止提醒（示例）', '未完成课时提醒（示例）'],
    'hrd.exemptionReason': ['外部结业凭证（示例）', '休假期间核查（示例）', '替代培训核查（示例）'],
    'hrd.classroomPlace': ['松光教室（虚构）', '清澜研讨室（虚构）'],

    // neighborhood
    'neighborhood.neighborhoodName': ['松光社区（虚构）', '银杏社区（虚构）', '白蜡社区（虚构）'],
    'neighborhood.districtName': ['虚构市清澜区', '虚构市松溪区'],
    'neighborhood.nickname': ['松光豆豆（虚构）', '白蜡星星（虚构）', '巷口云朵（虚构）'],
    'neighborhood.postTitle': [
      '在游乐场捡到一只蓝色手套（示例）',
      '一起探索社区散步路线（示例）',
      '分享一个小花盆（示例）',
    ],
    'neighborhood.postBody': ['虚构的社区消息，详情见帖子正文。', '写给邻居的示例帖子，不含电话号码和真实地址。'],
    'neighborhood.commentBody': ['谢谢分享消息。', '我确认一下，稍后在帖子里回复。', '晚上我可以去看看。'],
    'neighborhood.placeName': ['松光烘焙坊（虚构）', '清澜公园休息亭（虚构）', '白蜡小图书馆（虚构）'],
    'neighborhood.openHours': ['08:00—21:00', '09:00—18:00', '10:00—20:00'],
    'neighborhood.bannedWord': ['广告示例', '辱骂示例', '禁用词示例'],
    'neighborhood.keyword': ['手套', '散步', '分享', '社区消息'],

    // meetup
    'meetup.clubName': ['松光晨跑团（虚构）', '清澜读书会（虚构）', '白蜡桌游社（虚构）'],
    'meetup.interestTag': ['跑步', '阅读', '桌游', '摄影', '烹饪', '徒步'],
    'meetup.availableDays': ['工作日晚上', '周末', '周二和周四', '周六上午', '每天都可以'],
    'meetup.clubIntro': ['欢迎第一次参加的邻居加入的虚构社群。', '一起分享小小活动的示例社群。'],
    'meetup.gatheringTitle': ['1月第三周聚会（虚构）', '周末读书聊天（虚构）', '冬日散步聚会（虚构）'],
    'meetup.venueName': ['清澜步道入口（虚构）', '松光小聚会室（虚构）', '白蜡休息亭（虚构）'],
    'meetup.nickname': ['晨曦豆豆（虚构）', '书间云朵（虚构）', '小小星（虚构）'],
    'meetup.duesItem': ['聚会费（示例）', '饮品分摊（示例）', '器材租赁分摊（示例）'],
    'meetup.joinAnswer': ['我想从这个月开始参加活动。', '周末上午我可以参加。'],
    'meetup.ruleText': ['请互相尊重时间。', '请在群内交流，不要公开联系方式。', '取消参加时请告知群里。'],
    'meetup.cadenceLabel': ['每周六07:00', '每两周的周日10:00', '每月第一个周六14:00'],

    // fandom
    // The two fictional creators of the fandom pack: Chinese writes two names
    // of its own, not the Korean ones, and neither is a real artist.
    'fandom.creatorName': ['云隙花园', '晚星笺'],
    'fandom.fanNickname': ['小星星', '小嫩芽', '月亮豆', '光点点'],
    'fandom.benefitTitle': ['会员专享示例图片', '模拟活动报名', '虚构片段抢先看'],
    'fandom.postCaption': ['冬日工作室的虚构插画', '记录排练时间的示例帖子'],
    'fandom.clipTitle': ['30秒排练（虚构）', '工作室问候（虚构）', '冬日声音笔记（虚构）'],
    'fandom.letterBody': [
      '今天的示例帖子我看得很开心，期待下一次更新。',
      '冬日工作室的插画让人觉得很温暖，在此送上我的鼓励。',
    ],
    'fandom.eventTitle': ['冬日粉丝见面会（虚构）', '工作室故事活动（虚构）'],
    'fandom.agendaTitle': ['冬日小剧场日程（虚构）', '虚构的直播对谈', '新帖发布日程'],
    'fandom.venueLabel': ['冬日小剧场（虚构）', '松光工作室（虚构）', '线上示例空间'],

    // content
    'content.seriesTitle': ['纸灯塔的邮递小岛（虚构）', '云池的小地图（虚构）', '慢时钟的花园（虚构）'],
    'content.penName': ['字豆（虚构）', '纸星（虚构）', '云笔（虚构）'],
    'content.synopsisLine': ['虚构人物在小岛上整理信件的故事。', '一起画出地图上没有的池塘，这是一个虚构的故事。'],
    'content.genreName': ['奇幻', '日常', '冒险', '科学故事', '随笔'],
    'content.seriesSection': ['每周连载', '新作', '已完结', '每日连载', '短篇'],
    'content.episodeTitle': ['第一只纸船（虚构）', '池塘上的一个小点（虚构）', '没有时钟的午后（虚构）'],
    'content.cutAltText': ['虚构人物折纸船的插画', '池塘边两位虚构人物的插画'],
    'content.commentLine': ['纸船那一幕让我印象很深。', '我想继续读下一个示例章节。'],
    'content.chapterParagraph': [
      '岛上的邮箱里躺着一张空白的纸。孩子把它对折，做成了一只形似池塘的小纸船。这一段是为演示而原创的虚构示例。',
      '慢时钟旁边放着一盆小小的花。两个朋友没有给花取名字，而是把今天看到的云画了下来。这是原创的虚构示例段落。',
    ],
    'content.publisherName': ['纸灯塔出版社（虚构）', '云池出版社（虚构）'],
    'content.audioTitle': ['折纸船的午后（虚构）', '小池塘的声音笔记（虚构）'],
    'content.newsletterName': ['纸灯塔每周小记（虚构）', '云池小信笺（虚构）'],
    'content.articleHeadline': ['把日常笔记整理成小分组（虚构）', '记录冬日散步中看到的颜色（虚构）'],
    'content.topicName': ['日常笔记', '冬日散步', '小小科学', '阅读习惯'],
    'content.genreTaxonomy': ['奇幻', '日常', '冒险', '科学故事', '随笔'],
    'content.audioTaxonomy': ['有声书', '播客'],
    'content.topicTaxonomy': ['日常笔记', '冬日散步', '小小科学', '阅读习惯', '生活观察'],

    // helpdesk
    // Same order as the ticket categories in CoHelpdeskDomain.
    'helpdesk.ticketSubject': [
      '请帮忙确认团队邀请状态',
      '关于示例账单明细的疑问',
      '示例CSV导出报错',
      '关于集成状态的疑问',
      '关于示例页面按钮的疑问',
      '关于帮助入口位置的疑问',
    ],
    'helpdesk.ticketDescription': [
      '虚构客服账号里的邀请状态显示为待接受。',
      '我想核对虚构账单的明细和账期。',
      '把示例数据导出为CSV时出现了错误状态。',
      '我想确认虚构集成状态页面上的文案。',
      '在示例页面点击按钮后，页面没有任何变化。',
      '虚构客服帮助页面在哪里可以找到？',
    ],
    'helpdesk.macroName': ['示例受理确认', '补充信息确认', '处理进度通知'],
    'helpdesk.helpArticleTitle': ['示例邀请指南', '如何阅读虚构账单', '导出示例CSV数据'],
    'helpdesk.csatComment': ['我已查看了说明。', '示例说明很容易理解。', '还有一些细节需要确认。'],
    // Same order as the draft categories in CoFakerHelpdesk.
    'helpdesk.draftBody': [
      '请在账号设置中查看邀请状态。这是模拟的AI草稿，需由客服人员审核。',
      '请一并记录登录方式和示例报错信息。这是模拟的AI草稿，不会对账号做任何更改。',
      '请核对示例账单上的账期和明细。这是模拟的AI草稿，其中的价格均为虚构。',
      '请在工单备注中记录示例账单编号。这是模拟的AI草稿，并非真实的支付通知。',
      '请核对导出时选择的日期范围和格式。这是模拟的AI草稿，记录的示例报错不含个人信息。',
      '请核对示例CSV的列名和文件状态。这是模拟的AI草稿，需由客服人员审核。',
      '请记录示例集成状态和检查时间。这是模拟的AI草稿，不会发起任何外部调用。',
      '请记录出现问题的页面和复现步骤。这是模拟的AI草稿，不承诺任何结果。',
    ],
    'helpdesk.topicName': ['账号', '计费', '数据', '集成'],

    // campaign
    'campaign.brandName': ['春光烘焙坊（虚构）', '月光书店（虚构）', '绿园咖啡馆（虚构）'],
    'campaign.campaignTitle': ['冬季示例优惠', '首次到店示例消息', '周末示例消息'],
    'campaign.offerCopy': [
      '（广告）虚构冬季菜单的示例优惠券。如需退订，请在演示设置中查看。',
      '（广告）虚构商品的示例优惠。退订方式见演示设置。',
    ],
    'campaign.couponTitle': ['冬季8折示例优惠券', '首次到店9折示例优惠券'],
    'campaign.segmentName': ['近30天购买过的示例人群', '已同意接收营销信息的示例人群', '周末消息示例人群'],
    'campaign.failReason': ['缺少收件号码（示例）', '未同意接收营销信息（示例）', '未同意夜间接收（示例）'],

    // workplace
    'workplace.department': ['前端团队', '后端团队', '设计团队', '客服', '人力资源团队'],
    'workplace.approverRole': ['团队负责人', '部门负责人', '人力资源经理', '财务审核人', '高管'],
    'workplace.closeSection': ['工资', '费用报销', '考勤', '福利', '应计费用'],
    'workplace.position': ['专员', '经理', '团队负责人'],
    'workplace.workPlace': ['松光办公室（虚构）', '清澜办公中心（虚构）', '远程办公'],
    'workplace.shiftName': ['白班', '早班', '周末值班'],
    'workplace.approvalComment': ['已查看附带的示例记录。', '示例事由需要进一步说明。'],
    'workplace.projectName': ['客户门户改版（虚构）', '内部知识库整理（虚构）', '无障碍改进示例'],
    'workplace.workItemTitle': ['优化登录报错文案', '检查示例表格排序', '整理通知状态的显示'],
    'workplace.labelName': ['文案', '无障碍', '待办池', '待确认'],
    'workplace.milestoneTitle': ['首次评审里程碑', '示例页面完成', '回归检查'],
    'workplace.sprintName': ['冲刺{n}'],
    'workplace.commentBody': ['查看示例页面后留下反馈。', '开始下一项任务前，请先确认文案。'],
    'workplace.merchantName': ['野花餐馆（虚构）', '巷口小吃店（虚构）', '松光办公用品店（虚构）'],
    'workplace.accountName': [
      '餐费（示例）',
      '交通费（示例）',
      '会议费（示例）',
      '办公用品费（示例）',
      '差旅费（示例）',
      '其他费用（示例）',
    ],
    'workplace.rejectReasonText': ['缺少示例票据', '费用类别需要确认', '示例制度限额需要确认'],

    // brokerage
    'brokerage.projectTitle': ['示例客户门户搭建', '虚构服务页面改版', '示例预约页面搭建'],
    'brokerage.serviceCategory': ['网页界面', 'App界面', '办公设计', '生活服务'],
    'brokerage.providerName': ['代码阁楼工作室（虚构）', '松光界面工坊（虚构）', '清澜居家工坊（虚构）'],
    'brokerage.providerHeadline': ['展示示例页面和工作记录的虚构合作伙伴', '用于核对虚构项目范围的示例简介'],
    'brokerage.skillTag': ['Dart', '界面规划', '数据整理', '文案撰写'],
    'brokerage.proposalMessage': [
      '已为该示例整理好工作范围和进度检查点。',
      '针对虚构项目的各个阶段，提出检查点建议。',
    ],
    'brokerage.portfolioTitle': ['虚构客户门户示例', '示例预约页面记录', '虚构工作表格改进'],
    'brokerage.milestoneLabel': ['范围确认', '页面草稿确认', '示例功能确认', '交接记录'],
    'brokerage.homeServiceName': [
      '空调清洗（示例）',
      '小型搬家（示例）',
      '水龙头检修（示例）',
      '乐器入门课（示例）',
    ],
    'brokerage.requestAnswer': ['上门前，我想先确认一下服务范围。', '示例时间是周末上午。'],
    'brokerage.regionDong': ['虚构市松光街道', '虚构市清澜街道', '虚构市白蜡街道'],
    'brokerage.reviewText': ['已查看示例工作记录和说明。', '示例日程说明很容易理解。'],
    'brokerage.creditLabel': ['报价提交额度（示例）', '未查看报价返还额度（示例）', '充值额度（示例）'],
    'brokerage.advisorTitle': ['虚构税务专家', '虚构法律专家', '虚构劳动法专家'],
    'brokerage.consultTopic': ['术语说明示例', '咨询前确认事项示例', '材料清单说明示例'],
    'brokerage.qnaQuestion': ['这个制度术语是什么意思？（虚构问题）', '咨询记录里有哪些项目？（虚构问题）'],
    'brokerage.qnaAnswerGeneric': [
      '一般信息示例。制度介绍中可能包含术语、适用范围和所需材料等内容。本内容不含对个案的任何判断。',
      '一般信息示例。咨询记录会把问题和参考材料分开记录。不提供任何具体结果或处理方式。',
    ],
    'brokerage.consultNoteGeneric': [
      '一般信息示例记录：介绍了问题主题和制度术语。材料清单为用于说明的虚构条目。',
      '一般信息示例记录：查看了咨询记录的格式。不含针对个案的结论或建议。',
    ],
    'brokerage.officeName': ['松光咨询事务所（虚构）', '清澜档案事务所（虚构）'],
    'brokerage.serviceTypeName': ['保洁', '搬家', '维修', '课程'],

    // logistics
    'logistics.zoneName': ['松溪1片区（虚构）', '松溪2片区（虚构）', '清澜片区（虚构）'],
    'logistics.hubName': ['松光转运中心（虚构）', '清澜转运中心（虚构）'],
    // A masked plate: {n} is a two-digit number and {m} the last two digits.
    // Chinese writes the pattern of a Chinese plate, with its middle masked.
    'logistics.vehiclePlate': ['沪A·{n}●●{m}'],
    'logistics.deliveryNote': ['请勿放置门口，需当面签收。', '请通过单元门禁呼叫。', '请先与门卫确认。'],
    'logistics.exceptionDetail': [
      '敲门无人应答，已留下通知单。',
      '楼栋入口的门禁密码无法使用。',
      '到达时箱子已有凹陷，已拍照留存。',
      '收件人要求明天派送。',
      '地址中没有房间号。',
    ],
    'logistics.entranceHint': ['单元门#••••，请呼叫门卫室', '使用门口呼叫按钮，不显示密码'],
    'logistics.scanEvent': ['到达转运中心', '干线装车', '派送中', '派送完成', '派送未完成'],
    'logistics.carrierLabel': ['示例快递公司A（虚构）', '示例快递公司B（虚构）', '示例货运公司C（虚构）'],
    'logistics.freightType': ['包装材料', '食品物资', '建筑材料', '电子元件', '日用品'],
    'logistics.routeSummary': ['虚构松光片区→清澜片区', '虚构白蜡片区→松溪片区'],
    'logistics.fareItem': ['基础运费（示例）', '尾板升降附加费（示例）', '人工搬运费（示例）', '等待时间费（示例）'],
    // Same order as the items in CoLogisticsDomain: BOX-S-200, TAPE-OPP-48,
    // TOWEL-COT-03, RICE-BRN-02.
    'logistics.itemName': ['小号纸箱', '包装胶带48mm', '纯棉毛巾3条', '糙米2kg'],
    'logistics.ownerLabel': ['货主A（虚构）', '货主B（虚构）', '货主C（虚构）'],

    // hospitality
    'hospitality.propertyName': ['松林营地（虚构）', '清澜休憩酒店（虚构）', '白蜡小木屋（虚构）'],
    'hospitality.siteName': ['松风A区（虚构）', '松香B区（虚构）', '松果C区（虚构）'],
    'hospitality.amenity': ['独立烧烤区', '公共淋浴间', '无线网络'],
    'hospitality.stayOption': ['烧烤炉具套装（示例）', '一捆柴火（示例）', '提前入住（示例）'],
    'hospitality.seasonName': ['平季', '节假日旺季（示例）', '工作日特惠期（示例）'],
    'hospitality.ratePlan': ['标准示例房价', '含早示例房价', '工作日示例房价'],
    'hospitality.houseRule': ['夜间请保持公共区域安静。', '退房时请查看示例退房清单。'],
    'hospitality.bbqRule': [
      '烧烤炉开放时间为17:00至21:00。',
      '请在办理入住时预约烧烤炉。',
      '每个营位提供木炭和烤网。',
      '离开前请将火完全熄灭。',
      '客房露台禁止烧烤。',
    ],
    'hospitality.wifiHint': [
      '无线网络名称和密码在门边的卡片上。',
      '访客网络的密码请向前台咨询。',
      '访客网络覆盖客房和休息厅。',
      '22:00以后如信号中断，请重新连接。',
      '密码每周一更换。',
    ],
    'hospitality.reviewSnippet': ['示例客房说明一目了然。', '虚构住宿的使用说明整理得很清楚。'],
    'hospitality.hkCheckItem': ['更换床品', '清洁卫生间', '检查客用品', '检查迷你吧'],
    'hospitality.maintenanceIssue': [
      '卫生间漏水检查（示例）',
      '灯具检修申请（示例）',
      '空调面板显示检查（示例）',
      '家具损坏检查（示例）',
    ],
    'hospitality.lostItemName': ['蓝色雨伞', '灰色围巾', '一本书', '水杯'],
    'hospitality.specialRequest': ['高楼层、无烟房（示例）', '额外枕头需求（示例）', '安静客房需求（示例）'],
    'hospitality.menuItem': ['裙带菜汤套餐', '蔬菜意面', '水果酸奶', '热茶'],
    'hospitality.menuOption': ['米饭少一点', '米饭正常', '加配菜（示例）', '去冰'],
    'hospitality.amenityName': ['毛巾', '饮用水', '牙刷', '枕头'],
    'hospitality.localSpot': ['早市汤铺（虚构）', '巷口咖啡馆（虚构）', '松光步道（虚构）'],
    'hospitality.conciergeReply': [
      '虚构住宿的使用说明可在入住详情中查看。',
      '已将您的需求记录在示例登记簿中。',
      '附近的地点均为虚构的演示地点。',
    ],
    'hospitality.folioItem': ['房费（示例）', '客房送餐（示例）', '附加选项（示例）'],
  },
  // The texts that Chinese writes as English does: units of weight and volume,
  // the acronyms and file formats of the exam questions, and the name of a
  // programming language. The clinic and SaaS texts that read the same as
  // English (a unit symbol, an abbreviation) are listed here too.
  allowSameAsEnglish: <String, List<String>>{
    // The weight and the volume of a grocery item are written alike.
    'catalog.groceryUnit': ['*'],
    // The weight of a snack is written with its unit symbol.
    'catalog.commerceUnit': ['200g'],
    // Acronyms and file formats of the exam questions.
    'exam_prep.correctChoice': ['WHERE', 'TCP', 'HTTP'],
    'exam_prep.wrongChoice1': ['JPEG', 'PNG'],
    'exam_prep.wrongChoice2': ['CSS', 'MP3'],
    'exam_prep.wrongChoice3': ['SVG', 'TTF'],
    // The name of a programming language.
    'brokerage.skillTag': ['Dart'],
    // Units and the abbreviation of the clinic data, written as English does.
    'clinic.procedures.unit': ['ml'],
    'clinic.drugForms.unit': ['mg', 'g'],
    'clinic.ops.patientTags.label': ['VIP'],
  },
);
