import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/l10n_x.dart';

String homeGreetingForTime(AppLocalizations l10n, DateTime time) {
  final hour = time.toLocal().hour;
  if (hour >= 5 && hour < 12) return l10n.homeGreeting;
  if (hour >= 12 && hour < 18) return l10n.homeGreetingAfternoon;
  if (hour >= 18 && hour < 22) return l10n.homeGreetingEvening;
  return l10n.homeGreetingNight;
}

/// Refreshes across time periods, including when returning from background.
class HomeGreeting extends StatefulWidget {
  const HomeGreeting({super.key, this.style});

  final TextStyle? style;

  @override
  State<HomeGreeting> createState() => _HomeGreetingState();
}

class _HomeGreetingState extends State<HomeGreeting>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _timer?.cancel();
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    _timer = Timer(nextHour.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleRefresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        homeGreetingForTime(context.l10n, DateTime.now()),
        style: widget.style,
      );
}
