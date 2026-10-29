import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/entities.dart';
import '../models/shift.dart';
import '../services/place_service.dart';
import '../services/shift_service.dart';
import '../widgets/common.dart';
import 'location_form_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  late Future<(List<WorkLocation>, List<Shift>)> _future = _fetch();

  Future<(List<WorkLocation>, List<Shift>)> _fetch() async {
    final r = await Future.wait([PlaceService.all(), ShiftService.all()]);
    return (r[0] as List<WorkLocation>, r[1] as List<Shift>);
  }

  void _reload() => setState(() => _future = _fetch());

  Future<void> _open(List<Shift> shifts, [WorkLocation? l]) async {
    if (shifts.isEmpty) {
      toast(context, 'Hãy tạo ít nhất một ca làm việc trước khi thêm địa điểm.', error: true);
      return;
    }
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => LocationFormScreen(shifts: shifts, location: l)));
    if (changed == true) _reload();
  }

  Future<void> _delete(WorkLocation l) async {
    if (!await confirm(context, title: 'Xoá địa điểm', message: 'Xoá "${l.name}"? Mã QR của địa điểm này sẽ không dùng được nữa.', ok: 'Xoá', danger: true)) return;
    if (!mounted) return;
    if (await guarded(context, () => PlaceService.delete(l.id), success: 'Đã xoá địa điểm')) _reload();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<(List<WorkLocation>, List<Shift>)>(
        future: _future,
        builder: (context, snap) {
          final shifts = snap.data?.$2 ?? const <Shift>[];
          return Scaffold(
            appBar: AppBar(title: const Text('Địa điểm chấm công')),
            floatingActionButton: snap.hasData
                ? FloatingActionButton.extended(onPressed: () => _open(shifts), icon: const Icon(Icons.add_location_alt_rounded), label: const Text('Thêm'))
                : null,
            body: FutureView<(List<WorkLocation>, List<Shift>)>(
              future: _future,
              onRetry: _reload,
              builder: (context, data) {
                final list = data.$1;
                if (list.isEmpty) {
                  return const StateMessage(icon: Icons.location_off_rounded, title: 'Chưa có địa điểm', message: 'Thêm địa điểm để tạo mã QR chấm công.');
                }
                String shiftName(int id) => shifts.where((s) => s.id == id).map((s) => s.name).firstOrNull ?? 'Ca #$id';
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final l = list[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _open(shifts, l),
                          leading: const CircleAvatar(backgroundColor: Palette.indigoSoft, child: Icon(Icons.place_rounded, color: Palette.indigo)),
                          title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${(l.address ?? '').isEmpty ? '${l.latitude.toStringAsFixed(5)}, ${l.longitude.toStringAsFixed(5)}' : l.address!}\nBán kính ${l.radiusMeters} m · ${shiftName(l.shiftId)}'),
                          isThreeLine: true,
                          trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Palette.bad), onPressed: () => _delete(l)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      );
}
