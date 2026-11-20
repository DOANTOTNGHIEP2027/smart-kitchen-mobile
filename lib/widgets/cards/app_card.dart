import 'package:flutter/material.dart';

import '../../constants/app_colors_extension.dart';
import '../../constants/app_dimens.dart';

/// Card dùng chung (fe-app-shell.md §10.2, design-system.md §7.2). Bo góc + viền
/// lấy từ theme token; có ripple khi [onTap] khác null.
///
/// [highlighted] dùng cho item đang chọn / cần chú ý (viền primary).
/// [elevation] > 0 thêm bóng mềm (tắt ở dark vì vô hình trên nền tối).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppDimens.md),
    this.highlighted = false,
    this.elevation = 0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool highlighted;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final borderRadius = BorderRadius.circular(AppDimens.radiusMd);
    final background = highlighted
        ? Color.lerp(scheme.surface, scheme.primaryContainer, 0.4)!
        : scheme.surface;
    final border = highlighted
        ? Border.all(color: scheme.primary, width: 1.5)
        : Border.all(color: colors.border);
    final clampedElevation = elevation.clamp(0.0, 2.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: clampedElevation > 0
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.ambientShadow,
                  blurRadius: 14 * clampedElevation,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: background,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: border,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
