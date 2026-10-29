import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../models/entities.dart';
import '../services/attendance_service.dart';
import '../services/gps_service.dart';
import '../services/place_service.dart';
import '../widgets/common.dart';
import '../widgets/map_widgets.dart';
import 'face_liveness_screen.dart';

enum CheckOutcome { done, rescan }

/// Bước cuối của chấm công: đã có QR → đọc GPS → xác thực khuôn mặt → gửi lên server.
class CheckConfirmScreen extends StatefulWidget {
  const CheckConfirmScreen({super.key, required this.checkIn, required this.qrToken});

  final bool checkIn;
  final String qrToken;

  @override
  State<CheckConfirmScreen> createState() => _CheckConfirmScreenState();
}

class _CheckConfirmScreenState extends State<CheckConfirmScreen> {
  WorkLocation? _place;
  String? _placeError;

  GpsReading? _gps;
  GpsException? _gpsError;
  bool _readingGps = true;

  bool _faceOk = false;
  bool _sending = false;
  ApiException? _failure;

  @override
  void initState() {
    super.initState();
    _loadPlace();
    _readGps();
  }

  Future<void> _loadPlace() async {
    final id = PlaceService.locationIdOf(widget.qrToken);
    try {
      final p = await PlaceService.get(id!);
      if (mounted) setState(() => _place = p);
    } catch (e) {
      if (mounted) setState(() => _placeError = ApiException.of(e));
    }
  }

  Future<void> _readGps() async {
    setState(() {
      _readingGps = true;
      _gpsError = null;
    });
    try {
      final g = await GpsService.read();
      if (mounted) setState(() => _gps = g);
    } on GpsException catch (e) {
      if (mounted) setState(() => _gpsError = e);
    } finally {
      if (mounted) setState(() => _readingGps = false);
    }
  }

  double? get _distance {
    final p = _place, g = _gps;
    if (p == null || g == null) return null;
    return GpsService.distance(g.latitude, g.longitude, p.latitude, p.longitude);
  }

  bool get _inRange => _distance != null && _distance! <= _place!.radiusMeters;

  bool get _ready => _place != null && _gps != null && _inRange && _faceOk && !_sending;

  Future<void> _face() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const FaceLivenessScreen()));
    if (ok == true && mounted) setState(() => _faceOk = true);
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _failure = null;
    });
    try {
      final r = await AttendanceService.submit(checkIn: widget.checkIn, qrToken: widget.qrToken, gps: _gps!, faceVerified: _faceOk);
      if (!mounted) return;
      await _showSuccess(r);
      if (mounted) Navigator.pop(context, CheckOutcome.done);
    } on ApiException catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showSuccess(CheckResult r) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          icon: const CircleAvatar(radius: 30, backgroundColor: Color(0x261E8E5A), child: Icon(Icons.check_rounded, size: 36, color: Palette.ok)),
          title: Text(widget.checkIn ? 'Chấm công vào thành công' : 'Chấm công ra thành công', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fmtTime(r.timeLocal), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Palette.indigo)),
              Text(fmtDate(r.timeLocal), style: const TextStyle(color: Palette.muted)),
              const SizedBox(height: 10),
              Text('Cách điểm chấm công ${fmtMeters(r.distance)}'),
              if (r.isLate) const Padding(padding: EdgeInsets.only(top: 8), child: Pill('Đi trễ', Palette.warn, icon: Icons.alarm_rounded)),
              if (r.isEarlyLeave) const Padding(padding: EdgeInsets.only(top: 8), child: Pill('Về sớm', Palette.warn, icon: Icons.directions_run_rounded)),
              for (final f in r.flags) Padding(padding: const EdgeInsets.only(top: 8), child: Text('⚠ $f', style: const TextStyle(color: Palette.warn, fontSize: 13))),
            ],
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Xong'))],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.checkIn ? 'Chấm công vào' : 'Chấm công ra')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _stepCard(
              index: 1,
              title: 'Mã QR',
              state: _placeError != null ? _Step.bad : (_place == null ? _Step.busy : _Step.ok),
              subtitle: _placeError ?? (_place == null ? 'Đang đọc thông tin địa điểm…' : _place!.name),
            ),
            const SizedBox(height: 10),
            _gpsCard(),
            const SizedBox(height: 10),
            _stepCard(
              index: 3,
              title: 'Khuôn mặt',
              state: _faceOk ? _Step.ok : _Step.todo,
              subtitle: _faceOk ? 'Đã xác thực là người thật' : 'Cần xác thực bằng camera trước',
              action: _faceOk ? null : FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                onPressed: _face,
                icon: const Icon(Icons.face_retouching_natural_rounded),
                label: const Text('Xác thực khuôn mặt'),
              ),
            ),
            if (_failure != null) ...[const SizedBox(height: 14), _failureBox(_failure!)],
            const SizedBox(height: 20),
            BusyButton(
              label: widget.checkIn ? 'Gửi chấm công vào' : 'Gửi chấm công ra',
              icon: Icons.send_rounded,
              busy: _sending,
              onPressed: _ready ? _send : null,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _sending ? null : () => Navigator.pop(context, CheckOutcome.rescan),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Quét lại mã QR'),
            ),
          ],
        ),
      );

  Widget _gpsCard() {
    final d = _distance;
    final g = _gps;
    final p = _place;
    final subtitle = _readingGps
        ? 'Đang lấy vị trí…'
        : _gpsError != null
            ? _gpsError!.message
            : d == null
                ? 'Đang xác định khoảng cách…'
                : _inRange
                    ? 'Cách điểm chấm công ${fmtMeters(d)} (cho phép ${p!.radiusMeters} m)'
                    : 'Bạn cách điểm chấm công ${fmtMeters(d)}, quá bán kính cho phép ${p!.radiusMeters} m';
    return _stepCard(
      index: 2,
      title: 'Vị trí GPS',
      state: _readingGps || (g != null && p == null) ? _Step.busy : (_gpsError != null || (d != null && !_inRange) ? _Step.bad : (d == null ? _Step.todo : _Step.ok)),
      subtitle: subtitle,
      extra: g != null && p != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  child: MapBox(
                    center: LatLng(p.latitude, p.longitude),
                    zoom: 17,
                    radiusMeters: p.radiusMeters.toDouble(),
                    interactive: false,
                    markers: [pin(LatLng(p.latitude, p.longitude), color: Palette.indigo), dot(LatLng(g.latitude, g.longitude))],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Độ chính xác GPS ±${g.accuracy.round()} m', style: const TextStyle(fontSize: 12, color: Palette.muted)),
                if (g.isMocked)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Hệ điều hành báo vị trí giả lập, server sẽ từ chối.', style: TextStyle(color: Palette.bad, fontWeight: FontWeight.w600)),
                  ),
              ],
            )
          : null,
      action: _readingGps
          ? null
          : (_gpsError?.openLocationSettings == true || _gpsError?.openAppSettings == true)
              ? Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: _gpsError!.openLocationSettings ? GpsService.openLocationSettings : GpsService.openAppSettings,
                      child: const Text('Mở cài đặt'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.tonal(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)), onPressed: _readGps, child: const Text('Thử lại'))),
                ])
              : (_gpsError != null || (d != null && !_inRange))
                  ? FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: _readGps,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Lấy lại vị trí'),
                    )
                  : null,
    );
  }

  Widget _failureBox(ApiException e) {
    final rescan = e.code == 'QR_INVALID' || e.code == 'LOCATION_NOT_FOUND';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Palette.bad.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Palette.bad.withValues(alpha: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.error_outline_rounded, color: Palette.bad),
            const SizedBox(width: 8),
            Expanded(child: Text(_titleFor(e), style: const TextStyle(color: Palette.bad, fontWeight: FontWeight.w800, fontSize: 15))),
          ]),
          const SizedBox(height: 6),
          Text(e.message),
          for (final r in e.reasons) Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $r')),
          if (rescan) ...[
            const SizedBox(height: 4),
            const Text('Mã QR đổi liên tục, hãy quét lại mã đang hiển thị.', style: TextStyle(color: Palette.muted)),
          ],
        ],
      ),
    );
  }

  String _titleFor(ApiException e) => switch (e.code) {
        'QR_INVALID' => 'Mã QR không hợp lệ hoặc đã hết hạn',
        'LOCATION_NOT_FOUND' => 'Điểm chấm công không còn tồn tại',
        'OUT_OF_RANGE' => 'Bạn đang ngoài phạm vi chấm công',
        'FRAUD_SUSPECTED' => 'Chấm công bị từ chối vì nghi gian lận',
        'FACE_REQUIRED' || 'FACE_MISMATCH' => 'Chưa xác thực được khuôn mặt',
        'ALREADY_DONE' => 'Hôm nay bạn đã chấm công rồi',
        'NO_CHECKIN' => 'Bạn chưa chấm công vào hôm nay',
        _ => 'Không chấm công được',
      };

  Widget _stepCard({
    required int index,
    required String title,
    required _Step state,
    required String subtitle,
    Widget? extra,
    Widget? action,
  }) {
    final (icon, color) = switch (state) {
      _Step.ok => (Icons.check_circle_rounded, Palette.ok),
      _Step.bad => (Icons.error_rounded, Palette.bad),
      _Step.busy => (Icons.hourglass_top_rounded, Palette.muted),
      _Step.todo => (Icons.radio_button_unchecked_rounded, Palette.muted),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 15, backgroundColor: Palette.indigoSoft, child: Text('$index', style: const TextStyle(fontWeight: FontWeight.w800, color: Palette.indigo))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: state == _Step.bad ? Palette.bad : Palette.muted, height: 1.3)),
                    ],
                  ),
                ),
                state == _Step.busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Icon(icon, color: color),
              ],
            ),
            ?extra,
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }
}

enum _Step { ok, bad, busy, todo }
