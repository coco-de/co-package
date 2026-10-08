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
    'merchantNameFictional': textRole('travel_wallet.merchantNameFictional'),
    'spendCategory': enumRole([
      'food',
      'transport',
      'shopping',
      'lodging',
      'sightseeing',
      'other',
    ]),
    'cityName': textRole('travel_wallet.cityName'),
    'cardAlias': textRole('travel_wallet.cardAlias'),
    'tripName': textRole('travel_wallet.tripName'),
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
