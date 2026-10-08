import '../domain.dart';
import 'authored_roles.dart';

/// Fictional stay/housekeeping/concierge labels, masked guests and generic menus.
class CoHospitalityDomain extends CoFakerDomain {
  /// Creates the shared hospitality pack.
  const CoHospitalityDomain();
  @override
  String get name => 'hospitality';
  @override
  Map<String, CoDomainRole> get roles => {
    'propertyName': textRole('hospitality.propertyName'),
    'siteName': textRole('hospitality.siteName'),
    'siteType': enumRole(['glamping', 'caravan', 'auto_camping']),
    'amenity': textRole('hospitality.amenity'),
    'stayOption': textRole('hospitality.stayOption'),
    'seasonName': textRole('hospitality.seasonName'),
    'ratePlan': textRole('hospitality.ratePlan'),
    'guestName': maskedNameRole(),
    'bookingNo': codeRole('DEMO-STAY', dated: true),
    'houseRule': textRole('hospitality.houseRule'),
    'reviewSnippet': textRole('hospitality.reviewSnippet'),
    'roomNo': authoredRole(
      (f, c) =>
          '${3 + c.index ~/ 12 % 10}${(1 + c.index % 12).toString().padLeft(2, '0')}',
    ),
    'roomType': enumRole([
      'standard_double',
      'standard_twin',
      'deluxe',
      'suite',
    ]),
    'bedType': authoredRole(
      (f, c) => ['double', 'twin', 'double', 'double'][c.index % 4],
      coherent: true,
    ),
    'housekeepingStatus': enumRole([
      'occupied',
      'vacant_ready',
      'vacant_dirty',
      'cleaning',
      'inspection',
      'out_of_order',
    ]),
    'cleanType': enumRole(['checkout_clean', 'stayover_clean', 'turndown']),
    'hkCheckItem': textRole('hospitality.hkCheckItem'),
    'maintenanceCategory': enumRole([
      'plumbing',
      'electrical',
      'hvac',
      'furniture',
      'other',
    ]),
    'maintenanceIssue': textRole('hospitality.maintenanceIssue'),
    'lostItemName': textRole('hospitality.lostItemName'),
    'confirmationNo': codeRole('DEMO-CONF', dated: true),
    'specialRequest': textRole('hospitality.specialRequest'),
    'menuItem': textRole('hospitality.menuItem'),
    'menuOption': textRole('hospitality.menuOption'),
    'requestType': enumRole([
      'amenity',
      'housekeeping',
      'wake_up',
      'repair',
      'other',
    ]),
    'amenityName': textRole('hospitality.amenityName'),
    'localSpot': textRole('hospitality.localSpot'),
    'conciergeReply': textRole('hospitality.conciergeReply'),
    'folioItem': textRole('hospitality.folioItem'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'campsite': {
      'id': 'int',
      'name': 'String',
      'siteType': 'String',
      'status': 'String',
    },
    'stay_booking': {
      'id': 'int',
      'siteId': 'int',
      'bookingNo': 'String',
      'guestName': 'String',
      'status': 'String',
    },
    'hotel_room': {
      'id': 'int',
      'roomNo': 'String',
      'roomType': 'String',
      'bedType': 'String',
      'status': 'String',
    },
    'guest_request': {
      'id': 'int',
      'stayId': 'int',
      'requestType': 'String',
      'amenityName': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'campsite': {'name': 'siteName', 'siteType': 'siteType'},
    'stay_booking': {'bookingNo': 'bookingNo', 'guestName': 'guestName'},
    'hotel_room': {
      'roomNo': 'roomNo',
      'roomType': 'roomType',
      'bedType': 'bedType',
      'status': 'housekeepingStatus',
    },
    'guest_request': {
      'requestType': 'requestType',
      'amenityName': 'amenityName',
    },
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'campsite': {
      'status': ['on_sale', 'paused'],
    },
    'stay_booking': {
      'status': [
        'requested',
        'confirmed',
        'completed',
        'canceled',
        'declined',
        'no_show',
      ],
    },
    'guest_request': {
      'status': [
        'submitted',
        'acknowledged',
        'in_progress',
        'done',
        'canceled',
      ],
    },
  };
}
