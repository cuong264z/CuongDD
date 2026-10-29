import 'package:flutter/material.dart';

import 'check_confirm_screen.dart';
import 'qr_scan_screen.dart';

/// Chạy trọn luồng chấm công: quét QR → (GPS + khuôn mặt + gửi). Trả `true` nếu chấm công thành công.
/// Người dùng có thể bấm "Quét lại mã QR" ở bước cuối để quay lại bước quét.
Future<bool> startCheckFlow(BuildContext context, {required bool checkIn}) async {
  while (true) {
    if (!context.mounted) return false;
    final token = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => QrScanScreen(checkIn: checkIn)));
    if (token == null || !context.mounted) return false;
    final outcome = await Navigator.push<CheckOutcome>(context, MaterialPageRoute(builder: (_) => CheckConfirmScreen(checkIn: checkIn, qrToken: token)));
    if (outcome == CheckOutcome.rescan && context.mounted) continue;
    return outcome == CheckOutcome.done;
  }
}
