import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../utils/l10n_x.dart';
import '../stores/meal_composition_store.dart';

class MealCompositionPanel extends StatefulWidget {
  const MealCompositionPanel({
    super.key,
    required this.store,
    required this.slotId,
    required this.hasDishes,
    required this.readOnly,
  });
  final MealCompositionStore store;
  final String slotId;
  final bool hasDishes, readOnly;
  @override
  State<MealCompositionPanel> createState() => _MealCompositionPanelState();
}

class _MealCompositionPanelState extends State<MealCompositionPanel> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => widget.store.load(widget.slotId));
  }

  Future<void> _generate() async {
    if (widget.hasDishes) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.l10n.mealComposeReplaceTitle),
          content: Text(ctx.l10n.mealComposeReplaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.mealComposeRegenerate),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await widget.store.generate(
      widget.slotId,
      replaceExisting: widget.hasDishes,
    );
  }

  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) {
          final store = widget.store;
          final data = store.contexts[widget.slotId];
          final loading = store.busy[widget.slotId] == true;
          final message = store.messages[widget.slotId];
          final menu = data?.menu;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.mealComposeTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(context.l10n.mealComposePeoplePolicy),
                  if (data != null) ...[
                    Text(
                      context.l10n.mealComposePeopleCount(
                        data.diners
                            .where(
                              (d) =>
                                  d.kind == 'MEMBER' ||
                                  store.selected(widget.slotId, d.id),
                            )
                            .length,
                      ),
                    ),
                    ...data.diners.map(
                      (d) => d.kind == 'MEMBER'
                          ? Text(d.name)
                          : CheckboxListTile(
                              title: Text(d.name),
                              value: store.selected(widget.slotId, d.id),
                              onChanged: loading || widget.readOnly
                                  ? null
                                  : (v) => store.toggle(
                                        widget.slotId,
                                        d.id,
                                        v ?? false,
                                      ),
                            ),
                    ),
                  ],
                  if (loading) ...[
                    const LinearProgressIndicator(),
                    Text(context.l10n.mealComposeLoading),
                  ],
                  if (message != null && message != 'APPLIED')
                    Text(switch (message) {
                      'RUNNING' => context.l10n.mealComposeRunning,
                      'APPLIED_SYNC_PENDING' =>
                        context.l10n.mealComposeSyncPending,
                      'INCOMPLETE' => context.l10n.mealComposeIncomplete,
                      'STALE' ||
                      'ERR_MEAL_COMPOSITION_STALE' =>
                        context.l10n.mealComposeStale,
                      'ERR_MEAL_COMPOSITION_DISABLED' =>
                        context.l10n.mealComposeDisabled,
                      _ => context.l10n.mealComposeFailed,
                    }),
                  if (menu != null) ...[
                    for (final dish in menu.dishes)
                      Text(
                        context.l10n.mealComposeDishServings(
                          dish.name,
                          dish.servings.toStringAsFixed(1),
                        ),
                      ),
                    if (menu.totalCalories != null)
                      Text(
                        context.l10n.mealComposeCalories(
                          menu.totalCalories!.round(),
                        ),
                      ),
                    if (menu.warnings.isNotEmpty)
                      Text(context.l10n.mealComposeNutritionWarning),
                    if (menu.missing.isNotEmpty) ...[
                      Text(context.l10n.mealComposeShopping),
                      for (final item in menu.missing)
                        Text(
                          '${item.name}: ${item.quantity.toStringAsFixed(1)} ${item.unit}',
                        ),
                    ],
                  ],
                  if (!widget.readOnly)
                    FilledButton.icon(
                      onPressed: loading || data == null ? null : _generate,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        widget.hasDishes
                            ? context.l10n.mealComposeRegenerate
                            : context.l10n.mealComposeGenerate,
                      ),
                    ),
                  if (!loading)
                    TextButton(
                      onPressed: () => store.load(widget.slotId),
                      child: Text(context.l10n.mealComposeRefresh),
                    ),
                ],
              ),
            ),
          );
        },
      );
}
