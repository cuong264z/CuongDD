import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../models/entities.dart';
import '../services/leave_service.dart';
import '../widgets/common.dart';

/// Đơn nghỉ phép. Nhân viên: tạo / sửa / huỷ đơn của mình khi còn chờ duyệt.
/// Admin & Manager: xem tất cả đơn, lọc theo trạng thái, duyệt hoặc từ chối.
class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key, this.embedded = false});

  /// `true` khi nằm trong thanh điều hướng của trang chủ (không vẽ AppBar riêng).
  final bool embedded;

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  String? _filter = Session.canReview ? 'Pending' : null;
  late Future<List<Leave>> _future = LeaveService.list(status: _filter);

  void _reload() => setState(() => _future = LeaveService.list(status: _filter));

  Future<void> _edit([Leave? l]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LeaveForm(leave: l),
    );
    if (saved == true) _reload();
  }

  Future<void> _cancel(Leave l) async {
    if (!await confirm(context, title: 'Huỷ đơn nghỉ phép', message: 'Huỷ đơn ${fmtDate(l.fromDate)} – ${fmtDate(l.toDate)}?', ok: 'Huỷ đơn', danger: true)) return;
    if (!mounted) return;
    if (await guarded(context, () => LeaveService.delete(l.id), success: 'Đã huỷ đơn')) _reload();
  }

  Future<void> _review(Leave l, bool approve) async {
    final ok = await confirm(
      context,
      title: approve ? 'Duyệt đơn' : 'Từ chối đơn',
      message: '${l.userName}: ${fmtDate(l.fromDate)} – ${fmtDate(l.toDate)} (${l.days} ngày)',
      ok: approve ? 'Duyệt' : 'Từ chối',
      danger: !approve,
    );
    if (!ok || !mounted) return;
    if (await guarded(context, () => LeaveService.review(l.id, approve: approve), success: approve ? 'Đã duyệt đơn' : 'Đã từ chối đơn')) _reload();
  }

  (String, Color) _statusOf(String s) => switch (s) {
        'Approved' => ('Đã duyệt', Palette.ok),
        'Rejected' => ('Từ chối', Palette.bad),
        _ => ('Chờ duyệt', Palette.warn),
      };

  @override
  Widget build(BuildContext context) {
    final reviewer = Session.canReview;
    final body = Column(
      children: [
        if (reviewer)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final (value, label) in const [('Pending', 'Chờ duyệt'), ('Approved', 'Đã duyệt'), ('Rejected', 'Từ chối'), (null, 'Tất cả')])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _filter == value,
                      onSelected: (_) {
                        _filter = value;
                        _reload();
                      },
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: FutureView<List<Leave>>(
            future: _future,
            onRetry: _reload,
            builder: (context, list) => list.isEmpty
                ? StateMessage(
                    icon: Icons.event_available_rounded,
                    title: reviewer ? 'Không có đơn nào' : 'Bạn chưa có đơn nghỉ phép',
                    message: reviewer ? null : 'Nhấn "Tạo đơn" để xin nghỉ.',
                  )
                : RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _card(list[i], reviewer),
                    ),
                  ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: widget.embedded && !reviewer ? AppBar(title: const Text('Nghỉ phép')) : (widget.embedded ? null : AppBar(title: const Text('Đơn nghỉ phép'))),
      floatingActionButton: reviewer ? null : FloatingActionButton.extended(onPressed: _edit, icon: const Icon(Icons.add_rounded), label: const Text('Tạo đơn')),
      body: body,
    );
  }

  Widget _card(Leave l, bool reviewer) {
    final (label, color) = _statusOf(l.status);
    final sameDayRange = sameDay(l.fromDate, l.toDate);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reviewer ? l.userName : (sameDayRange ? fmtDate(l.fromDate) : '${fmtDate(l.fromDate)} – ${fmtDate(l.toDate)}'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                Pill(label, color),
              ],
            ),
            if (reviewer) ...[
              const SizedBox(height: 4),
              Text(sameDayRange ? fmtDate(l.fromDate) : '${fmtDate(l.fromDate)} – ${fmtDate(l.toDate)}', style: const TextStyle(color: Palette.muted)),
            ],
            const SizedBox(height: 8),
            Text(l.reason),
            const SizedBox(height: 6),
            Text('${l.days} ngày · gửi ${fmtDateTime(l.createdAt)}', style: const TextStyle(fontSize: 12, color: Palette.muted)),
            if (reviewer && l.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), foregroundColor: Palette.bad, side: const BorderSide(color: Palette.bad)),
                      onPressed: () => _review(l, false),
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44), backgroundColor: Palette.ok),
                      onPressed: () => _review(l, true),
                      child: const Text('Duyệt'),
                    ),
                  ),
                ],
              ),
            ],
            if (!reviewer && l.isPending) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(onPressed: () => _edit(l), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Sửa')),
                  TextButton.icon(
                    onPressed: () => _cancel(l),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Huỷ đơn'),
                    style: TextButton.styleFrom(foregroundColor: Palette.bad),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaveForm extends StatefulWidget {
  const _LeaveForm({this.leave});

  final Leave? leave;

  @override
  State<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<_LeaveForm> {
  late DateTime _from = widget.leave?.fromDate ?? DateTime.now().add(const Duration(days: 1));
  late DateTime _to = widget.leave?.toDate ?? _from;
  late final TextEditingController _reason = TextEditingController(text: widget.leave?.reason);
  final _form = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick(bool from) async {
    final today = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(today.year, today.month, today.day).subtract(const Duration(days: 30)),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() {
      if (from) {
        _from = d;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = d;
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_to.isBefore(_from)) {
      toast(context, 'Ngày kết thúc phải sau ngày bắt đầu', error: true);
      return;
    }
    setState(() => _saving = true);
    final l = widget.leave;
    final ok = await guarded(
      context,
      () => l == null ? LeaveService.create(_from, _to, _reason.text.trim()) : LeaveService.update(l.id, _from, _to, _reason.text.trim()),
      success: l == null ? 'Đã gửi đơn nghỉ phép' : 'Đã cập nhật đơn',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.leave == null ? 'Tạo đơn nghỉ phép' : 'Sửa đơn nghỉ phép', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      onPressed: () => _pick(true),
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: Text('Từ ${fmtDate(_from)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      onPressed: () => _pick(false),
                      icon: const Icon(Icons.event_available_rounded, size: 18),
                      label: Text('Đến ${fmtDate(_to)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _reason,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Lý do', alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Nhập lý do nghỉ' : null,
              ),
              const SizedBox(height: 18),
              BusyButton(label: widget.leave == null ? 'Gửi đơn' : 'Lưu', busy: _saving, onPressed: _save),
            ],
          ),
        ),
      );
}
