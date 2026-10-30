import 'package:flutter/material.dart';

import '../app/settings_controller.dart';
import '../services/biometric_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt ứng dụng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Giao diện & Chủ đề', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ValueListenableBuilder<bool>(
            valueListenable: settings.isDarkModeNotifier,
            builder: (_, isDark, __) {
              return SwitchListTile(
                title: const Text('Chế độ tối (Dark Mode)'),
                subtitle: const Text('Thay đổi màu nền ứng dụng'),
                value: isDark,
                onChanged: (val) {
                  settings.setDarkMode(val);
                },
              );
            },
          ),
          const Divider(),
          const Text('Kích thước chữ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ValueListenableBuilder<double>(
            valueListenable: settings.fontSizeFactorNotifier,
            builder: (_, factor, __) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: factor,
                    min: 0.8,
                    max: 1.4,
                    divisions: 3,
                    label: factor == 0.8 ? 'Nhỏ' : (factor == 1.0 ? 'Vừa' : (factor == 1.2 ? 'Lớn' : 'Rất lớn')),
                    onChanged: (val) {
                      settings.setFontSizeFactor(val);
                    },
                  ),
                  Text('Văn bản mẫu hiển thị (Cỡ hiện tại: ${(factor * 100).toInt()}%)'),
                ],
              );
            },
          ),
          const Divider(),
          const Text('Bảo mật', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SwitchListTile(
            title: const Text('Đăng nhập bằng Vân tay / Khuôn mặt'),
            subtitle: const Text('Dùng sinh trắc học cho lần đăng nhập sau'),
            value: _biometricEnabled,
            onChanged: (val) async {
              final canCheck = await BiometricService.isDeviceSupported();
              if (!canCheck) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thiết bị không hỗ trợ hoặc chưa cài sinh trắc học!')),
                  );
                }
                return;
              }
              await BiometricService.setBiometricEnabled(val);
              if (mounted) setState(() => _biometricEnabled = val);
            },
          ),
        ],
      ),
    );
  }
}