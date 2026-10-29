import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../services/auth_service.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common.dart';
import 'role_router.dart';

/// Quên mật khẩu: bước 1 nhập email, bước 2 nhập mã + mật khẩu mới.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailForm.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await guarded(context, () => AuthService.forgotPassword(_email.text.trim()), success: 'Nếu email có tài khoản, mã đã được gửi.');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _codeSent = true;
    });
  }

  Future<void> _reset() async {
    if (!_resetForm.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final r = await AuthService.resetPassword(email: _email.text.trim(), code: _code.text, newPassword: _password.text);
      if (!mounted) return;
      toast(context, 'Đã đổi mật khẩu');
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => RoleRouter.pageFor(r.role)), (_) => false);
    } catch (e) {
      if (mounted) toast(context, ApiException.of(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        showBack: true,
        title: 'Quên mật khẩu',
        subtitle: _codeSent ? 'Nhập mã 6 số trong email và đặt mật khẩu mới.' : 'Nhập email đã đăng ký để nhận mã đặt lại mật khẩu.',
        child: _codeSent ? _resetStep() : _emailStep(),
      );

  Widget _emailStep() => Form(
        key: _emailForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded)),
              validator: validateEmail,
            ),
            const SizedBox(height: 18),
            BusyButton(label: 'Gửi mã', busy: _busy, onPressed: _sendCode),
          ],
        ),
      );

  Widget _resetStep() => Form(
        key: _resetForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Mã 6 số', counterText: '', prefixIcon: Icon(Icons.pin_outlined)),
              validator: (v) => (v?.length ?? 0) == 6 ? null : 'Mã gồm 6 chữ số',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới', prefixIcon: Icon(Icons.lock_outline_rounded)),
              validator: validatePassword,
            ),
            const SizedBox(height: 18),
            BusyButton(label: 'Đổi mật khẩu', busy: _busy, onPressed: _reset),
            TextButton(onPressed: _busy ? null : () => setState(() => _codeSent = false), child: const Text('Gửi mã tới email khác')),
          ],
        ),
      );
}
