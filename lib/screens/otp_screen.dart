import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../core/api.dart';
import '../services/auth_service.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common.dart';
import 'role_router.dart';

enum OtpPurpose { login, register }

/// Nhập mã 6 số gửi qua email (đăng nhập bước 2 hoặc xác minh email sau khi đăng ký).
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email, required this.purpose});

  final String email;
  final OtpPurpose purpose;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _resendWait = 30;
  static const _validFor = 5 * 60;

  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _resendIn = _resendWait;
  int _expiresIn = _validFor;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendIn > 0) _resendIn--;
        if (_expiresIn > 0) _expiresIn--;
      });
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      toast(context, 'Mã gồm 6 chữ số', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await AuthService.verifyOtp(widget.email, _code.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => RoleRouter.pageFor(r.role)), (_) => false);
    } catch (e) {
      if (mounted) {
        toast(context, ApiException.of(e), error: true);
        _code.clear();
        _focus.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final ok = await guarded(context, () => AuthService.resendOtp(widget.email), success: 'Đã gửi mã mới tới email');
    if (ok && mounted) {
      setState(() {
        _resendIn = _resendWait;
        _expiresIn = _validFor;
      });
    }
  }

  String get _countdown => '${_expiresIn ~/ 60}:${two(_expiresIn % 60)}';

  static String two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final register = widget.purpose == OtpPurpose.register;
    return AuthShell(
      showBack: true,
      title: register ? 'Xác minh email' : 'Nhập mã xác nhận',
      subtitle: 'Mã 6 số đã gửi tới ${widget.email}. Mã có hiệu lực 5 phút, nhập sai tối đa 5 lần.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _code,
            focusNode: _focus,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 14),
            decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            onChanged: (v) {
              setState(() {});
              if (v.length == 6) _verify();
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _expiresIn > 0 ? 'Mã còn hiệu lực $_countdown' : 'Mã đã hết hạn, hãy gửi lại mã mới',
              style: TextStyle(color: _expiresIn > 0 ? Palette.muted : Palette.bad, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          BusyButton(label: register ? 'Xác minh và vào app' : 'Đăng nhập', busy: _busy, onPressed: _verify),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _resendIn > 0 ? null : _resend,
            child: Text(_resendIn > 0 ? 'Gửi lại mã sau ${_resendIn}s' : 'Gửi lại mã'),
          ),
        ],
      ),
    );
  }
}
