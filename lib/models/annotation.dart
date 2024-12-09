class Annotation {
  final String id;
  final String title;
  final String iconName;
  final String date;
  final String note;
  final double latitude;
  final double longitude;

  Annotation({
    required this.id,
    required this.title,
    required this.iconName,
    required this.date,
    required this.note,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iconName': iconName,
      'date': date,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
      id: json['id'] as String,
      title: json['title'] as String,
      iconName: json['iconName'] as String,
      date: json['date'] as String,
      note: json['note'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }

  @override
  String toString() {
    return 'Annotation(id: $id, title: $title, iconName: $iconName, date: $date, note: $note, latitude: $latitude, longitude: $longitude)';
  }
}