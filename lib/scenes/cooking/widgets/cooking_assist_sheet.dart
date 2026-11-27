import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../../assistant/domain/assistant_models.dart';
import '../../assistant/stores/assistant_store.dart';
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
  final TextEditingController _input = TextEditingController();
  final List<ReactionDisposer> _reactions = <ReactionDisposer>[];

  AssistantStore get _assist => widget.assist;

  @override
  void initState() {
    super.initState();
    // Phiên trợ lý mất (404/409 SESSION_*) → đóng sheet; màn nấu tự xử lý.
    _reactions.add(reaction<AssistErrorKind?>(
      (_) => _assist.errorKind,
      (kind) {
        // Sheet đang đóng dở (vuốt xuống) thì route trên cùng là màn nấu —
        // pop lúc đó sẽ bật dialog Huỷ bỏ ngoài ý muốn.
        if (kind == AssistErrorKind.ended &&
            mounted &&
            (ModalRoute.of(context)?.isCurrent ?? false)) {
          Navigator.of(context).pop();
        }
      },
    ));
    // Đọc to bubble trả lời mới cho trình đọc màn hình (§14.6).
    _reactions.add(reaction<int>(
      (_) => _assist.messages.length,
      (_) {
        if (!mounted || _assist.messages.isEmpty) return;
        final last = _assist.messages.last;
        if (last.role != AssistRole.assistant) return;
        SemanticsService.sendAnnouncement(
            View.of(context), last.text, Directionality.of(context));
      },
    ));
  }

  @override
  void dispose() {
    for (final dispose in _reactions) {
      dispose();
    }
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (!_assist.canSend(text)) return;
    _input.clear();
    await _assist.send(text);
  }

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
          child: Observer(
            builder: (_) => ListView(
              reverse: true,
              padding: const EdgeInsets.all(AppDimens.md),
              children: _buildThread(context).reversed.toList(),
            ),
          ),
        ),
        Observer(builder: (_) => _buildStatus(context)),
        _buildComposer(context),
      ],
    );
  }

  List<Widget> _buildThread(BuildContext context) {
    final l10n = context.l10n;
    final items = <Widget>[];
    if (_assist.messages.isEmpty) {
      items.add(_Bubble(text: l10n.cookingAssistGreeting, mine: false));
    }
    for (final m in _assist.messages) {
      if (m.role == AssistRole.user) {
        items.add(_Bubble(text: m.text, mine: true));
      } else {
        items.add(_AssistantReply(
          message: m,
          cooking: widget.cooking,
          onStepTap: (n) {
            widget.cooking.viewStepNumber(n);
            Navigator.of(context).maybePop();
          },
          // Chỉ câu hỏi lại MỚI NHẤT còn trả lời nhanh được.
          onAnswer: identical(m, _assist.messages.last) &&
                  _assist.canSend('x')
              ? _assist.send
              : null,
        ));
      }
    }
    if (_assist.isSending) {
      items.add(_Bubble(
        text: _progressText(context, _assist.progressTool),
        mine: false,
        footnote: _assist.isSlow ? l10n.cookingAssistSlow : null,
      ));
    }
    final kind = _assist.errorKind;
    if (_assist.state == AssistRequestState.error && kind != null) {
      final notice = switch (kind) {
        AssistErrorKind.filtered => l10n.cookingAssistFiltered,
        AssistErrorKind.unavailable => l10n.cookingAssistUnavailable,
        AssistErrorKind.generic => apiErrorMessage(l10n, _assist.error),
        AssistErrorKind.busy || AssistErrorKind.ended => null,
      };
      if (notice != null) items.add(_Bubble(text: notice, mine: false));
    }
    return items;
  }

  /// Nhãn tiến trình theo tool AI đang chạy (`turn.progress`); tool lạ ⇒
  /// "đang soạn…" như trước.
  static String _progressText(BuildContext context, String? tool) {
    final l10n = context.l10n;
    return switch (tool) {
      'assess_allergen_risk' => l10n.cookingAssistProgressAllergen,
      'kg_substitute' || 'kg_neighbors' => l10n.cookingAssistProgressSubstitute,
      'scale_recipe' => l10n.cookingAssistProgressScale,
      'step_qa' || 'get_recipe' => l10n.cookingAssistProgressStep,
      _ => l10n.cookingAssistSending,
    };
  }

  Widget _buildStatus(BuildContext context) {
    final l10n = context.l10n;
    if (_assist.isDisabled) return const SizedBox.shrink();
    if (_assist.isOffline) {
      return _Banner(message: l10n.cookingAssistOffline);
    }
    if (_assist.state == AssistRequestState.error &&
        _assist.errorKind == AssistErrorKind.busy) {
      return _Banner(
        message: l10n.cookingAssistBusy,
        action: _assist.canRetry
            ? TextButton(
                onPressed: _assist.retry,
                child: Text(l10n.cookingAssistRetry),
              )
            : null,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildComposer(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppDimens.md, AppDimens.sm, AppDimens.sm,
          AppDimens.sm + MediaQuery.viewInsetsOf(context).bottom),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _input,
        builder: (_, value, __) => Observer(
          builder: (_) {
            final enabled = _assist.canSend(value.text);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !_assist.isDisabled,
                    minLines: 1,
                    maxLines: 4,
                    // Quá 500: hiện bộ đếm + khoá gửi, KHÔNG cắt chữ (§14.2).
                    maxLength: AssistantStore.maxMessageLength,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration:
                        InputDecoration(hintText: l10n.cookingAssistHint),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  tooltip: l10n.cookingAssistSend,
                  onPressed: enabled ? _send : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine, this.footnote});

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

class _Banner extends StatelessWidget {
  const _Banner({required this.message, this.action});

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
class _AssistantReply extends StatelessWidget {
  const _AssistantReply({
    required this.message,
    required this.cooking,
    required this.onStepTap,
    this.onAnswer,
  });

  final AssistMessage message;
  final CookingSessionStore cooking;
  final ValueChanged<int> onStepTap;

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
    final showStepChip =
        stepRef != null && cooking.indexOfStepNumber(stepRef) >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Bubble(text: message.text, mine: false),
          if (reply != null) ...<Widget>[
            if (showStepChip || reply.fallback)
              Wrap(
                spacing: AppDimens.sm,
                children: <Widget>[
                  if (showStepChip)
                    ActionChip(
                      label: Text(l10n.cookingAssistStepChip(stepRef)),
                      onPressed: () => onStepTap(stepRef),
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
          if (data != null) ...<Widget>[
            for (final s in data.substitutes) _SubstituteCard(option: s),
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
              _ScaledTable(items: data.scaledIngredients),
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

class _SubstituteCard extends StatelessWidget {
  const _SubstituteCard({required this.option});

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
                _Tag(
                    text: l10n.cookingAssistInStock,
                    color: AppColors.success,
                    background: AppColors.successSurface),
              // Guard §14.7.3 — LLM hoặc chưa kiểm → luôn có nhãn.
              if (option.isAllergenUnverified)
                _Tag(
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

class _Tag extends StatelessWidget {
  const _Tag({
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

class _ScaledTable extends StatelessWidget {
  const _ScaledTable({required this.items});

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
