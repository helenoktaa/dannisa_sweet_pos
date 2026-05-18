import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/services/secure_storage.dart';
import 'package:dannisa_sweet_pos/core/theme/app_theme.dart';

// ── Auth ───────────────────────────────────────────────────
import 'package:dannisa_sweet_pos/features/auth/presentation/pages/login_page.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/pages/register_page.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';

// ── Admin Pages ────────────────────────────────────────────
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/admin_home_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/kelola_produk_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/kelola_kategori_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/kelola_user_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/daftar_produk_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/input_transaksi_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/laporan_transaksi_page.dart';

// ── Providers ──────────────────────────────────────────────
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/kategori_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/produk_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/user_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/transaksi_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/laporan_provider.dart';

// ── Legacy provider (jika masih dipakai di dashboard lama) ─
import 'package:dannisa_sweet_pos/features/dashboard/presentation/providers/product_provider.dart';

// ══════════════════════════════════════════════════════════
//  AppRouter
// ══════════════════════════════════════════════════════════
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

  // Legacy
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashPage(),
        login: (_) => const LoginPage(),
        register: (_) => const RegisterPage(),
        adminHome: (_) => const AdminHomePage(),
        dashboard: (_) => const AdminHomePage(), // legacy redirect

        // ── Kelola Data ──────────────────────────────────
        kelolaProduk: (_) => const KelolaProdukPage(),
        kelolaKategori: (_) => const KelolaKategoriPage(),
        kelolaUser: (_) => const KelolaUserPage(),       
        daftarProduk: (_) => const DaftarProdukPage(),   

        // ── Transaksi & Laporan ──────────────────────────
        inputTransaksi: (_) => const InputTransaksiPage(), 
        laporan: (_) => const LaporanTransaksiPage(),       
      };
}

// ══════════════════════════════════════════════════════════
//  MyApp
// ══════════════════════════════════════════════════════════
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Auth ────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // ── Legacy (jika masih dipakai) ─────────────────
        ChangeNotifierProvider(create: (_) => ProductProvider()),

        // ── Admin providers ──────────────────────────────
        ChangeNotifierProvider(create: (_) => KategoriProvider()),
        ChangeNotifierProvider(create: (_) => ProdukProvider()),   
        ChangeNotifierProvider(create: (_) => UserProvider()),     
        ChangeNotifierProvider(create: (_) => TransaksiProvider()), 
        ChangeNotifierProvider(create: (_) => LaporanProvider()),  
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

// ══════════════════════════════════════════════════════════
//  SplashPage
// ══════════════════════════════════════════════════════════
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
              // ── Logo ──────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E8C), Color(0xFFC2185B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E8C).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.cake_outlined,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // ── App name ──────────────────────────────
              const Text(
                'Dannisa Sweet',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE91E8C),
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Point of Sale',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              // ── Loading indicator ──────────────────────
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFE91E8C),
                ),
              ),
            ],
          ),
        ),
      );
}