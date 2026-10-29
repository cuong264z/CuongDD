import 'package:flutter/material.dart';

import '../core/api.dart';
import '../services/auth_service.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final email = _email.text.trim();
      await AuthService.register(fullName: _name.text.trim(), email: email, password: _password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OtpScreen(email: email, purpose: OtpPurpose.register)));
    } catch (e) {
      if (mounted) toast(context, ApiException.of(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        showBack: true,
        title: 'Tạo tài khoản',
        subtitle: 'Dùng email thật: mã xác minh sẽ được gửi về đó. Tài khoản mới có vai trò Nhân viên.',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Nhập họ tên' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded)),
                validator: validateEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  helperText: 'Ít nhất 6 ký tự, có chữ thường và chữ số',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                validator: validatePassword,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                obscureText: _hide,
                decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu', prefixIcon: Icon(Icons.lock_reset_rounded)),
                validator: (v) => v != _password.text ? 'Mật khẩu nhập lại không khớp' : null,
              ),
              const SizedBox(height: 20),
              BusyButton(label: 'Đăng ký và nhận mã', busy: _busy, onPressed: _submit),
            ],
          ),
        ),
      );
}
