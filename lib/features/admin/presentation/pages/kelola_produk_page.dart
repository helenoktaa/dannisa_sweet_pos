import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/features/admin/data/models/produk_model.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/produk_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/kategori_provider.dart';

// ── Warna tema Dannisa Sweet ───────────────────────────────
const _primary = Color(0xFFE91E8C);
const _primaryDark = Color(0xFFC2185B);
const _accent = Color(0xFFFF6B9D);
const _surface = Color(0xFFFFF0F7);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFEF4444);

class KelolaProdukPage extends StatefulWidget {
  const KelolaProdukPage({super.key});

  @override
  State<KelolaProdukPage> createState() => _KelolaProdukPageState();
}

class _KelolaProdukPageState extends State<KelolaProdukPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterKategori = 'Semua';
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdukProvider>().fetchProduks();
      context.read<KategoriProvider>().fetchKategoris();
    });
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  List<ProdukModel> _getFiltered(List<ProdukModel> products) {
    return products.where((p) {
      final matchSearch = p.namaProduk.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchKategori =
          _filterKategori == 'Semua' ||
          (p.kategori?.namaKategori == _filterKategori);
      return matchSearch && matchKategori;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProdukProvider>();
    final kategoriProvider = context.watch<KategoriProvider>();
    final filtered = _getFiltered(provider.produks);

    // Daftar kategori untuk filter chip
    final kategoriList = [
      'Semua',
      ...kategoriProvider.kategoris.map((k) => k.namaKategori),
    ];

    // Summary stats
    final totalProduk = provider.produks.length;
    final stokHabis = provider.produks.where((p) => p.stok == 0).length;
    final stokMenipis = provider.produks
        .where((p) => p.stok > 0 && p.stok <= 5)
        .length;

    return Scaffold(
      backgroundColor: _surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── App Bar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primary,
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
                    // Dekorasi lingkaran latar
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      top: 30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Teks header
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Kelola Produk',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '$totalProduk produk terdaftar',
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
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                tooltip: 'Tambah Produk',
                onPressed: () => _showFormDialog(context),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Summary Cards ──────────────────────────────────
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Total Produk',
                      value: '$totalProduk',
                      icon: Icons.inventory_2_outlined,
                      color: _primary,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Stok Menipis',
                      value: '$stokMenipis',
                      icon: Icons.warning_amber_outlined,
                      color: _warning,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Stok Habis',
                      value: '$stokHabis',
                      icon: Icons.remove_shopping_cart_outlined,
                      color: _danger,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search Bar ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari nama produk...',
                    hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: _primary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: _textSecondary,
                            ),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // ── Filter Chips Kategori ──────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kategoriList.length,
                itemBuilder: (context, i) {
                  final k = kategoriList[i];
                  final isSelected = _filterKategori == k;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filterKategori = k),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? _primary : _cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? _primary : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          k,
                          style: TextStyle(
                            color: isSelected ? Colors.white : _textSecondary,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],

        // ── List Produk ──────────────────────────────────────
        body: switch (provider.status) {
          ProdukStatus.loading || ProdukStatus.initial => const Center(
            child: CircularProgressIndicator(color: _primary),
          ),
          ProdukStatus.error => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 56, color: _primary),
                const SizedBox(height: 12),
                Text(
                  provider.error ?? 'Terjadi kesalahan',
                  style: const TextStyle(color: _textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.fetchProduks(),
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
          ProdukStatus.loaded =>
            filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Produk "$_searchQuery" tidak ditemukan'
                              : 'Belum ada produk',
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showFormDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Produk Pertama'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      return _ProdukCard(
                        produk: filtered[i],
                        index: i,
                        onEdit: () =>
                            _showFormDialog(context, produk: filtered[i]),
                        onDelete: () => _confirmDelete(context, filtered[i]),
                      );
                    },
                  ),
        },
      ),

      // ── FAB Tambah Produk ────────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () => _showFormDialog(context),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.add),
          label: const Text(
            'Tambah Produk',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showFormDialog(BuildContext context, {ProdukModel? produk}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProdukFormSheet(produk: produk),
    );
  }

  void _confirmDelete(BuildContext context, ProdukModel produk) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: _danger),
            SizedBox(width: 8),
            Text(
              'Hapus Produk',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, color: _danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      produk.namaProduk,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Produk yang dihapus tidak dapat dikembalikan.',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<ProdukProvider>().deleteProduk(
                produk.idProduk,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? '${produk.namaProduk} berhasil dihapus'
                        : 'Gagal menghapus produk',
                  ),
                  backgroundColor: ok ? _success : _danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Produk Card ────────────────────────────────────────────
class _ProdukCard extends StatelessWidget {
  final ProdukModel produk;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProdukCard({
    required this.produk,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _stokColor {
    if (produk.stok == 0) return _danger;
    if (produk.stok <= 5) return _warning;
    return _success;
  }

  String get _stokLabel {
    if (produk.stok == 0) return 'Habis';
    if (produk.stok <= 5) return 'Menipis';
    return 'Tersedia';
  }

  bool get _isExpired {
    if (produk.expiredDate == null) {
      return false;
    }

    return produk.expiredDate!.isBefore(DateTime.now());
  }

  bool get _isExpiringSoon {
    if (produk.expiredDate == null) {
      return false;
    }

    final diff = produk.expiredDate!.difference(DateTime.now()).inDays;

    return diff <= 7 && diff >= 0;
  }

  String get _expiredLabel {
    if (produk.expiredDate == null) {
      return "-";
    }

    if (_isExpired) {
      return "Expired";
    }

    if (_isExpiringSoon) {
      return "Mendekati expired";
    }

    final d = produk.expiredDate!;

    return "${d.day}/${d.month}/${d.year}";
  }

  double get _laba => produk.hargaJual - produk.hargaModal;
  double get _marginPersen =>
      produk.hargaModal > 0 ? (_laba / produk.hargaModal) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
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
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar produk
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primary.withOpacity(0.8),
                        _accent.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      produk.namaProduk.isNotEmpty
                          ? produk.namaProduk[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info utama
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              produk.namaProduk,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge stok
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _stokColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _stokColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: _stokColor, size: 7),
                                const SizedBox(width: 4),
                                Text(
                                  _stokLabel,
                                  style: TextStyle(
                                    color: _stokColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,

                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),

                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),

                              borderRadius: BorderRadius.circular(6),
                            ),

                            child: Text(
                              produk.kategori?.namaKategori ?? "-",

                              style: const TextStyle(
                                fontSize: 11,
                                color: _primary,
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),

                            decoration: BoxDecoration(
                              color: produk.statusProduk == "preorder"
                                  ? Colors.orange.withOpacity(0.12)
                                  : Colors.green.withOpacity(0.12),

                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Text(
                              produk.statusProduk == "preorder"
                                  ? "Pre Order"
                                  : "Ready Stock",

                              style: TextStyle(
                                fontSize: 11,

                                color: produk.statusProduk == "preorder"
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ),

                          Text(
                            "ID: ${produk.idProduk}",
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (produk.statusProduk != "preorder")
                        Padding(
                          padding: const EdgeInsets.only(top: 6),

                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,

                                color: _isExpired ? Colors.red : Colors.orange,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                _expiredLabel,

                                style: TextStyle(
                                  fontSize: 11,

                                  color: _isExpired
                                      ? Colors.red
                                      : Colors.orange,
                                ),
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

          // Divider
          Divider(height: 1, color: Colors.grey.shade100),

          // Info harga & stok
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _InfoItem(
                  label: 'Harga Jual',
                  value: 'Rp ${_formatRupiah(produk.hargaJual)}',
                  valueColor: _primary,
                ),
                _dividerV(),
                _InfoItem(
                  label: 'Modal',
                  value: 'Rp ${_formatRupiah(produk.hargaModal)}',
                  valueColor: _textPrimary,
                ),
                _dividerV(),
                _InfoItem(
                  label: 'Laba',
                  value:
                      'Rp ${_formatRupiah(_laba)} (${_marginPersen.toStringAsFixed(0)}%)',
                  valueColor: _success,
                ),
                _dividerV(),
                _InfoItem(
                  label: 'Stok',
                  value: produk.statusProduk == "preorder"
                      ? "By Order"
                      : "${produk.stok}",
                  valueColor: _stokColor,
                ),
              ],
            ),
          ),

          // Action buttons
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.orange,
                    ),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: _danger,
                    ),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(
                        color: _danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerV() => Container(
    width: 1,
    height: 28,
    color: Colors.grey.shade200,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );

  String _formatRupiah(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}jt';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}rb';
    return val.toStringAsFixed(0);
  }
}

// ── Info Item kecil ────────────────────────────────────────
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet Form Tambah/Edit ──────────────────────────
class _ProdukFormSheet extends StatefulWidget {
  final ProdukModel? produk;
  const _ProdukFormSheet({this.produk});

  @override
  State<_ProdukFormSheet> createState() => _ProdukFormSheetState();
}

class _ProdukFormSheetState extends State<_ProdukFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _hargaModalCtrl;
  late final TextEditingController _hargaJualCtrl;
  late final TextEditingController _stokCtrl;
  String? _selectedKategoriId;
  bool _isLoading = false;
  late final TextEditingController _expiredCtrl;

  String _statusProduk = "ready";

  bool get _isEdit => widget.produk != null;

  // Kalkulasi laba preview
  double get _labaPreview {
    final modal = double.tryParse(_hargaModalCtrl.text) ?? 0;
    final jual = double.tryParse(_hargaJualCtrl.text) ?? 0;
    return jual - modal;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _idCtrl = TextEditingController(text: p?.idProduk ?? '');
    _namaCtrl = TextEditingController(text: p?.namaProduk ?? '');
    _hargaModalCtrl = TextEditingController(
      text: p?.hargaModal.toStringAsFixed(0) ?? '',
    );
    _hargaJualCtrl = TextEditingController(
      text: p?.hargaJual.toStringAsFixed(0) ?? '',
    );
    _stokCtrl = TextEditingController(text: p?.stok.toString() ?? '');
    _selectedKategoriId = p?.idKategori;
    _statusProduk = p?.statusProduk ?? "ready";

    _expiredCtrl = TextEditingController(
      text: p?.expiredDate != null
          ? p!.expiredDate!.toIso8601String().split("T")[0]
          : "",
    );

    // Rebuild saat harga berubah untuk preview laba
    _hargaModalCtrl.addListener(() => setState(() {}));
    _hargaJualCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _namaCtrl.dispose();
    _hargaModalCtrl.dispose();
    _hargaJualCtrl.dispose();
    _stokCtrl.dispose();
    _expiredCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori terlebih dahulu'),
          backgroundColor: _warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<ProdukProvider>();

    bool ok;
    if (_isEdit) {
      ok = await provider.updateProduk(
        idProduk: _idCtrl.text.trim(),
        namaProduk: _namaCtrl.text.trim(),
        hargaModal: double.parse(_hargaModalCtrl.text),
        hargaJual: double.parse(_hargaJualCtrl.text),
        stok: _statusProduk == "preorder" ? 0 : int.parse(_stokCtrl.text),
        idKategori: _selectedKategoriId!,
        statusProduk: _statusProduk,

        expiredDate: _expiredCtrl.text.isEmpty ? null : _expiredCtrl.text,
      );
    } else {
      ok = await provider.createProduk(
        idProduk: _idCtrl.text.trim(),
        namaProduk: _namaCtrl.text.trim(),
        hargaModal: double.parse(_hargaModalCtrl.text),
        hargaJual: double.parse(_hargaJualCtrl.text),
        stok: _statusProduk == "preorder" ? 0 : int.parse(_stokCtrl.text),
        idKategori: _selectedKategoriId!,
        statusProduk: _statusProduk,

        expiredDate: _expiredCtrl.text.isEmpty ? null : _expiredCtrl.text,
      );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? _isEdit
                    ? 'Produk berhasil diupdate ✓'
                    : 'Produk berhasil ditambahkan ✓'
              : _isEdit
              ? 'Gagal update produk'
              : 'Gagal tambah produk',
        ),
        backgroundColor: ok ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kategoris = context.watch<KategoriProvider>().kategoris;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                    color: _primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form
            Flexible(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ID & Nama
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _FormField(
                            controller: _idCtrl,
                            label: 'ID Produk',
                            hint: 'DS031',
                            enabled: !_isEdit,
                            prefixIcon: Icons.tag,
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: _FormField(
                            controller: _namaCtrl,
                            label: 'Nama Produk',
                            hint: 'Bolen Pisang Coklat',
                            prefixIcon: Icons.cake_outlined,
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Harga Modal & Jual
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            controller: _hargaModalCtrl,
                            label: 'Harga Modal',
                            hint: '13000',
                            prefixIcon: Icons.money_off_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FormField(
                            controller: _hargaJualCtrl,
                            label: 'Harga Jual',
                            hint: '20000',
                            prefixIcon: Icons.sell_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            // Harga Jual validator
                            validator: (v) {
                              if (v?.isEmpty ?? true)
                                return 'Harga jual wajib diisi';
                              final hargaJual = double.tryParse(v!) ?? 0;
                              if (hargaJual <= 0)
                                return 'Harga jual harus lebih dari 0';
                              final hargaModal =
                                  double.tryParse(_hargaModalCtrl.text) ?? 0;
                              if (hargaJual < hargaModal) {
                                return 'Harga jual tidak boleh kurang dari modal';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Preview laba
                    if (_hargaModalCtrl.text.isNotEmpty &&
                        _hargaJualCtrl.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _labaPreview >= 0
                              ? _success.withOpacity(0.08)
                              : _danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _labaPreview >= 0
                                ? _success.withOpacity(0.3)
                                : _danger.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _labaPreview >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 16,
                              color: _labaPreview >= 0 ? _success : _danger,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Estimasi Laba: Rp ${_labaPreview.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _labaPreview >= 0 ? _success : _danger,
                              ),
                            ),
                            if (_labaPreview < 0)
                              const Flexible(
                                child: Text(
                                  ' ⚠️ Harga jual tidak boleh kurang dari modal!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _danger,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Stok & Kategori
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _FormField(
                            controller: _stokCtrl,
                            enabled: _statusProduk == "ready",
                            label: 'Stok',
                            hint: '0',
                            prefixIcon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            value: _selectedKategoriId,
                            decoration: InputDecoration(
                              labelText: 'Kategori',
                              prefixIcon: const Icon(
                                Icons.category_outlined,
                                color: _primary,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: kategoris
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k.idKategori,
                                    child: Text(
                                      k.namaKategori,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedKategoriId = v),
                            validator: (v) =>
                                v == null ? 'Pilih kategori' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _statusProduk,

                            decoration: InputDecoration(
                              labelText: "Status",

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),

                            items: const [
                              DropdownMenuItem(
                                value: "ready",
                                child: Text("Ready Stock"),
                              ),

                              DropdownMenuItem(
                                value: "preorder",
                                child: Text("Pre Order"),
                              ),
                            ],

                            onChanged: (v) {
                              setState(() {
                                _statusProduk = v!;

                                if (_statusProduk == "preorder") {
                                  _expiredCtrl.clear();
                                  _stokCtrl.text = "0";
                                }
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: TextFormField(
                            controller: _expiredCtrl,

                            enabled: _statusProduk == "ready",

                            readOnly: true,

                            decoration: InputDecoration(
                              labelText: "Expired Date",

                              prefixIcon: const Icon(Icons.calendar_today),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),

                            onTap: () async {
                              if (_statusProduk == "preorder") return;

                              final picked = await showDatePicker(
                                context: context,

                                initialDate: DateTime.now(),

                                firstDate: DateTime.now(),

                                lastDate: DateTime(2035),
                              );

                              if (picked != null) {
                                _expiredCtrl.text = picked
                                    .toIso8601String()
                                    .split("T")[0];
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // Tombol submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading || _labaPreview < 0
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

// ── Reusable Form Field ────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: _primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        labelStyle: const TextStyle(fontSize: 13),
      ),
    );
  }
}
