import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/transaksi_provider.dart';
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
const _info = Color(0xFF0EA5E9);

// ── Helper format rupiah ───────────────────────────────────
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

// ── Helper format tanggal ──────────────────────────────────
String _formatTanggal(String raw) {
  try {
    final dt = DateTime.parse(raw).toLocal();
    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return raw;
  }
}

// ══════════════════════════════════════════════════════════
//  InputTransaksiPage
// ══════════════════════════════════════════════════════════
class InputTransaksiPage extends StatefulWidget {
  final String? jenisOrder; // 'ready' atau 'preorder'
  const InputTransaksiPage({super.key, this.jenisOrder});

  @override
  State<InputTransaksiPage> createState() => _InputTransaksiPageState();
}

class _InputTransaksiPageState extends State<InputTransaksiPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterKategoriId = 'Semua';
  late TabController _tabController;
  int _activeTab = 0; // 0 = Ready Stock, 1 = Pre Order

  @override
  void initState() {
    super.initState();
    final initialTab = widget.jenisOrder == 'preorder' ? 1 : 0;
    _activeTab = initialTab;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _activeTab = _tabController.index;
        _searchQuery = '';
        _filterKategoriId = 'Semua';
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdukProvider>().fetchProduks();
      context.read<KategoriProvider>().fetchKategoris();
      context.read<TransaksiProvider>().loadKeranjang();
      context.read<TransaksiProvider>().fetchPreOrderAktif();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produkProvider = context.watch<ProdukProvider>();
    final kategoriProvider = context.watch<KategoriProvider>();
    final transaksiProvider = context.watch<TransaksiProvider>();

    final filtered = produkProvider.produks.where((p) {
      final matchSearch = p.namaProduk.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchKategori =
          _filterKategoriId == 'Semua' || p.idKategori == _filterKategoriId;

      if (_activeTab == 0) {
        return matchSearch &&
            matchKategori &&
            p.statusProduk == 'ready' &&
            p.stok > 0;
      } else {
        return matchSearch && matchKategori && p.statusProduk == 'preorder';
      }
    }).toList();

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          widget.jenisOrder == 'preorder'
              ? 'Pre Order'
              : widget.jenisOrder == 'ready'
              ? 'Ready Stock'
              : 'Input Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Tombol keranjang
          if (transaksiProvider.keranjang.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      _showKeranjangSheet(context, transaksiProvider),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${transaksiProvider.totalItem}',
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(width: 4),
        ],
        // ── Tab Ready Stock / Pre Order ────────────────────
        bottom: widget.jenisOrder != null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: _primary,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Ready Stock'),
                      Tab(text: 'Pre Order'),
                    ],
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          // ── Search & Filter ──────────────────────────────
          Container(
            color: _primary,
            child: Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner info pre order
                  if (_activeTab == 1) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Produk pre order akan diproses setelah pembayaran dikonfirmasi.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Search
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
                      decoration: InputDecoration(
                        hintText: _activeTab == 0
                            ? 'Cari produk ready stock...'
                            : 'Cari produk pre order...',
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

                  // Filter kategori
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildChip('Semua', 'Semua'),
                        ...kategoriProvider.kategoris.map(
                          (k) => _buildChip(k.idKategori, k.namaKategori),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Grid Produk ──────────────────────────────────
          Expanded(
            child: produkProvider.status == ProdukStatus.loading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _activeTab == 0
                              ? Icons.inventory_2_outlined
                              : Icons.access_time_outlined,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _activeTab == 0
                              ? 'Produk tidak ditemukan'
                              : 'Belum ada produk pre order',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: _activeTab == 1 ? 0.65 : 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final qty = transaksiProvider.getQty(p.idProduk);
                      return _ProdukCard(
                        produk: p,
                        index: i,
                        qty: qty,
                        isPreOrder: _activeTab == 1,
                        onAdd: () => transaksiProvider.tambahItem(p),
                        onRemove: () =>
                            transaksiProvider.kurangiItem(p.idProduk),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── Bottom bar keranjang ─────────────────────────────
      bottomNavigationBar: transaksiProvider.keranjang.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${transaksiProvider.totalItem} item',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                          Text(
                            _formatRupiah(transaksiProvider.totalHarga),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showKeranjangSheet(context, transaksiProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      label: const Text(
                        'Keranjang',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChip(String id, String label) {
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

  void _showKeranjangSheet(BuildContext context, TransaksiProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _KeranjangSheet(
          onCheckoutSuccess: (result) async {
            final invoice = await provider.fetchInvoice(result.idTransaksi);
            if (!context.mounted) return;

            Navigator.pop(context);

            if (invoice != null) {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: _InvoiceDialog(invoice: invoice),
                ),
              );
            }

            provider.clearKeranjang();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Helper expired (salin dari daftar produk)
// ══════════════════════════════════════════════════════════
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
  if (exp == null) return '';
  if (_isExpired(exp)) return 'Expired';
  if (_isExpiringSoon(exp)) return 'Exp. soon';
  return '${exp.day}/${exp.month}/${exp.year}';
}

Color _expiredColor(DateTime? exp) {
  if (exp == null) return _textSecondary;
  if (_isExpired(exp)) return _danger;
  if (_isExpiringSoon(exp)) return _warning;
  return _textSecondary;
}

// ══════════════════════════════════════════════════════════
//  Produk Card — detail lengkap
// ══════════════════════════════════════════════════════════

class _ProdukCard extends StatelessWidget {
  final ProdukModel produk;
  final int index;
  final int qty;
  final bool isPreOrder;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProdukCard({
    required this.produk,
    required this.index,
    required this.qty,
    required this.isPreOrder,
    required this.onAdd,
    required this.onRemove,
  });

  Color get _accent {
    final colors = [
      _primary,
      _info,
      const Color(0xFF8B5CF6),
      _success,
      _warning,
    ];
    return colors[index % colors.length];
  }

  Widget _bannerFallback() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cake_outlined, color: Colors.white, size: 40),
        if (produk.namaKategori != null && produk.namaKategori!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            produk.namaKategori!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isInCart = qty > 0;
    final canAdd = isPreOrder || produk.stok > qty;
    final expired = _isExpired(produk.expiredDate);
    final expColor = _expiredColor(produk.expiredDate);
    final stokColor = isPreOrder
        ? Colors.orange
        : produk.stok == 0
        ? _danger
        : produk.stok <= 5
        ? _warning
        : _success;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInCart ? _primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isInCart
                ? _primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top banner ────────────────────────────────────
          Container(
            height: 120,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPreOrder
                    ? [Colors.orange.shade400, Colors.orange.shade300]
                    : [_accent, _accent.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Stack(
              children: [
                if (produk.imageUrl != null && produk.imageUrl!.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      produk.imageUrl!.startsWith('http')
                          ? produk.imageUrl!
                          : '${ApiConstants.serverUrl}${produk.imageUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _bannerFallback(),
                    ),
                  )
                else
                  _bannerFallback(),
                // Badge qty di keranjang
                if (isInCart)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x$qty',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                // Badge Pre Order
                Positioned(
                  top: 7,
                  right: 7,
                  child: Builder(
                    builder: (_) {
                      Color bgColor;
                      String label;

                      if (isPreOrder) {
                        bgColor = Colors.orange.shade600;
                        label = 'Pre Order';
                      } else if (produk.stok <= 5 && produk.stok > 0) {
                        bgColor = _warning;
                        label = 'Menipis';
                      } else if (produk.stok == 0) {
                        bgColor = _danger;
                        label = 'Habis';
                      } else {
                        bgColor = _success;
                        label = 'Ready';
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Info ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nama produk
                  Text(
                    produk.namaProduk,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _textPrimary,
                    ),
                    maxLines: 1, // ← 2 → 1 biar tidak makan 2 baris
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Stok
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: stokColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isPreOrder ? 'By Order' : 'Stok: ${produk.stok}',
                        style: TextStyle(
                          fontSize: 11,
                          color: stokColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Expired date
                  if (!isPreOrder && produk.expiredDate != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: expColor),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            _expiredLabel(produk.expiredDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: expColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Harga
                  if (produk.adaDiskon) ...[
                    Text(
                      _formatRupiah(produk.hargaJual),
                      style: const TextStyle(
                        fontSize: 9,
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
                ],
              ),
            ),
          ),

          // ── Tombol tambah/kurang ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 9),
            child: expired
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Expired',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : qty == 0
                ? GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isPreOrder ? Colors.orange.shade500 : _primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 15),
                          SizedBox(width: 4),
                          Text(
                            'Tambah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: _danger,
                            size: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: canAdd ? onAdd : null,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: canAdd
                                ? _primary.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add,
                            color: canAdd ? _primary : Colors.grey.shade400,
                            size: 15,
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
}

// ══════════════════════════════════════════════════════════
//  Keranjang Bottom Sheet
// ══════════════════════════════════════════════════════════
class _KeranjangSheet extends StatefulWidget {
  final Function(TransaksiResult) onCheckoutSuccess;
  const _KeranjangSheet({required this.onCheckoutSuccess});

  @override
  State<_KeranjangSheet> createState() => _KeranjangSheetState();
}

class _KeranjangSheetState extends State<_KeranjangSheet> {
  final _namaCtrl = TextEditingController();
  final _bayarCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  String _metode = 'Tunai';
  bool _isLoading = false;

  bool get _isTunai => _metode == 'Tunai';
  double get _jumlahBayar =>
      double.tryParse(_bayarCtrl.text.replaceAll('.', '')) ?? 0;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _bayarCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  bool _hasPreOrder(TransaksiProvider provider) {
    return provider.keranjang.any(
      (item) => item.produk.statusProduk == 'preorder',
    );
  }

  bool get _canCheckout {
    final provider = context.read<TransaksiProvider>();
    if (provider.keranjang.isEmpty) return false;
    if (_namaCtrl.text.trim().isEmpty) return false;
    if (_isTunai &&
        !_hasPreOrder(provider) &&
        _jumlahBayar < provider.totalHarga)
      return false;
    return true;
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: _primary, size: 20),
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
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransaksiProvider>();
    final isPreOrder = _hasPreOrder(provider);
    final kembalian = _isTunai ? _jumlahBayar - provider.totalHarga : 0.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: _primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Keranjang (${provider.totalItem} item)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    provider.clearKeranjang();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Kosongkan',
                    style: TextStyle(color: _danger, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Banner pre order di keranjang
          if (isPreOrder)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keranjang mengandung produk pre order. Status pembayaran akan Pending.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // List item keranjang
          Flexible(
            child: Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: provider.keranjang.length,
                itemBuilder: (ctx, i) {
                  final item = provider.keranjang[i];
                  final itemIsPreOrder = item.produk.statusProduk == 'preorder';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: itemIsPreOrder ? Colors.orange.shade50 : _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: itemIsPreOrder
                          ? Border.all(color: Colors.orange.shade200)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.produk.namaProduk,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (itemIsPreOrder) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade500,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'PO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                _formatRupiah(item.produk.hargaJual),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  provider.kurangiItem(item.produk.idProduk),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: _danger,
                                  size: 14,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                '${item.qty}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => provider.tambahItem(item.produk),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: _primary,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 72,
                          child: Text(
                            _formatRupiah(item.subtotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 1),

          // Checkout form
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  children: [
                    // Total
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primary, _primaryDark],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Belanja',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatRupiah(provider.totalHarga),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nama customer
                    TextField(
                      controller: _namaCtrl,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDeco(
                        hint: 'Nama Customer',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // Metode pembayaran
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.payment_outlined,
                                  color: _primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _metode,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _textPrimary,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Tunai',
                                        child: Text('Tunai'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Transfer',
                                        child: Text('Transfer'),
                                      ),
                                    ],
                                    onChanged: (v) => setState(() {
                                      _metode = v!;
                                      _bayarCtrl.clear();
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Jumlah bayar — sembunyikan untuk pre order
                        Expanded(
                          child: isPreOrder
                              ? Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.orange.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Bayar nanti',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _isTunai
                              ? TextField(
                                  controller: _bayarCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: _inputDeco(
                                    hint: 'Jumlah Bayar',
                                    icon: Icons.attach_money_outlined,
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _info.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _info.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _metode == 'QRIS'
                                            ? Icons.qr_code_outlined
                                            : Icons.account_balance_outlined,
                                        color: _info,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Bayar nanti',
                                          style: TextStyle(
                                            color: _info,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),

                    // Kembalian (Tunai, bukan pre order)
                    if (_isTunai && !isPreOrder && _jumlahBayar > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: kembalian >= 0
                              ? _success.withOpacity(0.1)
                              : _danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              kembalian >= 0 ? 'Kembalian' : 'Kurang Bayar',
                              style: TextStyle(
                                color: kembalian >= 0 ? _success : _danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatRupiah(kembalian.abs()),
                              style: TextStyle(
                                color: kembalian >= 0 ? _success : _danger,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Field catatan untuk pre order
                    if (isPreOrder) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _catatanCtrl,
                        maxLines: 2,
                        decoration: _inputDeco(
                          hint: 'Catatan pre order (opsional)',
                          icon: Icons.notes_outlined,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Tombol proses
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading || !_canCheckout
                            ? null
                            : () => _prosesTransaksi(context, provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          disabledBackgroundColor: Colors.grey.shade200,
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isPreOrder
                                        ? 'Buat Pre Order'
                                        : 'Proses Transaksi',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  Future<void> _prosesTransaksi(
    BuildContext context,
    TransaksiProvider provider,
  ) async {
    setState(() => _isLoading = true);

    final result = await provider.checkout(
      namaCustomer: _namaCtrl.text.trim(),
      jumlahBayar: _isTunai ? _jumlahBayar : 0,
      metodePembayaran: _metode,
      catatan: _catatanCtrl.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result != null) {
      widget.onCheckoutSuccess(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal memproses transaksi'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════
//  Invoice Dialog
// ══════════════════════════════════════════════════════════
class _InvoiceDialog extends StatefulWidget {
  final InvoiceResult invoice;
  const _InvoiceDialog({required this.invoice});

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  final _invoiceKey = GlobalKey();
  bool _isUpdatingStatus = false;
  bool _sudahLunas = false;
  bool _isSharingImage = false;
  final _bayarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sudahLunas = widget.invoice.statusPembayaran.toLowerCase() == 'lunas';
  }

  @override
  void dispose() {
    _bayarCtrl.dispose();
    super.dispose();
  }

  Future<void> _shareInvoiceAsImage() async {
    setState(() => _isSharingImage = true);
    try {
      final boundary =
          _invoiceKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/invoice_${widget.invoice.idTransaksi}.png',
      );
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('Error share image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat gambar invoice'),
            backgroundColor: _danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingImage = false);
    }
  }

  Future<void> _updateLunas() async {
    final provider = context.read<TransaksiProvider>();
    final jumlahBayar =
        double.tryParse(_bayarCtrl.text.replaceAll('.', '')) ??
        widget.invoice.totalPenjualan;

    setState(() => _isUpdatingStatus = true);

    final ok = await provider.updateStatusPembayaran(
      idTransaksi: widget.invoice.idTransaksi,
      jumlahBayar: jumlahBayar,
    );

    setState(() {
      _isUpdatingStatus = false;
      if (ok) _sudahLunas = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Status pembayaran diperbarui menjadi Lunas ✓'
              : 'Gagal update status',
        ),
        backgroundColor: ok ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final isTransfer = inv.metodePembayaran != 'Tunai';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Widget yang di-screenshot
            RepaintBoundary(
              key: _invoiceKey,
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header invoice
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, _primaryDark],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _sudahLunas
                                  ? Icons.check_circle
                                  : Icons.receipt_long_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Dannisa Sweet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Invoice Pembelian',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _sudahLunas
                                  ? _success.withOpacity(0.3)
                                  : _warning.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _sudahLunas ? '✓ Lunas' : '⏳ Pending',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _InvRow(
                            label: 'ID Transaksi',
                            value: inv.idTransaksi,
                          ),
                          _InvRow(
                            label: 'Tanggal',
                            value: _formatTanggal(inv.tanggalTransaksi),
                          ),
                          _InvRow(label: 'Customer', value: inv.namaCustomer),
                          _InvRow(label: 'Kasir', value: inv.namaKasir),
                          _InvRow(label: 'Metode', value: inv.metodePembayaran),
                          const Divider(height: 20),

                          ...inv.detail.map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 5,
                                    color: _primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${d.namaProduk} x${d.qty}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    _formatRupiah(d.subTotal),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Divider(height: 20),
                          _InvRow(
                            label: 'Total',
                            value: _formatRupiah(inv.totalPenjualan),
                            isBold: true,
                          ),

                          if (inv.jenisOrder == 'pre_order')
                            _InvRow(
                              label: 'DP Minimal (50%)',
                              value: _formatRupiah(inv.totalPenjualan * 0.5),
                              isBold: true,
                              color: _warning,
                            ),

                          // ── Kembalian (hanya tunai, bukan pre order)
                          if (!isTransfer &&
                              inv.kembalian > 0 &&
                              inv.jenisOrder != 'pre_order')
                            _InvRow(
                              label: 'Kembalian',
                              value: _formatRupiah(inv.kembalian),
                              color: _success,
                            ),

                          // Sesudah — muncul untuk transfer DAN pre order:
                          if ((isTransfer || inv.jenisOrder == 'pre_order') &&
                              inv.infoPembayaran != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _info.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _info.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Info Pembayaran',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _info,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _InvRow(
                                    label: 'Rekening',
                                    value: inv.infoPembayaran!.noRekening,
                                  ),
                                  _InvRow(
                                    label: 'Atas Nama',
                                    value: inv.infoPembayaran!.namaRekening,
                                  ),
                                  _InvRow(
                                    label: 'WA Konfirmasi',
                                    value: inv.infoPembayaran!.whatsapp,
                                  ),
                                  Text(
                                    inv.infoPembayaran!.catatan,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSharingImage ? null : _shareInvoiceAsImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSharingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.chat, size: 20),
                      label: Text(
                        _isSharingImage
                            ? 'Membuat gambar...'
                            : 'Kirim Invoice ke WhatsApp',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(color: _primary),
                      ),
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

// ── Invoice Row ────────────────────────────────────────────
class _InvRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _InvRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: _textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: color ?? _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
