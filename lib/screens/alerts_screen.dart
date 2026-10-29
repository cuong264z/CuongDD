import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../models/entities.dart';
import '../services/alert_service.dart';
import '../widgets/common.dart';

/// Cảnh báo gian lận: fake GPS, máy lạ, QR sai... Admin/Manager xem và đánh dấu đã xử lý; Admin xoá.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool? _resolved = false;
  late Future<List<FraudAlert>> _future = AlertService.list(resolved: _resolved);

  void _reload() => setState(() => _future = AlertService.list(resolved: _resolved));

  Future<void> _resolve(FraudAlert a) async {
    if (await guarded(context, () => AlertService.resolve(a.id), success: 'Đã đánh dấu xử lý')) _reload();
  }

  Future<void> _delete(FraudAlert a) async {
    if (!await confirm(context, title: 'Xoá cảnh báo', message: 'Xoá cảnh báo của ${a.userName}?', ok: 'Xoá', danger: true)) return;
    if (!mounted) return;
    if (await guarded(context, () => AlertService.delete(a.id), success: 'Đã xoá cảnh báo')) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.embedded ? null : AppBar(title: const Text('Cảnh báo gian lận')),
        body: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  for (final (value, label) in const [(false, 'Chưa xử lý'), (true, 'Đã xử lý'), (null, 'Tất cả')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _resolved == value,
                        onSelected: (_) {
                          _resolved = value;
                          _reload();
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: FutureView<List<FraudAlert>>(
                future: _future,
                onRetry: _reload,
                builder: (context, list) => list.isEmpty
                    ? const StateMessage(icon: Icons.verified_user_rounded, title: 'Không có cảnh báo', message: 'Hiện chưa phát hiện hành vi bất thường.', color: Palette.ok)
                    : RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final a = list[i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(a.resolved ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: a.resolved ? Palette.ok : Palette.warn),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(a.reason, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('${a.userName} · ${fmtDateTime(a.createdAt)}', style: const TextStyle(color: Palette.muted, fontSize: 13)),
                                    if ((a.detail ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(a.detail!),
                                    ],
                                    if (!a.resolved || Session.isAdmin)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (Session.isAdmin)
                                            TextButton.icon(
                                              onPressed: () => _delete(a),
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                              label: const Text('Xoá'),
                                              style: TextButton.styleFrom(foregroundColor: Palette.bad),
                                            ),
                                          if (!a.resolved)
                                            TextButton.icon(onPressed: () => _resolve(a), icon: const Icon(Icons.done_rounded, size: 18), label: const Text('Đã xử lý')),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
}
