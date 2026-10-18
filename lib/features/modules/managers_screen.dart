import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class ManagersScreen extends StatefulWidget {
  const ManagersScreen({super.key});
  @override
  State<ManagersScreen> createState() => _ManagersScreenState();
}

class _ManagersScreenState extends State<ManagersScreen> {
  bool loading = true;
  String? error;
  List items = [];
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await context.read<AuthService>().api.dio.get('managers', queryParameters: {
        if (searchCtrl.text.trim().isNotEmpty) 'search': searchCtrl.text.trim(),
      });
      if (res.data is Map && res.data['managers'] is List) {
        items = List.from(res.data['managers'] as List);
      } else {
        items = [];
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'administrator':
        return 'مدیر کل';
      case 'shop_manager':
        return 'مدیر فروشگاه';
      case 'editor':
        return 'ویرایشگر';
      case 'customer':
        return 'مشتری';
      case 'subscriber':
        return 'مشترک';
      default:
        return role;
    }
  }

  Future<void> _openActions(Map m) async {
    final id = m['id'];
    final name = m['display_name']?.toString() ?? 'مدیر';
    final roles = m['roles'];
    final role = roles is List && roles.isNotEmpty
        ? roles.first.toString()
        : (m['role']?.toString() ?? '');

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0E1838),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMute, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 14),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text('نقش فعلی: ${_roleLabel(role)}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.manage_accounts_rounded, color: AppColors.purpleGlow),
              title: const Text('تغییر نقش', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'role'),
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_rounded, color: Color(0xFFF87171)),
              title: const Text('حذف از مدیران (تبدیل به مشتری)', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'demote'),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );

    if (action == null || !mounted) return;
    if (action == 'role') {
      await _changeRole(m);
    } else if (action == 'demote') {
      await _setRole(id, 'customer', removeFromList: true);
    }
  }

  Future<void> _changeRole(Map m) async {
    final id = m['id'];
    final roles = m['roles'];
    String role = roles is List && roles.isNotEmpty
        ? roles.first.toString()
        : (m['role']?.toString() ?? '');

    final ok = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0E1838),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 10),
            const Text('انتخاب نقش جدید', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            for (final r in ['administrator', 'shop_manager', 'editor'])
              ListTile(
                title: Text(_roleLabel(r), style: const TextStyle(color: Colors.white)),
                trailing: role == r ? const Icon(Icons.check, color: AppColors.purpleGlow) : null,
                onTap: () => Navigator.pop(ctx, r),
              ),
            const SizedBox(height: 12),
          ]),
        );
      },
    );
    if (ok == null || ok == role) return;
    await _setRole(id, ok);
  }

  Future<void> _setRole(dynamic id, String newRole, {bool removeFromList = false}) async {
    try {
      final res = await context.read<AuthService>().api.dio.post(
        'managers',
        data: {'id': id, 'role': newRole},
        options: Options(
          contentType: 'application/json',
          headers: {'Content-Type': 'application/json'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (res.statusCode == 403 || (res.data is Map && res.data['code'] == 'fy_forbidden')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('دسترسی کافی نیست — فقط مدیر کل می‌تواند نقش را تغییر دهد'),
            backgroundColor: Color(0xFF7F1D1D),
          ));
        }
        return;
      }
      if (res.statusCode != null && res.statusCode! >= 400) {
        final msg = res.data is Map ? (res.data['message'] ?? res.data['code'] ?? 'خطا') : 'خطا';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$msg'),
            backgroundColor: const Color(0xFF7F1D1D),
          ));
        }
        return;
      }

      setState(() {
        if (removeFromList || !['administrator', 'shop_manager', 'editor'].contains(newRole)) {
          items = items.where((e) => (e as Map)['id']?.toString() != id.toString()).toList();
        } else {
          items = items.map((e) {
            final mm = Map<String, dynamic>.from(e as Map);
            if (mm['id']?.toString() == id.toString()) {
              mm['role'] = newRole;
              mm['roles'] = [newRole];
            }
            return mm;
          }).toList();
        }
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(removeFromList ? 'از مدیران حذف شد' : 'نقش به ${_roleLabel(newRole)} تغییر کرد'),
          backgroundColor: const Color(0xFF065F46),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: const Color(0xFF7F1D1D),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'مدیریت مدیران',
          subtitle: 'تغییر نقش و حذف از مدیران',
          leadingIcon: Icons.admin_panel_settings_rounded,
          leadingColor: AppColors.purple,
          onRefresh: _load,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: TextField(
            controller: searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'جستجوی مدیر...',
              hintStyle: const TextStyle(color: AppColors.textDim),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMute),
              filled: true,
              fillColor: const Color(0xFF0B1230),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.purpleGlow),
                onPressed: _load,
              ),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                  : items.isEmpty
                      ? const Center(child: Text('مدیری یافت نشد', style: TextStyle(color: AppColors.textDim)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final m = Map<String, dynamic>.from(items[i] as Map);
                            final name = m['display_name']?.toString() ?? '';
                            final email = m['email']?.toString() ?? '';
                            final av = m['avatar']?.toString() ?? '';
                            final roles = m['roles'];
                            final role = roles is List && roles.isNotEmpty
                                ? roles.first.toString()
                                : (m['role']?.toString() ?? '');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: NeonCard(
                                onTap: () => _openActions(m),
                                child: Row(children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [Color(0xFF7047F5), Color(0xFF2868FF)]),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: av.startsWith('http')
                                        ? Image.network(av, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                                            Center(child: Text(name.isNotEmpty ? name[0] : 'م', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))))
                                        : Center(child: Text(name.isNotEmpty ? name[0] : 'م', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(email, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      const Text('برای تغییر نقش یا حذف ضربه بزنید', style: TextStyle(color: AppColors.textMute, fontSize: 10)),
                                    ]),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.purple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(_roleLabel(role), style: const TextStyle(color: AppColors.purpleGlow, fontSize: 11)),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
        ),
      ]),
    );
  }
}
