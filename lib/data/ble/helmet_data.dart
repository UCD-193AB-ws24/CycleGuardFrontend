class HelmetData {
  final double speed, distance, latitude, longitude;
  static final List<double> _divisors = [1e2, 1e3, 1e6, 1e6];


  HelmetData._construct(this.speed, this.distance, this.latitude, this.longitude);

  static HelmetData parseBluetoothData(List<int> bluetoothDataList) {
    final speed = bluetoothDataList[0]/_divisors[0];
    final distance = bluetoothDataList[1]/_divisors[1];
    final latitude = bluetoothDataList[2]/_divisors[2];
    final longitude = bluetoothDataList[3]/_divisors[3];

    return HelmetData._construct(speed, distance, latitude, longitude);
  }
}