import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/routes/app_router.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dannisa Sweet POS', style: TextStyle(fontSize: 16)),
            Text(
              'Halo, ${auth.user?.namaUser ?? 'Admin'}!',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, AppRouter.login);
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 28,
                    child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.namaUser ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        auth.user?.jabatan.namaJabatan ?? 'Admin',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu Transaksi
            const Text(
              'Transaksi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MenuCard(
                    icon: Icons.point_of_sale,
                    label: 'Input Transaksi',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, AppRouter.inputTransaksi),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MenuCard(
                    icon: Icons.bar_chart,
                    label: 'Laporan',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, AppRouter.laporan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Menu Produk
            const Text(
              'Kelola Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MenuCard(
                    icon: Icons.cake_outlined,
                    label: 'Kelola Produk',
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(context, AppRouter.kelolaProduk),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MenuCard(
                    icon: Icons.category_outlined,
                    label: 'Kelola Kategori',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, AppRouter.kelolaKategori),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MenuCard(
                    icon: Icons.people_outline,
                    label: 'Kelola User',
                    color: Colors.indigo,
                    onTap: () => Navigator.pushNamed(context, AppRouter.kelolaUser),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MenuCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Daftar Produk',
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, AppRouter.daftarProduk),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}