import 'language_safety.dart';

/// Chinese (Simplified): a fictional name carries `（虚构）` in full-width
/// parentheses, and consultation text starts with `一般信息示例`. The brands
/// are the Chinese spellings of real medicines, works, companies, and banks
/// (the Latin ones are scanned through the English list).
const LanguageSafety zhSafety = LanguageSafety(
  fictionalMarker: '（虚构）',
  generalInfoPrefix: '一般信息示例',
  deniedPromises: <String>[
    '100%',
    '100 %',
    '百分之百',
    '保证',
    '一定',
    '肯定',
    '必定',
    '必胜',
    '稳赢',
    '包赢',
    '包过',
    '胜诉',
    '务必',
    '您应该',
    '您应当',
    '建议您',
  ],
  deniedBrands: <String>[
    // Medicines and veterinary products.
    '泰诺',
    '芬必得',
    '白加黑',
    '云南白药',
    '福来恩',
    '大宠爱',
    '拜宠清',
    '海乐妙',
    '爱沃克',
    '辉瑞',
    // Works, companies, services, and banks.
    '哈利·波特',
    '哈利波特',
    '海贼王',
    '我独自升级',
    '漫威',
    '火影忍者',
    '鬼灭之刃',
    '斗罗大陆',
    '三星',
    '星巴克',
    '腾讯',
    '阿里巴巴',
    '淘宝',
    '华为',
    '奈飞',
    '微信',
    '工商银行',
    '建设银行',
    '招商银行',
    '农业银行',
    '平安保险',
    '中国人寿',
  ],
);
