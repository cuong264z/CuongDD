import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/session.dart';
import '../models/entities.dart';
import '../services/alert_service.dart';
import '../services/department_service.dart';
import '../services/place_service.dart';
import '../services/shift_service.dart';
import '../services/user_service.dart';
import '../widgets/common.dart';
import 'alerts_screen.dart';
import 'attendance_list_screen.dart';
import 'departments_screen.dart';
import 'employees_screen.dart';
import 'leaves_screen.dart';
import 'locations_screen.dart';
import 'profile_view.dart';
import 'qr_display_screen.dart';
import 'report_screen.dart';
import 'shifts_screen.dart';

class _Feature {
  const _Feature(this.title, this.icon, this.builder, {this.color = Palette.indigo});
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
  final Color color;
}

/// Trang chủ quản trị: menu bên trái (Drawer) + lưới chức năng kèm số liệu nhanh.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  static final _manage = [
    _Feature('Nhân viên', Icons.groups_rounded, (_) => const EmployeesScreen()),
    _Feature('Phòng ban', Icons.apartment_rounded, (_) => const DepartmentsScreen()),
    _Feature('Ca làm việc', Icons.schedule_rounded, (_) => const ShiftsScreen()),
    _Feature('Địa điểm', Icons.place_rounded, (_) => const LocationsScreen()),
  ];
  static final _operate = [
    _Feature('Mã QR chấm công', Icons.qr_code_2_rounded, (_) => const QrDisplayScreen(), color: Palette.navy),
    _Feature('Chấm công & bản đồ', Icons.map_rounded, (_) => const AttendanceListScreen(), color: Palette.ok),
    _Feature('Bảng công', Icons.table_chart_rounded, (_) => const ReportScreen(), color: Palette.ok),
    _Feature('Đơn nghỉ phép', Icons.event_note_rounded, (_) => const LeavesScreen(), color: Palette.warn),
    _Feature('Cảnh báo gian lận', Icons.shield_rounded, (_) => const AlertsScreen(), color: Palette.bad),
  ];

  late Future<_Counts> _counts = _fetch();

  Future<_Counts> _fetch() async {
    final r = await Future.wait([
      UserService.search(pageSize: 1),
      DepartmentService.all(),
      ShiftService.all(),
      PlaceService.all(),
      AlertService.list(resolved: false),
    ]);
    return _Counts(
      employees: (r[0] as Paged).total,
      departments: (r[1] as List).length,
      shifts: (r[2] as List).length,
      locations: (r[3] as List).length,
      alerts: (r[4] as List).length,
    );
  }

  void _reload() => setState(() => _counts = _fetch());

  Future<void> _open(_Feature f) async {
    await Navigator.push(context, MaterialPageRoute(builder: f.builder));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Quản trị')),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Palette.navy, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(radius: 24, backgroundColor: Palette.amber, child: Icon(Icons.admin_panel_settings_rounded, color: Palette.navy)),
                      const SizedBox(height: 12),
                      Text(Session.fullName.isEmpty ? 'Quản trị viên' : Session.fullName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(Session.email, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
                const _DrawerHeading('Quản lý dữ liệu'),
                for (final f in _manage) _drawerItem(f),
                const _DrawerHeading('Vận hành'),
                for (final f in _operate) _drawerItem(f),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: const Text('Hồ sơ'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Hồ sơ')), body: const ProfileView())));
                  },
                ),
                ListTile(leading: const Icon(Icons.logout_rounded, color: Palette.bad), title: const Text('Đăng xuất', style: TextStyle(color: Palette.bad)), onTap: () => logoutAndGoToLogin(context)),
              ],
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text('Xin chào, ${Session.fullName.isEmpty ? 'Admin' : Session.fullName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Tổng quan hệ thống chấm công', style: TextStyle(color: Palette.muted)),
              const SizedBox(height: 14),
              FutureBuilder<_Counts>(
                future: _counts,
                builder: (context, snap) {
                  final c = snap.data;
                  String v(int? n) => n == null ? '–' : '$n';
                  return GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.05,
                    children: [
                      StatTile(label: 'Nhân viên', value: v(c?.employees), icon: Icons.groups_rounded),
                      StatTile(label: 'Phòng ban', value: v(c?.departments), icon: Icons.apartment_rounded),
                      StatTile(label: 'Ca làm việc', value: v(c?.shifts), icon: Icons.schedule_rounded),
                      StatTile(label: 'Địa điểm', value: v(c?.locations), icon: Icons.place_rounded, color: Palette.ok),
                      StatTile(label: 'Cảnh báo mới', value: v(c?.alerts), icon: Icons.shield_rounded, color: (c?.alerts ?? 0) > 0 ? Palette.bad : Palette.ok),
                    ],
                  );
                },
              ),
              const SectionTitle('Quản lý dữ liệu'),
              _grid(_manage),
              const SectionTitle('Vận hành'),
              _grid(_operate),
            ],
          ),
        ),
      );

  Widget _drawerItem(_Feature f) => ListTile(
        leading: Icon(f.icon, color: f.color),
        title: Text(f.title),
        onTap: () {
          Navigator.pop(context);
          _open(f);
        },
      );

  Widget _grid(List<_Feature> items) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final f in items)
            SizedBox(
              width: (MediaQuery.of(context).size.width - 42) / 2,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(f),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(color: f.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(f.icon, color: f.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(f.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
}

class _Counts {
  _Counts({required this.employees, required this.departments, required this.shifts, required this.locations, required this.alerts});
  final int employees, departments, shifts, locations, alerts;
}

class _DrawerHeading extends StatelessWidget {
  const _DrawerHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: Palette.muted)),
      );
}
