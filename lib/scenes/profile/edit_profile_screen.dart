import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards/app_card.dart';
import 'stores/profile_store.dart';

/// Form BLOCKED tới khi BE ship `PUT /api/v1/users/me` (FE-3 §10.2, Guard 1).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController nameController = TextEditingController(
      text: Get.find<ProfileStore>().currentUser?.fullName ?? '');

  @override
  void dispose() {
    nameController.dispose();
    Get.find<ProfileStore>().clearEditProfileError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.profileEditTitle,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF6E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.orange),
                ),
                const SizedBox(height: 16),
                Text(context.l10n.profileEditBlocked, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: context.l10n.fullName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
