import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/store_service.dart';
import '../../core/services/fcm_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _url = TextEditingController();
  final _token = TextEditingController();
  bool _hide = true;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilled) {
      _prefilled = true;
      _loadSaved();
    }
  }

  Future<void> _loadSaved() async {
    final auth = context.read<AuthService>();
    final url = await auth.getSavedSiteUrl();
    final token = await auth.getSavedToken();
    if (url != null) _url.text = url;
    if (token != null) _token.text = token;
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _url.text.trim();
    final token = _token.text.trim();
    if (url.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('آدرس سایت و توکن را وارد کنید')),
      );
      return;
    }
    final auth = context.read<AuthService>();
    final stores = context.read<StoreService>();
    final ok = await auth.connectWithToken(siteUrl: url, token: token);
    if (ok && mounted) {
      await stores.addStore(Store(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: auth.site?['name']?.toString() ?? 'فروشگاه',
        url: url,
        token: token,
      ));
      // ثبت توکن FCM برای پوش
      try {
        await FcmService().syncToken(auth);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 40, color: Color(0xFF6C63FF)),
                ),
                const SizedBox(height: 16),
                const Text('فروشگاه‌یار',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('مدیریت حرفه‌ای فروشگاه ووکامرس',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 36),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252640),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('آدرس سایت', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _url,
                        keyboardType: TextInputType.url,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: Colors.black, fontSize: 15),
                        enableInteractiveSelection: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFECECF3),
                          hintText: 'https://yoursite.com',
                          hintStyle: const TextStyle(color: Colors.black38),
                          prefixIcon: const Icon(Icons.language, color: Colors.black54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('توکن اتصال', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _token,
                        obscureText: _hide,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: Colors.black, fontSize: 15),
                        enableInteractiveSelection: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFECECF3),
                          hintText: 'توکن ذخیره می‌شود',
                          hintStyle: const TextStyle(color: Colors.black38),
                          prefixIcon: const Icon(Icons.vpn_key, color: Colors.black54),
                          suffixIcon: IconButton(
                            icon: Icon(_hide ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'توکن ذخیره می‌ماند — بعد از خروج دوباره وارد کردن لازم نیست',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(auth.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _connect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('ورود به فروشگاه',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
