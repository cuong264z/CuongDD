import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Khung chung cho các màn đăng nhập: nền navy, thẻ trắng nổi ở giữa.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.title, required this.subtitle, required this.child, this.showBack = false});

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Palette.navy,
        body: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Palette.indigo.withValues(alpha: 0.35)),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Palette.amber.withValues(alpha: 0.12)),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(color: Palette.amber, borderRadius: BorderRadius.circular(20)),
                              child: const Icon(Icons.fingerprint_rounded, size: 38, color: Palette.navy),
                            ),
                            const SizedBox(height: 14),
                            const Text('SmartCheck HHC',
                                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 440),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Palette.ink)),
                                  const SizedBox(height: 4),
                                  Text(subtitle, style: const TextStyle(color: Palette.muted, height: 1.35)),
                                  const SizedBox(height: 22),
                                  child,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Kiểm tra mật khẩu theo luật của server: >= 6 ký tự, có chữ thường và chữ số.
String? validatePassword(String? v) {
  final s = v ?? '';
  if (s.length < 6) return 'Tối thiểu 6 ký tự';
  if (!RegExp(r'[a-z]').hasMatch(s)) return 'Cần ít nhất một chữ thường';
  if (!RegExp(r'\d').hasMatch(s)) return 'Cần ít nhất một chữ số';
  return null;
}

String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Email không hợp lệ';
  return null;
}
