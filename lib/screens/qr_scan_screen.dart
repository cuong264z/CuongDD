import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../app/theme.dart';
import '../services/place_service.dart';
import '../widgets/camera_stage.dart';

/// Quét mã QR của điểm chấm công. Trả về nguyên chuỗi đã quét (`SC1....`) hoặc `null` nếu thoát.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, required this.checkIn});

  final bool checkIn;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final BarcodeScanner _scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
  bool _found = false;
  String? _hint;

  @override
  void dispose() {
    _scanner.close();
    super.dispose();
  }

  Future<void> _onImage(InputImage image) async {
    if (_found) return;
    final codes = await _scanner.processImage(image);
    if (_found || !mounted) return;
    for (final code in codes) {
      final raw = code.rawValue;
      if (raw == null) continue;
      if (PlaceService.locationIdOf(raw) != null) {
        _found = true;
        Navigator.pop(context, raw.trim());
        return;
      }
      if (_hint == null) setState(() => _hint = 'Đây không phải mã chấm công của SmartCheck');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            CameraStage(lens: CameraLensDirection.back, onImage: _onImage, reason: 'Cần camera để quét mã QR tại điểm chấm công.'),
            // Khung ngắm
            IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: CustomPaint(painter: _CornersPainter()),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).padding.bottom),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent]),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.checkIn ? 'Quét mã để chấm công VÀO' : 'Quét mã để chấm công RA',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hint ?? 'Đưa mã QR do quản lý hiển thị vào giữa khung',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _hint == null ? Colors.white70 : Palette.amber),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Palette.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const len = 36.0;
    final w = size.width, h = size.height;
    canvas
      ..drawLine(const Offset(0, 0), const Offset(len, 0), p)
      ..drawLine(const Offset(0, 0), const Offset(0, len), p)
      ..drawLine(Offset(w, 0), Offset(w - len, 0), p)
      ..drawLine(Offset(w, 0), Offset(w, len), p)
      ..drawLine(Offset(0, h), Offset(len, h), p)
      ..drawLine(Offset(0, h), Offset(0, h - len), p)
      ..drawLine(Offset(w, h), Offset(w - len, h), p)
      ..drawLine(Offset(w, h), Offset(w, h - len), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
