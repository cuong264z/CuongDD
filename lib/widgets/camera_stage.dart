import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    show InputImage, InputImageFormat, InputImageFormatValue, InputImageMetadata, InputImageRotationValue;
import 'package:permission_handler/permission_handler.dart';

import '../app/theme.dart';

typedef ImageHandler = Future<void> Function(InputImage image);

enum _Stage { asking, denied, blocked, opening, live, failed }

/// Mở camera, xin quyền, phủ hình xem trước vào vùng chứa và đưa từng khung hình (đã đổi sang
/// [InputImage] cho ML Kit) cho [onImage]. Bỏ qua khung hình mới khi lần xử lý trước chưa xong.
class CameraStage extends StatefulWidget {
  const CameraStage({super.key, required this.lens, required this.onImage, required this.reason});

  final CameraLensDirection lens;
  final ImageHandler onImage;

  /// Giải thích vì sao cần camera, hiện khi bị từ chối quyền.
  final String reason;

  @override
  State<CameraStage> createState() => _CameraStageState();
}

class _CameraStageState extends State<CameraStage> with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _description;
  _Stage _stage = _Stage.asking;
  String _failure = '';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _controller;
    _controller = null;
    if (c != null) {
      // Phải nhả hẳn camera trước khi màn khác mở lại, nếu không camera mới bị treo.
      unawaited(() async {
        try {
          if (c.value.isStreamingImages) await c.stopImageStream();
        } catch (_) {}
        try {
          await c.dispose();
        } catch (_) {}
      }());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Người dùng vừa sang Cài đặt cấp quyền xong → thử lại.
    if (state == AppLifecycleState.resumed && (_stage == _Stage.denied || _stage == _Stage.blocked)) _open();
  }

  Future<void> _open() async {
    setState(() => _stage = _Stage.asking);
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _stage = status.isPermanentlyDenied ? _Stage.blocked : _Stage.denied);
      return;
    }
    setState(() => _stage = _Stage.opening);
    CameraController? c;
    try {
      // Thêm thời hạn: có máy mở camera mà không báo lỗi cũng không trả lời.
      await (() async {
        final cams = await availableCameras();
        final description = cams.firstWhere((x) => x.lensDirection == widget.lens, orElse: () => cams.first);
        _description = description;
        c = CameraController(
          description,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
        );
        await c!.initialize();
        if (!mounted) return;
        await c!.startImageStream(_onFrame);
      })()
          .timeout(const Duration(seconds: 12));
      if (!mounted) {
        await c?.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _stage = _Stage.live;
      });
    } on TimeoutException {
      await c?.dispose();
      _fail('Camera không phản hồi. Hãy đóng ứng dụng khác đang dùng camera rồi thử lại.');
    } on CameraException catch (e) {
      await c?.dispose();
      _fail(e.description ?? e.code);
    } catch (_) {
      await c?.dispose();
      _fail('Máy không có camera dùng được.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.failed;
      _failure = message;
    });
  }

  Future<void> _onFrame(CameraImage frame) async {
    if (_processing) return;
    final input = _toInputImage(frame);
    if (input == null) return;
    _processing = true;
    try {
      await widget.onImage(input);
    } finally {
      _processing = false;
    }
  }

  /// Màn hình khoá chiều dọc nên chiều xoay của ảnh chính là hướng cảm biến.
  InputImage? _toInputImage(CameraImage frame) {
    final cam = _description;
    if (cam == null) return null;
    final rotation = InputImageRotationValue.fromRawValue(cam.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(frame.format.raw);
    if (rotation == null || format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (frame.planes.length != 1) return null;
    final plane = frame.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => switch (_stage) {
        _Stage.asking || _Stage.opening => const Center(child: CircularProgressIndicator(color: Colors.white)),
        _Stage.denied => _Notice(
            icon: Icons.no_photography_outlined,
            title: 'Cần quyền camera',
            body: widget.reason,
            action: 'Cấp quyền',
            onAction: _open,
          ),
        _Stage.blocked => _Notice(
            icon: Icons.no_photography_outlined,
            title: 'Camera đang bị chặn',
            body: 'Hãy bật quyền Camera cho ứng dụng trong Cài đặt rồi quay lại.',
            action: 'Mở Cài đặt',
            onAction: openAppSettings,
          ),
        _Stage.failed => _Notice(
            icon: Icons.videocam_off_outlined,
            title: 'Không mở được camera',
            body: _failure,
            action: 'Thử lại',
            onAction: _open,
          ),
        _Stage.live => _cover(_controller!),
      };

  /// Phóng hình xem trước cho phủ kín vùng chứa (kiểu "cover").
  Widget _cover(CameraController c) => LayoutBuilder(builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        var scale = size.aspectRatio * c.value.aspectRatio;
        if (scale < 1) scale = 1 / scale;
        return SizedBox.fromSize(
          size: size,
          child: ClipRect(child: Transform.scale(scale: scale, child: Center(child: CameraPreview(c)))),
        );
      });
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.body, required this.action, required this.onAction});

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: Colors.white70),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.4)),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(160, 48), backgroundColor: Palette.amber, foregroundColor: Palette.navy),
                onPressed: onAction,
                child: Text(action),
              ),
            ],
          ),
        ),
      );
}
