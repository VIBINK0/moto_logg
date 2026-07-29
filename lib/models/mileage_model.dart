class MileageRecord {
  final String id;
  final double odometerReading;
  final double fuelLiters;
  final double pricePerLiter;
  final DateTime date;

  MileageRecord({
    required this.id,
    required this.odometerReading,
    required this.fuelLiters,
    required this.pricePerLiter,
    required this.date,
  });

  double get totalCost => fuelLiters * pricePerLiter;

  Map<String, dynamic> toJson() => {
        'id': id,
        'odometerReading': odometerReading,
        'fuelLiters': fuelLiters,
        'pricePerLiter': pricePerLiter,
        'date': date.toIso8601String(),
      };

  factory MileageRecord.fromJson(Map<String, dynamic> json) => MileageRecord(
        id: json['id'],
        odometerReading: (json['odometerReading'] as num).toDouble(),
        fuelLiters: (json['fuelLiters'] as num).toDouble(),
        pricePerLiter: (json['pricePerLiter'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      );
}

class MileageComparison {
  final MileageRecord current;
  final MileageRecord? previous;

  MileageComparison({required this.current, this.previous});

  double get distanceTraveled =>
      previous != null ? current.odometerReading - previous!.odometerReading : 0;

  // Mileage is calculated based on fuel filled at the CURRENT reading 
  // to cover the distance since PREVIOUS reading.
  double get mileage => (previous != null && current.fuelLiters > 0)
      ? distanceTraveled / current.fuelLiters
      : 0;

  double get pricePerKm => (previous != null && distanceTraveled > 0)
      ? current.totalCost / distanceTraveled
      : 0;
}
