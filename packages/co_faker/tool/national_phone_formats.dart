// Prints every national phone format as JSON for tool/verify_phone_formats.py:
//
//   dart run tool/national_phone_formats.dart | python3 tool/verify_phone_formats.py
import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';

void main() {
  final formats = [
    for (final country in CoFakerCountries.all)
      for (final format
          in CoFakerNationalLocales
              .byCountry[country.code]!
              .national!
              .phoneFormats)
        {
          'country': country.code,
          'national': format.national,
          'international': format.international,
          'mobile': format.mobile,
        },
  ];
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(formats));
}
