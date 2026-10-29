import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app/theme.dart';
import '../core/api.dart';
import '../models/entities.dart';
import '../services/place_service.dart';

/// Màn "Điểm chấm công" cho Admin/Manager: hiện mã QR của một địa điểm, tự đổi mã mỗi 30 giây.
class QrDisplayScreen extends StatefulWidget {
  const QrDisplayScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  static const _refreshEvery = 30;

  List<WorkLocation> _locations = [];
  WorkLocation? _selected;
  String? _token;
  String? _error;
  bool _loadingList = true;
  int _left = _refreshEvery;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _selected == null) return;
      setState(() => _left--);
      if (_left <= 0) _fetchToken();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _loadingList = true;
      _error = null;
    });
    try {
      final list = await PlaceService.all();
      if (!mounted) return;
      setState(() {
        _locations = list;
        _loadingList = false;
        _selected = list.isEmpty ? null : list.first;
      });
      if (_selected != null) _fetchToken();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingList = false;
          _error = ApiException.of(e);
        });
      }
    }
  }

  Future<void> _fetchToken() async {
    final loc = _selected;
    if (loc == null) return;
    _left = _refreshEvery;
    try {
      final t = await PlaceService.qrToken(loc.id);
      if (!mounted || _selected?.id != loc.id) return;
      setState(() {
        _token = t;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.of(e));
    }
  }

  void _select(WorkLocation l) {
    setState(() {
      _selected = l;
      _token = null;
    });
    _fetchToken();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Palette.navy,
        appBar: widget.embedded
            ? null
            : AppBar(backgroundColor: Palette.navy, foregroundColor: Colors.white, title: const Text('Mã QR chấm công', style: TextStyle(color: Colors.white))),
        body: SafeArea(child: _body()),
      );

  Widget _body() {
    if (_loadingList) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_locations.isEmpty) {
      return Center(
        child: _error != null
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.tonal(onPressed: _loadLocations, child: const Text('Thử lại')),
              ])
            : const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Chưa có địa điểm nào. Admin hãy tạo địa điểm chấm công trước.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              ),
      );
    }
    final progress = _left / _refreshEvery;
    return Column(
      children: [
        SizedBox(
          height: 58,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            children: [
              for (final l in _locations)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l.name),
                    selected: _selected?.id == l.id,
                    onSelected: (_) => _select(l),
                    selectedColor: Palette.amber,
                    backgroundColor: Colors.white12,
                    labelStyle: TextStyle(color: _selected?.id == l.id ? Palette.navy : Colors.white, fontWeight: FontWeight.w600),
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selected?.name ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Nhân viên mở app, chọn Chấm công rồi quét mã này', style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: _token == null
                          ? Center(
                              child: _error != null
                                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                                      Text(_error!, textAlign: TextAlign.center),
                                      TextButton(onPressed: _fetchToken, child: const Text('Thử lại')),
                                    ])
                                  : const CircularProgressIndicator(),
                            )
                          : QrImageView(data: _token!, size: 250, backgroundColor: Colors.white, errorCorrectionLevel: QrErrorCorrectLevel.M),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 250,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 8, color: Palette.amber, backgroundColor: Colors.white12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_error != null && _token != null ? 'Chưa làm mới được mã, đang thử lại…' : 'Tự đổi mã sau $_left giây',
                      style: TextStyle(color: _error != null && _token != null ? Palette.amber : Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
