import 'package:flutter/material.dart';

/// Scaffold dùng chung (fe-app-shell.md §10.1) — mọi màn hình bọc qua đây để
/// AppBar/SafeArea nhất quán.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleMaxLines = 1,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.showBackButton = true,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;

  /// > 1 cho tiêu đề dài (vd. "Bữa trưa · Thứ Hai 16/11"): cho xuống dòng và
  /// thu nhỏ chữ một chút thay vì bị cắt "…".
  final int titleMaxLines;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  /// `false` ẩn nút back tự động trên AppBar (design-system.md §7.3).
  final bool showBackButton;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final titleText = title;
    return Scaffold(
      appBar: titleText != null
          ? AppBar(
              title: titleMaxLines > 1
                  ? Text(
                      titleText,
                      maxLines: titleMaxLines,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    )
                  : Text(titleText),
              actions: actions,
              leading: leading,
              automaticallyImplyLeading:
                  automaticallyImplyLeading && showBackButton,
            )
          : null,
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
