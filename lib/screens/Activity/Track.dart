class Track {
  DateTime date;
  String duration;
  int stepCount;
  double distance;
  double speed;

  Track(this.date, this.duration, this.stepCount, this.distance, this.speed);

  Track.fromJson(Map<String, dynamic> json)
      : date = DateTime.parse(json['date']),
        duration = json['duration'],
        stepCount = json['stepCount'],
        distance = json['distance'],
        speed = json['speed'];

  Map<String, dynamic> toJson() => {
    'date': date.toString(),
    'duration': duration,
    'stepCount': stepCount,
    'distance': distance,
    'speed': speed
  };
}