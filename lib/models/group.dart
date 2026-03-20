class Group {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final String inviteCode;
  final List<String> memberIds;
  final List<String> adminIds;
  final DateTime createdAt;
  final int memberCount; // 新增字段

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    required this.inviteCode,
    required this.memberIds,
    required this.adminIds,
    required this.createdAt,
    required this.memberCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'inviteCode': inviteCode,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'createdAt': createdAt.toIso8601String(),
      'memberCount': memberCount,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      creatorId: map['creatorId'] as String,
      inviteCode: map['inviteCode'] as String,
      memberIds: List<String>.from(map['memberIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      // 优先从后端 Dto 的 memberCount 取值，兜底使用 memberIds 的长度
      memberCount: map['memberCount'] as int? ?? (List<String>.from(map['memberIds'] ?? [])).length,
    );
  }

  bool isAdmin(String userId) {
    return userId == creatorId || adminIds.contains(userId);
  }
}

class GroupMember {
  final String id;
  final String username;
  final String nickname;

  GroupMember({
    required this.id,
    required this.username,
    required this.nickname,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] as String,
      username: map['username'] as String,
      nickname: map['nickname'] as String,
    );
  }
}
