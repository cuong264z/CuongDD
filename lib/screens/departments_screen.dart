import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/department.dart';
import '../services/department_service.dart';
import '../widgets/common.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  late Future<List<Department>> _future = DepartmentService.all();

  void _reload() => setState(() => _future = DepartmentService.all());

  Future<void> _edit([Department? d]) async {
    final name = TextEditingController(text: d?.name);
    final desc = TextEditingController(text: d?.description);
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(d == null ? 'Thêm phòng ban' : 'Sửa phòng ban'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Tên phòng ban'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Mô tả (không bắt buộc)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final n = name.text.trim();
    final ds = desc.text.trim().isEmpty ? null : desc.text.trim();
    name.dispose();
    desc.dispose();
    if (ok != true || !mounted) return;
    final done = await guarded(
      context,
      () => d == null ? DepartmentService.create(n, ds) : DepartmentService.update(d.id, n, ds),
      success: d == null ? 'Đã thêm phòng ban' : 'Đã cập nhật',
    );
    if (done) _reload();
  }

  Future<void> _delete(Department d) async {
    if (!await confirm(context, title: 'Xoá phòng ban', message: 'Xoá "${d.name}"? Không xoá được nếu còn nhân viên thuộc phòng này.', ok: 'Xoá', danger: true)) return;
    if (!mounted) return;
    if (await guarded(context, () => DepartmentService.delete(d.id), success: 'Đã xoá')) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Phòng ban')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _edit,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm'),
        ),
        body: FutureView<List<Department>>(
          future: _future,
          onRetry: _reload,
          builder: (context, list) => list.isEmpty
              ? const StateMessage(icon: Icons.apartment_rounded, title: 'Chưa có phòng ban', message: 'Nhấn "Thêm" để tạo phòng ban đầu tiên.')
              : RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final d = list[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _edit(d),
                          leading: const CircleAvatar(backgroundColor: Palette.indigoSoft, child: Icon(Icons.apartment_rounded, color: Palette.indigo)),
                          title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: (d.description ?? '').isEmpty ? null : Text(d.description!),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Palette.bad), onPressed: () => _delete(d)),
                        ),
                      );
                    },
                  ),
                ),
        ),
      );
}
