import 'package:get/get.dart';

import '../../../routing/app_routes.dart';
import '../../../routing/route_guards.dart';
import 'receipt_result_scene.dart';
import 'receipt_scan_binding.dart';
import 'receipt_scan_scene.dart';

/// #68 — CHỈ push từ icon trên ShoppingListScene (shopping-receipt-scan.md
/// §12.1). Cả 2 màn dùng chung `ReceiptScanStore` (fenix) qua 1 binding.
final List<GetPage<dynamic>> receiptPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: AppRoutes.receiptScan,
    page: () => const ReceiptScanScene(),
    binding: ReceiptScanBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: AppRoutes.receiptScanResult,
    page: () => const ReceiptResultScene(),
    binding: ReceiptScanBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
