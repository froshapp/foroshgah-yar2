import 'package:flutter/material.dart';
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

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final q = searchCtrl.text.trim();
      final res = await context.read<AuthService>().api.dio.get('managers', queryParameters: {
        if (q.isNotEmpty) 'search': q,
      });
      if (res.data is Map && res.data['managers'] is List) {
        items = res.data['managers'] as List;
      } else {
        items = [];
      }
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'administrator': return 'مدیر کل';
      case 'shop_manager': return 'مدیر فروشگاه';
      case 'editor': return 'ویرایشگر';
      case 'author': return 'نویسنده';
      case 'customer': return 'مشتری';
      default: return role;
    }
  }

  Future<void> _changeRole(Map m) async {
    final id = int.tryParse('${m['id']}') ?? 0;
    if (id == 0) return;
    String role = (m['role'] ?? m['roles'] is List && (m['roles'] as List).isNotEmpty
            ? (m['roles'] as List).first
            : 'shop_manager')
        .toString();
    final ok = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('تغییر نقش', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final r in ['administrator', 'shop_manager', 'editor', 'customer'])
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
    try {
      await context.read<AuthService>().api.dio.post('managers', data: {'id': id, 'role': ok});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('نقش به‌روز شد'),
          backgroundColor: Color(0xFF065F46),
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
          title: 'مدیران و دسترسی',
          subtitle: 'نقش‌های مدیریت فروشگاه',
          leadingIcon: Icons.admin_panel_settings_rounded,
          leadingColor: AppColors.purple,
          showSettingsGear: false,
          onRefresh: _load,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: TextField(
            controller: searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'جستجوی کاربر برای ارتقا به مدیر...',
              hintStyle: const TextStyle(color: AppColors.textMute, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMute),
              filled: true,
              fillColor: const Color(0xFF0B1230),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.purpleGlow), onPressed: _load),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final m = Map<String, dynamic>.from(items[i] as Map);
                          final name = m['display_name']?.toString() ?? '—';
                          final email = m['email']?.toString() ?? '';
                          final roles = m['roles'];
                          final role = roles is List && roles.isNotEmpty
                              ? roles.first.toString()
                              : (m['role']?.toString() ?? '');
                          final av = m['avatar']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NeonCard(
                              onTap: () => _changeRole(m),
                              child: Row(children: [
                                Container(
                                  width: 48, height: 48,
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
        ),
      ]),
    );
  }
}
