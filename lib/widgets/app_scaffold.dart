import 'package:flutter/material.dart';

/// Scaffold dùng chung (fe-app-shell.md §10.1) — mọi màn hình bọc qua đây để
/// AppBar/SafeArea nhất quán.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final titleText = title;
    return Scaffold(
      appBar: titleText != null
          ? AppBar(
              title: Text(titleText),
              actions: actions,
              leading: leading,
              automaticallyImplyLeading: automaticallyImplyLeading,
            )
          : null,
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
