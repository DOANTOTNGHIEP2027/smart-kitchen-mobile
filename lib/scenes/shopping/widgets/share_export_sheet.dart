import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/states/view_state.dart';
import '../../profile/domain/household_roster.dart';
import '../domain/shopping_share_text_builder.dart';
import '../stores/shopping_store.dart';
import 'assignee_widgets.dart';

/// Chia sẻ danh sách đi chợ (#69 §11): "Sao chép dạng text" chạy thật; "Chia
/// sẻ link" disabled vĩnh viễn — BE không có endpoint share (Guard #2).
class ShareExportSheet extends StatelessWidget {
  const ShareExportSheet({super.key, required this.store});

  final ShoppingStore store;

  Future<void> _copy(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final all = store.items;
    // FamilyStore có thể chưa đăng ký (đường /family → pop) — KHÔNG Get.find
    // trần; không có roster ⇒ không hậu tố (Guard #14, fix P0-2).
    final roster = shoppingFamilyStore()?.rosterState;
    final names = roster is SuccessState<HouseholdRoster>
        ? <String, String>{for (final m in roster.data.members) m.userId: m.fullName}
        : const <String, String>{};
    final text = ShoppingShareTextBuilder.build(
      // Guard #12: TOÀN BỘ món, không theo filter đang bật.
      groups: ShoppingShareTextBuilder.groupAllForShare(all),
      checkedCount: store.completed.length,
      totalCount: all.length,
      labels: ShoppingShareLabels(
        header: l10n.shoppingShareTextHeader,
        progress: l10n.shoppingShareTextProgress,
        uncategorized: l10n.shoppingShareTextUncategorized,
        footer: l10n.shoppingShareTextFooter,
      ),
      memberNamesById: names,
    );
    await Clipboard.setData(ClipboardData(text: text));
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.shoppingShareCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(
      builder: (_) {
        final hasItems = store.items.isNotEmpty;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.shoppingShareTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppDimens.sm),
                ListTile(
                  key: const ValueKey<String>('share-copy-text'),
                  leading: const Icon(Icons.copy_rounded),
                  title: Text(l10n.shoppingShareCopyText),
                  subtitle: hasItems ? null : Text(l10n.shoppingShareNoItems),
                  enabled: hasItems,
                  onTap: hasItems ? () => _copy(context) : null,
                ),
                ListTile(
                  key: const ValueKey<String>('share-link'),
                  leading: const Icon(Icons.link_rounded),
                  title: Text(l10n.shoppingShareLink),
                  trailing: Chip(
                    label: Text(l10n.shoppingShareComingSoon, style: const TextStyle(fontSize: 11)),
                  ),
                  enabled: false,
                  onTap: null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
