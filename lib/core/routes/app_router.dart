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
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/transaksi_pending_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/dashboard_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/admin_main_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/stok_history_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/pilih_transaksi_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/markdown_pricing_page.dart';

// ── Kasir Pages ────────────────────────────────────────────
import 'package:dannisa_sweet_pos/features/kasir/presentation/pages/kasir_home_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/dashboard_page.dart'; 

// ── Providers ──────────────────────────────────────────────
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/kategori_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/produk_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/user_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/transaksi_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/laporan_provider.dart';
import 'package:dannisa_sweet_pos/features/dashboard/presentation/providers/product_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/stok_history_provider.dart';

// ══════════════════════════════════════════════════════════
//  AppRouter
// ══════════════════════════════════════════════════════════
class AppRouter {
  static const String splash         = '/';
  static const String login          = '/login';
  static const String register       = '/register';

  // Admin routes
  static const String adminHome      = '/admin/home';
  static const String kelolaProduk   = '/admin/produk';
  static const String kelolaKategori = '/admin/kategori';
  static const String kelolaUser     = '/admin/user';
  static const String daftarProduk   = '/admin/daftar-produk';
  static const String inputTransaksi = '/admin/transaksi';
  static const String laporan        = '/admin/laporan';
  static const String transaksiPending = '/admin/transaksi-pending';
  static const String stokHistory   = '/stok-history';

  // Kasir routes
  static const String kasirHome      = '/kasir/home';
  static const String kasirDashboard = '/kasir/dashboard'; 

  // Legacy
  static const String dashboard      = '/dashboard';

  //markdown pricing
  static const String markdownPricing = '/admin/markdown-pricing';


  static Map<String, WidgetBuilder> get routes => {
        splash:         (_) => const SplashPage(),
        login:          (_) => const LoginPage(),
        register:       (_) => const RegisterPage(),

        // ── Admin ──────────────────────────────────────────
        adminHome:      (_) => const AdminMainPage(),
        dashboard:      (_) => const AdminHomePage(), // legacy
        kelolaProduk:   (_) => const KelolaProdukPage(),
        kelolaKategori: (_) => const KelolaKategoriPage(),
        kelolaUser:     (_) => const KelolaUserPage(),
        daftarProduk:   (_) => const DaftarProdukPage(),
        inputTransaksi: (_) => const PilihTransaksiPage(),
        laporan:        (_) => const LaporanTransaksiPage(),
        transaksiPending: (_) => const TransaksiPendingPage(),
        stokHistory:      (_) => const StokHistoryPage(),
        markdownPricing: (_) => const MarkdownPricingPage(),
        

        // ── Kasir ──────────────────────────────────────────
        kasirHome:      (_) => const KasirHomePage(),
        kasirDashboard: (_) => const DashboardPage(),
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => KategoriProvider()),
        ChangeNotifierProvider(create: (_) => ProdukProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TransaksiProvider()),
        ChangeNotifierProvider(create: (_) => LaporanProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => StokHistoryProvider()),
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
//  Masalah sebelumnya: hanya cek token (tidak tahu role)
//  Fix: pakai AuthProvider.checkAuthStatus() lalu cek role
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

    if (token == null || token.isEmpty) {
      // Belum login → ke halaman login
      Navigator.pushReplacementNamed(context, AppRouter.login);
      return;
    }

    // Sudah punya token → fetch profile untuk dapat data user + role
    final auth = context.read<AuthProvider>();
    await auth.checkAuthStatus();

    if (!mounted) return;

    if (auth.isAuthenticated && auth.user != null) {
      // Redirect berdasarkan role jabatan
      final role = auth.user!.jabatan.namaJabatan;
      if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, AppRouter.adminHome);
      } else {
        // Kasir atau role lain
        Navigator.pushReplacementNamed(context, AppRouter.kasirHome);
      }
    } else {
      // Token expired / invalid → ke login
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE91E8C), Color(0xFFC2185B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.cake_outlined,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // App name
              const Text(
                'Dannisa Sweet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Point of Sale',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),

              // Loading
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}