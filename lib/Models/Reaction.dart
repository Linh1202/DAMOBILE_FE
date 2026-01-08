class Reaction {
  final String userId;
  final String emoji;
  final DateTime createdAt;

  Reaction({
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      userId: json['user_id']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'Reaction(userId: $userId, emoji: $emoji)';
}