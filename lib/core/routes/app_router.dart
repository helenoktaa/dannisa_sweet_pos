import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/services/secure_storage.dart';
import 'package:dannisa_sweet_pos/core/theme/app_theme.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/pages/login_page.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/pages/register_page.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';
import 'package:dannisa_sweet_pos/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dannisa_sweet_pos/features/dashboard/presentation/providers/product_provider.dart';

class AppRouter {
  static const String splash   = '/';
  static const String login    = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';

  // verifyEmail dihapus — tidak pakai Firebase lagi

  static Map<String, WidgetBuilder> get routes => {
    splash:    (_) => const SplashPage(),
    login:     (_) => const LoginPage(),
    register:  (_) => const RegisterPage(),
    dashboard: (_) => const AuthGuard(child: DashboardPage()),
  };
}

// AuthGuard: cek status auth sebelum masuk halaman
class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.authenticated => child,      // Lanjut ke halaman
      _ => const LoginPage(),                 // Redirect login
    };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
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

// SplashPage: cek token tersimpan, redirect otomatis
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
    final route = token != null ? AppRouter.dashboard : AppRouter.login;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo atau nama app
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