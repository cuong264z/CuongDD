import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/entities.dart';
import '../services/attendance_service.dart';
import '../widgets/common.dart';

/// Bảng công theo tháng. Nhân viên thấy của mình; Admin/Manager thấy cả công ty.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<ReportRow>> _future = AttendanceService.report(_month.year, _month.month);

  void _go(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() {
      _month = next;
      _future = AttendanceService.report(next.year, next.month);
    });
  }

  void _reload() => setState(() => _future = AttendanceService.report(_month.year, _month.month));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Bảng công')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: [
                IconButton.filledTonal(onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left_rounded)),
                Expanded(
                  child: Center(
                    child: Text('Tháng ${_month.month}/${_month.year}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                IconButton.filledTonal(onPressed: isCurrent ? null : () => _go(1), icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
          Expanded(
            child: FutureView<List<ReportRow>>(
              future: _future,
              onRetry: _reload,
              builder: (context, rows) {
                if (rows.isEmpty) {
                  return const StateMessage(icon: Icons.table_chart_outlined, title: 'Chưa có dữ liệu công', message: 'Không có lượt chấm công nào trong tháng này.');
                }
                final days = rows.fold<int>(0, (a, r) => a + r.daysWorked);
                final late = rows.fold<int>(0, (a, r) => a + r.lateCount);
                final early = rows.fold<int>(0, (a, r) => a + r.earlyLeaveCount);
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(child: StatTile(label: 'Ngày công', value: '$days', icon: Icons.event_available_rounded, color: Palette.ok)),
                          const SizedBox(width: 10),
                          Expanded(child: StatTile(label: 'Đi trễ', value: '$late', icon: Icons.alarm_rounded, color: Palette.warn)),
                          const SizedBox(width: 10),
                          Expanded(child: StatTile(label: 'Về sớm', value: '$early', icon: Icons.directions_run_rounded, color: Palette.bad)),
                        ],
                      ),
                      if (rows.length > 1) const SectionTitle('Chi tiết từng người'),
                      if (rows.length > 1)
                        for (final r in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: ListTile(
                                title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text('${r.daysWorked} ngày công · trễ ${r.lateCount} · về sớm ${r.earlyLeaveCount}'),
                                trailing: r.lateCount + r.earlyLeaveCount == 0 ? const Icon(Icons.verified_rounded, color: Palette.ok) : null,
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
