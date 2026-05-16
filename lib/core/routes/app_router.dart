import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/services/secure_storage.dart';
import 'package:dannisa_sweet_pos/core/theme/app_theme.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/pages/login_page.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/pages/register_page.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/admin_home_page.dart';
import 'package:dannisa_sweet_pos/features/dashboard/presentation/providers/product_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/kelola_produk_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/kategori_provider.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Admin routes
  static const String adminHome = '/admin/home';
  static const String kelolaProduk = '/admin/produk';
  static const String kelolaKategori = '/admin/kategori';
  static const String kelolaUser = '/admin/user';
  static const String daftarProduk = '/admin/daftar-produk';
  static const String inputTransaksi = '/admin/transaksi';
  static const String laporan = '/admin/laporan';

  // Kasir routes
  static const String kasirHome = '/kasir/home';

  // Legacy (tetap ada untuk backward compat)
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    adminHome: (_) => const AdminHomePage(),
    // Route lain akan ditambahkan step by step
    dashboard: (_) => const AdminHomePage(), // legacy redirect
    kelolaProduk: (_) => const KelolaProdukPage(),
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => KategoriProvider()),
      ],
      child: MaterialApp(
        title: 'Dannisa Sweet POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRouter.splash,
        routes: AppRouter.routes,
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final token = await SecureStorageService.getToken();
    final route = token != null ? AppRouter.adminHome : AppRouter.login;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront, size: 80, color: Color(0xFF1565C0)),
          const SizedBox(height: 16),
          const Text(
            'Dannisa Sweet POS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
