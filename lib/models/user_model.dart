class UserModel {
  String id;
  String name;
  String email;
  String role;  // 'admin', 'mentor', 'student'
  String status;  // 'pending', 'approved'
  String? profilePicUrl; // <-- Profile picture field added

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.profilePicUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      status: map['status'] ?? 'pending',
      profilePicUrl: map['profilePicUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'profilePicUrl': profilePicUrl,
    };
  }
}
