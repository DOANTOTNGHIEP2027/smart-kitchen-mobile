import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_text_styles.dart';

/// Một mục trong [AppBottomNav].
class AppBottomNavDestination {
  const AppBottomNavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  /// Icon mặc định (không active) — outline.
  final IconData icon;

  /// Icon khi active — solid / filled.
  final IconData activeIcon;

  final String label;
}

/// Bottom navigation theo mock `docs/design/frontend/mockups/fe-app-shell.html`
/// (đối chiếu 2026-09-16).
///
/// Mock dùng "dot" 22×22 với border-radius 6 (trông như ô vuông bo góc, không
/// phải Material pill indicator): màu xám khi inactive, accent cam khi active.
/// Label dưới nhỏ 11px — active đậm màu cam.
///
/// Trước đây dùng `NavigationBar` mặc định → lệch hoàn toàn (indicator pill
/// Material 3, label 12-14px).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppBottomNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: AppDimens.borderWidth)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: List<Widget>.generate(destinations.length, (i) {
            final isActive = i == selectedIndex;
            final d = destinations[i];
            return Expanded(
              child: InkResponse(
                onTap: () => onDestinationSelected(i),
                radius: 36,
                highlightShape: BoxShape.circle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.border,
                          borderRadius: const BorderRadius.all(Radius.circular(6)),
                        ),
                        child: Icon(
                          isActive ? d.activeIcon : d.icon,
                          size: 14,
                          color: AppColors.surface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.label,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
