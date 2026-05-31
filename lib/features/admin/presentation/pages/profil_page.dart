import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/routes/app_router.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';

// ── Warna tema Dannisa Sweet ───────────────────────────────
const _primary = Color(0xFFE91E8C);
const _primaryDark = Color(0xFFC2185B);
const _surface = Color(0xFFFFF0F7);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);
const _success = Color(0xFF10B981);
const _danger = Color(0xFFEF4444);
const _info = Color(0xFF0EA5E9);

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final namaUser = user?.namaUser ?? '-';
    final email = user?.email ?? '-';
    final jabatan = user?.jabatan.namaJabatan ?? '-';
    final rekPembayaran = user?.rekPembayaran ?? '-';
    final whatsapp = user?.whatsapp ?? '-';

    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
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
                      right: -40, top: -40,
                      child: Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20, bottom: -20,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Avatar besar
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  namaUser.isNotEmpty
                                      ? namaUser[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              namaUser,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    jabatan,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
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

          // ── Body ──────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Info Akun ──────────────────────────
                    _SectionLabel(label: 'Informasi Akun'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.person_outline,
                            label: 'Nama Lengkap',
                            value: namaUser,
                            color: _primary,
                          ),
                          _Divider(),
                          _InfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: email,
                            color: _info,
                          ),
                          _Divider(),
                          _InfoTile(
                            icon: Icons.work_outline,
                            label: 'Jabatan',
                            value: jabatan,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Info Pembayaran ────────────────────
                    _SectionLabel(label: 'Info Pembayaran'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.account_balance_outlined,
                            label: 'Rekening Pembayaran',
                            value: rekPembayaran.isNotEmpty &&
                                    rekPembayaran != '-'
                                ? rekPembayaran
                                : 'Belum diisi',
                            color: _success,
                          ),
                          _Divider(),
                          _InfoTile(
                            icon: Icons.phone_outlined,
                            label: 'WhatsApp',
                            value: whatsapp.isNotEmpty && whatsapp != '-'
                                ? whatsapp
                                : 'Belum diisi',
                            color: const Color(0xFF25D366),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Toko ──────────────────────────────
                    _SectionLabel(label: 'Informasi Toko'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.store_outlined,
                            label: 'Nama Toko',
                            value: 'Dannisa Sweet',
                            color: _primary,
                          ),
                          _Divider(),
                          _InfoTile(
                            icon: Icons.cake_outlined,
                            label: 'Jenis Usaha',
                            value: 'Dessert & Kue',
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Tombol Logout ──────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmLogout(context, auth),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.logout_outlined, size: 20),
                        label: const Text(
                          'Keluar dari Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── App version ────────────────────────
                    Center(
                      child: Text(
                        'Dannisa Sweet POS v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Akun',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    await auth.logout();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }
}

// ── Section Label ──────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Info Tile ──────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: _textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Divider ────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }
}