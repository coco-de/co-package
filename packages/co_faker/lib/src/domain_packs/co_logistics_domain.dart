import '../domain.dart';
import 'authored_roles.dart';

/// Fictional logistics/WMS identifiers, masked plates and generic item labels.
class CoLogisticsDomain extends CoFakerDomain {
  /// Creates the last-mile, freight and WMS pack.
  const CoLogisticsDomain();
  @override
  String get name => 'logistics';
  static const _items = <(String, String, String)>[
    ('BOX-S-200', '종이 박스 소', 'Small paper box'),
    ('TAPE-OPP-48', '포장 테이프 48mm', 'Packaging tape 48mm'),
    ('TOWEL-COT-03', '면 수건 3입', 'Cotton towels, 3 pieces'),
    ('RICE-BRN-02', '현미 2kg', 'Brown rice 2kg'),
  ];
  @override
  Map<String, CoDomainRole> get roles => {
    'trackingNo': codeRole('HD', dated: true),
    'routeCode': codeRole('R', width: 3, dated: true),
    'zoneName': textRole(
      ['솔내동 1권역(가상)', '솔내동 2권역(가상)', '가람동 권역(가상)'],
      [
        'Solnae zone 1 (fictional)',
        'Solnae zone 2 (fictional)',
        'Garam zone (fictional)',
      ],
    ),
    'hubName': textRole(
      ['솔빛 허브(가상)', '가람 허브(가상)'],
      ['Solbit hub (fictional)', 'Garam hub (fictional)'],
    ),
    'vehicleType': enumRole([
      'ton1_cargo',
      'ton2_5_wing',
      'ton5_cargo',
      'ton11_wing',
      'reefer_box',
    ]),
    'vehiclePlate': authoredRole(
      (f, c) =>
          '${10 + c.index % 80}가●●${(c.index % 100).toString().padLeft(2, '0')}',
      description: 'Masked fictional plate, never complete',
    ),
    'timeWindow': authoredRole(
      (f, c) =>
          '${(9 + c.index % 9).toString().padLeft(2, '0')}:00~${(11 + c.index % 9).toString().padLeft(2, '0')}:00',
    ),
    'parcelSize': enumRole(['small', 'medium', 'large', 'oversized']),
    'deliveryNote': textRole(
      ['문 앞 보관 금지 · 직접 수령', '공동현관에서 호출해 주세요.', '경비실 확인 후 전달해 주세요.'],
      [
        'No unattended delivery; hand over directly.',
        'Please ring at the shared entrance.',
        'Please check with the security desk.',
      ],
    ),
    'entranceHint': textRole(
      ['공동현관 #●●●● · 경비실 호출', '입구 호출 버튼 이용 · 비밀번호 없음'],
      [
        'Shared entrance #••••; call security desk',
        'Use the entrance call button; no password shown',
      ],
    ),
    'exceptionReason': enumRole([
      'absent',
      'wrong_address',
      'damaged',
      'refused',
      'access_denied',
    ]),
    'scanEvent': textRole(
      ['허브 입고', '간선 상차', '배송 출발', '배송 완료', '미배송'],
      [
        'Hub arrival',
        'Line-haul loading',
        'Out for delivery',
        'Delivery complete',
        'Delivery not completed',
      ],
    ),
    'driverName': firstNameRole(),
    'carrierLabel': textRole(
      ['예시 배송사 A(가상)', '예시 배송사 B(가상)', '예시 운송사 C(가상)'],
      [
        'Example carrier A (fictional)',
        'Example carrier B (fictional)',
        'Example freight carrier C (fictional)',
      ],
    ),
    'freightType': textRole(
      ['포장재', '식자재', '건자재', '전자부품', '생활용품'],
      [
        'Packaging',
        'Food supplies',
        'Building materials',
        'Electronic parts',
        'Household goods',
      ],
    ),
    'tonnage': authoredRole(
      (f, c) => [1.0, 2.5, 5.0, 11.0, 5.0][c.index % 5],
      type: 'double',
      coherent: true,
    ),
    'palletCount': intRole(1, 24),
    'loadingDock': authoredRole((f, c) => 'D${1 + c.index % 8}'),
    'routeSummary': textRole(
      ['가상시 솔빛권역 → 가람권역', '가상시 물푸레권역 → 솔내권역'],
      [
        'Fictional Solbit zone → Garam zone',
        'Fictional Mulpare zone → Solnae zone',
      ],
    ),
    'fareItem': textRole(
      ['기본 운임(예시)', '리프트 추가(예시)', '수작업 추가(예시)', '대기 시간(예시)'],
      [
        'Base fare (example)',
        'Liftgate add-on (example)',
        'Manual handling (example)',
        'Waiting time (example)',
      ],
    ),
    'sku': authoredRole(
      (f, c) => _items[c.index % _items.length].$1,
      coherent: true,
    ),
    'itemName': authoredRole(
      (f, c) => localized(
        f,
        _items[c.index % _items.length].$2,
        _items[c.index % _items.length].$3,
      ),
      coherent: true,
    ),
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
    'ownerLabel': textRole(
      ['화주사 A(가상)', '화주사 B(가상)', '화주사 C(가상)'],
      [
        'Cargo owner A (fictional)',
        'Cargo owner B (fictional)',
        'Cargo owner C (fictional)',
      ],
    ),
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
