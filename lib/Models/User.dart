class User {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final String? phoneNumber;
  final bool isOnline;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.phoneNumber,
    this.isOnline = false,
  });

  factory User.fromJson(dynamic json) {
    final Map<String, dynamic> data = json is Map<String, dynamic> 
        ? json 
        : Map<String, dynamic>.from(json as Map);
    return User(
      id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      fullName: data['username'] ?? data['full_name'] ?? data['fullName'] ?? '',
      avatarUrl: data['avatar_url'] ?? data['avatarUrl'],
      bio: data['bio'],
      phoneNumber: data['phone_number'] ?? data['phoneNumber'] ?? data['phone_Number'],
      isOnline: data['is_online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'phone_number': phoneNumber,
      'is_online': isOnline,
    };
  }
}