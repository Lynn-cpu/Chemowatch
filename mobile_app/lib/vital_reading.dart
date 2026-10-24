// One VitalReading represents one set of temperature and heart-rate readings.
class VitalReading {
  final double temperature;
  final int heartRate;
  final DateTime time;

  const VitalReading({
    required this.temperature,
    required this.heartRate,
    required this.time,
  });

  // Convert a reading into a format that can be saved.
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'heartRate': heartRate,
      'time': time.toIso8601String(),
    };
  }

  // Re-create a reading when loading saved data.
  factory VitalReading.fromJson(Map<String, dynamic> json) {
    return VitalReading(
      temperature: (json['temperature'] as num).toDouble(),
      heartRate: (json['heartRate'] as num).toInt(),
      time: DateTime.parse(json['time'] as String),
    );
  }
}