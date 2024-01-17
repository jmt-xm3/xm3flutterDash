
class Reading {
  String time = "";
  double speed = 0.0;
  double altitude = 0.0;

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'speedMps': speed,
      'altitude': altitude,
    };
  }
}