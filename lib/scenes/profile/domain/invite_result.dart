/// Response POST `/households/invites` (OAS InviteResponse).
class InviteResult {
  const InviteResult({
    required this.code,
    required this.link,
    required this.expiresAt,
  });

  final String code;
  final String link;
  final DateTime expiresAt;
}
