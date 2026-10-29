import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/session.dart';
import '../models/entities.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

/// Thông tin tài khoản + đăng xuất, dùng cho cả ba vai trò.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late Future<Profile> _future = AuthService.me();

  void _reload() => setState(() => _future = AuthService.me());

  Future<void> _logout() async {
    if (!await confirm(context, title: 'Đăng xuất', message: 'Bạn muốn đăng xuất khỏi tài khoản này?', ok: 'Đăng xuất')) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => FutureView<Profile>(
        future: _future,
        onRetry: _reload,
        builder: (context, p) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Palette.indigo,
                child: Text(p.fullName.isEmpty ? '?' : p.fullName.trim()[0].toUpperCase(), style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(p.fullName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
            Center(child: Text(p.email, style: const TextStyle(color: Palette.muted))),
            const SizedBox(height: 8),
            Center(child: Pill(Roles.label(p.role), Palette.indigo)),
            const SizedBox(height: 22),
            Card(
              child: Column(
                children: [
                  _row(Icons.badge_outlined, 'Mã nhân viên', (p.employeeCode ?? '').isEmpty ? 'Chưa có' : p.employeeCode!),
                  const Divider(height: 1),
                  _row(Icons.phone_android_rounded, 'Thiết bị chấm công', p.deviceBound ? 'Đã gắn với máy của bạn' : 'Chưa gắn (gắn ở lần chấm công đầu)'),
                  const Divider(height: 1),
                  _row(Icons.face_rounded, 'Khuôn mặt đã đăng ký', p.hasFace ? 'Có' : 'Chưa (dùng xác thực người thật)'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Palette.bad, side: const BorderSide(color: Palette.bad)),
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      );

  Widget _row(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon, color: Palette.indigo),
        title: Text(label, style: const TextStyle(fontSize: 13, color: Palette.muted)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, color: Palette.ink, fontWeight: FontWeight.w600)),
      );
}

/// Đăng xuất nhanh từ menu của Admin/Manager.
Future<void> logoutAndGoToLogin(BuildContext context) async {
  if (!await confirm(context, title: 'Đăng xuất', message: 'Bạn muốn đăng xuất khỏi ${Session.fullName.isEmpty ? 'tài khoản này' : Session.fullName}?', ok: 'Đăng xuất')) return;
  await AuthService.logout();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
}
