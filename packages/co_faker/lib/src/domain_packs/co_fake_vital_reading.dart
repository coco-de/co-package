import '../co_faker.dart';

/// Bounded illustrative vital signs with coherent systolic/diastolic ordering.
class CoFakeVitalReading {
  /// Constructs a pair and associated example vital signs.
  const CoFakeVitalReading({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.bodyTemperature,
    required this.bloodGlucose,
  });

  /// Generates only illustrative ranges; performs no medical classification.
  factory CoFakeVitalReading.generate(CoFaker f) => CoFakeVitalReading(
    systolic: f.number.int(min: 110, max: 140),
    diastolic: f.number.int(min: 70, max: 90),
    pulse: f.number.int(min: 60, max: 95),
    bodyTemperature: f.number.decimal(min: 36.2, max: 37.4, decimals: 1),
    bloodGlucose: f.number.int(min: 80, max: 140),
  );

  /// Example systolic pressure in mmHg.
  final int systolic;

  /// Example diastolic pressure in mmHg.
  final int diastolic;

  /// Example pulse in beats/minute.
  final int pulse;

  /// Example temperature in Celsius.
  final double bodyTemperature;

  /// Example blood glucose in mg/dL.
  final int bloodGlucose;

  /// Serialized primitive values with their units.
  Map<String, Object?> toJson() => {
    'systolic': systolic,
    'diastolic': diastolic,
    'pressureUnit': 'mmHg',
    'pulse': pulse,
    'bodyTemperature': bodyTemperature,
    'temperatureUnit': 'C',
    'bloodGlucose': bloodGlucose,
    'glucoseUnit': 'mg/dL',
  };
}
