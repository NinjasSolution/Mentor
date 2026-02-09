class MentorModel {
  String userId;
  String? email; // Added email field
  List<String> skills;
  String experience;
  String bio;
  String? name;
  String? phone;
  String? profilePicUrl;
  String? bannerUrl;
  String? linkedinUrl;
  String? githubUrl;
  String? youtubeUrl;
  double averageRating;
  int ratingCount;

  MentorModel({
    required this.userId,
    this.email,
    required this.skills,
    required this.experience,
    required this.bio,
    this.name,
    this.phone,
    this.profilePicUrl,
    this.bannerUrl,
    this.linkedinUrl,
    this.githubUrl,
    this.youtubeUrl,
    this.averageRating = 0.0,
    this.ratingCount = 0,
  });

  factory MentorModel.fromMap(Map<String, dynamic> map) {
    return MentorModel(
      userId: map['userId'] ?? '',
      email: map['email'] as String?,
      skills: map['skills'] != null ? List<String>.from(map['skills']) : [],
      experience: map['experience'] ?? '',
      bio: map['bio'] ?? '',
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      profilePicUrl: map['profilePicUrl'] as String?,
      bannerUrl: map['bannerUrl'] as String?,
      linkedinUrl: map['linkedinUrl'] as String?,
      githubUrl: map['githubUrl'] as String?,
      youtubeUrl: map['youtubeUrl'] as String?,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'skills': skills,
      'experience': experience,
      'bio': bio,
      'name': name,
      'phone': phone,
      'profilePicUrl': profilePicUrl,
      'bannerUrl': bannerUrl,
      'linkedinUrl': linkedinUrl,
      'githubUrl': githubUrl,
      'youtubeUrl': youtubeUrl,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    };
  }
}
