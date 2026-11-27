import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../assistant/stores/assistant_store.dart';
import '../../assistant/widgets/assistant_chat_view.dart';
import '../stores/cooking_session_store.dart';

/// Mở sheet chat trợ lý (~70% màn hình, kéo xuống để đóng — §14.1).
Future<void> showCookingAssistSheet(
  BuildContext context, {
  required AssistantStore assist,
  required CookingSessionStore cooking,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.7,
      child: CookingAssistSheet(assist: assist, cooking: cooking),
    ),
  );
}

/// Nội dung sheet trợ lý ở màn nấu — nguồn là [AssistantStore] ngữ cảnh
/// COOKING (#204, FE design `kitchen-assistant.md` v2 S3, S5–S5c, S8, S9, S11).
class CookingAssistSheet extends StatefulWidget {
  const CookingAssistSheet({
    super.key,
    required this.assist,
    required this.cooking,
  });

  final AssistantStore assist;
  final CookingSessionStore cooking;

  @override
  State<CookingAssistSheet> createState() => _CookingAssistSheetState();
}

class _CookingAssistSheetState extends State<CookingAssistSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
          child: Text(l10n.cookingAssistTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: AppDimens.sm),
        Expanded(
          child: AssistantChatView(
            assist: widget.assist,
            greeting: l10n.cookingAssistGreeting,
            hasStep: (n) => widget.cooking.indexOfStepNumber(n) >= 0,
            onStepTap: (n) {
              widget.cooking.viewStepNumber(n);
              Navigator.of(context).maybePop();
            },
            // Sheet đang đóng dở (vuốt xuống) thì route trên cùng là màn nấu —
            // pop lúc đó sẽ bật dialog Huỷ bỏ ngoài ý muốn.
            onEnded: () {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ],
    );
  }
}
