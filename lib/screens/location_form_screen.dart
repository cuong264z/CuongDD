import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show MapController;
import 'package:latlong2/latlong.dart';

import '../models/entities.dart';
import '../models/shift.dart';
import '../services/gps_service.dart';
import '../services/place_service.dart';
import '../widgets/common.dart';
import '../widgets/map_widgets.dart';

/// Thêm / sửa địa điểm chấm công: chạm bản đồ để chọn toạ độ, chỉnh bán kính, chọn ca.
class LocationFormScreen extends StatefulWidget {
  const LocationFormScreen({super.key, required this.shifts, this.location});

  final List<Shift> shifts;
  final WorkLocation? location;

  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen> {
  // Tâm bản đồ mặc định khi chưa có địa điểm: TP.HCM.
  static const _defaultCenter = LatLng(10.8019, 106.7144);

  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.location?.name);
  late final TextEditingController _address = TextEditingController(text: widget.location?.address);
  late LatLng _point = widget.location == null ? _defaultCenter : LatLng(widget.location!.latitude, widget.location!.longitude);
  late double _radius = (widget.location?.radiusMeters ?? 100).toDouble();
  late int _shiftId = widget.shifts.any((s) => s.id == widget.location?.shiftId) ? widget.location!.shiftId : widget.shifts.first.id;
  final _map = MapController();
  bool _saving = false;
  bool _locating = false;

  bool get _isEdit => widget.location != null;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _useMyPosition() async {
    setState(() => _locating = true);
    try {
      final g = await GpsService.read();
      final p = LatLng(g.latitude, g.longitude);
      if (!mounted) return;
      setState(() => _point = p);
      _map.move(p, 17);
    } on GpsException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final l = WorkLocation(
      id: widget.location?.id ?? 0,
      name: _name.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      latitude: _point.latitude,
      longitude: _point.longitude,
      radiusMeters: _radius.round(),
      shiftId: _shiftId,
    );
    final ok = await guarded(context, () => _isEdit ? PlaceService.update(l) : PlaceService.create(l), success: _isEdit ? 'Đã lưu địa điểm' : 'Đã thêm địa điểm');
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Sửa địa điểm' : 'Thêm địa điểm')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên địa điểm', prefixIcon: Icon(Icons.business_rounded)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên địa điểm' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Địa chỉ (không bắt buộc)', prefixIcon: Icon(Icons.signpost_outlined)),
              ),
              const SectionTitle('Vị trí trên bản đồ'),
              SizedBox(
                height: 280,
                child: MapBox(
                  center: _point,
                  controller: _map,
                  radiusMeters: _radius,
                  markers: [pin(_point)],
                  onTap: (p) => setState(() => _point = p),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_point.latitude.toStringAsFixed(6)}, ${_point.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _locating ? null : _useMyPosition,
                    icon: _locating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Vị trí của tôi'),
                  ),
                ],
              ),
              const Text('Chạm vào bản đồ để đặt điểm chấm công.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              Text('Bán kính cho phép: ${_radius.round()} m', style: const TextStyle(fontWeight: FontWeight.w700)),
              Slider(value: _radius, min: 20, max: 500, divisions: 48, label: '${_radius.round()} m', onChanged: (v) => setState(() => _radius = v)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _shiftId,
                decoration: const InputDecoration(labelText: 'Ca làm việc áp dụng', prefixIcon: Icon(Icons.schedule_rounded)),
                items: [for (final s in widget.shifts) DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.range})'))],
                onChanged: (v) => setState(() => _shiftId = v ?? _shiftId),
              ),
              const SizedBox(height: 22),
              BusyButton(label: _isEdit ? 'Lưu thay đổi' : 'Tạo địa điểm', busy: _saving, onPressed: _save),
            ],
          ),
        ),
      );
}
