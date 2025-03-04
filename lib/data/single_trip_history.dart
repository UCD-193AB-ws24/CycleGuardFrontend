class SingleTripInfo {
  final double distance, calories, time;

  const SingleTripInfo({required this.distance, required this.calories, required this.time});

  factory SingleTripInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "distance": String distance,
      "calories": String calories,
      "time": String time,
      } => SingleTripInfo(
        distance: double.parse(distance),
        calories: double.parse(calories),
        time: double.parse(time),
      ),
      _ => throw const FormatException("failed to load DayHistory"),
    };
  }

  @override
  String toString() {
    return 'SingleTripInfo{distance: $distance, calories: $calories, time: $time}';
  }
}