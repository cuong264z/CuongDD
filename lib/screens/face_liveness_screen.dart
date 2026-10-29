import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../app/theme.dart';
import '../core/liveness.dart';
import '../widgets/camera_stage.dart';

/// Xác thực người thật bằng camera trước: ML Kit nhận diện khuôn mặt ngay trên máy,
/// người dùng làm hai động tác ngẫu nhiên (mỉm cười / nghiêng đầu / ngẩng đầu).
/// Trả `true` khi vượt qua, `null`/`false` nếu thoát.
class FaceLivenessScreen extends StatefulWidget {
  const FaceLivenessScreen({super.key});

  @override
  State<FaceLivenessScreen> createState() => _FaceLivenessScreenState();
}

class _FaceLivenessScreenState extends State<FaceLivenessScreen> {
  static const _timeLimit = Duration(seconds: 30);

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(enableClassification: true, performanceMode: FaceDetectorMode.fast),
  );
  final LivenessTracker _tracker = LivenessTracker();
  Timer? _deadline;
  bool _timedOut = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _armDeadline();
  }

  @override
  void dispose() {
    _deadline?.cancel();
    _detector.close();
    super.dispose();
  }

  void _armDeadline() {
    _deadline?.cancel();
    _deadline = Timer(_timeLimit, () {
      if (mounted && !_tracker.isDone) setState(() => _timedOut = true);
    });
  }

  void _retry() {
    _tracker.reset();
    setState(() => _timedOut = false);
    _armDeadline();
  }

  Future<void> _onImage(InputImage image) async {
    if (_timedOut || _finished) return;
    final faces = await _detector.processImage(image);
    if (!mounted || _timedOut || _finished) return;

    FaceSample? sample;
    if (faces.length == 1) {
      final f = faces.first;
      sample = FaceSample(smile: f.smilingProbability, roll: f.headEulerAngleZ ?? 0, pitch: f.headEulerAngleX ?? 0);
    }
    _tracker.update(faces: faces.length, sample: sample);
    setState(() {});

    if (_tracker.isDone) {
      _finished = true;
      _deadline?.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _tracker.isDone;
    final ringColor = done ? Palette.ok : Palette.amber;
    return Scaffold(
      backgroundColor: Palette.navy,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(color: Colors.white, onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ),
            const SizedBox(height: 4),
            const Text('Xác thực khuôn mặt', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Kiểm tra bạn là người thật, không phải ảnh chụp', style: TextStyle(color: Colors.white60)),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 270,
                        height: 270,
                        child: ClipOval(
                          child: ColoredBox(
                            color: Colors.black,
                            child: CameraStage(lens: CameraLensDirection.front, onImage: _onImage, reason: 'Cần camera trước để xác thực bạn là người thật khi chấm công.'),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: SizedBox.expand(child: CustomPaint(painter: _RingPainter(_tracker.progress, ringColor))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: _timedOut
                  ? Column(children: [
                      const Text('Hết thời gian, chưa xác thực được', style: TextStyle(color: Palette.amber, fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Palette.amber, foregroundColor: Palette.navy),
                        onPressed: _retry,
                        child: const Text('Thử lại'),
                      ),
                    ])
                  : Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _tracker.message,
                            key: ValueKey(_tracker.message),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: done ? Palette.ok : Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _tracker.challengeCount; i++)
                              Container(
                                width: 34,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: i < _tracker.completed ? Palette.ok : Colors.white24,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    canvas.drawArc(rect, 0, 2 * pi, false, Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.color != color;
}
