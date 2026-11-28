import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/assistant_models.dart';

// Khối hiển thị dùng chung cho sheet trợ lý màn nấu và màn trợ lý toàn màn
// (#204, FE design `kitchen-assistant.md` v2 S3–S5c, S8).

class AssistantBubble extends StatelessWidget {
  const AssistantBubble({super.key, required this.text, required this.mine, this.footnote});

  final String text;
  final bool mine;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md, vertical: AppDimens.sm),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        decoration: BoxDecoration(
          color: mine ? AppColors.primaryContainer : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(text, style: theme.textTheme.bodyMedium),
            if (footnote != null)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.xs),
                child: Text(footnote!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }
}

class AssistantBanner extends StatelessWidget {
  const AssistantBanner({super.key, required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md, vertical: AppDimens.xs),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.warning)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Bubble trả lời + các khối kèm theo (§14.4).
class AssistantReplyView extends StatelessWidget {
  const AssistantReplyView({
    super.key,
    required this.message,
    this.hasStep,
    this.onStepTap,
    this.onAnswer,
    this.onRecipeTap,
    this.actionStatus,
    this.actionCode,
    this.isActionInFlight,
    this.onConfirmAction,
    this.onRejectAction,
  });

  final AssistMessage message;

  /// Bấm thẻ món (S4); `null` ⇒ thẻ không bấm được.
  final ValueChanged<RecipeCard>? onRecipeTap;

  /// Trạng thái hiện tại của đề xuất — xem `AssistantStore.actionStatus`.
  final ActionStatus Function(AssistantAction action)? actionStatus;
  final String? Function(String actionId)? actionCode;
  final bool Function(String actionId)? isActionInFlight;
  final ValueChanged<String>? onConfirmAction;
  final ValueChanged<String>? onRejectAction;

  /// Bước `stepRef` có trong buổi nấu đang mở không — `null` ⇒ không hiện chip
  /// bước (ngoài màn nấu).
  final bool Function(int stepNumber)? hasStep;
  final ValueChanged<int>? onStepTap;

  /// Gửi một lựa chọn của `question` như tin nhắn mới; `null` ⇒ chỉ hiển thị.
  final ValueChanged<String>? onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final reply = message.reply;
    final data = reply?.cooking;
    final small = theme.textTheme.bodySmall;
    final stepRef = data?.stepRef;
    final showStepChip = stepRef != null && (hasStep?.call(stepRef) ?? false);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AssistantBubble(text: message.text, mine: false),
          if (reply != null) ...<Widget>[
            if (showStepChip || reply.fallback)
              Wrap(
                spacing: AppDimens.sm,
                children: <Widget>[
                  if (showStepChip)
                    ActionChip(
                      label: Text(l10n.cookingAssistStepChip(stepRef)),
                      onPressed:
                          onStepTap == null ? null : () => onStepTap!(stepRef),
                    ),
                  if (reply.fallback)
                    Chip(
                      label: Text(l10n.cookingAssistDegraded),
                      backgroundColor: AppColors.surfaceSubtle,
                      labelStyle:
                          small?.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            // Câu dị ứng chỉ hiện đúng nguyên văn BE/AI trả, dòng riêng.
            if (reply.allergenNote != null)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.xs),
                child: Text('⚠ ${reply.allergenNote}',
                    style: small?.copyWith(color: AppColors.warning)),
              ),
            for (final d in reply.suspectedDishes)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.xs),
                child: Text(l10n.cookingAssistSuspected(d.name, d.allergen),
                    style: small?.copyWith(color: AppColors.textSecondary)),
              ),
            if (reply.needsInput && reply.question != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.xs),
                child: Text(reply.question!.text,
                    style: theme.textTheme.bodyMedium),
              ),
              Wrap(
                spacing: AppDimens.sm,
                children: <Widget>[
                  for (final option in reply.question!.options)
                    ActionChip(
                      label: Text(option),
                      onPressed:
                          onAnswer == null ? null : () => onAnswer!(option),
                    ),
                ],
              ),
            ],
          ],
          if (reply != null && reply.recipeCards.isNotEmpty)
            for (final card in reply.recipeCards.take(5))
              RecipeCardTile(
                card: card,
                onTap: onRecipeTap == null ? null : () => onRecipeTap!(card),
              ),
          if (reply != null)
            for (final action in reply.actions)
              // Observer riêng: trạng thái đổi sau khi bấm, build này nằm ngoài
              // Observer của luồng tin nên MobX không theo dõi được.
              Observer(
                builder: (_) => ActionCard(
                  action: action,
                  status: actionStatus?.call(action) ?? action.status,
                  code: actionCode?.call(action.actionId),
                  inFlight: isActionInFlight?.call(action.actionId) ?? false,
                  onConfirm: onConfirmAction == null
                      ? null
                      : () => onConfirmAction!(action.actionId),
                  onReject: onRejectAction == null
                      ? null
                      : () => onRejectAction!(action.actionId),
                ),
              ),
          if (reply != null && reply.mealPlan.isNotEmpty)
            MealPlanView(slots: reply.mealPlan),
          if (data != null) ...<Widget>[
            for (final s in data.substitutes) SubstituteCard(option: s),
            if (data.blockedSubstitutes.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l10n.cookingAssistBlocked, style: small),
                children: <Widget>[
                  for (final b in data.blockedSubstitutes)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(b.substitute),
                      subtitle: Text(b.reason),
                    ),
                ],
              ),
            if (data.scaledIngredients.isNotEmpty)
              ScaledTable(items: data.scaledIngredients),
            if (data.isStepAnswer)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.xs),
                child: Text(l10n.cookingAssistFoodSafety,
                    style: small?.copyWith(color: AppColors.textSecondary)),
              ),
          ],
        ],
      ),
    );
  }
}

class SubstituteCard extends StatelessWidget {
  const SubstituteCard({super.key, required this.option});

  final SubstituteOption option;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    return Container(
      margin: const EdgeInsets.only(top: AppDimens.xs),
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${option.substitute} · ${option.ratio}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (option.contextNote != null)
            Text(option.contextNote!, style: small),
          Wrap(
            spacing: AppDimens.xs,
            children: <Widget>[
              if (option.inStock)
                AssistantTag(
                    text: l10n.cookingAssistInStock,
                    color: AppColors.success,
                    background: AppColors.successSurface),
              // Guard §14.7.3 — LLM hoặc chưa kiểm → luôn có nhãn.
              if (option.isAllergenUnverified)
                AssistantTag(
                    text: l10n.cookingAssistUnverified,
                    color: AppColors.warning,
                    background: AppColors.warningSurface),
            ],
          ),
        ],
      ),
    );
  }
}

class AssistantTag extends StatelessWidget {
  const AssistantTag({super.key, 
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppDimens.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.sm, vertical: AppDimens.xs / 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class ScaledTable extends StatelessWidget {
  const ScaledTable({super.key, required this.items});

  final List<ScaledIngredient> items;

  static String _qty(double? v) {
    if (v == null) return '–';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.xs),
              child: Text(
                i.originalQuantity == null && i.scaledQuantity == null
                    ? '${i.name}${i.note == null ? '' : ': ${i.note}'}'
                    : '${i.name}: ${_qty(i.originalQuantity)} → '
                        '${_qty(i.scaledQuantity)} ${i.unit ?? ''}'
                        '${i.note == null ? '' : ' (${i.note})'}',
                style: small,
              ),
            ),
        ],
      ),
    );
  }
}

/// Thẻ món AI gợi ý (S4): tên, lý do, nguyên liệu còn thiếu, nhãn dị ứng.
class RecipeCardTile extends StatelessWidget {
  const RecipeCardTile({super.key, required this.card, this.onTap});

  final RecipeCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    return Card(
      margin: const EdgeInsets.only(top: AppDimens.xs),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(card.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (card.reason != null) Text(card.reason!, style: small),
              if (card.missingIngredients.isNotEmpty)
                Text(
                    l10n.assistantMissingIngredients(
                        card.missingIngredients.join(', ')),
                    style: small?.copyWith(color: AppColors.textSecondary)),
              if (card.allergenTags.isNotEmpty)
                Wrap(
                  spacing: AppDimens.xs,
                  children: <Widget>[
                    for (final tag in card.allergenTags)
                      AssistantTag(
                          text: tag,
                          color: AppColors.warning,
                          background: AppColors.warningSurface),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thực đơn nhiều ngày (`mealPlan`): mỗi ngày/bữa một nhóm món.
class MealPlanView extends StatelessWidget {
  const MealPlanView({super.key, required this.slots});

  final List<PlanSlot> slots;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final slot in slots)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.xs),
              child: Text(
                '${l10n.assistantPlanDay(slot.day)} · ${slot.mealType}: '
                '${slot.dishes.map((d) => d.name).join(', ')}',
                style: small,
              ),
            ),
        ],
      ),
    );
  }
}

/// Thẻ hành động (S6/S7): đề xuất chờ xác nhận, hoặc kết quả sau khi bấm.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.action,
    required this.status,
    this.code,
    this.inFlight = false,
    this.onConfirm,
    this.onReject,
  });

  final AssistantAction action;
  final ActionStatus status;
  final String? code;
  final bool inFlight;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    final pending = status == ActionStatus.pending;
    final shopping = action.type == AssistantAction.shoppingAddItems;
    final label = switch (status) {
      ActionStatus.done =>
        shopping ? l10n.assistantActionDoneShopping : l10n.assistantActionDone,
      ActionStatus.failed => l10n.assistantActionFailed(code ?? '-'),
      ActionStatus.expired => l10n.assistantActionExpired,
      ActionStatus.rejected => l10n.assistantActionRejected,
      ActionStatus.pending || ActionStatus.executing => null,
    };
    return Card(
      margin: const EdgeInsets.only(top: AppDimens.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(action.summary,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.xs),
                child: Text(label,
                    style: small?.copyWith(
                        color: status == ActionStatus.done
                            ? AppColors.success
                            : AppColors.textSecondary)),
              ),
            if (pending || status == ActionStatus.executing)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: pending && !inFlight ? onReject : null,
                    child: Text(l10n.assistantActionCancel),
                  ),
                  FilledButton(
                    onPressed: pending && !inFlight ? onConfirm : null,
                    child: Text(shopping
                        ? l10n.assistantActionConfirmShopping
                        : l10n.assistantActionConfirm),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
