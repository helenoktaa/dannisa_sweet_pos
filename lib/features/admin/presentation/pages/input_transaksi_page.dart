import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
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
  const InputTransaksiPage({super.key});

  @override
  State<InputTransaksiPage> createState() => _InputTransaksiPageState();
}

class _InputTransaksiPageState extends State<InputTransaksiPage> {
  String _searchQuery = '';
  String _filterKategoriId = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdukProvider>().fetchProduks();
      context.read<KategoriProvider>().fetchKategoris();
      context.read<TransaksiProvider>().clearKeranjang();
    });
  }

  @override
  Widget build(BuildContext context) {
    final produkProvider = context.watch<ProdukProvider>();
    final kategoriProvider = context.watch<KategoriProvider>();
    final transaksiProvider = context.watch<TransaksiProvider>();

    final filtered = produkProvider.produks.where((p) {
      final matchSearch =
          p.namaProduk.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchKategori =
          _filterKategoriId == 'Semua' || p.idKategori == _filterKategoriId;
      return matchSearch && matchKategori && p.stok > 0;
    }).toList();

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Input Transaksi',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (transaksiProvider.keranjang.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white),
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
                children: [
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
                        hintText: 'Cari produk...',
                        hintStyle:
                            TextStyle(color: _textSecondary, fontSize: 14),
                        prefixIcon:
                            const Icon(Icons.search, color: _primary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: _textSecondary),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                    child: CircularProgressIndicator(color: _primary))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Produk tidak ditemukan',
                                style: TextStyle(color: _textSecondary)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.82,
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
                                fontSize: 12, color: _textSecondary),
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
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      label: const Text('Keranjang',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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
          border: Border.all(
              color: isActive ? _primary : Colors.grey.shade300),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
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

  void _showKeranjangSheet(
      BuildContext context, TransaksiProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _KeranjangSheet(
          onCheckoutSuccess: (result) async {
            // Fetch invoice setelah checkout berhasil
            final invoice = await provider.fetchInvoice(result.idTransaksi);
            if (!context.mounted) return;

            // Tutup keranjang sheet
            Navigator.pop(context);

            // Tampilkan invoice dialog
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

            // Clear keranjang & kembali ke halaman produk
            provider.clearKeranjang();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Produk Card
// ══════════════════════════════════════════════════════════
class _ProdukCard extends StatelessWidget {
  final ProdukModel produk;
  final int index;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProdukCard({
    required this.produk,
    required this.index,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  Color get _accent {
    final colors = [_primary, _info, const Color(0xFF8B5CF6), _success, _warning];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isInCart = qty > 0;
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
          // Top area
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.6)],
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
                const Center(
                  child: Icon(Icons.cake_outlined, color: Colors.white, size: 36),
                ),
                if (isInCart)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'x$qty',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stok: ${produk.stok}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
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
                  const Spacer(),
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

          // Add/Remove buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: qty == 0
                ? GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Tambah',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.remove,
                              color: _danger, size: 16),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('$qty',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: _textPrimary)),
                        ),
                      ),
                      GestureDetector(
                        onTap: qty < produk.stok ? onAdd : null,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: qty < produk.stok
                                ? _primary.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add,
                              color: qty < produk.stok
                                  ? _primary
                                  : Colors.grey.shade400,
                              size: 16),
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
  String _metode = 'Tunai';
  bool _isLoading = false;

  // Tunai → wajib input nominal
  // Transfer/QRIS → nominal 0, bayar nanti
  bool get _isTunai => _metode == 'Tunai';
  double get _jumlahBayar =>
      double.tryParse(_bayarCtrl.text.replaceAll('.', '')) ?? 0;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _bayarCtrl.dispose();
    super.dispose();
  }

  bool get _canCheckout {
    final provider = context.read<TransaksiProvider>();
    if (provider.keranjang.isEmpty) return false;
    if (_namaCtrl.text.trim().isEmpty) return false;
    if (_isTunai && _jumlahBayar < provider.totalHarga) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransaksiProvider>();
    final kembalian = _isTunai
        ? _jumlahBayar - provider.totalHarga
        : 0.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
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
                  child: const Icon(Icons.shopping_cart_outlined,
                      color: _primary, size: 20),
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
                  child: const Text('Kosongkan',
                      style: TextStyle(color: _danger, fontSize: 13)),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List item
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: provider.keranjang.length,
              itemBuilder: (ctx, i) {
                final item = provider.keranjang[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.produk.namaProduk,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _textPrimary)),
                            Text(_formatRupiah(item.produk.hargaJual),
                                style: const TextStyle(
                                    fontSize: 12, color: _textSecondary)),
                          ],
                        ),
                      ),
                      // Qty control
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                provider.kurangiItem(item.produk.idProduk),
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: _danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.remove,
                                  color: _danger, size: 14),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('${item.qty}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                          ),
                          GestureDetector(
                            onTap: () => provider.tambahItem(item.produk),
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add,
                                  color: _primary, size: 14),
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
                              color: _primary),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Checkout form
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Total
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    gradient:
                        LinearGradient(colors: [_primary, _primaryDark]),
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Belanja',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      Text(_formatRupiah(provider.totalHarga),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
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
                      icon: Icons.person_outline),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    // Metode pembayaran
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _metode,
                        decoration: _inputDeco(
                            hint: 'Metode',
                            icon: Icons.payment_outlined),
                        items: const [
                          DropdownMenuItem(
                              value: 'Tunai', child: Text('Tunai')),
                          DropdownMenuItem(
                              value: 'Transfer', child: Text('Transfer')),
                          DropdownMenuItem(
                              value: 'QRIS', child: Text('QRIS')),
                        ],
                        onChanged: (v) => setState(() {
                          _metode = v!;
                          _bayarCtrl.clear();
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Jumlah bayar (hanya untuk Tunai)
                    Expanded(
                      child: _isTunai
                          ? TextField(
                              controller: _bayarCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: _inputDeco(
                                  hint: 'Jumlah Bayar',
                                  icon: Icons.attach_money_outlined),
                            )
                          : Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _info.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _info.withOpacity(0.3)),
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
                                  Expanded(
                                    child: Text(
                                      'Bayar nanti',
                                      style: TextStyle(
                                          color: _info,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),

                // Kembalian (hanya Tunai)
                if (_isTunai && _jumlahBayar > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
                              color:
                                  kembalian >= 0 ? _success : _danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        Text(
                          _formatRupiah(kembalian.abs()),
                          style: TextStyle(
                              color:
                                  kembalian >= 0 ? _success : _danger,
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],

                // Info untuk Transfer/QRIS
                if (!_isTunai) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: _info.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: _info, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Invoice akan ditampilkan untuk dikirim ke WhatsApp customer',
                            style: TextStyle(
                                color: _info,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
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
                          borderRadius: BorderRadius.circular(14)),
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Proses Transaksi',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
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

  InputDecoration _inputDeco(
      {required String hint, required IconData icon}) {
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _prosesTransaksi(
      BuildContext context, TransaksiProvider provider) async {
    setState(() => _isLoading = true);

    final result = await provider.checkout(
      namaCustomer: _namaCtrl.text.trim(),
      jumlahBayar: _isTunai ? _jumlahBayar : 0,
      metodePembayaran: _metode,
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
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════
//  Invoice Dialog
//  Tampil setelah checkout berhasil
//  Flow: lihat invoice → kirim WA → update status Lunas
// ══════════════════════════════════════════════════════════
class _InvoiceDialog extends StatefulWidget {
  final InvoiceResult invoice;
  const _InvoiceDialog({required this.invoice});

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  bool _isUpdatingStatus = false;
  bool _sudahLunas = false;
  final _bayarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sudahLunas =
        widget.invoice.statusPembayaran.toLowerCase() == 'lunas';
  }

  @override
  void dispose() {
    _bayarCtrl.dispose();
    super.dispose();
  }

  // Buat pesan WA dari invoice
  String _buildWaMessage() {
    final inv = widget.invoice;
    final buffer = StringBuffer();
    buffer.writeln('🍰 *Dannisa Sweet*');
    buffer.writeln('━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 *Invoice: ${inv.idTransaksi}*');
    buffer.writeln('👤 Customer: ${inv.namaCustomer}');
    buffer.writeln('📅 Tanggal: ${_formatTanggal(inv.tanggalTransaksi)}');
    buffer.writeln('');
    buffer.writeln('*Detail Pesanan:*');
    for (final d in inv.detail) {
      buffer.writeln(
          '• ${d.namaProduk} x${d.qty} = ${_formatRupiah(d.subTotal)}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 Total: *${_formatRupiah(inv.totalPenjualan)}*');
    buffer.writeln('💳 Metode: ${inv.metodePembayaran}');

    if (inv.infoPembayaran != null && inv.metodePembayaran != 'Tunai') {
      final info = inv.infoPembayaran!;
      buffer.writeln('');
      buffer.writeln('*Info Transfer:*');
      buffer.writeln('🏦 ${info.noRekening}');
      buffer.writeln('👤 a.n. ${info.namaRekening}');
      buffer.writeln('📝 ${info.catatan}');
    }

    buffer.writeln('');
    buffer.writeln('Terima kasih sudah berbelanja! 🙏');
    return buffer.toString();
  }

  Future<void> _kirimWa() async {
    final inv = widget.invoice;
    String? noWa;

    // Ambil nomor WA dari info_pembayaran jika Transfer/QRIS
    if (inv.infoPembayaran != null && inv.infoPembayaran!.whatsapp.isNotEmpty) {
      noWa = inv.infoPembayaran!.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
      if (noWa.startsWith('0')) {
        noWa = '62${noWa.substring(1)}';
      }
    }

    final message = Uri.encodeComponent(_buildWaMessage());
    final url = noWa != null
        ? 'https://wa.me/$noWa?text=$message'
        : 'https://wa.me/?text=$message';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        content: Text(ok
            ? 'Status pembayaran diperbarui menjadi Lunas ✓'
            : 'Gagal update status'),
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
            // ── Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_primary, _primaryDark]),
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
                  const SizedBox(height: 10),
                  Text(
                    _sudahLunas ? 'Transaksi Selesai!' : 'Invoice',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
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
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body invoice ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Info dasar
                  _InvoiceRow(label: 'ID Transaksi', value: inv.idTransaksi),
                  _InvoiceRow(
                      label: 'Tanggal',
                      value: _formatTanggal(inv.tanggalTransaksi)),
                  _InvoiceRow(label: 'Customer', value: inv.namaCustomer),
                  _InvoiceRow(label: 'Kasir', value: inv.namaKasir),
                  _InvoiceRow(label: 'Metode', value: inv.metodePembayaran),
                  const Divider(height: 20),

                  // Detail item
                  ...inv.detail.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 5, color: _primary),
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
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),

                  const Divider(height: 20),

                  // Total
                  _InvoiceRow(
                    label: 'Total',
                    value: _formatRupiah(inv.totalPenjualan),
                    isBold: true,
                    color: _textPrimary,
                  ),

                  // Info Transfer/QRIS
                  if (isTransfer && inv.infoPembayaran != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _info.withOpacity(0.2)),
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
                          _InvoiceRow(
                            label: 'Rekening',
                            value: inv.infoPembayaran!.noRekening,
                          ),
                          _InvoiceRow(
                            label: 'Atas Nama',
                            value: inv.infoPembayaran!.namaRekening,
                          ),
                          _InvoiceRow(
                            label: 'WA Konfirmasi',
                            value: inv.infoPembayaran!.whatsapp,
                          ),
                          const SizedBox(height: 4),
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

                  // Input jumlah bayar (Transfer/QRIS, belum lunas)
                  if (isTransfer && !_sudahLunas) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bayarCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah yang dibayar',
                        hintStyle: TextStyle(
                            color: _textSecondary, fontSize: 13),
                        prefixIcon: const Icon(
                            Icons.attach_money_outlined,
                            color: _primary,
                            size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: _primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Action buttons ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Kirim WA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _kirimWa,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat, size: 20),
                      label: const Text(
                        'Kirim Invoice ke WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  // Update Lunas (hanya Transfer/QRIS & belum lunas)
                  if (isTransfer && !_sudahLunas) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isUpdatingStatus ? null : _updateLunas,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isUpdatingStatus
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(
                                Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Tandai Sudah Lunas',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Tutup
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tutup',
                          style: TextStyle(color: _primary)),
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
class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _InvoiceRow({
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
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: _textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isBold ? FontWeight.w800 : FontWeight.w600,
                color: color ?? _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}