import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../constants/app_dimens.dart';
import '../../../routing/app_routes.dart';
import '../../../utils/l10n_x.dart';
import '../domain/assistant_models.dart';
import '../stores/assistant_store.dart';
import '../widgets/assistant_chat_view.dart';
import 'assistant_routes.dart';

/// Màn trợ lý bếp toàn màn (#204, FE design v2 KA-FE-1/2): GLOBAL mở từ FAB
/// toàn cục (S1), PLANNING mở từ ô bữa của thực đơn (S2). Màn nấu vẫn dùng
/// sheet riêng với cùng [AssistantChatView].
class AssistantScene extends StatefulWidget {
  const AssistantScene({super.key, required this.entry, this.store});

  final AssistantEntry entry;

  /// Cho test; mặc định lấy qua [AssistantRoutes.storeFor].
  final AssistantStore? store;

  @override
  State<AssistantScene> createState() => _AssistantSceneState();
}

class _AssistantSceneState extends State<AssistantScene> {
  late final AssistantStore _store =
      widget.store ?? AssistantRoutes.storeFor(widget.entry);

  bool get _isGlobal => widget.entry.contextType == AssistantContextType.global;

  @override
  void initState() {
    super.initState();
    _store.open();
  }

  @override
  void dispose() {
    // Store GLOBAL bền qua các lần mở; store PLANNING chỉ sống cùng màn.
    if (!_isGlobal && widget.store == null) _store.dispose();
    super.dispose();
  }

  /// Thẻ món mang id KB; BE trả `recipeId` (vật chất hoá như khi thêm món).
  Future<void> _openRecipe(RecipeCard card) async {
    final recipeId = await _store.resolveRecipe(card.kbRecipeId);
    if (recipeId == null || !mounted) return;
    await Get.toNamed<void>(AppRoutes.recipeDetail.replaceFirst(':id', recipeId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = widget.entry.slotLabel;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.assistantTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!_isGlobal && label != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.md, AppDimens.sm, AppDimens.md, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.restaurant_menu, size: 18),
                    label: Text(widget.entry.horizonDays > 1
                        ? '$label · ${l10n.assistantHorizonOption(widget.entry.horizonDays)}'
                        : label),
                  ),
                ),
              ),
            Expanded(
              child: AssistantChatView(
                assist: _store,
                greeting: _isGlobal
                    ? l10n.assistantGreeting
                    : l10n.assistantPlanningGreeting,
                suggestions: _isGlobal
                    ? <String>[
                        l10n.assistantSuggestTonight,
                        l10n.assistantSuggestExpiring,
                        l10n.assistantSuggestFamily,
                        l10n.assistantSuggestQuick,
                      ]
                    : <String>[l10n.assistantSuggestPlanMeal],
                onEnded: () {
                  if (mounted) Navigator.of(context).maybePop();
                },
                onRecipeTap: _openRecipe,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
