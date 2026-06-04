import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/routes/app_router.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/transaksi_provider.dart';

// ── Warna tema Dannisa Sweet ───────────────────────────────
const _primary = Color(0xFFE91E8C);
const _primaryDark = Color(0xFFC2185B);
const _surface = Color(0xFFFFF0F7);
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);

// ── Menu key constants (sama dengan backend) ───────────────
const _keyDashboard = 'dashboard';
const _keyTransaksi = 'transaksi';
const _keyProduk = 'produk';
const _keyLaporan = 'laporan';
const _keyKelolaUser = 'kelola_user';

class KasirHomePage extends StatefulWidget {
  const KasirHomePage({super.key});

  @override
  State<KasirHomePage> createState() => _KasirHomePageState();
}

class _KasirHomePageState extends State<KasirHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idUser = context.read<AuthProvider>().user?.idUser ?? '';
      context.read<TransaksiProvider>().setIdUser(idUser);
    });
  }

  // Bangun daftar menu card berdasarkan menu_keys user
  List<Widget> _buildMenuCards(List<String> menuKeys, BuildContext context) {
    final List<Widget> cards = [];

    // ── Dashboard ──────────────────────────────────────────
    if (menuKeys.contains(_keyDashboard)) {
      cards.add(
        _MenuCard(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          description: 'Ringkasan stok & transaksi pending',
          color: const Color(0xFFE91E8C),
          onTap: () => Navigator.pushNamed(context, AppRouter.adminHome),
        ),
      );
    }

    // ── Transaksi ──────────────────────────────────────────
    if (menuKeys.contains(_keyTransaksi)) {
      if (cards.isNotEmpty) cards.add(const SizedBox(height: 12));
      cards.add(
        _MenuCard(
          icon: Icons.point_of_sale,
          label: 'Input Transaksi',
          description: 'Catat penjualan baru',
          color: const Color(0xFF10B981),
          onTap: () => Navigator.pushNamed(context, AppRouter.inputTransaksi),
        ),
      );
      cards.add(const SizedBox(height: 12));
      cards.add(
        _MenuCard(
          icon: Icons.pending_actions_outlined,
          label: 'Transaksi Pending',
          description: 'Follow up pembayaran customer',
          color: const Color(0xFFF59E0B),
          onTap: () => Navigator.pushNamed(context, AppRouter.transaksiPending),
        ),
      );
    }

    // ── Produk ─────────────────────────────────────────────
    if (menuKeys.contains(_keyProduk)) {
      if (cards.isNotEmpty) cards.add(const SizedBox(height: 12));
      cards.add(
        _MenuCard(
          icon: Icons.inventory_2_outlined,
          label: 'Daftar Produk',
          description: 'Lihat katalog produk & stok',
          color: const Color(0xFF0EA5E9),
          onTap: () => Navigator.pushNamed(context, AppRouter.daftarProduk),
        ),
      );
    }

    // ── Laporan ────────────────────────────────────────────
    if (menuKeys.contains(_keyLaporan)) {
      if (cards.isNotEmpty) cards.add(const SizedBox(height: 12));
      cards.add(
        _MenuCard(
          icon: Icons.bar_chart_outlined,
          label: 'Laporan',
          description: 'Lihat laporan transaksi',
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.pushNamed(context, AppRouter.laporan),
        ),
      );
    }

    // ── Kelola User ────────────────────────────────────────
    if (menuKeys.contains(_keyKelolaUser)) {
      if (cards.isNotEmpty) cards.add(const SizedBox(height: 12));
      cards.add(
        _MenuCard(
          icon: Icons.people_outline,
          label: 'Kelola User',
          description: 'Manajemen akun pengguna',
          color: const Color(0xFFEC4899),
          onTap: () => Navigator.pushNamed(context, AppRouter.kelolaUser),
        ),
      );
    }

    // Fallback kalau menu_keys kosong
    if (cards.isEmpty) {
      cards.add(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'Belum ada menu yang diberikan.\nHubungi Admin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final namaUser = auth.user?.namaUser ?? 'Kasir';
    final menuKeys = auth.user?.menuKeys ?? [];
    final now = DateTime.now();
    final greeting = now.hour < 11
        ? 'Selamat Pagi'
        : now.hour < 15
        ? 'Selamat Siang'
        : now.hour < 18
        ? 'Selamat Sore'
        : 'Selamat Malam';

    return Scaffold(
      backgroundColor: _surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text('Yakin ingin keluar dari aplikasi?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: _textSecondary),
                      ),
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
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Header ────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _primaryDark],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Dekorasi
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    top: 40,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),

                  // Konten
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$greeting,',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      namaUser,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Avatar
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    namaUser.isNotEmpty
                                        ? namaUser[0].toUpperCase()
                                        : 'K',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Badge jabatan & toko
                          Row(
                            children: [
                              _Badge(
                                icon: Icons.point_of_sale_outlined,
                                label:
                                    auth.user?.jabatan.namaJabatan ?? 'Kasir',
                              ),
                              const SizedBox(width: 8),
                              _Badge(
                                icon: Icons.store_outlined,
                                label: 'Dannisa Sweet',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: _primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Menu Cards dinamis ──────────────────────
                  ..._buildMenuCards(menuKeys, context),

                  const SizedBox(height: 32),

                  // ── Info toko ───────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cake,
                            color: _primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dannisa Sweet',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _primary,
                              ),
                            ),
                            Text(
                              'Sistem POS — Dessert & Kue',
                              style: TextStyle(
                                fontSize: 12,
                                color: _primary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge ──────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu Card ──────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios, color: color, size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
