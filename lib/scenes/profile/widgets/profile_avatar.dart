import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_cached_image.dart';

/// Avatar tròn của ProfileScreen/EditProfileScreen (§10.1, §10.2).
///
/// Ưu tiên: [previewBytes] (ảnh vừa chọn, chưa lưu) → [avatarUrl] (qua
/// cache; tải lỗi → icon người, không crash — Q9) → chữ cái đầu của
/// [fullName] (hoặc `?` khi chưa đặt tên — GUEST).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    this.fullName,
    this.previewBytes,
    this.size = defaultSize,
  });

  static const double defaultSize = 88;

  final String? avatarUrl;
  final String? fullName;
  final Uint8List? previewBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final preview = previewBytes;
    if (preview != null) {
      return ClipOval(
        child: Image.memory(
          preview,
          key: const ValueKey<String>('profile-avatar-preview'),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initial(context),
        ),
      );
    }
    final url = avatarUrl;
    if (url != null && url.isNotEmpty) {
      return AppCachedImage(
        url: url,
        width: size,
        height: size,
        shape: AppCachedImageShape.circle,
        placeholderIcon: Icons.person,
        errorIcon: Icons.person,
      );
    }
    return _initial(context);
  }

  Widget _initial(BuildContext context) {
    final name = fullName?.trim() ?? '';
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.sageLight,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.sage,
            ),
      ),
    );
  }
}
