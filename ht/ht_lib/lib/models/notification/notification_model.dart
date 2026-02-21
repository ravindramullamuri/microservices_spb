class NotificationItem {
  final String uuid;
  final int userId;
  final bool seen;
  final DateTime? seenAt;
  final bool active;
  final String createdBy;
  final String? lastModifiedBy;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  final String title;
  final String message;

  NotificationItem({
    required this.uuid,
    required this.userId,
    required this.seen,
    required this.seenAt,
    required this.active,
    required this.createdBy,
    required this.lastModifiedBy,
    required this.createdAt,
    required this.lastModifiedAt,
    required this.title,
    required this.message,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      uuid: json['uuid'],
      userId: json['userId'],
      seen: json['seen'],
      seenAt: json['seenAt'] != null ? DateTime.parse(json['seenAt']) : null,
      active: json['active'],
      createdBy: json['createdBy'],
      lastModifiedBy: json['lastModifiedBy'],
      createdAt: DateTime.parse(json['createdAt']),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt']),
      title: json['title'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'userId': userId,
      'seen': seen,
      'seenAt': seenAt?.toIso8601String(),
      'active': active,
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'title': title,
      'message': message,
    };
  }

  NotificationItem copyWith({
    bool? seen,
    DateTime? seenAt,
  }) {
    return NotificationItem(
      uuid: uuid,
      userId: userId,
      seen: seen ?? this.seen,
      seenAt: seenAt ?? this.seenAt,
      active: active,
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy,
      createdAt: createdAt,
      lastModifiedAt: lastModifiedAt,
      title: title,
      message: message,
    );
  }
}
