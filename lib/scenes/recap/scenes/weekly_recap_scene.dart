import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_error_view.dart';
import '../stores/weekly_recap_store.dart';
import '../widgets/insight_card.dart';
import '../widgets/recap_skeleton.dart';
import '../widgets/shareable_recap_card.dart';

/// Màn hình Weekly Recap "kiểu Wrapped" (weekly-recap-screen.md, issue #86).
class WeeklyRecapScene extends StatefulWidget {
  const WeeklyRecapScene({super.key});

  @override
  State<WeeklyRecapScene> createState() => _WeeklyRecapSceneState();
}

class _WeeklyRecapSceneState extends State<WeeklyRecapScene> {
  late final WeeklyRecapStore _store;
  final _shareCardKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _store = Get.find<WeeklyRecapStore>();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.recapTitle,
      body: Observer(builder: (context) {
        switch (_store.status) {
          case RecapLoadStatus.loading:
            return const RecapSkeleton();
          case RecapLoadStatus.noHousehold:
            return AppEmptyView(message: l10n.recapNoHousehold);
          case RecapLoadStatus.empty:
            return AppEmptyView(message: l10n.recapEmpty);
          case RecapLoadStatus.error:
            return AppErrorView(
              message: _store.error?.message ?? l10n.recapError,
              onRetry: _store.retry,
            );
          case RecapLoadStatus.ready:
            final s = _store.summary!;
            return RefreshIndicator(
              onRefresh: () => _store.fetchAll(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  RepaintBoundary(
                    key: _shareCardKey,
                    child: ShareableRecapCard(
                      summary: s,
                      ownInsight: _store.ownInsight,
                      streakStatus: _store.streakStatus,
                      streak: _store.streak,
                      onRetryStreak: _store.retryStreak,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: l10n.recapShareTooltip,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share),
                      onPressed: _isSharing ? null : _shareRecap,
                    ),
                  ),
                  InsightCardList(
                    insights: _store.orderedMemberInsights,
                    emptyText: l10n.recapEmptyInsights,
                  ),
                ],
              ),
            );
        }
      }),
    );
  }

  /// Chụp PNG phần hero+stats qua [RepaintBoundary] rồi mở share sheet
  /// (weekly-recap-screen.md §9.5). Toàn bộ bọc try/catch, guard null —
  /// không crash khi share thất bại (Guard #10).
  Future<void> _shareRecap() async {
    final l10n = context.l10n;
    setState(() => _isSharing = true);
    try {
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = await File(
        '${dir.path}/weekly_recap_${DateTime.now().millisecondsSinceEpoch}.png',
      ).writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: l10n.recapShare,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recapShareFailed)),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}