import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.construction_outlined,
                      color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.profileEditBlocked,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              enabled: false,
              decoration: InputDecoration(
                labelText: context.l10n.fullName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
