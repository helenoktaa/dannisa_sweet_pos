import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/transaksi_provider.dart';
import 'package:dio/dio.dart';

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

// ─────────────────────────────────────────────────────────────
//  Model: TransaksiPending
//  Sesuai response: data.data (array)
// ─────────────────────────────────────────────────────────────
class TransaksiPending {
  final String idTransaksi;
  final String tanggalTransaksi;
  final String namaCustomer;
  final double jumlahBayar;
  final double jumlahDp;
  final String metodePembayaran;
  final String statusPembayaran;
  final String jenisOrder;
  final int totalItem;
  final double totalPenjualan;
  final List<DetailPending> detail;
  final String? tanggalLunas;

  const TransaksiPending({
    required this.idTransaksi,
    required this.tanggalTransaksi,
    required this.namaCustomer,
    required this.jumlahBayar,
    required this.jumlahDp,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.jenisOrder,
    required this.totalItem,
    required this.totalPenjualan,
    required this.detail,
    required this.tanggalLunas,
  });

  factory TransaksiPending.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawDetail = json['detail'] as List<dynamic>? ?? [];
    return TransaksiPending(
      idTransaksi: json['id_transaksi'] as String? ?? '',
      tanggalTransaksi: json['tanggal_transaksi'] as String? ?? '',
      namaCustomer: json['nama_customer'] as String? ?? '',
      jumlahBayar: (json['jumlah_bayar'] as num?)?.toDouble() ?? 0,
      jumlahDp: (json['jumlah_dp'] as num?)?.toDouble() ?? 0,
      metodePembayaran: json['metode_pembayaran'] as String? ?? '',
      statusPembayaran: json['status_pembayaran'] as String? ?? '',
      jenisOrder: json['jenis_order'] as String? ?? 'ready_stock',
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      totalPenjualan: (json['total_penjualan'] as num?)?.toDouble() ?? 0,
      detail: rawDetail
          .map((e) => DetailPending.fromJson(e as Map<String, dynamic>))
          .toList(),
      tanggalLunas: json['tanggal_lunas'] as String?,
    );
  }
}

class DetailPending {
  final String idProduk;
  final String namaProduk;
  final int qty;
  final double hargaJual;
  final double subTotal;

  const DetailPending({
    required this.idProduk,
    required this.namaProduk,
    required this.qty,
    required this.hargaJual,
    required this.subTotal,
  });

  factory DetailPending.fromJson(Map<String, dynamic> json) {
    final produk = json['produk'] as Map<String, dynamic>? ?? {};
    return DetailPending(
      idProduk: json['id_produk'] as String? ?? '',
      namaProduk: produk['nama_produk'] as String? ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      hargaJual: (json['harga_jual'] as num?)?.toDouble() ?? 0,
      subTotal: (json['sub_total'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ══════════════════════════════════════════════════════════
//  TransaksiPendingPage
// ══════════════════════════════════════════════════════════
class TransaksiPendingPage extends StatefulWidget {
  const TransaksiPendingPage({super.key});

  @override
  State<TransaksiPendingPage> createState() => _TransaksiPendingPageState();
}

class _TransaksiPendingPageState extends State<TransaksiPendingPage> {
  List<TransaksiPending> _transaksis = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch Pending dan DP sekaligus
      final results = await Future.wait([
        DioClient.instance.get(
          ApiConstants.transaksi,
          queryParameters: {'status': 'Pending'},
        ),
        DioClient.instance.get(
          ApiConstants.transaksi,
          queryParameters: {'status': 'DP'},
        ),
      ]);

      final List<dynamic> pendingList =
          results[0].data['data'] as List<dynamic>? ?? [];
      final List<dynamic> dpList =
          results[1].data['data'] as List<dynamic>? ?? [];

      setState(() {
        _transaksis =
            [...pendingList, ...dpList]
                .map(
                  (e) => TransaksiPending.fromJson(e as Map<String, dynamic>),
                )
                .toList()
              ..sort(
                (a, b) => b.tanggalTransaksi.compareTo(a.tanggalTransaksi),
              );
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data['message'] ?? 'Gagal memuat data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── App Bar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primary,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchPending,
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 4),
            ],
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
                      left: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Transaksi Pending',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            _isLoading
                                ? 'Memuat...'
                                : '${_transaksis.length} transaksi belum lunas',
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

          // ── Header area ──────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Transaksi di bawah menunggu konfirmasi pembayaran dari customer.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _warning.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
        ],

        // ── Body ─────────────────────────────────────────────
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 56, color: _primary),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: _textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchPending,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : _transaksis.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: _success.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Semua transaksi sudah lunas! 🎉',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _transaksis.length,
                itemBuilder: (ctx, i) => _PendingCard(
                  transaksi: _transaksis[i],
                  onUpdated: _fetchPending, // refresh setelah lunas
                ),
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Pending Card
// ══════════════════════════════════════════════════════════
class _PendingCard extends StatelessWidget {
  final TransaksiPending transaksi;
  final VoidCallback onUpdated;

  const _PendingCard({required this.transaksi, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final t = transaksi;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _warning.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _warning.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.pending_outlined,
                      color: _warning,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            t.namaCustomer,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '⏳ Pending',
                              style: TextStyle(
                                fontSize: 11,
                                color: _warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTanggal(t.tanggalTransaksi),
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            t.idTransaksi,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatRupiah(t.totalPenjualan),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _primary,
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

          // ── Detail items ──────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: t.detail
                  .map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 5, color: _primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${d.namaProduk} x${d.qty}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _formatRupiah(d.subTotal),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // ── Action buttons ────────────────────────────────
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
                // Lihat Invoice & Kirim WA
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showInvoice(context),
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: _info,
                    ),
                    label: const Text(
                      'Invoice & WA',
                      style: TextStyle(
                        color: _info,
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
                // Tandai Lunas
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showLunasDialog(context),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: _success,
                    ),
                    label: const Text(
                      'Tandai Lunas',
                      style: TextStyle(
                        color: _success,
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

  // ── Lihat Invoice & Kirim WA ───────────────────────────
  Future<void> _showInvoice(BuildContext context) async {
    // Fetch invoice
    InvoiceResult? invoice;
    try {
      final response = await DioClient.instance.get(
        '${ApiConstants.transaksi}/${transaksi.idTransaksi}/invoice',
      );
      final data = response.data['data'] as Map<String, dynamic>;
      invoice = InvoiceResult.fromJson(data);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat invoice'),
            backgroundColor: _danger,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Tampilkan invoice dialog
    await showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TransaksiProvider>(),
        child: _InvoicePendingDialog(invoice: invoice!, onLunas: onUpdated),
      ),
    );
  }

  // ── Tandai Lunas langsung ──────────────────────────────
  Future<void> _showLunasDialog(BuildContext context) async {
    final bayarCtrl = TextEditingController();
    final dpCtrl = TextEditingController();
    String selectedStatus = transaksi.statusPembayaran == 'DP'
        ? 'Lunas'
        : 'Lunas';
    DateTime selectedTanggal = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: _success),
              SizedBox(width: 8),
              Text(
                'Update Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Info transaksi ────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Customer',
                        value: transaksi.namaCustomer,
                      ),
                      _InfoRow(
                        label: 'Total',
                        value: _formatRupiah(transaksi.totalPenjualan),
                      ),
                      _InfoRow(
                        label: 'Metode',
                        value: transaksi.metodePembayaran,
                      ),
                      _InfoRow(
                        label: 'Jenis Order',
                        value: transaksi.jenisOrder == 'pre_order'
                            ? 'Pre Order'
                            : 'Ready Stock',
                      ),
                      _InfoRow(
                        label: 'Tgl Transaksi',
                        value: _formatTanggal(transaksi.tanggalTransaksi),
                      ),
                      const SizedBox(height: 6),

                      // ── Date picker tgl pembayaran ────────
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedTanggal,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: _primary,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setStateDialog(() => selectedTanggal = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tgl Pembayaran',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${selectedTanggal.day}/${selectedTanggal.month}/${selectedTanggal.year}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.edit_calendar_outlined,
                                    size: 14,
                                    color: _primary,
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
                const SizedBox(height: 14),

                // ── Pilihan DP / Lunas — HANYA pre order belum DP ──
                if (transaksi.jenisOrder == 'pre_order' &&
                    transaksi.statusPembayaran != 'DP') ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setStateDialog(() => selectedStatus = 'Lunas'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedStatus == 'Lunas'
                                  ? _success.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedStatus == 'Lunas'
                                    ? _success
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: selectedStatus == 'Lunas'
                                      ? _success
                                      : _textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lunas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: selectedStatus == 'Lunas'
                                        ? _success
                                        : _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setStateDialog(() => selectedStatus = 'DP'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedStatus == 'DP'
                                  ? _warning.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedStatus == 'DP'
                                    ? _warning
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  color: selectedStatus == 'DP'
                                      ? _warning
                                      : _textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'DP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: selectedStatus == 'DP'
                                        ? _warning
                                        : _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Info sisa — kalau sudah DP ────────────
                if (transaksi.statusPembayaran == 'DP') ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: _warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sudah DP ${_formatRupiah(transaksi.jumlahDp)} • '
                            'Sisa ${_formatRupiah(transaksi.totalPenjualan - transaksi.jumlahDp)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Input nominal DP ──────────────────────
                if (selectedStatus == 'DP') ...[
                  TextField(
                    controller: dpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nominal DP (min. 50%)',
                      hintText:
                          'Min. ${_formatRupiah(transaksi.totalPenjualan * 0.5)}',
                      prefixIcon: const Icon(
                        Icons.payments_outlined,
                        color: _warning,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _warning,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Input jumlah bayar ────────────────────
                TextField(
                  controller: bayarCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: transaksi.statusPembayaran == 'DP'
                        ? 'Jumlah Pelunasan'
                        : 'Jumlah Diterima',
                    hintText: transaksi.statusPembayaran == 'DP'
                        ? _formatRupiah(
                            transaksi.totalPenjualan - transaksi.jumlahDp,
                          )
                        : _formatRupiah(transaksi.totalPenjualan),
                    prefixIcon: const Icon(Icons.attach_money, color: _primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: _textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedStatus == 'DP' ? _warning : _success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (bayarCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        selectedStatus == 'DP'
                            ? 'Masukkan jumlah yang diterima'
                            : 'Masukkan jumlah yang diterima customer',
                      ),
                      backgroundColor: _danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  return;
                }
                if (selectedStatus == 'DP' && dpCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('Masukkan nominal DP'),
                      backgroundColor: _danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(
                selectedStatus == 'DP' ? 'Konfirmasi DP' : 'Konfirmasi Lunas',
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final jumlahBayar =
        double.tryParse(bayarCtrl.text.replaceAll('.', '')) ??
        transaksi.totalPenjualan;
    final jumlahDp = double.tryParse(dpCtrl.text.replaceAll('.', '')) ?? 0;

    final provider = context.read<TransaksiProvider>();
    final ok = await provider.updateStatusPembayaran(
      idTransaksi: transaksi.idTransaksi,
      statusPembayaran: selectedStatus,
      jumlahBayar: jumlahBayar,
      jumlahDp: selectedStatus == 'DP' ? jumlahDp : 0,
      tanggalLunas: selectedStatus == 'Lunas' ? selectedTanggal : null,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? selectedStatus == 'DP'
                    ? '${transaksi.namaCustomer} - DP dikonfirmasi ✓'
                    : '${transaksi.namaCustomer} - pembayaran lunas ✓'
              : 'Gagal update status',
        ),
        backgroundColor: ok ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (ok) onUpdated();
  }
}

// ══════════════════════════════════════════════════════════
//  Invoice Pending Dialog
// ══════════════════════════════════════════════════════════
class _InvoicePendingDialog extends StatefulWidget {
  final InvoiceResult invoice;
  final VoidCallback onLunas;

  const _InvoicePendingDialog({required this.invoice, required this.onLunas});

  @override
  State<_InvoicePendingDialog> createState() => _InvoicePendingDialogState();
}

class _InvoicePendingDialogState extends State<_InvoicePendingDialog> {
  final _bayarCtrl = TextEditingController();
  bool _isUpdating = false;
  bool _sudahLunas = false;
  final _invoiceKey = GlobalKey();
  bool _isSharingImage = false;

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
    } finally {
      if (mounted) {
        setState(() => _isSharingImage = false);
      }
    }
  }

  Future<void> _tandaiLunas() async {
    setState(() => _isUpdating = true);
    final jumlahBayar =
        double.tryParse(_bayarCtrl.text.replaceAll('.', '')) ??
        widget.invoice.totalPenjualan;

    final provider = context.read<TransaksiProvider>();
    final ok = await provider.updateStatusPembayaran(
      idTransaksi: widget.invoice.idTransaksi,
      jumlahBayar: jumlahBayar,
    );

    setState(() {
      _isUpdating = false;
      if (ok) _sudahLunas = true;
    });

    if (!mounted) return;
    if (ok) {
      widget.onLunas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pembayaran dikonfirmasi ✓'),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _invoiceKey,
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
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
                          const SizedBox(height: 10),
                          Text(
                            _sudahLunas
                                ? 'Pembayaran Dikonfirmasi!'
                                : 'Invoice',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                          _InfoRow(label: 'ID', value: inv.idTransaksi),
                          _InfoRow(
                            label: 'Tanggal',
                            value: _formatTanggal(inv.tanggalTransaksi),
                          ),
                          _InfoRow(label: 'Customer', value: inv.namaCustomer),
                          _InfoRow(label: 'Kasir', value: inv.namaKasir),
                          _InfoRow(
                            label: 'Metode',
                            value: inv.metodePembayaran,
                          ),

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

                          _InfoRow(
                            label: 'Total',
                            value: _formatRupiah(inv.totalPenjualan),
                            isBold: true,
                          ),

                          if (inv.infoPembayaran != null) ...[
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

                                  _InfoRow(
                                    label: 'Rekening',
                                    value: inv.infoPembayaran!.noRekening,
                                  ),

                                  _InfoRow(
                                    label: 'Atas Nama',
                                    value: inv.infoPembayaran!.namaRekening,
                                  ),

                                  _InfoRow(
                                    label: 'WA',
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

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Kirim WA
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
                      icon: const Icon(Icons.chat, size: 20),
                      label: Text(
                        _isSharingImage
                            ? 'Membuat gambar...'
                            : 'Kirim Invoice ke WhatsApp',
                      ),
                    ),
                  ),

                  // Tandai Lunas
                  if (!_sudahLunas) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUpdating ? null : _tandaiLunas,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isUpdating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Tandai Sudah Lunas',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],

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

// ── Info Row ───────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
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
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
