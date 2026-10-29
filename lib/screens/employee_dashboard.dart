import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../models/entities.dart';
import '../services/attendance_service.dart';
import '../widgets/common.dart';
import 'check_flow.dart';
import 'leaves_screen.dart';
import 'profile_view.dart';
import 'report_screen.dart';

/// Trang chủ nhân viên: thanh điều hướng dưới 4 mục, nút chấm công nổi ở tab "Hôm nay".
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _tab = 0;
  // Đổi key để buộc các tab tải lại sau khi chấm công.
  int _refreshToken = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _TodayTab(key: ValueKey('today$_refreshToken'), onChecked: () => setState(() => _refreshToken++), onOpenReport: () => setState(() => _tab = 1)),
      Scaffold(appBar: AppBar(title: const Text('Lịch sử & bảng công')), body: _HistoryTab(key: ValueKey('history$_refreshToken'))),
      const LeavesScreen(embedded: true),
      Scaffold(appBar: AppBar(title: const Text('Cá nhân')), body: const ProfileView()),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today_rounded), label: 'Hôm nay'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded), label: 'Lịch sử'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note_rounded), label: 'Nghỉ phép'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Cá nhân'),
        ],
      ),
    );
  }
}

class _TodayData {
  _TodayData(this.today, this.recent, this.month);
  final List<AttendanceRecord> today;
  final List<AttendanceRecord> recent;
  final ReportRow? month;

  AttendanceRecord? get checkIn => today.where((r) => r.isCheckIn).firstOrNull;
  AttendanceRecord? get checkOut => today.where((r) => !r.isCheckIn).firstOrNull;
}

class _TodayTab extends StatefulWidget {
  const _TodayTab({super.key, required this.onChecked, required this.onOpenReport});

  final VoidCallback onChecked;
  final VoidCallback onOpenReport;

  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  late Future<_TodayData> _future = _fetch();

  Future<_TodayData> _fetch() async {
    final now = DateTime.now();
    final mine = await AttendanceService.mine(days: 7);
    ReportRow? month;
    try {
      month = (await AttendanceService.report(now.year, now.month)).firstOrNull;
    } catch (_) {
      // Thiếu số liệu tháng thì vẫn cho chấm công bình thường.
    }
    return _TodayData(mine.where((r) => sameDay(r.time, now)).toList(), mine.take(5).toList(), month);
  }

  void _reload() => setState(() => _future = _fetch());

  Future<void> _check(bool checkIn) async {
    final ok = await startCheckFlow(context, checkIn: checkIn);
    if (ok) widget.onChecked();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = Session.fullName.trim().split(' ').lastOrNull ?? '';
    return FutureBuilder<_TodayData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        final canIn = data != null && data.checkIn == null;
        final canOut = data != null && data.checkIn != null && data.checkOut == null;
        return Scaffold(
          backgroundColor: Palette.background,
          body: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 18, 20, 56),
                  decoration: const BoxDecoration(
                    color: Palette.navy,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(first.isEmpty ? 'Xin chào!' : 'Xin chào, $first!', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${weekdayVi(now)}, ${fmtDate(now)}', style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _statusCard(snap),
                  ),
                ),
                if (data != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: StatTile(label: 'Ngày công tháng ${now.month}', value: '${data.month?.daysWorked ?? 0}', icon: Icons.event_available_rounded, color: Palette.ok)),
                          const SizedBox(width: 10),
                          Expanded(child: StatTile(label: 'Đi trễ', value: '${data.month?.lateCount ?? 0}', icon: Icons.alarm_rounded, color: Palette.warn)),
                          const SizedBox(width: 10),
                          Expanded(child: StatTile(label: 'Về sớm', value: '${data.month?.earlyLeaveCount ?? 0}', icon: Icons.directions_run_rounded, color: Palette.bad)),
                        ]),
                        SectionTitle('Gần đây', trailing: TextButton(onPressed: widget.onOpenReport, child: const Text('Xem tất cả'))),
                        if (data.recent.isEmpty)
                          const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Chưa có lượt chấm công nào', style: TextStyle(color: Palette.muted)))))
                        else
                          Card(child: Column(children: [for (var i = 0; i < data.recent.length; i++) ...[if (i > 0) const Divider(height: 1), _RecordTile(data.recent[i])]])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          // Luôn hiện nút quét QR; chưa biết trạng thái hôm nay (đang tải/lỗi mạng) thì mặc định là chấm công vào.
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Palette.amber,
            foregroundColor: Palette.navy,
            onPressed: data != null && !canIn && !canOut ? null : () => _check(data == null || canIn),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              data != null && !canIn && !canOut ? 'Đã chấm công đủ hôm nay' : (canOut ? 'Quét QR chấm công ra' : 'Quét QR chấm công vào'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    );
  }

  Widget _statusCard(AsyncSnapshot<_TodayData> snap) {
    if (snap.connectionState != ConnectionState.done) {
      return const Card(child: SizedBox(height: 150, child: Center(child: CircularProgressIndicator())));
    }
    if (snap.hasError) {
      return Card(
        child: SizedBox(height: 190, child: StateMessage(icon: Icons.cloud_off_rounded, title: 'Không tải được dữ liệu', message: snap.error.toString(), actionLabel: 'Thử lại', onAction: _reload, color: Palette.bad)),
      );
    }
    final d = snap.data!;
    final String headline;
    if (d.checkIn == null) {
      headline = 'Bạn chưa chấm công hôm nay';
    } else if (d.checkOut == null) {
      headline = 'Đang trong ca làm việc';
    } else {
      headline = 'Hoàn thành ngày làm việc';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _timeBox('Giờ vào', d.checkIn, Icons.login_rounded, Palette.ok)),
                Container(width: 1, height: 52, color: const Color(0xFFE3E5F2)),
                Expanded(child: _timeBox('Giờ ra', d.checkOut, Icons.logout_rounded, Palette.indigo)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: Palette.ok),
                    onPressed: d.checkIn == null ? () => _check(true) : null,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    label: const Text('Quét QR vào'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: d.checkIn != null && d.checkOut == null ? () => _check(false) : null,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    label: const Text('Quét QR ra'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBox(String label, AttendanceRecord? r, IconData icon, Color color) => Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Palette.muted)),
          ]),
          const SizedBox(height: 6),
          Text(r == null ? '--:--' : fmtTime(r.time), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: r == null ? Palette.muted : color)),
          if (r != null && (r.isLate || r.isEarlyLeave)) Padding(padding: const EdgeInsets.only(top: 4), child: Pill(r.isLate ? 'Đi trễ' : 'Về sớm', Palette.warn)),
        ],
      );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile(this.r);

  final AttendanceRecord r;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: r.isCheckIn ? Palette.ok.withValues(alpha: 0.12) : Palette.indigoSoft,
          child: Icon(r.isCheckIn ? Icons.login_rounded : Icons.logout_rounded, color: r.isCheckIn ? Palette.ok : Palette.indigo, size: 20),
        ),
        title: Text('${r.isCheckIn ? 'Vào' : 'Ra'} lúc ${fmtTime(r.time)}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${dayLabel(r.time)} · ${r.location}'),
        trailing: r.isLate ? const Pill('Trễ', Palette.warn) : (r.isEarlyLeave ? const Pill('Về sớm', Palette.warn) : null),
      );
}

/// Lịch sử 30 ngày gom theo ngày + lối vào bảng công tháng.
class _HistoryTab extends StatefulWidget {
  const _HistoryTab({super.key});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late Future<List<AttendanceRecord>> _future = AttendanceService.mine(days: 30);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = AttendanceService.mine(days: 30));

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TabBar(controller: _tabs, tabs: const [Tab(text: '30 ngày qua'), Tab(text: 'Bảng công tháng')]),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                FutureView<List<AttendanceRecord>>(
                  future: _future,
                  onRetry: _reload,
                  builder: (context, list) {
                    if (list.isEmpty) return const StateMessage(icon: Icons.history_toggle_off_rounded, title: 'Chưa có lịch sử', message: 'Các lượt chấm công của bạn sẽ hiện ở đây.');
                    final groups = <String, List<AttendanceRecord>>{};
                    for (final r in list) {
                      groups.putIfAbsent(apiDate(r.time), () => []).add(r);
                    }
                    return RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          for (final g in groups.values) ...[
                            SectionTitle(dayLabel(g.first.time)),
                            Card(child: Column(children: [for (var i = 0; i < g.length; i++) ...[if (i > 0) const Divider(height: 1), _RecordTile(g[i])]])),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const ReportScreen(embedded: true),
              ],
            ),
          ),
        ],
      );
}
