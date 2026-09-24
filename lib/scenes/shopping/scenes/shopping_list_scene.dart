import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../inventory/domain/unit_option.dart';
import '../domain/shopping_item.dart';
import '../stores/shopping_store.dart';

class ShoppingListScene extends StatefulWidget { const ShoppingListScene({super.key}); @override State<ShoppingListScene> createState() => _ShoppingListSceneState(); }
class _ShoppingListSceneState extends State<ShoppingListScene> {
  @override void initState() { super.initState(); Get.find<ShoppingStore>().init(); }
  @override Widget build(BuildContext context) {
    final store = Get.find<ShoppingStore>();
    return AppScaffold(title: context.l10n.navShopping, actions: <Widget>[IconButton(onPressed: store.sync, icon: const Icon(Icons.refresh))], body: Observer(builder: (_) {
      if (store.isLoading) return const Center(child: CircularProgressIndicator());
      if (store.items.isEmpty) return AppEmptyView(icon: Icons.shopping_cart_outlined, message: context.l10n.stateEmptyDefault);
      return ListView(children: <Widget>[..._section(context, store.pending, false, store), if (store.completed.isNotEmpty) ..._section(context, store.completed, true, store)]);
    }), floatingActionButton: FloatingActionButton(onPressed: () => _add(context, store), child: const Icon(Icons.add)));
  }
  List<Widget> _section(BuildContext context, List<ShoppingItem> items, bool completed, ShoppingStore store) => items.map((item) => ListTile(
    leading: Checkbox(value: completed, onChanged: item.canToggle ? (_) => store.toggle(item) : null),
    title: Text(item.name, style: completed ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
    subtitle: item.isPendingSync ? const Icon(Icons.sync, size: 16, color: AppColors.warning) : null,
    trailing: Text('${item.displayQuantity} ${item.displayUnit}'),
  )).toList();
  Future<void> _add(BuildContext context, ShoppingStore store) async {
    final name = TextEditingController(); final quantity = TextEditingController(text: '1'); String unit = unitOptions.first.value;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => Padding(padding: EdgeInsets.fromLTRB(AppDimens.md, AppDimens.md, AppDimens.md, MediaQuery.of(context).viewInsets.bottom + AppDimens.md), child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      TextField(controller: name, autofocus: true, decoration: InputDecoration(hintText: context.l10n.add)),
      TextField(controller: quantity, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: context.l10n.inventorySearchHint)),
      DropdownButton<String>(value: unit, isExpanded: true, items: unitOptions.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(), onChanged: (v) { if (v != null) unit = v; }),
      FilledButton(onPressed: () async { await store.add(name.text, double.tryParse(quantity.text) ?? 0, unit); if (context.mounted) Navigator.pop(context); }, child: Text(context.l10n.add)),
    ])));
  }
}
