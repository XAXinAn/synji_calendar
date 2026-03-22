class Schedule {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final String? location;
  final String? groupId;
  final String? creatorName;
  final DateTime updatedAt; 
  final bool isDeleted;     

  Schedule({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.location,
    this.groupId,
    this.creatorName,
    DateTime? updatedAt,
    this.isDeleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'dateTime': dateTime.toUtc().toIso8601String(),
      'location': location,
      'groupId': groupId,
      'creatorName': creatorName,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    // 1. 处理删除标记 (防御所有后端可能的返回格式)
    final dynamic rawDel = map['isDeleted'] ?? map['is_deleted'];
    bool deleted = (rawDel == 1 || rawDel == '1' || rawDel == true || rawDel == 'true');

    // 2. 处理时间 (防御 camelCase 和 snake_case)
    String? rawTime = map['dateTime']?.toString() ?? map['date_time']?.toString();
    String? rawUpdated = map['updatedAt']?.toString() ?? map['updated_at']?.toString();

    return Schedule(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      dateTime: rawTime != null ? DateTime.parse(rawTime).toLocal() : DateTime.now(),
      location: map['location']?.toString(),
      groupId: map['groupId']?.toString() ?? map['group_id']?.toString(),
      creatorName: map['creatorName']?.toString() ?? map['creator_name']?.toString(),
      updatedAt: rawUpdated != null ? DateTime.parse(rawUpdated).toLocal() : DateTime.now(),
      isDeleted: deleted,
    );
  }

  Schedule copyWith({
    String? id, String? title, String? description, DateTime? dateTime,
    String? location, String? groupId, String? creatorName, DateTime? updatedAt, bool? isDeleted,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      groupId: groupId ?? this.groupId,
      creatorName: creatorName ?? this.creatorName,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
