import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/store_service.dart';
import 'core/services/orders_service.dart';
import 'core/services/products_service.dart';
import 'core/services/dashboard_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final auth = AuthService();
  await auth.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => StoreService()..loadStores()),
        ChangeNotifierProvider(create: (_) => OrdersService()),
        ChangeNotifierProvider(create: (_) => ProductsService()),
        ChangeNotifierProvider(create: (_) => DashboardService()),
      ],
      child: const ForoshgahYarApp(),
    ),
  );
}
