class Schedule {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final String? location;

  Schedule({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dateTime: DateTime.parse(map['dateTime'] as String),
      location: map['location'] as String?,
    );
  }

  Schedule copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
    );
  }
}
