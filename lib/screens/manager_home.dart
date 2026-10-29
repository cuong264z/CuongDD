import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/session.dart';
import 'alerts_screen.dart';
import 'attendance_list_screen.dart';
import 'employees_screen.dart';
import 'leaves_screen.dart';
import 'profile_view.dart';
import 'qr_display_screen.dart';
import 'report_screen.dart';

/// Trang chủ quản lý: các tab nằm trên đầu (mã QR, chấm công, duyệt phép, bảng công, cảnh báo).
class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quản lý', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(Session.fullName, style: const TextStyle(fontSize: 12, color: Palette.muted, fontWeight: FontWeight.w500)),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) {
                  switch (v) {
                    case 'employees':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeesScreen()));
                    case 'profile':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Hồ sơ')), body: const ProfileView())));
                    case 'logout':
                      logoutAndGoToLogin(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'employees', child: ListTile(leading: Icon(Icons.groups_rounded), title: Text('Danh sách nhân viên'), contentPadding: EdgeInsets.zero)),
                  PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person_rounded), title: Text('Hồ sơ'), contentPadding: EdgeInsets.zero)),
                  PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout_rounded), title: Text('Đăng xuất'), contentPadding: EdgeInsets.zero)),
                ],
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Mã QR'),
                Tab(icon: Icon(Icons.how_to_reg_rounded), text: 'Chấm công'),
                Tab(icon: Icon(Icons.event_note_rounded), text: 'Duyệt phép'),
                Tab(icon: Icon(Icons.table_chart_rounded), text: 'Bảng công'),
                Tab(icon: Icon(Icons.shield_outlined), text: 'Cảnh báo'),
              ],
            ),
          ),
          body: const TabBarView(
            physics: NeverScrollableScrollPhysics(), // tránh vuốt nhầm khi đang kéo bản đồ
            children: [
              QrDisplayScreen(embedded: true),
              AttendanceListScreen(embedded: true),
              LeavesScreen(embedded: true),
              ReportScreen(embedded: true),
              AlertsScreen(embedded: true),
            ],
          ),
        ),
      );
}
