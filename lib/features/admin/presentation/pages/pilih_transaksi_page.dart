import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/input_transaksi_page.dart';
// import 'package:dannisa_sweet_pos/features/admin/presentation/pages/input_preorder_page.dart';

const _primary = Color(0xFFE91E8C);
const _primaryDark = Color(0xFFC2185B);
const _surface = Color(0xFFFFF0F7);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);

class PilihTransaksiPage extends StatelessWidget {
  const PilihTransaksiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Input Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header dekoratif
          Container(
            color: _primary,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Jenis Transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih sesuai jenis produk yang akan dipesan',
                    style: TextStyle(fontSize: 13, color: _textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Dua pilihan
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Ready Stock
                  _TransaksiCard(
                    icon: Icons.storefront_outlined,
                    title: 'Ready Stock',
                    subtitle: 'Produk tersedia langsung',
                    color: _primary,
                    gradientColors: const [Color(0xFFE91E8C), Color(0xFFC2185B)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InputTransaksiPage(
                          jenisOrder: 'ready',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pre Order
                  _TransaksiCard(
                    icon: Icons.access_time_outlined,
                    title: 'Pre Order',
                    subtitle: 'Produk dibuat sesuai pesanan',
                    color: Colors.orange.shade600,
                    gradientColors: [Colors.orange.shade500, Colors.orange.shade700],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InputTransaksiPage(
                          jenisOrder: 'preorder',
                        ),
                      ),
                    ),
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

class _TransaksiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _TransaksiCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),

            // Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ),
          ],
        ),
      ),
    );
  }
}