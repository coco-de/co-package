import '../domain.dart';
import 'authored_roles.dart';

/// Brand-free travel-wallet merchants, budgets and masked cards.
class CoTravelWalletDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoTravelWalletDomain();
  @override
  String get name => 'travel_wallet';
  @override
  Map<String, CoDomainRole> get roles => {
    'merchantNameFictional': textRole(
      ['골목 우동집(가상)', '역 앞 편의점(가상)', '여행자 숙소(가상)'],
      [
        'Lane noodle shop (fictional)',
        'Station convenience shop (fictional)',
        'Traveler lodge (fictional)',
      ],
    ),
    'spendCategory': enumRole([
      'food',
      'transport',
      'shopping',
      'lodging',
      'sightseeing',
      'other',
    ]),
    'cityName': textRole(
      ['오사카', '도쿄', '방콕', '하노이'],
      ['Osaka', 'Tokyo', 'Bangkok', 'Hanoi'],
    ),
    'cardAlias': textRole(
      ['나들이 트래블(가상)', '여행 예산 카드(가상)'],
      ['Outing travel card (fictional)', 'Trip budget card (fictional)'],
    ),
    'tripName': textRole(
      ['오사카 3박 4일', '방콕 주말 여행', '하노이 산책 여행'],
      ['Four days in Osaka', 'Bangkok weekend', 'Hanoi walking trip'],
    ),
    'budgetCategory': enumRole([
      'food',
      'transport',
      'shopping',
      'lodging',
      'sightseeing',
      'other',
    ]),
    'maskedCardNumber': authoredRole(
      (f, _) => '•••• ${f.random.digits('####')}',
      description: 'Masked last four only, never a valid card number',
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'wallet_spend': {
      'id': 'int',
      'merchantName': 'String',
      'spendCategory': 'String',
      'cityName': 'String',
      'spentAt': 'DateTime',
    },
    'travel_card': {
      'id': 'int',
      'cardAlias': 'String',
      'maskedNumber': 'String',
      'status': 'String',
    },
    'budget_line': {'id': 'int', 'tripId': 'int', 'budgetCategory': 'String'},
    'rate_alert': {'id': 'int', 'direction': 'String', 'status': 'String'},
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'wallet_spend': {
      'merchantName': 'merchantNameFictional',
      'spendCategory': 'spendCategory',
      'cityName': 'cityName',
    },
    'travel_card': {
      'cardAlias': 'cardAlias',
      'maskedNumber': 'maskedCardNumber',
    },
    'budget_line': {'budgetCategory': 'budgetCategory'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'travel_card': {
      'status': ['active', 'frozen', 'closed'],
    },
    'rate_alert': {
      'direction': ['below', 'above'],
      'status': ['active', 'paused', 'triggered', 'expired'],
    },
  };
}
