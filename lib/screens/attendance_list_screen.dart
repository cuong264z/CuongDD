import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../models/entities.dart';
import '../services/attendance_service.dart';
import '../widgets/common.dart';
import '../widgets/map_widgets.dart';

/// Admin/Manager: chấm công của mọi người theo ngày, có bản đồ nơi mỗi người đã chấm công.
class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  static const _pageSize = 30;

  DateTime _day = DateTime.now();
  final List<AttendanceRecord> _items = [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final from = DateTime(_day.year, _day.month, _day.day);
      final r = await AttendanceService.all(from: from, to: from.add(const Duration(days: 1)), page: more ? _page + 1 : 1, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        if (more) {
          _page++;
        } else {
          _page = 1;
          _items.clear();
        }
        _items.addAll(r.items);
        _total = r.total;
      });
    } catch (e) {
      if (mounted) {
        if (more) {
          toast(context, ApiException.of(e), error: true);
        } else {
          setState(() => _error = ApiException.of(e));
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _pickDay() async {
    final d = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(2025), lastDate: DateTime.now());
    if (d == null) return;
    _day = d;
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.embedded ? null : AppBar(title: const Text('Chấm công')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      _day = _day.subtract(const Duration(days: 1));
                      _load();
                    },
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _pickDay,
                      child: Text(dayLabel(_day), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: sameDay(_day, DateTime.now())
                        ? null
                        : () {
                            _day = _day.add(const Duration(days: 1));
                            _load();
                          },
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: _showMap ? 'Xem danh sách' : 'Xem bản đồ',
                    onPressed: () => setState(() => _showMap = !_showMap),
                    icon: Icon(_showMap ? Icons.view_list_rounded : Icons.map_rounded),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StateMessage(icon: Icons.cloud_off_rounded, title: 'Không tải được dữ liệu', message: _error, actionLabel: 'Thử lại', onAction: _load, color: Palette.bad);
    }
    if (_items.isEmpty) {
      return const StateMessage(icon: Icons.event_busy_rounded, title: 'Không có lượt chấm công', message: 'Chưa ai chấm công trong ngày này.');
    }
    return _showMap ? _map() : _list();
  }

  Widget _list() => RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: _items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            if (i == _items.length) {
              if (_items.length >= _total) {
                return Padding(padding: const EdgeInsets.all(12), child: Center(child: Text('$_total lượt chấm công', style: const TextStyle(color: Palette.muted))));
              }
              return OutlinedButton(
                onPressed: _loadingMore ? null : () => _load(more: true),
                child: _loadingMore ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Xem thêm (${_items.length}/$_total)'),
              );
            }
            final r = _items[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: r.isCheckIn ? Palette.ok.withValues(alpha: 0.12) : Palette.indigoSoft,
                  child: Icon(r.isCheckIn ? Icons.login_rounded : Icons.logout_rounded, color: r.isCheckIn ? Palette.ok : Palette.indigo),
                ),
                title: Text(r.userName ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${r.isCheckIn ? 'Vào' : 'Ra'} lúc ${fmtTime(r.time)} · ${r.location} · cách ${fmtMeters(r.distance)}'),
                trailing: r.isLate ? const Pill('Trễ', Palette.warn) : (r.isEarlyLeave ? const Pill('Về sớm', Palette.warn) : null),
              ),
            );
          },
        ),
      );

  Widget _map() {
    final located = _items.where((r) => r.latitude != null && r.longitude != null).toList();
    if (located.isEmpty) return const StateMessage(icon: Icons.location_off_rounded, title: 'Không có toạ độ để vẽ');
    final points = [for (final r in located) LatLng(r.latitude!, r.longitude!)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: MapBox(
        center: points.first,
        zoom: 16,
        markers: [
          for (var i = 0; i < located.length; i++)
            pin(
              points[i],
              color: located[i].isCheckIn ? Palette.ok : Palette.indigo,
              onTap: () => toast(context, '${located[i].userName} · ${located[i].isCheckIn ? 'vào' : 'ra'} ${fmtTime(located[i].time)}'),
            ),
        ],
      ),
    );
  }
}
