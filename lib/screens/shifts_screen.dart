import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../models/shift.dart';
import '../services/shift_service.dart';
import '../widgets/common.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  late Future<List<Shift>> _future = ShiftService.all();

  void _reload() => setState(() => _future = ShiftService.all());

  TimeOfDay _toTime(String hms) {
    final p = hms.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _toApi(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}:00';

  Future<void> _edit([Shift? s]) async {
    final name = TextEditingController(text: s?.name);
    final tolerance = TextEditingController(text: (s?.lateToleranceMinutes ?? 10).toString());
    var start = s == null ? const TimeOfDay(hour: 8, minute: 0) : _toTime(s.startTime);
    var end = s == null ? const TimeOfDay(hour: 17, minute: 0) : _toTime(s.endTime);
    final form = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) => AlertDialog(
          title: Text(s == null ? 'Thêm ca làm việc' : 'Sửa ca làm việc'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Tên ca'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên ca' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: Text('Vào ${start.format(c)}'),
                        onPressed: () async {
                          final t = await showTimePicker(context: c, initialTime: start);
                          if (t != null) setLocal(() => start = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text('Ra ${end.format(c)}'),
                        onPressed: () async {
                          final t = await showTimePicker(context: c, initialTime: end);
                          if (t != null) setLocal(() => end = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tolerance,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cho phép đi trễ (phút)'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n < 0 || n > 240) ? 'Nhập số từ 0 đến 240' : null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Huỷ')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
              onPressed: () {
                if (!form.currentState!.validate()) return;
                if (end.hour * 60 + end.minute <= start.hour * 60 + start.minute) {
                  toast(c, 'Giờ ra phải sau giờ vào', error: true);
                  return;
                }
                Navigator.pop(c, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    final n = name.text.trim();
    final tol = int.tryParse(tolerance.text) ?? 0;
    name.dispose();
    tolerance.dispose();
    if (ok != true || !mounted) return;
    final done = await guarded(
      context,
      () => s == null
          ? ShiftService.create(n, _toApi(start), _toApi(end), tol)
          : ShiftService.update(s.id, n, _toApi(start), _toApi(end), tol),
      success: s == null ? 'Đã thêm ca' : 'Đã cập nhật',
    );
    if (done) _reload();
  }

  Future<void> _delete(Shift s) async {
    if (!await confirm(context, title: 'Xoá ca làm việc', message: 'Xoá "${s.name}"? Không xoá được nếu đang gán cho địa điểm.', ok: 'Xoá', danger: true)) return;
    if (!mounted) return;
    if (await guarded(context, () => ShiftService.delete(s.id), success: 'Đã xoá')) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ca làm việc')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _edit,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm'),
        ),
        body: FutureView<List<Shift>>(
          future: _future,
          onRetry: _reload,
          builder: (context, list) => list.isEmpty
              ? const StateMessage(icon: Icons.schedule_rounded, title: 'Chưa có ca làm việc', message: 'Tạo ca trước rồi gán cho địa điểm chấm công.')
              : RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _edit(s),
                          leading: const CircleAvatar(backgroundColor: Palette.indigoSoft, child: Icon(Icons.schedule_rounded, color: Palette.indigo)),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${s.range} · trễ tối đa ${s.lateToleranceMinutes} phút'),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Palette.bad), onPressed: () => _delete(s)),
                        ),
                      );
                    },
                  ),
                ),
        ),
      );
}
