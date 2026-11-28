import 'package:flutter/material.dart';
import '../../../constants/app_colors_extension.dart';

/// Hỗ trợ tên nhóm seed và tên nhập tay; cùng hệ Material rounded.
({IconData icon, Color color, Color background}) foodCategoryVisual(
    BuildContext context, String? category, String name) {
  final colors = Theme.of(context).colorScheme;
  final accents = context.appColors;
  final text = '${category ?? ''} $name'.toLowerCase();
  IconData icon;
  Color color;
  if (name.toLowerCase().contains('sữa')) {
    icon = Icons.local_drink_rounded;
    color = accents.info;
  } else if (text.contains('trứng') || text.contains('egg')) {
    icon = Icons.egg_rounded;
    color = accents.warning;
  } else if (text.contains('sữa') || text.contains('milk')) {
    icon = Icons.local_drink_rounded;
    color = accents.info;
  } else if (text.contains('hải sản') ||
      text.contains('thịt cá') ||
      text.contains('cá ') ||
      text.contains('tôm') ||
      text.contains('mực')) {
    icon = Icons.set_meal_rounded;
    color = accents.info;
  } else if (text.contains('thịt') ||
      text.contains('gà') ||
      text.contains('sườn')) {
    icon = Icons.kebab_dining_rounded;
    color = colors.primary;
  } else if (text.contains('rau') ||
      text.contains('nấm') ||
      text.contains('đậu')) {
    icon = Icons.eco_rounded;
    color = accents.success;
  } else if (text.contains('trái cây') || text.contains('hoa quả')) {
    icon = Icons.local_florist_rounded;
    color = colors.primary;
  } else if (text.contains('gia vị') ||
      text.contains('dầu') ||
      text.contains('mắm')) {
    icon = Icons.soup_kitchen_rounded;
    color = accents.warning;
  } else if (text.contains('đồ uống') || text.contains('nước')) {
    icon = Icons.local_cafe_rounded;
    color = accents.info;
  } else if (text.contains('khô') ||
      text.contains('gạo') ||
      text.contains('phở')) {
    icon = Icons.grain_rounded;
    color = colors.primary;
  } else {
    icon = Icons.restaurant_rounded;
    color = colors.primary;
  }
  return (
    icon: icon,
    color: color,
    background: Color.alphaBlend(color.withValues(alpha: 0.12), colors.surface)
  );
}
