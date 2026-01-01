class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final String? phoneNumber;
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.phoneNumber,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'bio': bio,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'],
    email: json['email'],
    displayName: json['displayName'],
    photoUrl: json['photoUrl'],
    bio: json['bio'],
    phoneNumber: json['phoneNumber'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );
}
