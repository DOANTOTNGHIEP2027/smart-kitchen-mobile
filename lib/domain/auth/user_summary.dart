/// Mirror `UserSummary` trong `docs/contracts/openapi/auth-jwt.yaml`.
///
/// Field JSON dùng camelCase theo `docs/contracts/naming-convention.md`.
/// `email`/`fullName`/`avatarUrl` nullable vì user GUEST (qr-join) không có email.
class UserSummary {
  const UserSummary({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
        id: json['id'] as String,
        email: json['email'] as String?,
        fullName: json['fullName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
      };

  /// Tên hiển thị an toàn cho UI khi user chưa đặt `fullName`.
  String get displayName => fullName ?? email ?? id;
}
