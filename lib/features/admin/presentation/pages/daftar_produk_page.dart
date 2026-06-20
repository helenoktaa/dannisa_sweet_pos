import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/produk_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/kategori_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/data/models/produk_model.dart';

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

class DaftarProdukPage extends StatefulWidget {
  const DaftarProdukPage({super.key});

  @override
  State<DaftarProdukPage> createState() => _DaftarProdukPageState();
}

class _DaftarProdukPageState extends State<DaftarProdukPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterKategoriId = 'Semua';
  bool _isGridView = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdukProvider>().fetchProduks();
      context.read<KategoriProvider>().fetchKategoris();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produkProvider = context.watch<ProdukProvider>();
    final kategoriProvider = context.watch<KategoriProvider>();

    final filtered = produkProvider.produks.where((p) {
      final matchSearch = p.namaProduk.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchKategori =
          _filterKategoriId == 'Semua' || p.idKategori == _filterKategoriId;
      return matchSearch && matchKategori;
    }).toList();

    final stokHabis = produkProvider.produks.where((p) => p.stok == 0).length;
    final stokMenipis = produkProvider.produks
        .where((p) => p.stok > 0 && p.stok <= 5)
        .length;

    return Scaffold(
      backgroundColor: _surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── App Bar ─────────────────────────────────────────
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
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Daftar Produk',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${produkProvider.produks.length} produk tersedia',
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
              // Toggle grid/list view
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list_outlined : Icons.grid_view,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Stats & Search ───────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    // Stats
                    Row(
                      children: [
                        _StatCard(
                          label: 'Total Produk',
                          value: '${produkProvider.produks.length}',
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
                    const SizedBox(height: 12),

                    // Search bar
                    Container(
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
                          hintText: 'Cari produk...',
                          hintStyle: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
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
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Kategori
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('Semua', 'Semua'),
                          ...kategoriProvider.kategoris.map(
                            (k) =>
                                _buildFilterChip(k.idKategori, k.namaKategori),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
        ],

        // ── Body ─────────────────────────────────────────────
        body: switch (produkProvider.status) {
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
                  produkProvider.error ?? 'Terjadi kesalahan',
                  style: const TextStyle(color: _textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => produkProvider.fetchProduks(),
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
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Produk "$_searchQuery" tidak ditemukan'
                              : 'Belum ada produk',
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : _isGridView
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.64,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _ProdukGridCard(produk: filtered[i], index: i),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _ProdukListCard(produk: filtered[i], index: i),
                  ),
        },
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isActive = _filterKategoriId == id;
    return GestureDetector(
      onTap: () => setState(() => _filterKategoriId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _primary : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _primary : Colors.grey.shade300),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : _textSecondary,
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    style: const TextStyle(fontSize: 10, color: _textSecondary),
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

// ── Helper: format harga ───────────────────────────────────
String _formatRupiah(double amount) {
  final str = amount.toStringAsFixed(0);
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
    count++;
  }
  return 'Rp ${buffer.toString().split('').reversed.join()}';
}

// ── Stok badge helper ──────────────────────────────────────
Color _stokColor(int stok) {
  if (stok == 0) return _danger;
  if (stok <= 5) return _warning;
  return _success;
}

String _stokLabel(int stok) {
  if (stok == 0) return 'Habis';
  if (stok <= 5) return 'Menipis';
  return 'Tersedia';
}

bool _isExpired(DateTime? exp) {
  if (exp == null) return false;

  return exp.isBefore(DateTime.now());
}

bool _isExpiringSoon(DateTime? exp) {
  if (exp == null) return false;

  final days = exp.difference(DateTime.now()).inDays;

  return days <= 7 && days >= 0;
}

String _expiredLabel(DateTime? exp) {
  if (exp == null) {
    return "-";
  }

  if (_isExpired(exp)) {
    return "Expired";
  }

  if (_isExpiringSoon(exp)) {
    return "Mendekati expired";
  }

  return "${exp.day}/${exp.month}/${exp.year}";
}

// ── Produk Grid Card ───────────────────────────────────────
class _ProdukGridCard extends StatelessWidget {
  final ProdukModel produk;
  final int index;

  const _ProdukGridCard({required this.produk, required this.index});

  Color get _accentColor {
    final colors = [
      _primary,
      const Color(0xFF0EA5E9),
      const Color(0xFF8B5CF6),
      _success,
      _warning,
      const Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final stokColor = produk.statusProduk == "preorder"
        ? Colors.orange
        : _stokColor(produk.stok);

    final stokLabel = produk.statusProduk == "preorder"
        ? "Pre Order"
        : _stokLabel(produk.stok);

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image placeholder / icon ──────────────────────
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor, _accentColor.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cake_outlined,
                        color: Colors.white,
                        size: 36,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        produk.namaKategori ?? '',

                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stok badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: stokColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stokLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Diskon badge di pojok kiri atas
                if (produk.adaDiskon)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'DISKON',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Info ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produk.namaProduk,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: _textPrimary,
                    ),

                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  Wrap(
                    spacing: 4,
                    runSpacing: 3,

                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),

                        decoration: BoxDecoration(
                          color: produk.statusProduk == "preorder"
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),

                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Text(
                          produk.statusProduk == "preorder"
                              ? "Pre Order"
                              : "Ready Stock",

                          style: TextStyle(
                            fontSize: 9,

                            color: produk.statusProduk == "preorder"
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ),

                      if (produk.statusProduk != "preorder" &&
                          produk.expiredDate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(
                              Icons.schedule,
                              size: 11,

                              color: _isExpired(produk.expiredDate)
                                  ? Colors.red
                                  : Colors.orange,
                            ),

                            const SizedBox(width: 3),

                            Text(
                              _expiredLabel(produk.expiredDate),

                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Badge diskon
                  if (produk.adaDiskon) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _danger,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${produk.porsenDiskon?.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRupiah(produk.hargaJual),
                      style: const TextStyle(
                        fontSize: 10,
                        color: _textSecondary,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: _textSecondary,
                      ),
                    ),
                    Text(
                      _formatRupiah(produk.hargaTampil),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _danger,
                      ),
                    ),
                  ] else 
                    Text(
                      _formatRupiah(produk.hargaJual),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _primary,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 11,
                        color: stokColor,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          produk.statusProduk == "preorder"
                              ? "By Order"
                              : "Stok: ${produk.stok}",
                          style: TextStyle(
                            fontSize: 10,
                            color: stokColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

// ── Produk List Card ───────────────────────────────────────
class _ProdukListCard extends StatelessWidget {
  final ProdukModel produk;
  final int index;

  const _ProdukListCard({required this.produk, required this.index});

  Color get _accentColor {
    final colors = [
      _primary,
      const Color(0xFF0EA5E9),
      const Color(0xFF8B5CF6),
      _success,
      _warning,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final stokColor = _stokColor(produk.stok);
    final stokLabel = _stokLabel(produk.stok);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentColor, _accentColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.cake_outlined, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produk.namaProduk,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    produk.namaKategori ?? '-',
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (produk.adaDiskon)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _danger,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${produk.porsenDiskon?.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatRupiah(produk.hargaJual),
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: _textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatRupiah(produk.hargaTampil),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _danger,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          _formatRupiah(produk.hargaJual),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: _primary,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: stokColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 11,
                              color: stokColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              produk.statusProduk == "preorder"
                                  ? "By Order"
                                  : "$stokLabel (${produk.stok})",
                              style: TextStyle(
                                fontSize: 11,
                                color: stokColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
    );
  }
}
