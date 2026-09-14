/// A locally-stored user profile.
///
/// The app has no account backend — sign up / sign in are simulated — so
/// this is the on-device record of "who is using this phone", persisted
/// across restarts via [UserProfileService].
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.role,
    this.avatarPath,
  });

  final String name;
  final String email;
  final String role;

  /// Path to the profile photo file in the app's documents directory, or
  /// null if none has been set.
  final String? avatarPath;

  UserProfile copyWith({
    String? name,
    String? email,
    String? role,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Farmer',
      avatarPath: json['avatar_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'avatar_path': avatarPath,
    };
  }
}
