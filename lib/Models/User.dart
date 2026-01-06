class User {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
  });

  factory User.fromJson(dynamic json) {
    final Map<String, dynamic> data = json is Map<String, dynamic> 
        ? json 
        : Map<String, dynamic>.from(json as Map);
    return User(
      id: data['id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      fullName: data['username'] ?? data['full_name'] ?? data['fullName'] ?? '',
      avatarUrl: data['avatar_url'] ?? data['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    };
  }
}
