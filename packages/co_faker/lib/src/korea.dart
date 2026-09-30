import 'co_faker.dart';
import 'modules.dart';

/// A Korean road-name address split into the parts forms usually ask for.
typedef CoKoreanAddress = ({
  String postalCode,
  String sido,
  String sigungu,
  String road,
  int buildingNumber,
  String detail,
  String line1,
  String line2,
});

/// A Korean public holiday. [substitute] marks a substitute holiday
/// (대체공휴일); [block] groups the three days of Seollal and Chuseok.
typedef CoKoreanHoliday = ({
  DateTime date,
  String name,
  bool substitute,
  String? block,
});

/// Generates Korean identity values that are shaped like real ones but are
/// **deliberately invalid**, so they can never be mistaken for, or collide
/// with, a real person's or business's identifier.
///
/// The fake-by-construction rules:
///
/// - [mobilePhone] uses `010-0###-####`. Korean mobile subscriber numbers
///   never start the middle block with `0`, so the value is unassignable.
/// - [landlinePhone] uses `{area}-0##-####`: local exchanges never start with
///   `0` because `0` is the trunk prefix.
/// - [rrn] (resident registration number) keeps a real-looking birth date
///   and sex digit, but the last digit is forced to **fail** the checksum
///   ([isRrnChecksumValid] is always `false`). Every number issued before
///   October 2020 satisfies that checksum, so an unmasked value can never be
///   a real number; unmasked values for later birth dates (when the back
///   block became random) are refused. It is masked by default
///   (`YYMMDD-G******`), the way EMR screens show it.
/// - [businessNumber] (사업자등록번호) is forced to fail its checksum
///   ([isBusinessNumberChecksumValid] is always `false`).
///
/// Addresses use real public road names with random building numbers, and
/// postal codes follow the real per-province ranges, so a generated address
/// may coincidentally exist. Addresses are not identifiers, but do not use
/// them to send mail.
class CoFakerKorea {
  /// Creates a Korean identity generator backed by [faker].
  CoFakerKorea(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates an unassignable mobile number such as `010-0123-4567`.
  String mobilePhone({bool dashed = true}) {
    final value = faker.random.digits('010-0###-####');
    return dashed ? value : value.replaceAll('-', '');
  }

  /// Masks the middle block of a phone number: `010-0123-4567` becomes
  /// `010-****-4567`.
  static String maskPhone(String phone) {
    final parts = phone.split('-');
    if (parts.length != 3) return phone;
    return '${parts[0]}-${'*' * parts[1].length}-${parts[2]}';
  }

  /// Generates an unassignable landline number such as `02-012-3456`.
  ///
  /// [areaCode] defaults to a random Korean area code; pass the one matching
  /// an address from [roadAddress] for consistency ([areaCodeOf]).
  String landlinePhone({String? areaCode}) {
    final area = areaCode ?? faker.random.pick(_areaCodes);
    return faker.random.digits('$area-0##-####');
  }

  /// Returns the landline area code of a province name such as `서울특별시`.
  static String areaCodeOf(String sido) {
    for (final region in _regions) {
      if (region.sido == sido) return region.areaCode;
    }
    return '02';
  }

  /// Generates a date of birth in the inclusive age range, at midnight in
  /// the time zone of `faker.now`.
  DateTime birthDate({int minAge = 20, int maxAge = 60}) {
    final value = faker.date.dateOfBirth(
      minAge: minAge,
      maxAge: maxAge,
      utc: faker.now.isUtc,
    );
    return faker.now.isUtc
        ? DateTime.utc(value.year, value.month, value.day)
        : DateTime(value.year, value.month, value.day);
  }

  /// Generates a fake resident registration number (주민등록번호).
  ///
  /// The first block and the sex digit are derived from [birthDate] and
  /// [sex] (`1`/`2` before 2000, `3`/`4` from 2000). With [masked] (the
  /// default) the rest is replaced with `*`. Unmasked values carry an
  /// invalid check digit and require a birth date before October 2020 —
  /// see the class documentation.
  String rrn({DateTime? birthDate, CoSex? sex, bool masked = true}) {
    final birth = birthDate ?? this.birthDate();
    final resolvedSex = sex ?? faker.person.sex();
    final century = birth.year >= 2000 ? 2 : 0;
    final sexDigit = 1 + century + (resolvedSex == CoSex.female ? 1 : 0);
    final front =
        '${_two(birth.year % 100)}${_two(birth.month)}${_two(birth.day)}';
    if (masked) return '$front-$sexDigit******';
    if (!birth.isBefore(DateTime(2020, 10))) {
      throw ArgumentError.value(
        birth,
        'birthDate',
        'unmasked fake numbers need a birth date before 2020-10 (the '
            'checksum era); use masked: true',
      );
    }
    final body = '$front$sexDigit${faker.random.digits('#####')}';
    final valid = _rrnCheckDigit(body);
    final check = (valid + 1 + faker.random.int(max: 8)) % 10;
    return '$front-${body.substring(6)}$check';
  }

  /// Whether [value] passes the legacy resident registration number
  /// checksum. Always `false` for values generated by [rrn].
  static bool isRrnChecksumValid(String value) {
    final digits = value.replaceAll('-', '');
    if (!RegExp(r'^\d{13}$').hasMatch(digits)) return false;
    return _rrnCheckDigit(digits.substring(0, 12)) == int.parse(digits[12]);
  }

  /// Generates a fake business registration number (사업자등록번호) such as
  /// `123-45-67890` whose check digit is deliberately wrong.
  String businessNumber({bool dashed = true}) {
    final body = faker.random.digits('#########');
    final valid = _businessCheckDigit(body);
    final check = (valid + 1 + faker.random.int(max: 8)) % 10;
    final digits = '$body$check';
    if (!dashed) return digits;
    return '${digits.substring(0, 3)}-${digits.substring(3, 5)}-'
        '${digits.substring(5)}';
  }

  /// Whether [value] passes the business registration number checksum.
  /// Always `false` for values generated by [businessNumber].
  static bool isBusinessNumberChecksumValid(String value) {
    final digits = value.replaceAll('-', '');
    if (!RegExp(r'^\d{10}$').hasMatch(digits)) return false;
    return _businessCheckDigit(digits.substring(0, 9)) == int.parse(digits[9]);
  }

  /// Generates a road-name address (도로명 주소) with a matching postal code
  /// and an apartment-style detail line.
  CoKoreanAddress roadAddress() {
    final region = faker.random.pick(_regions);
    final road = faker.random.pick(region.roads);
    final number = faker.random.int(min: 1, max: 520);
    final postal = faker.random
        .int(min: region.postalMin, max: region.postalMax)
        .toString()
        .padLeft(5, '0');
    final detail = faker.random.bool()
        ? '${faker.random.int(min: 101, max: 115)}동 '
              '${faker.random.int(min: 1, max: 25)}'
              '${_two(faker.random.int(min: 1, max: 8))}호'
        : '${faker.random.int(min: 2, max: 12)}층';
    return (
      postalCode: postal,
      sido: region.sido,
      sigungu: region.sigungu,
      road: road,
      buildingNumber: number,
      detail: detail,
      line1: '${region.sido} ${region.sigungu} $road $number',
      line2: detail,
    );
  }

  /// The first and last years supported by [holidays].
  static const (int, int) holidayYears = (2024, 2030);

  /// Returns the Korean public holidays of [year] (2024-2030), sorted, as
  /// UTC midnight dates. Does not consume the random stream.
  ///
  /// Includes the fixed solar holidays (신정, 삼일절, 어린이날, 현충일,
  /// 광복절, 개천절, 한글날, 성탄절), the lunar holidays from a per-year
  /// table (설날 and 추석 with the days before and after, 부처님오신날), and
  /// substitute holidays under the current rules:
  ///
  /// - 설날·추석: a day falling on a Sunday or on another holiday adds a
  ///   substitute on the next non-holiday weekday.
  /// - 어린이날: Saturday, Sunday, or another holiday adds a substitute.
  /// - 삼일절, 광복절, 개천절, 한글날, 부처님오신날, 성탄절: Saturday or
  ///   Sunday adds a substitute.
  /// - 신정 and 현충일 have no substitute.
  ///
  /// Election days and one-off temporary holidays (임시공휴일) are not
  /// included; merge them yourself. Throws for years outside
  /// [holidayYears].
  static List<CoKoreanHoliday> holidays({required int year}) {
    final lunar = _lunar[year];
    if (lunar == null) {
      throw ArgumentError.value(
        year,
        'year',
        'supported years are ${holidayYears.$1}-${holidayYears.$2}',
      );
    }
    DateTime d(int m, int day) => DateTime.utc(year, m, day);
    final seollal = d(lunar.$1.$1, lunar.$1.$2);
    final chuseok = d(lunar.$2.$1, lunar.$2.$2);
    final buddha = d(lunar.$3.$1, lunar.$3.$2);
    const oneDay = Duration(days: 1);
    // (date, name, block, substitute rule): 0 none, 1 weekend, 2 weekend or
    // overlap, 3 Sunday or overlap (lunar blocks).
    final base = <(DateTime, String, String?, int)>[
      (d(1, 1), '신정', null, 0),
      (seollal.subtract(oneDay), '설날 연휴', 'seollal', 3),
      (seollal, '설날', 'seollal', 3),
      (seollal.add(oneDay), '설날 연휴', 'seollal', 3),
      (d(3, 1), '삼일절', null, 1),
      (d(5, 5), '어린이날', null, 2),
      (buddha, '부처님오신날', null, 1),
      (d(6, 6), '현충일', null, 0),
      (d(8, 15), '광복절', null, 1),
      (chuseok.subtract(oneDay), '추석 연휴', 'chuseok', 3),
      (chuseok, '추석', 'chuseok', 3),
      (chuseok.add(oneDay), '추석 연휴', 'chuseok', 3),
      (d(10, 3), '개천절', null, 1),
      (d(10, 9), '한글날', null, 1),
      (d(12, 25), '성탄절', null, 1),
    ];
    final taken = <DateTime>{for (final h in base) h.$1};
    final substitutes = <CoKoreanHoliday>[];
    final blocksDone = <String>{};
    bool overlaps(DateTime date) => base.where((h) => h.$1 == date).length > 1;
    DateTime nextFree(DateTime after) {
      var day = after.add(oneDay);
      while (taken.contains(day) ||
          day.weekday == DateTime.saturday ||
          day.weekday == DateTime.sunday) {
        day = day.add(oneDay);
      }
      return day;
    }

    for (final h in base) {
      final (date, name, block, rule) = h;
      final weekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final String? label;
      DateTime after = date;
      switch (rule) {
        case 1:
          label = weekend ? name : null;
        case 2:
          label = weekend || overlaps(date) ? name : null;
        case 3:
          final days = base.where((x) => x.$3 == block).map((x) => x.$1);
          final trigger = days.any(
            (x) => x.weekday == DateTime.sunday || overlaps(x),
          );
          label = trigger && blocksDone.add(block!)
              ? (block == 'seollal' ? '설날' : '추석')
              : null;
          after = days.reduce((a, b) => a.isAfter(b) ? a : b);
        default:
          label = null;
      }
      if (label == null) continue;
      final day = nextFree(after);
      taken.add(day);
      substitutes.add((
        date: day,
        name: '대체공휴일($label)',
        substitute: true,
        block: null,
      ));
    }
    final all = <CoKoreanHoliday>[
      for (final h in base)
        (date: h.$1, name: h.$2, substitute: false, block: h.$3),
      ...substitutes,
    ]..sort((a, b) => a.date.compareTo(b.date));
    return all;
  }

  /// Returns the holidays falling on the calendar day of [date], if any.
  static List<CoKoreanHoliday> holidaysOn(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    return holidays(year: date.year).where((h) => h.date == day).toList();
  }

  /// Lunar holidays per year: (설날, 추석, 부처님오신날) as (month, day).
  static const Map<int, ((int, int), (int, int), (int, int))> _lunar =
      <int, ((int, int), (int, int), (int, int))>{
        2024: ((2, 10), (9, 17), (5, 15)),
        2025: ((1, 29), (10, 6), (5, 5)),
        2026: ((2, 17), (9, 25), (5, 24)),
        2027: ((2, 6), (9, 15), (5, 13)),
        2028: ((1, 26), (10, 3), (5, 2)),
        2029: ((2, 13), (9, 22), (5, 20)),
        2030: ((2, 3), (9, 12), (5, 9)),
      };

  /// Generates a card approval number (8 digits).
  String cardApprovalNumber() => faker.random.digits('########');

  static int _rrnCheckDigit(String twelve) {
    const weights = <int>[2, 3, 4, 5, 6, 7, 8, 9, 2, 3, 4, 5];
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(twelve[i]) * weights[i];
    }
    return (11 - sum % 11) % 10;
  }

  static int _businessCheckDigit(String nine) {
    const weights = <int>[1, 3, 7, 1, 3, 7, 1, 3, 5];
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(nine[i]) * weights[i];
    }
    sum += (int.parse(nine[8]) * 5) ~/ 10;
    return (10 - sum % 10) % 10;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static const List<String> _areaCodes = <String>[
    '02',
    '031',
    '032',
    '051',
    '053',
    '042',
    '062',
    '064',
  ];

  static const List<
    ({
      String sido,
      String sigungu,
      List<String> roads,
      String areaCode,
      int postalMin,
      int postalMax,
    })
  >
  _regions = [
    (
      sido: '서울특별시',
      sigungu: '강남구',
      roads: <String>['테헤란로', '강남대로', '도산대로', '압구정로', '논현로'],
      areaCode: '02',
      postalMin: 6000,
      postalMax: 6399,
    ),
    (
      sido: '서울특별시',
      sigungu: '서초구',
      roads: <String>['서초대로', '반포대로', '방배로'],
      areaCode: '02',
      postalMin: 6500,
      postalMax: 6799,
    ),
    (
      sido: '서울특별시',
      sigungu: '송파구',
      roads: <String>['올림픽로', '송파대로', '백제고분로'],
      areaCode: '02',
      postalMin: 5500,
      postalMax: 5899,
    ),
    (
      sido: '서울특별시',
      sigungu: '마포구',
      roads: <String>['월드컵북로', '양화로', '독막로'],
      areaCode: '02',
      postalMin: 3900,
      postalMax: 4199,
    ),
    (
      sido: '서울특별시',
      sigungu: '영등포구',
      roads: <String>['여의대로', '국제금융로', '영등포로'],
      areaCode: '02',
      postalMin: 7200,
      postalMax: 7499,
    ),
    (
      sido: '경기도',
      sigungu: '성남시 분당구',
      roads: <String>['판교역로', '분당로', '황새울로'],
      areaCode: '031',
      postalMin: 13400,
      postalMax: 13699,
    ),
    (
      sido: '경기도',
      sigungu: '수원시 영통구',
      roads: <String>['광교중앙로', '영통로', '봉영로'],
      areaCode: '031',
      postalMin: 16400,
      postalMax: 16799,
    ),
    (
      sido: '경기도',
      sigungu: '고양시 일산동구',
      roads: <String>['중앙로', '정발산로', '장백로'],
      areaCode: '031',
      postalMin: 10300,
      postalMax: 10499,
    ),
    (
      sido: '인천광역시',
      sigungu: '연수구',
      roads: <String>['컨벤시아대로', '송도과학로', '청량로'],
      areaCode: '032',
      postalMin: 21900,
      postalMax: 22099,
    ),
    (
      sido: '부산광역시',
      sigungu: '해운대구',
      roads: <String>['해운대로', '센텀중앙로', '달맞이길'],
      areaCode: '051',
      postalMin: 48000,
      postalMax: 48199,
    ),
    (
      sido: '부산광역시',
      sigungu: '부산진구',
      roads: <String>['중앙대로', '서면로', '전포대로'],
      areaCode: '051',
      postalMin: 47100,
      postalMax: 47399,
    ),
    (
      sido: '대구광역시',
      sigungu: '중구',
      roads: <String>['동성로', '국채보상로', '달구벌대로'],
      areaCode: '053',
      postalMin: 41900,
      postalMax: 41999,
    ),
    (
      sido: '대전광역시',
      sigungu: '서구',
      roads: <String>['둔산로', '대덕대로', '계룡로'],
      areaCode: '042',
      postalMin: 35200,
      postalMax: 35399,
    ),
    (
      sido: '광주광역시',
      sigungu: '서구',
      roads: <String>['상무중앙로', '운천로', '치평로'],
      areaCode: '062',
      postalMin: 61900,
      postalMax: 62099,
    ),
    (
      sido: '제주특별자치도',
      sigungu: '제주시',
      roads: <String>['연북로', '노형로', '도령로'],
      areaCode: '064',
      postalMin: 63100,
      postalMax: 63399,
    ),
  ];
}
