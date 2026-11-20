import 'package:flutter/material.dart';

import '../constants/app_colors_extension.dart';
import '../constants/app_dimens.dart';
import '../utils/l10n_x.dart';

/// Lớp phủ loading toàn vùng (design-system.md §7.5).
///
/// Chặn chạm vào nội dung bên dưới (chống gửi trùng) nhưng KHÔNG chặn back:
/// không dùng `PopScope`, không đụng `Navigator`. Bọc `body` của
/// `AppScaffold`, không bọc cả `Scaffold`, để nút back trên AppBar vẫn bấm
/// được. FAB nằm ngoài body — màn có FAB tự disable khi đang loading.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return Stack(
      children: <Widget>[
        // ExcludeFocus: AbsorbPointer không chặn bàn phím/IME — ô đang focus
        // vẫn submit được nếu thiếu lớp này (code review M2).
        ExcludeFocus(
          excluding: isLoading,
          child: ExcludeSemantics(excluding: isLoading, child: child),
        ),
        if (isLoading)
          Positioned.fill(
            child: Semantics(
              liveRegion: true,
              label: text ?? context.l10n.commonLoading,
              // AbsorbPointer thay ModalBarrier: ModalBarrier(dismissible:false)
              // phát tiếng alert mỗi lần chạm (design §7.5).
              child: AbsorbPointer(
                child: ColoredBox(
                  color: context.appColors.scrim,
                  // scaleDown: vùng bọc thấp (vd. một card) không bị overflow.
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusLg),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.lg,
                            vertical: AppDimens.md + AppDimens.xs,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              if (text != null) ...<Widget>[
                                const SizedBox(height: AppDimens.md),
                                ExcludeSemantics(
                                  child: Text(
                                    text,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
