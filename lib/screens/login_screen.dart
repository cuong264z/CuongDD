import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common.dart';
import 'forgot_password_screen.dart';
import 'otp_screen.dart';
import 'register_screen.dart';
import 'role_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.notice});

  final String? notice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  bool _isDeviceSupported = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    final supported = await BiometricService.isDeviceSupported();
    if (mounted) {
      setState(() {
        _isDeviceSupported = supported;
      });
    }
  }

  Future<void> _loginBiometric() async {
    final enabled = await BiometricService.isBiometricEnabled();
    final hasToken = await AuthService.hasSavedToken();

    if (!enabled) {
      if (mounted) {
        toast(context, 'Bạn chưa bật xác thực sinh trắc học trong Cài đặt app!', error: true);
      }
      return;
    }

    if (!hasToken) {
      if (mounted) {
        toast(context, 'Vui lòng đăng nhập bằng mật khẩu hoặc Google lần đầu để kích hoạt!', error: true);
      }
      return;
    }

    final authenticated = await BiometricService.authenticate();
    if (authenticated && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => RoleRouter.pageFor(Session.role)),
            (route) => false,
      );
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _busy = true);
    try {
      final result = await AuthService.loginWithGoogle();
      if (result != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => RoleRouter.pageFor(Session.role)),
              (_) => false,
        );
      }
    } catch (e) {
      if (mounted) toast(context, ApiException.of(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final email = _email.text.trim();
      await AuthService.login(email, _password.text);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: email, purpose: OtpPurpose.login)));
    } catch (e) {
      if (mounted) toast(context, ApiException.of(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
    title: 'Đăng nhập',
    subtitle: 'Nhập email và mật khẩu, mã xác nhận 6 số sẽ được gửi tới email của bạn.',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.notice != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Palette.amber.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
              child: Text(widget.notice!, style: const TextStyle(color: Palette.ink)),
            ),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded)),
            validator: validateEmail,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _hide,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              child: const Text('Quên mật khẩu?'),
            ),
          ),
          BusyButton(label: 'Tiếp tục', busy: _busy, onPressed: _submit, icon: Icons.arrow_forward_rounded),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _loginGoogle,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Palette.indigo),
            label: const Text('Đăng nhập bằng Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_isDeviceSupported) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _loginBiometric,
              icon: const Icon(Icons.face_retouching_natural_rounded, size: 22, color: Palette.indigo),
              label: const Text('Quét mặt / Vân tay'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Chưa có tài khoản?', style: TextStyle(color: Palette.muted)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Đăng ký'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}