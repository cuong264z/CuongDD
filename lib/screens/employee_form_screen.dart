import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/api.dart';
import '../models/department.dart';
import '../models/employee.dart';
import '../models/entities.dart';
import '../services/department_service.dart';
import '../services/user_service.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common.dart';

/// Thêm nhân viên mới (employeeId == null) hoặc sửa nhân viên. Chỉ Admin.
class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key, this.employeeId});

  final String? employeeId;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  List<Department> _departments = [];
  int? _departmentId;
  String _role = Roles.employee;
  bool _active = true;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.employeeId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deps = await DepartmentService.all();
      Employee? e;
      if (_isEdit) e = await UserService.get(widget.employeeId!);
      if (!mounted) return;
      setState(() {
        _departments = deps;
        if (e != null) {
          _name.text = e.fullName;
          _email.text = e.email;
          _code.text = e.employeeCode ?? '';
          _role = e.role ?? Roles.employee;
          _active = e.isActive;
          _departmentId = deps.any((d) => d.id == e!.departmentId) ? e.departmentId : null;
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = ApiException.of(e);
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final code = _code.text.trim().isEmpty ? null : _code.text.trim();
    final ok = await guarded(
      context,
      () => _isEdit
          ? UserService.update(widget.employeeId!,
              fullName: _name.text.trim(), employeeCode: code, departmentId: _departmentId, role: _role, isActive: _active)
          : UserService.create(
              email: _email.text.trim(),
              password: _password.text,
              fullName: _name.text.trim(),
              employeeCode: code,
              departmentId: _departmentId,
              role: _role),
      success: _isEdit ? 'Đã lưu thay đổi' : 'Đã thêm nhân viên',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _resetDevice() async {
    if (!await confirm(context,
        title: 'Gỡ ràng buộc thiết bị',
        message: 'Tài khoản này sẽ được gắn lại với máy đầu tiên dùng để chấm công. Dùng khi nhân viên đổi điện thoại.',
        ok: 'Gỡ')) {
      return;
    }
    if (!mounted) return;
    await guarded(context, () => UserService.resetDevice(widget.employeeId!), success: 'Đã gỡ ràng buộc thiết bị');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Sửa nhân viên' : 'Thêm nhân viên')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? StateMessage(icon: Icons.cloud_off_rounded, title: 'Không tải được dữ liệu', message: _error, actionLabel: 'Thử lại', onAction: _load, color: Palette.bad)
                : _formBody(),
      );

  Widget _formBody() => Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              enabled: !_isEdit,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                helperText: _isEdit ? 'Không đổi được email' : null,
              ),
              validator: validateEmail,
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu ban đầu',
                  helperText: 'Ít nhất 6 ký tự, có chữ thường và chữ số',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: validatePassword,
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Mã nhân viên (không bắt buộc)', prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int?>(
              initialValue: _departmentId,
              decoration: const InputDecoration(labelText: 'Phòng ban', prefixIcon: Icon(Icons.apartment_rounded)),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Chưa phân phòng')),
                for (final d in _departments) DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
              ],
              onChanged: (v) => setState(() => _departmentId = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Vai trò', prefixIcon: Icon(Icons.admin_panel_settings_outlined)),
              items: [for (final r in Roles.all) DropdownMenuItem(value: r, child: Text(Roles.label(r)))],
              onChanged: (v) => setState(() => _role = v ?? Roles.employee),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Tài khoản đang hoạt động'),
                subtitle: const Text('Tắt để khoá, người này sẽ không đăng nhập được'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              OutlinedButton.icon(
                onPressed: _resetDevice,
                icon: const Icon(Icons.phonelink_erase_rounded),
                label: const Text('Gỡ ràng buộc thiết bị'),
              ),
            ],
            const SizedBox(height: 22),
            BusyButton(label: _isEdit ? 'Lưu thay đổi' : 'Tạo nhân viên', busy: _saving, onPressed: _save),
          ],
        ),
      );
}
