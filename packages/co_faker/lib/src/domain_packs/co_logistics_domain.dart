import '../domain.dart';
import 'authored_roles.dart';

/// Fictional logistics/WMS identifiers, masked plates and generic item labels.
class CoLogisticsDomain extends CoFakerDomain {
  /// Creates the last-mile, freight and WMS pack.
  const CoLogisticsDomain();
  @override
  String get name => 'logistics';

  /// SKU codes; the item's name is `logistics.itemName` in the same order.
  static const _skus = <String>[
    'BOX-S-200',
    'TAPE-OPP-48',
    'TOWEL-COT-03',
    'RICE-BRN-02',
  ];
  @override
  Map<String, CoDomainRole> get roles => {
    'trackingNo': codeRole('HD', dated: true),
    'routeCode': codeRole('R', width: 3, dated: true),
    'zoneName': textRole('logistics.zoneName'),
    'hubName': textRole('logistics.hubName'),
    'vehicleType': enumRole([
      'ton1_cargo',
      'ton2_5_wing',
      'ton5_cargo',
      'ton11_wing',
      'reefer_box',
    ]),
    'vehiclePlate': authoredRole(
      (f, c) => f.l10n.format('logistics.vehiclePlate', {
        'n': 10 + c.index % 80,
        'm': (c.index % 100).toString().padLeft(2, '0'),
      }),
      description: 'Masked fictional plate, never complete',
    ),
    'timeWindow': authoredRole(
      (f, c) =>
          '${(9 + c.index % 9).toString().padLeft(2, '0')}:00~${(11 + c.index % 9).toString().padLeft(2, '0')}:00',
    ),
    'parcelSize': enumRole(['small', 'medium', 'large', 'oversized']),
    'deliveryNote': textRole('logistics.deliveryNote'),
    'entranceHint': textRole('logistics.entranceHint'),
    'exceptionReason': enumRole([
      'absent',
      'wrong_address',
      'damaged',
      'refused',
      'access_denied',
    ]),
    'scanEvent': textRole('logistics.scanEvent'),
    'driverName': firstNameRole(),
    'carrierLabel': textRole('logistics.carrierLabel'),
    'freightType': textRole('logistics.freightType'),
    'tonnage': authoredRole(
      (f, c) => [1.0, 2.5, 5.0, 11.0, 5.0][c.index % 5],
      type: 'double',
      coherent: true,
    ),
    'palletCount': intRole(1, 24),
    'loadingDock': authoredRole((f, c) => 'D${1 + c.index % 8}'),
    'routeSummary': textRole('logistics.routeSummary'),
    'fareItem': textRole('logistics.fareItem'),
    'sku': authoredRole(
      (f, c) => _skus[c.index % _skus.length],
      coherent: true,
    ),
    'itemName': indexedTextRole('logistics.itemName', rows: _skus.length),
    'binCode': authoredRole(
      (f, c) =>
          '${['A', 'B', 'C', 'D'][c.index % 4]}-${(1 + c.index % 12).toString().padLeft(2, '0')}-${(1 + c.index % 4).toString().padLeft(2, '0')}-${1 + c.index % 3}',
    ),
    'lotNo': codeRole('DEMO-LOT', dated: true),
    'expiryDate': authoredRole(
      (f, _) => f.date.future(days: 365, utc: true),
      type: 'DateTime',
      description: 'Illustrative expiry after the supplied clock, UTC',
    ),
    'asnNo': codeRole('ASN', dated: true),
    'waveNo': codeRole('WAVE', dated: true),
    'palletId': codeRole('DEMO-PALLET'),
    'dockNo': authoredRole((f, c) => 'D${1 + c.index % 8}'),
    'ownerLabel': textRole('logistics.ownerLabel'),
    // W1 recipe fields (co-package#78).
    'recipientArea': authoredRole(
      (f, _) => f.address.city(),
      description: 'City of the recipient in the locale',
    ),
    'shelfSlot': authoredRole(
      (f, c) =>
          '${['A', 'B', 'C', 'D', 'E', 'F'][c.index % 6]}-'
          '${(1 + c.index % 20).toString().padLeft(2, '0')}-${1 + c.index % 4}',
      description: 'Shelf slot code: aisle, bay, level',
    ),
    'signatureData': signatureRole(),
    'exceptionDetail': textRole('logistics.exceptionDetail'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'delivery_route': {
      'id': 'int',
      'routeCode': 'String',
      'driverName': 'String',
      'zoneName': 'String',
      'vehiclePlate': 'String',
      'status': 'String',
    },
    'delivery_stop': {
      'id': 'int',
      'routeId': 'int',
      'trackingNo': 'String',
      'timeWindow': 'String',
      'entranceHint': 'String',
      'status': 'String',
    },
    'freight_order': {
      'id': 'int',
      'vehicleType': 'String',
      'tonnage': 'double',
      'palletCount': 'int',
      'status': 'String',
    },
    'bin_stock': {
      'id': 'int',
      'itemName': 'String',
      'skuCode': 'String',
      'binCode': 'String',
      'lotNo': 'String',
      'expiryDate': 'DateTime',
    },
    'inbound_order': {
      'id': 'int',
      'asnNo': 'String',
      'dockNo': 'String',
      'ownerLabel': 'String',
      'status': 'String',
    },
    'outbound_order': {
      'id': 'int',
      'waveNo': 'String',
      'carrierLabel': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'delivery_route': {
      'routeCode': 'routeCode',
      'driverName': 'driverName',
      'zoneName': 'zoneName',
      'vehiclePlate': 'vehiclePlate',
    },
    'delivery_stop': {
      'trackingNo': 'trackingNo',
      'timeWindow': 'timeWindow',
      'entranceHint': 'entranceHint',
    },
    'freight_order': {
      'vehicleType': 'vehicleType',
      'tonnage': 'tonnage',
      'palletCount': 'palletCount',
    },
    'bin_stock': {
      'itemName': 'itemName',
      'skuCode': 'sku',
      'binCode': 'binCode',
      'lotNo': 'lotNo',
      'expiryDate': 'expiryDate',
    },
    'inbound_order': {
      'asnNo': 'asnNo',
      'dockNo': 'dockNo',
      'ownerLabel': 'ownerLabel',
    },
    'outbound_order': {'waveNo': 'waveNo', 'carrierLabel': 'carrierLabel'},
    'load_item': {
      'trackingNo': 'trackingNo',
      'recipientArea': 'recipientArea',
      'shelfSlot': 'shelfSlot',
    },
    'parcel_scan': {'trackingNo': 'trackingNo'},
    'delivery_proof': {'signatureData': 'signatureData'},
    'delivery_exception': {'detail': 'exceptionDetail'},
    'courier': {'vehicleType': 'vehicleType', 'vehiclePlate': 'vehiclePlate'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'delivery_route': {
      'status': ['assigned', 'loading', 'on_road', 'returned_to_hub', 'closed'],
    },
    'delivery_stop': {
      'status': ['pending', 'arrived', 'failed', 'delivered', 'returned'],
    },
    'freight_order': {
      'status': [
        'requested',
        'quoted',
        'accepted',
        'dispatched',
        'loaded',
        'in_transit',
        'unloaded',
        'settled',
        'canceled',
      ],
    },
    'inbound_order': {
      'status': [
        'scheduled',
        'arrived',
        'inspecting',
        'putaway',
        'on_hold',
        'stored',
        'canceled',
      ],
    },
    'outbound_order': {
      'status': [
        'instructed',
        'picking',
        'inspecting',
        'packed',
        'shipped',
        'held',
      ],
    },
  };
}
