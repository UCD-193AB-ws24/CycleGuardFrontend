class SingleTripInfo {
  final double distance, calories, time, averageAltitude, climb;

  const SingleTripInfo({required this.distance, required this.calories, required this.time,
  required this.averageAltitude, required this.climb});

  factory SingleTripInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "distance": String distance,
      "calories": String calories,
      "time": String time,
      "averageAltitude": String averageAltitude,
      "climb": String climb,
      } => SingleTripInfo(
        distance: double.parse(distance),
        calories: double.parse(calories),
        time: double.parse(time),
        averageAltitude: double.parse(averageAltitude),
        climb: double.parse(climb),
      ),
      _ => throw const FormatException("failed to load DayHistory"),
    };
  }

  @override
  String toString() {
    return 'SingleTripInfo{distance: $distance, calories: $calories, time: $time}';
  }
}