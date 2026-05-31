import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dannisa_sweet_pos/core/routes/app_router.dart';

// ── Warna tema Dannisa Sweet ───────────────────────────────
const _primary = Color(0xFFE91E8C);
const _primaryDark = Color(0xFFC2185B);
const _surface = Color(0xFFFFF0F7);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);

class KelolaTabPage extends StatelessWidget {
  const KelolaTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primary,
            automaticallyImplyLeading: false,
            systemOverlayStyle: SystemUiOverlayStyle.light,
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
                      right: -30, top: -20,
                      child: Container(
                        width: 150, height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20, bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Kelola Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Kelola produk, kategori & user',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Container(
          color: _primary,
          child: Container(
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                // ── Grid menu 2 kolom ──────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _GridCard(
                      icon: Icons.cake_outlined,
                      label: 'Kelola Produk',
                      description: 'Tambah, edit, hapus produk',
                      color: _primary,
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.kelolaProduk),
                    ),
                    _GridCard(
                      icon: Icons.category_outlined,
                      label: 'Kelola Kategori',
                      description: 'Atur kategori produk',
                      color: const Color(0xFF0EA5E9),
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.kelolaKategori),
                    ),
                    _GridCard(
                      icon: Icons.people_outline,
                      label: 'Kelola User',
                      description: 'Manajemen akun admin & kasir',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.kelolaUser),
                    ),
                    _GridCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Daftar Produk',
                      description: 'Lihat katalog produk & stok',
                      color: const Color(0xFF06B6D4),
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.daftarProduk),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Stok History ───────────────────────────
                _MenuCard(
                  icon: Icons.history_outlined,
                  label: 'Riwayat Stok',
                  description: 'History penambahan & pengurangan stok',
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.pushNamed(
                      context, AppRouter.stokHistory),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Grid Card ──────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _GridCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                    fontSize: 10, color: _textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu Card (full width) ─────────────────────────────────
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
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                    const SizedBox(height: 3),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 12, color: _textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios,
                    color: color, size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}