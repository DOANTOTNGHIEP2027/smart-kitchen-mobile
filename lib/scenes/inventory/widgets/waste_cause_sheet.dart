import 'package:flutter/material.dart';

import '../../../utils/l10n_x.dart';

enum WasteCause { overbought, forgotten, spoiledEarly }

enum WasteEndpoint { put, delete }

class WasteReasonChoice {
  const WasteReasonChoice({required this.reason, required this.wasteCause});
  const WasteReasonChoice.skipped()
      : reason = null,
        wasteCause = null;

  final String? reason;
  final String? wasteCause;

  bool get isSkipped => wasteCause == null;
}

WasteReasonChoice wasteChoiceFor(WasteCause cause, WasteEndpoint endpoint) {
  return WasteReasonChoice(
    reason: endpoint == WasteEndpoint.put && cause == WasteCause.forgotten
        ? 'EXPIRED'
        : 'WASTE',
    wasteCause: switch (cause) {
      WasteCause.overbought => 'OVERBOUGHT',
      WasteCause.forgotten => 'FORGOTTEN',
      WasteCause.spoiledEarly => 'SPOILED_EARLY',
    },
  );
}

Future<WasteReasonChoice> showWasteCauseSheet(
  BuildContext context, {
  required WasteEndpoint endpoint,
}) async {
  final result = await showModalBottomSheet<WasteReasonChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) => _WasteCauseSheet(endpoint: endpoint),
  );
  return result ?? const WasteReasonChoice.skipped();
}

class _WasteCauseSheet extends StatelessWidget {
  const _WasteCauseSheet({required this.endpoint});

  final WasteEndpoint endpoint;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.l10n.inventoryWasteTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(context.l10n.inventoryWasteSubtitle),
            const SizedBox(height: 8),
            _choice(
              context,
              icon: Icons.shopping_basket_outlined,
              label: context.l10n.inventoryWasteOverbought,
              cause: WasteCause.overbought,
            ),
            _choice(
              context,
              icon: Icons.event_busy_outlined,
              label: context.l10n.inventoryWasteForgotten,
              cause: WasteCause.forgotten,
            ),
            _choice(
              context,
              icon: Icons.warning_amber_outlined,
              label: context.l10n.inventoryWasteSpoiledEarly,
              cause: WasteCause.spoiledEarly,
            ),
            ListTile(
              leading: const Icon(Icons.skip_next_outlined),
              title: Text(context.l10n.skip),
              onTap: () => Navigator.of(context).pop(
                const WasteReasonChoice.skipped(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(
    BuildContext context, {
    required IconData icon,
    required String label,
    required WasteCause cause,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(
        wasteChoiceFor(cause, endpoint),
      ),
    );
  }
}
