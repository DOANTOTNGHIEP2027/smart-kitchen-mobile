import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../domain/assistant_models.dart';
import '../stores/assistant_store.dart';
import 'assistant_message_widgets.dart';

/// Khung chat trợ lý dùng chung: luồng tin, trạng thái (offline/bận/quá
/// nhanh), ô nhập. Sheet màn nấu và màn trợ lý toàn màn chỉ khác lời chào,
/// chip gợi ý và cách xử lý chip bước (#204, FE design v2 S1–S5c, S8–S11).
class AssistantChatView extends StatefulWidget {
  const AssistantChatView({
    super.key,
    required this.assist,
    required this.greeting,
    this.suggestions = const <String>[],
    this.hasStep,
    this.onStepTap,
    this.onEnded,
  });

  final AssistantStore assist;

  /// Lời chào khi chưa có tin nào (S1/S2).
  final String greeting;

  /// Chip gợi ý dưới lời chào; chạm = gửi đúng câu đó.
  final List<String> suggestions;

  /// Xem [AssistantReplyView.hasStep] — chỉ màn nấu có.
  final bool Function(int stepNumber)? hasStep;
  final ValueChanged<int>? onStepTap;

  /// Phiên trợ lý mất (404/409 SESSION_*) — bên chứa quyết định đóng.
  final VoidCallback? onEnded;

  @override
  State<AssistantChatView> createState() => _AssistantChatViewState();
}

class _AssistantChatViewState extends State<AssistantChatView> {
  final TextEditingController _input = TextEditingController();
  final List<ReactionDisposer> _reactions = <ReactionDisposer>[];

  AssistantStore get _assist => widget.assist;

  @override
  void initState() {
    super.initState();
    _reactions.add(reaction<AssistErrorKind?>(
      (_) => _assist.errorKind,
      (kind) {
        if (kind == AssistErrorKind.ended && mounted) widget.onEnded?.call();
      },
    ));
    // Đọc to bubble trả lời mới cho trình đọc màn hình.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
    if (_assist.messages.isEmpty && !_assist.isLoadingHistory) {
      items.add(AssistantBubble(text: widget.greeting, mine: false));
      if (widget.suggestions.isNotEmpty) {
        items.add(Wrap(
          spacing: AppDimens.sm,
          children: <Widget>[
            for (final s in widget.suggestions)
              ActionChip(
                label: Text(s),
                onPressed: _assist.canSend(s) ? () => _assist.send(s) : null,
              ),
          ],
        ));
      }
    }
    if (_assist.isLoadingHistory) {
      items.add(const Center(child: CircularProgressIndicator()));
    }
    for (final m in _assist.messages) {
      if (m.role == AssistRole.user) {
        items.add(AssistantBubble(text: m.text, mine: true));
      } else {
        items.add(AssistantReplyView(
          message: m,
          hasStep: widget.hasStep,
          onStepTap: widget.onStepTap,
          // Chỉ câu hỏi lại MỚI NHẤT còn trả lời nhanh được.
          onAnswer:
              identical(m, _assist.messages.last) && _assist.canSend('x')
                  ? _assist.send
                  : null,
        ));
      }
    }
    if (_assist.isSending) {
      items.add(AssistantBubble(
        text: progressText(context, _assist.progressTool),
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
        AssistErrorKind.rateLimited => l10n.assistantRateLimited,
        AssistErrorKind.busy || AssistErrorKind.ended => null,
      };
      if (notice != null) items.add(AssistantBubble(text: notice, mine: false));
    }
    return items;
  }

  /// Nhãn tiến trình theo tool AI đang chạy (`turn.progress`); tool lạ ⇒
  /// "đang soạn…".
  static String progressText(BuildContext context, String? tool) {
    final l10n = context.l10n;
    return switch (tool) {
      'assess_allergen_risk' => l10n.cookingAssistProgressAllergen,
      'kg_substitute' || 'kg_neighbors' => l10n.cookingAssistProgressSubstitute,
      'scale_recipe' => l10n.cookingAssistProgressScale,
      'step_qa' || 'get_recipe' => l10n.cookingAssistProgressStep,
      'search_recipes' => l10n.assistantProgressSearch,
      _ => l10n.cookingAssistSending,
    };
  }

  Widget _buildStatus(BuildContext context) {
    final l10n = context.l10n;
    if (_assist.isDisabled) return const SizedBox.shrink();
    if (_assist.isOffline) {
      return AssistantBanner(message: l10n.cookingAssistOffline);
    }
    if (_assist.state == AssistRequestState.error &&
        _assist.errorKind == AssistErrorKind.busy) {
      return AssistantBanner(
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
                    // Quá giới hạn: hiện bộ đếm + khoá gửi, KHÔNG cắt chữ.
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
