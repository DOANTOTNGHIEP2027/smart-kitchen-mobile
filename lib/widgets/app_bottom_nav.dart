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

/// Bottom navigation theo chuẩn DESIGN_SYSTEM.md:
/// Bo tròn mềm mại cạnh trên (20dp), đổ bóng môi trường hắt lên trên nhẹ,
/// mục active có pill container màu cam ấm `#FFF2EA` và icon cam tươi `#FF7A45`.
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: AppDimens.borderWidth,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: isActive ? 46 : 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryContainer
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusPill),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          isActive ? d.activeIcon : d.icon,
                          size: 20,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.label,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
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
