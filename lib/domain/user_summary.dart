class UserSummary {
  const UserSummary({
    required this.id,
    required this.fullName,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? avatarUrl;
}
