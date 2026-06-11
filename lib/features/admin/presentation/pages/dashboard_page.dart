import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/routes/app_router.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/dashboard_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/transaksi_provider.dart';

// ── Warna tema Dannisa Sweet ───────────────────────────────
const _primary = Color(0xFFE91E8C);
const _primaryDark = Color(0xFFC2185B);
const _surface = Color(0xFFFFF0F7);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);
const _success = Color(0xFF10B981);
const _danger = Color(0xFFEF4444);
const _warning = Color(0xFFF59E0B);
const _info = Color(0xFF0EA5E9);

class DashboardPage extends StatefulWidget {
  final bool isKasir;
  const DashboardPage({super.key, this.isKasir = false});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
      // Set idUser ke TransaksiProvider
      final idUser = context.read<AuthProvider>().user?.idUser ?? '';
      context.read<TransaksiProvider>().setIdUser(idUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final namaUser = auth.user?.namaUser ?? 'Admin';
    final jabatan = auth.user?.jabatan.namaJabatan ?? 'Admin';
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
      body: RefreshIndicator(
        color: _primary,
        onRefresh: () => context.read<DashboardProvider>().refresh(),
        child: CustomScrollView(
          slivers: [
            // ── App Bar / Header ───────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: _primary,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              automaticallyImplyLeading: false,
              actions: widget.isKasir
                  ? [
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
                          final auth = context.read<AuthProvider>();
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
                              content: const Text(
                                'Yakin ingin keluar dari aplikasi?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
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
                          Navigator.pushReplacementNamed(
                            context,
                            AppRouter.login,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                    ]
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primary, _primaryDark],
                    ),
                  ),
                  child: Stack(
                    children: [
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
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$greeting,',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.85,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          namaUser,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Avatar
                                  Container(
                                    width: 48,
                                    height: 48,
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
                                            : 'A',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Badge jabatan & toko
                              Row(
                                children: [
                                  _Badge(
                                    icon: Icons.admin_panel_settings_outlined,
                                    label: jabatan,
                                  ),
                                  const SizedBox(width: 8),
                                  const _Badge(
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
              ),
            ),

            // ── Body ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: _primary,
                child: Container(
                  decoration: const BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: switch (dashboard.status) {
                    DashboardStatus.loading ||
                    DashboardStatus.initial => const SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    ),
                    DashboardStatus.error => SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              size: 48,
                              color: _primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dashboard.error ?? 'Gagal memuat dashboard',
                              style: const TextStyle(color: _textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context
                                  .read<DashboardProvider>()
                                  .fetchDashboard(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DashboardStatus.loaded => _DashboardContent(
                      data: dashboard.data!,
                      harian: dashboard.harian!,
                      isKasir: widget.isKasir,
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Dashboard Content
// ══════════════════════════════════════════════════════════
// ── Dashboard Content ──────────────────────────────────────
class _DashboardContent extends StatelessWidget {
  final DashboardModel data;
  final DashboardHarianModel harian;
  final bool isKasir;
  const _DashboardContent({
    required this.data,
    required this.harian,
    this.isKasir = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Notif pending > 3 hari
          if (harian.totalPendingLewat3Hari > 0) ...[
            _NotifPendingBanner(total: harian.totalPendingLewat3Hari),
            const SizedBox(height: 16),
          ],

          // 2. Lunas hari ini
          if (!isKasir) ...[
            _LunasHariIniCard(total: harian.totalLunasHariIni),
            const SizedBox(height: 12),
          ],

          // 3. Keuntungan bersih
          if (!isKasir) ...[
            _KeuntunganCard(harian: harian),
            const SizedBox(height: 24),
          ],

          if (isKasir) const SizedBox(height: 8),
          
          // 4. Ringkasan hari ini
          const _SectionTitle(title: 'Ringkasan Hari Ini'),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Pending',
                value: '${data.totalPending}',
                icon: Icons.pending_actions_outlined,
                color: _warning,
                suffix: 'transaksi',
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.transaksiPending),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Mendekati Expired',
                value: '${data.totalMendekatiExpired}',
                icon: Icons.event_busy_outlined,
                color: _danger,
                suffix: 'produk',
                onTap: () => Navigator.pushNamed(
                  context,
                  isKasir ? AppRouter.daftarProduk : AppRouter.kelolaProduk,
                ), // ← pakai kelolaProduk
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Stok Menipis',
                value: '${data.totalStokMenipis}',
                icon: Icons.inventory_2_outlined,
                color: _info,
                suffix: 'produk',
                onTap: () => Navigator.pushNamed(
                  context,
                  isKasir ? AppRouter.daftarProduk : AppRouter.kelolaProduk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Transaksi terbaru (maks 3)
          if (harian.transaksiTerbaru.isNotEmpty) ...[
            _SectionTitle(
              title: 'Transaksi Terbaru',
              trailing: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.laporan),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(color: _primary, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...harian.transaksiTerbaru
                .take(3)
                .map((t) => _TransaksiTerbaruCard(transaksi: t)),
            const SizedBox(height: 24),
          ],

          // 6. Empty state
          if (data.totalPending == 0 &&
              data.totalMendekatiExpired == 0 &&
              data.totalStokMenipis == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: _success.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Semua berjalan lancar! 🎉',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tidak ada transaksi pending,\nproduk expired, atau stok menipis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Notif Banner ───────────────────────────────────────────
class _NotifPendingBanner extends StatelessWidget {
  final int total;
  const _NotifPendingBanner({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _danger.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: _danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: _textPrimary),
                children: [
                  TextSpan(
                    text: '$total transaksi pending ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _danger,
                    ),
                  ),
                  const TextSpan(
                    text: 'sudah lebih dari 3 hari. Segera konfirmasi!',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lunas Hari Ini Card ────────────────────────────────────
class _LunasHariIniCard extends StatelessWidget {
  final int total;
  const _LunasHariIniCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_success, Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _success.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaksi Lunas Hari Ini',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total transaksi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
    );
  }
}

// ── Keuntungan Card ────────────────────────────────────────
class _KeuntunganCard extends StatelessWidget {
  final DashboardHarianModel harian;
  const _KeuntunganCard({required this.harian});

  String _fmt(double v) {
    final str = v.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Keuntungan Bersih Hari Ini',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _fmt(harian.keuntunganBersih),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                label: 'Transaksi',
                value: '${harian.totalTransaksi}x',
                color: _info,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: 'Omzet',
                value: _fmt(harian.totalOmzet),
                color: _success,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: 'Modal',
                value: _fmt(harian.totalModal),
                color: _warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaksi Terbaru Card ─────────────────────────────────
class _TransaksiTerbaruCard extends StatelessWidget {
  final TransaksiTerbaruModel transaksi;
  const _TransaksiTerbaruCard({required this.transaksi});

  String _fmt(double v) {
    final str = v.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    final isLunas = transaksi.statusPembayaran == 'Lunas';
    final statusColor = isLunas ? _success : _warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                isLunas ? Icons.check_circle_outline : Icons.pending_outlined,
                color: statusColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaksi.namaCustomer,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 10,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      transaksi.tanggalTransaksi,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 10,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${transaksi.totalItem} item',
                      style: const TextStyle(
                        fontSize: 10,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(transaksi.jumlahBayar),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      transaksi.metodePembayaran,
                      style: const TextStyle(
                        fontSize: 9,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      transaksi.statusPembayaran,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Title ──────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String suffix;
  final VoidCallback? onTap; // ← tambah ini

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.suffix,
    this.onTap, // ← tambah ini
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        // ← wrap dengan ini
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                suffix,
                style: const TextStyle(fontSize: 10, color: _textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pending Card ───────────────────────────────────────────
class _PendingCard extends StatelessWidget {
  final TransaksiPendingModel transaksi;
  const _PendingCard({required this.transaksi});

  @override
  Widget build(BuildContext context) {
    final isLewat = transaksi.sudahLewat3Hari;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLewat ? _danger.withOpacity(0.4) : _warning.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLewat
                  ? _danger.withOpacity(0.1)
                  : _warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                isLewat ? Icons.warning_amber_outlined : Icons.pending_outlined,
                color: isLewat ? _danger : _warning,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaksi.namaCustomer,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  '${transaksi.idTransaksi} • ${transaksi.metodePembayaran}',
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLewat
                      ? _danger.withOpacity(0.1)
                      : _warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLewat
                      ? '${transaksi.hariMenunggu} hari ⚠️'
                      : '${transaksi.hariMenunggu} hari',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isLewat ? _danger : _warning,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaksi.tanggalTransaksi,
                style: const TextStyle(fontSize: 10, color: _textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Expired Card ───────────────────────────────────────────
class _ExpiredCard extends StatelessWidget {
  final ProdukExpiredModel produk;
  const _ExpiredCard({required this.produk});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _danger.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.event_busy_outlined, color: _danger, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produk.namaProduk,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  'Stok: ${produk.stok} • Expired: ${produk.expiredDate}',
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${produk.sisaHari} hari',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stok Card ──────────────────────────────────────────────
class _StokCard extends StatelessWidget {
  final ProdukStokModel produk;
  const _StokCard({required this.produk});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _info.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.inventory_2_outlined, color: _info, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produk.namaProduk,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  'Status: ${produk.statusProduk}',
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Stok ${produk.stok}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _info,
              ),
            ),
          ),
        ],
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
