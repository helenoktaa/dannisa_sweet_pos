import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/routes/app_router.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/transaksi_provider.dart';

// ── Pages yang dipakai kasir ───────────────────────────────
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/dashboard_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/daftar_produk_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/laporan_transaksi_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/transaksi_pending_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/pilih_transaksi_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/kelola_user_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/input_transaksi_page.dart';

// ── Warna tema ─────────────────────────────────────────────
const _primary = Color(0xFFE91E8C);
const _textSecondary = Color(0xFF6B7280);

// ── Menu key constants ─────────────────────────────────────
const _keyDashboard = 'dashboard';
const _keyTransaksi = 'transaksi';
const _keyProduk = 'produk';
const _keyLaporan = 'laporan';
const _keyKelolaUser = 'kelola_user';

// ── Definisi satu tab ──────────────────────────────────────
class _TabItem {
  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;

  const _TabItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}

// ── Semua tab yang mungkin muncul ──────────────────────────
final _allTabs = [
  _TabItem(
    key: _keyDashboard,
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    page: const _KasirDashboardWrapper(),
  ),
  _TabItem(
    key: _keyTransaksi,
    label: 'Transaksi',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_outlined,
    page: const InputTransaksiPage(),
  ),
  _TabItem(
    key: _keyProduk,
    label: 'Produk',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
    page: const DaftarProdukPage(),
  ),
  _TabItem(
    key: _keyLaporan,
    label: 'Laporan',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart,
    page: const LaporanTransaksiPage(),
  ),
  _TabItem(
    key: _keyKelolaUser,
    label: 'Kelola User',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    page: const KelolaUserPage(),
  ),
];

// ══════════════════════════════════════════════════════════
//  KasirHomePage
// ══════════════════════════════════════════════════════════
class KasirHomePage extends StatefulWidget {
  const KasirHomePage({super.key});

  @override
  State<KasirHomePage> createState() => _KasirHomePageState();
}

class _KasirHomePageState extends State<KasirHomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idUser = context.read<AuthProvider>().user?.idUser ?? '';
      context.read<TransaksiProvider>().setIdUser(idUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final menuKeys = auth.user?.menuKeys ?? [];

    // Filter tab berdasarkan menuKeys user
    final visibleTabs = _allTabs
        .where((t) => menuKeys.contains(t.key))
        .toList();

    // Fallback kalau tidak ada menu sama sekali
    if (visibleTabs.isEmpty) {
      return _NoMenuPage(onLogout: () => _logout(context, auth));
    }

    // Pastikan index tidak out of range setelah filter
    final safeIndex = _currentIndex.clamp(0, visibleTabs.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F7),
      body: IndexedStack(
        index: safeIndex,
        children: visibleTabs.map((t) => t.page).toList(),
      ),
      bottomNavigationBar: _buildBottomNav(visibleTabs, safeIndex),
    );
  }

  Widget _buildBottomNav(List<_TabItem> tabs, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab items
              ...tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final isActive = i == currentIndex;
                return _NavItem(
                  icon: isActive ? tab.activeIcon : tab.icon,
                  label: tab.label,
                  isActive: isActive,
                  onTap: () => setState(() => _currentIndex = i),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await auth.logout();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }
}

// ── Nav Item ───────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isLogout;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLogout
        ? Colors.redAccent
        : isActive
        ? _primary
        : _textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kasir Dashboard Wrapper ────────────────────────────────
// DashboardPage dibungkus agar card expired/stok menipis
// navigate ke DaftarProduk, bukan KelolaProduk
class _KasirDashboardWrapper extends StatelessWidget {
  const _KasirDashboardWrapper();

  @override
  Widget build(BuildContext context) {
    // DashboardPage sudah menerima parameter opsional isKasir
    // Lihat catatan di bawah — kita perlu modifikasi DashboardPage
    return const DashboardPage(isKasir: true);
  }
}

// ── No Menu Fallback ───────────────────────────────────────
class _NoMenuPage extends StatelessWidget {
  final VoidCallback onLogout;
  const _NoMenuPage({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: _primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum Ada Akses Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hubungi Admin untuk mendapatkan\nakses menu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: _textSecondary),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
