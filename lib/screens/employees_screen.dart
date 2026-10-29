import 'dart:async';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../models/employee.dart';
import '../services/user_service.dart';
import '../widgets/common.dart';
import 'employee_form_screen.dart';

/// Danh sách nhân viên có tìm kiếm và phân trang. Manager chỉ xem, Admin thêm/sửa/xoá.
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  final List<Employee> _items = [];
  Timer? _debounce;
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (more) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }
    try {
      final r = await UserService.search(q: _search.text, page: more ? _page + 1 : 1, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        if (more) {
          _page++;
        } else {
          _items.clear();
        }
        _items.addAll(r.items);
        _total = r.total;
      });
    } catch (e) {
      if (mounted) {
        if (more) {
          toast(context, ApiException.of(e), error: true);
        } else {
          setState(() => _error = ApiException.of(e));
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  Future<void> _open([Employee? e]) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EmployeeFormScreen(employeeId: e?.id)));
    if (changed == true) _load();
  }

  Future<void> _delete(Employee e) async {
    if (!await confirm(context, title: 'Xoá nhân viên', message: 'Xoá "${e.fullName}" cùng dữ liệu chấm công của họ?', ok: 'Xoá', danger: true)) return;
    if (!mounted) return;
    if (await guarded(context, () => UserService.delete(e.id), success: 'Đã xoá nhân viên')) _load();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Session.isAdmin;
    return Scaffold(
      appBar: AppBar(title: const Text('Nhân viên')),
      floatingActionButton: admin
          ? FloatingActionButton.extended(onPressed: _open, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Thêm'))
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, email hoặc mã nhân viên',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          _load();
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _body(admin)),
        ],
      ),
    );
  }

  Widget _body(bool admin) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StateMessage(icon: Icons.cloud_off_rounded, title: 'Không tải được danh sách', message: _error, actionLabel: 'Thử lại', onAction: _load, color: Palette.bad);
    }
    if (_items.isEmpty) {
      return const StateMessage(icon: Icons.group_off_rounded, title: 'Không có nhân viên nào', message: 'Thử từ khoá khác hoặc thêm nhân viên mới.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: _items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == _items.length) {
            if (_items.length >= _total) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Center(child: Text('Tổng cộng $_total nhân viên', style: const TextStyle(color: Palette.muted))),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: OutlinedButton(
                onPressed: _loadingMore ? null : () => _load(more: true),
                child: _loadingMore
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Xem thêm (${_items.length}/$_total)'),
              ),
            );
          }
          final e = _items[i];
          return Card(
            child: ListTile(
              onTap: admin ? () => _open(e) : null,
              leading: CircleAvatar(
                backgroundColor: e.isActive ? Palette.indigoSoft : const Color(0xFFEDEDED),
                child: Text(
                  e.fullName.isEmpty ? '?' : e.fullName.trim()[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w800, color: e.isActive ? Palette.indigo : Palette.muted),
                ),
              ),
              title: Text(e.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text([
                if ((e.employeeCode ?? '').isNotEmpty) e.employeeCode!,
                e.email,
                if ((e.department ?? '').isNotEmpty) e.department!,
              ].join(' · ')),
              trailing: admin
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      if (!e.isActive) const Pill('Đã khoá', Palette.bad),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Palette.bad), onPressed: () => _delete(e)),
                    ])
                  : (e.isActive ? null : const Pill('Đã khoá', Palette.bad)),
            ),
          );
        },
      ),
    );
  }
}
