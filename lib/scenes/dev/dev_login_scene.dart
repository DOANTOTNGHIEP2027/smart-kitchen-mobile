import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../domain/auth/user_summary.dart';
import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';

/// TẠM THỜI — chỗ giữ cho `AppRoutes.login` để app shell chạy được độc lập.
///
/// `fe-onboarding` (#28) sở hữu màn hình login thật và sẽ đăng ký `GetPage`
/// của nó cho cùng tên route; khi đó **xóa cả file này và
/// `AppPages.devPlaceholderPages`**. Scene này không gọi backend — nó nạp một
/// session giả để demo được guard, shell và việc decode claim JWT.
class DevLoginScene extends StatelessWidget {
  const DevLoginScene({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.devLoginTitle,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppCard(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(
                    Icons.restaurant_menu,
                    size: AppDimens.stateIcon,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    context.l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    context.l10n.devLoginSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppDimens.lg),
                  AppButton(
                    label: context.l10n.devLoginCta,
                    icon: Icons.login,
                    onPressed: () => _enterDemoSession(),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    context.l10n.devLoginBanner,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enterDemoSession() async {
    await Get.find<SessionStore>().setSession(
      accessToken: _fakeAccessToken(),
      refreshToken: 'demo-refresh-token',
      user: const UserSummary(
        id: 'demo-user',
        email: 'demo@smartkitchen.local',
        fullName: 'Demo User',
      ),
    );
    await Get.offAllNamed<void>(AppRoutes.shellRoot);
  }

  /// JWT giả, KHÔNG ký — chỉ để `decodeJwtPayload` có claim thật mà đọc. Chữ
  /// ký là chuỗi rác; BE sẽ từ chối token này, đúng như mong đợi.
  String _fakeAccessToken() {
    String encode(Map<String, dynamic> part) =>
        base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');

    final header = encode(<String, dynamic>{'alg': 'none', 'typ': 'JWT'});
    final payload = encode(<String, dynamic>{
      'sub': 'demo-user',
      'household_id': 'demo-household',
      'role': 'OWNER',
      'provider': 'EMAIL',
    });
    return '$header.$payload.demo-signature';
  }
}
