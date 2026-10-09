import '../domain.dart';
import 'authored_roles.dart';

/// Fictional neighborhoods, rental spaces, house rules and host messages.
class CoSpaceRentalDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoSpaceRentalDomain();
  @override
  String get name => 'space_rental';
  @override
  Map<String, CoDomainRole> get roles => {
    'spaceName': textRole('space_rental.spaceName'),
    'spaceCategory': enumRole(['study', 'party', 'practice']),
    'districtName': textRole('space_rental.districtName'),
    'amenity': textRole('space_rental.amenity'),
    'equipmentOption': textRole('space_rental.equipmentOption'),
    'houseRule': textRole('space_rental.houseRule'),
    'refundPolicyLabel': enumRole(['standard', 'flexible', 'strict']),
    'hostName': firstNameRole(),
    'bookingPurpose': textRole('space_rental.bookingPurpose'),
    'guestMessage': textRole('space_rental.guestMessage'),
    'hostReply': textRole('space_rental.hostReply'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'rental_space': {
      'id': 'int',
      'name': 'String',
      'category': 'String',
      'district': 'String',
      'refundPolicy': 'String',
      'hostName': 'String',
      'imageUrl': 'String',
    },
    'space_booking': {
      'id': 'int',
      'spaceId': 'int',
      'bookingNo': 'String',
      'purpose': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'rental_space': {
      'name': 'spaceName',
      'category': 'spaceCategory',
      'district': 'districtName',
      'refundPolicy': 'refundPolicyLabel',
      'hostName': 'hostName',
    },
    'space_booking': {
      'bookingNo': 'booking.bookingNo',
      'purpose': 'bookingPurpose',
    },
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'space_booking': {
      'status': [
        'requested',
        'approved',
        'declined',
        'cancelled',
        'expired',
        'completed',
      ],
    },
  };
}
