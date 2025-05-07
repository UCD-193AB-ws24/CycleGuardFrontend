class SingleTripInfo {
  final double distance, calories, time, averageAltitude, climb;

  const SingleTripInfo({required this.distance, required this.calories, required this.time,
  required this.averageAltitude, required this.climb});

  factory SingleTripInfo.fromJson(Map<String, dynamic> json) {
    double distance=0, calories=0, time=0, averageAltitude=0, climb=0;
    if (json.containsKey("distance")) distance = double.parse(json["distance"]);
    if (json.containsKey("calories")) calories = double.parse(json["calories"]);
    if (json.containsKey("time")) time = double.parse(json["time"]);
    if (json.containsKey("averageAltitude")) averageAltitude = double.parse(json["averageAltitude"]);
    if (json.containsKey("climb")) climb = double.parse(json["climb"]);
    return SingleTripInfo(distance: distance, calories: calories, time: time, averageAltitude: averageAltitude, climb: climb);
  }

  @override
  String toString() {
    return 'SingleTripInfo{distance: $distance, calories: $calories, time: $time, averageAltitude: $averageAltitude, '
        'climb: $climb}';
  }
}