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

// ── Status order config (sama seperti di pre_order_page) ──
const _statusConfig = {
  'menunggu_diproses': {
    'label': 'Menunggu Diproses',
    'color': 0xFFF59E0B,
    'icon': Icons.hourglass_empty,
  },
  'sedang_dibuat': {
    'label': 'Sedang Dibuat',
    'color': 0xFF0EA5E9,
    'icon': Icons.bakery_dining,
  },
  'sedang_diantar': {
    'label': 'Sedang Diantar',
    'color': 0xFF8B5CF6,
    'icon': Icons.delivery_dining,
  },
  'pesanan_diterima': {
    'label': 'Pesanan Diterima',
    'color': 0xFF10B981,
    'icon': Icons.check_circle_outline,
  },
  'selesai': {
    'label': 'Selesai',
    'color': 0xFF10B981,
    'icon': Icons.check_circle,
  },
  'dibatalkan': {
    'label': 'Dibatalkan',
    'color': 0xFFEF4444,
    'icon': Icons.cancel_outlined,
  },
};

const _urutanStatus = [
  'menunggu_diproses',
  'sedang_dibuat',
  'sedang_diantar',
  'pesanan_diterima',
  'selesai',
];

String? _nextStatus(String current) {
  final idx = _urutanStatus.indexOf(current);
  if (idx == -1 || idx >= _urutanStatus.length - 1) return null;
  return _urutanStatus[idx + 1];
}

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
  final String statusOrder;
   final String catatan;

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
    required this.statusOrder,
    required this.catatan,
    
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
      statusOrder: json['status_order'] as String? ?? 'menunggu_diproses',
      catatan: json['catatan'] as String? ?? '',
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
                  onUpdated: _fetchPending,
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
    final isPreOrder = t.jenisOrder == 'pre_order';

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
                          Expanded(
                            child: Text(
                              t.namaCustomer,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPreOrder
                                  ? _primary.withOpacity(0.1)
                                  : _warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPreOrder ? '🎂 Pre Order' : '📦 Ready Stock',
                              style: TextStyle(
                                fontSize: 11,
                                color: isPreOrder ? _primary : _warning,
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

          // ── Detail items ringkas ───────────────────────────
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

          // ── Info status pembayaran ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Icon(
                  t.statusPembayaran == 'Lunas'
                      ? Icons.check_circle_outline
                      : t.statusPembayaran == 'DP'
                      ? Icons.payments_outlined
                      : Icons.hourglass_empty,
                  size: 14,
                  color: t.statusPembayaran == 'Lunas'
                      ? _success
                      : t.statusPembayaran == 'DP'
                      ? _warning
                      : _textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.statusPembayaran == 'DP'
                        ? 'DP ${_formatRupiah(t.jumlahDp)} • Sisa ${_formatRupiah(t.totalPenjualan - t.jumlahDp)}'
                        : 'Status Bayar: ${t.statusPembayaran}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.statusPembayaran == 'Lunas'
                          ? _success
                          : t.statusPembayaran == 'DP'
                          ? _warning
                          : _textSecondary,
                    ),
                  ),
                ),
              ],
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
                if (isPreOrder)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: context.read<TransaksiProvider>(),
                            child: PreOrderStatusPage(
                              transaksi: t,
                              onUpdated: onUpdated,
                            ),
                          ),
                        ),
                      ).then((_) => onUpdated()),
                      icon: const Icon(Icons.tune, size: 16, color: _primary),
                      label: const Text(
                        'Kelola Pre Order',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                else
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

  Future<void> _showInvoice(BuildContext context) async {
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
    await showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TransaksiProvider>(),
        child: _InvoicePendingDialog(invoice: invoice!, onLunas: onUpdated),
      ),
    );
  }

  Future<void> _showLunasDialog(BuildContext context) async {
    final bayarCtrl = TextEditingController();
    final dpCtrl = TextEditingController();
    final t = transaksi;
    final isTransfer = t.metodePembayaran.toLowerCase().contains('transfer');
    String selectedStatus = 'Lunas';
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(label: 'Customer', value: t.namaCustomer),
                      _InfoRow(
                        label: 'Total',
                        value: _formatRupiah(t.totalPenjualan),
                      ),
                      _InfoRow(label: 'Metode', value: t.metodePembayaran),
                      _InfoRow(
                        label: 'Tgl Transaksi',
                        value: _formatTanggal(t.tanggalTransaksi),
                      ),
                      const SizedBox(height: 6),
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
                          if (picked != null)
                            setStateDialog(() => selectedTanggal = picked);
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
                if (!isTransfer)
                  TextField(
                    controller: bayarCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Diterima',
                      hintText: _formatRupiah(t.totalPenjualan),
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: _primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _info.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: _info),
                        const SizedBox(width: 8),
                        Text(
                          'Transfer — jumlah: ${_formatRupiah(t.totalPenjualan)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                backgroundColor: _success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (!isTransfer && bayarCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('Masukkan jumlah yang diterima'),
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
              child: const Text('Konfirmasi Lunas'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final jumlahBayar = isTransfer
        ? t.totalPenjualan
        : (double.tryParse(bayarCtrl.text.replaceAll('.', '')) ??
              t.totalPenjualan);

    final provider = context.read<TransaksiProvider>();
    final navigator = Navigator.of(context);
    final ok = await provider.updateStatusPembayaran(
      idTransaksi: t.idTransaksi,
      statusPembayaran: selectedStatus,
      jumlahBayar: jumlahBayar,
      jumlahDp: 0,
      tanggalLunas: selectedTanggal,
    );

    if (!context.mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal update status'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Update list di background
    onUpdated();

    // Fetch invoice terbaru lalu tampilkan dialog invoice lunas
    InvoiceResult? invoice;
    try {
      final response = await DioClient.instance.get(
        '${ApiConstants.transaksi}/${t.idTransaksi}/invoice',
      );
      final data = response.data['data'] as Map<String, dynamic>;
      invoice = InvoiceResult.fromJson(data);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lunas ✓ tapi gagal memuat invoice'),
            backgroundColor: _warning,
          ),
        );
      }
      return;
    }

    await navigator.push(
      DialogRoute(
        context: navigator.context,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider, // ← pakai provider yang sudah disimpan
          child: _InvoicePendingDialog(
            invoice: invoice!,
            onLunas: onUpdated,
            initialSudahLunas: true,
          ),
        ),
      ),
    );

    if (!context.mounted) return;

    // Buka invoice dialog langsung dalam kondisi sudah lunas
    await showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TransaksiProvider>(),
        child: _InvoicePendingDialog(
          invoice: invoice!,
          onLunas: onUpdated,
          initialSudahLunas: true,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  PreOrderStatusPage — kelola status & pembayaran pre order
// ══════════════════════════════════════════════════════════
class PreOrderStatusPage extends StatefulWidget {
  final TransaksiPending transaksi;
  final VoidCallback onUpdated;

  const PreOrderStatusPage({
    super.key,
    required this.transaksi,
    required this.onUpdated,
  });

  @override
  State<PreOrderStatusPage> createState() => _PreOrderStatusPageState();
}

class _PreOrderStatusPageState extends State<PreOrderStatusPage> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String nextStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Update Status'),
        content: Text(
          'Ubah status ke "${_statusConfig[nextStatus]?['label']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ya, Update'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdating = true);
    final ok = await context.read<TransaksiProvider>().updateStatusOrder(
      idTransaksi: widget.transaksi.idTransaksi,
      statusOrder: nextStatus,
    );
    setState(() => _isUpdating = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Status berhasil diupdate ✓' : 'Gagal update status',
        ),
        backgroundColor: ok ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (ok) {
      widget.onUpdated();
      Navigator.pop(context);
    }
  }

  Future<void> _batalkan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
          'Pesanan ini akan dibatalkan dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdating = true);
    final ok = await context.read<TransaksiProvider>().updateStatusOrder(
      idTransaksi: widget.transaksi.idTransaksi,
      statusOrder: 'dibatalkan',
    );
    setState(() => _isUpdating = false);

    if (!mounted) return;
    if (ok) {
      widget.onUpdated();
      Navigator.pop(context);
    }
  }

  Future<void> _bayarDp() async {
    final t = widget.transaksi;
    final dp50 = t.totalPenjualan * 0.5;
    final controller = TextEditingController(text: dp50.toStringAsFixed(0));

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bayar DP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Minimal 50% = ${_formatRupiah(dp50)}',
                style: const TextStyle(fontSize: 13, color: _textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah DP',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Konfirmasi DP'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    final jumlahDp = double.tryParse(controller.text) ?? 0;
    if (jumlahDp < dp50) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DP minimal ${_formatRupiah(dp50)}'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);
    final ok = await context.read<TransaksiProvider>().bayarDp(
      idTransaksi: widget.transaksi.idTransaksi,
      jumlahDp: jumlahDp,
    );
    setState(() => _isUpdating = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'DP berhasil dicatat ✓' : 'Gagal mencatat DP'),
        backgroundColor: ok ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (ok) {
      widget.onUpdated();
      Navigator.pop(context);
    }
  }

  Future<void> _lunasi() async {
    final t = widget.transaksi;
    final sisaBayar = t.totalPenjualan - t.jumlahDp;
    final controller = TextEditingController(
      text: sisaBayar.toStringAsFixed(0),
    );

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lunasi Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Sisa: ${_formatRupiah(sisaBayar)}',
                style: const TextStyle(fontSize: 13, color: _textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Bayar',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Lunasi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    final jumlahBayar = double.tryParse(controller.text) ?? 0;
    setState(() => _isUpdating = true);
    final ok = await context.read<TransaksiProvider>().lunasi(
      idTransaksi: widget.transaksi.idTransaksi,
      jumlahBayar: jumlahBayar,
    );
    setState(() => _isUpdating = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Pembayaran lunas ✓' : 'Gagal melunasi'),
        backgroundColor: ok ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (ok) {
      widget.onUpdated();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaksi;
    final nextStatus = _nextStatus(t.statusOrder);
    final sudahSelesai =
        t.statusOrder == 'selesai' || t.statusOrder == 'dibatalkan';

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          t.idTransaksi,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🎂 Pre Order',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info pesanan ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                  const Text(
                    'Info Pesanan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Customer', value: t.namaCustomer),
                  _InfoRow(
                    label: 'Tanggal',
                    value: _formatTanggal(t.tanggalTransaksi),
                  ),
                  _InfoRow(label: 'Metode Bayar', value: t.metodePembayaran),
                  _InfoRow(
                    label: 'Status Bayar',
                    value: t.statusPembayaran,
                    // valueColor tidak ada di _InfoRow pending, skip atau tambahkan
                  ),
                  if (t.catatan.isNotEmpty)
                    _InfoRow(label: 'Catatan', value: t.catatan),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Detail produk ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
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
                  const Text(
                    'Detail Produk',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...t.detail.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.cake_outlined,
                              size: 16,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              d.namaProduk,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'x${d.qty}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatRupiah(d.subTotal),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatRupiah(t.totalPenjualan),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Status tracker ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                  const Text(
                    'Status Pesanan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _StatusTracker(currentStatus: t.statusOrder),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tombol aksi ───────────────────────────────
            if (!sudahSelesai) ...[
              // Bayar DP
              if (t.statusPembayaran == 'Pending') ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _bayarDp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _warning,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text(
                      'Bayar DP 50%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Info DP + Lunasi
              if (t.statusPembayaran == 'DP') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: _warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'DP terbayar: ${_formatRupiah(t.jumlahDp)}  •  Sisa: ${_formatRupiah(t.totalPenjualan - t.jumlahDp)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _lunasi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Lunasi Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Update status
              if (nextStatus != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : () => _updateStatus(nextStatus),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _statusConfig[nextStatus]?['icon'] as IconData? ??
                                Icons.arrow_forward,
                            size: 20,
                          ),
                    label: Text(
                      'Update ke "${_statusConfig[nextStatus]?['label']}"',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Batalkan
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isUpdating ? null : _batalkan,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: _danger,
                    size: 18,
                  ),
                  label: const Text(
                    'Batalkan Pesanan',
                    style: TextStyle(
                      color: _danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.statusOrder == 'selesai'
                      ? _success.withOpacity(0.1)
                      : _danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: t.statusOrder == 'selesai'
                        ? _success.withOpacity(0.3)
                        : _danger.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t.statusOrder == 'selesai'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: t.statusOrder == 'selesai' ? _success : _danger,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.statusOrder == 'selesai'
                          ? 'Pesanan Selesai'
                          : 'Pesanan Dibatalkan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: t.statusOrder == 'selesai' ? _success : _danger,
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

// ══════════════════════════════════════════════════════════
//  Invoice Pending Dialog
// ══════════════════════════════════════════════════════════
class _InvoicePendingDialog extends StatefulWidget {
  final InvoiceResult invoice;
  final VoidCallback onLunas;
  final bool initialSudahLunas;

  const _InvoicePendingDialog({
    required this.invoice,
    required this.onLunas,
    this.initialSudahLunas = false,
  });

  @override
  State<_InvoicePendingDialog> createState() => _InvoicePendingDialogState();
}

class _InvoicePendingDialogState extends State<_InvoicePendingDialog> {
  final _bayarCtrl = TextEditingController();
  bool _isUpdating = false;
  bool _sudahLunas = false;
  final _invoiceKey = GlobalKey();
  bool _isSharingImage = false;
  InvoiceResult? _invoiceUpdated;

  @override
  void initState() {
    super.initState();
    if (widget.initialSudahLunas) {
      _sudahLunas = true;
      _invoiceUpdated = widget.invoice;
    }
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
    } finally {
      if (mounted) setState(() => _isSharingImage = false);
    }
  }

  // ── GANTI SELURUH _tandaiLunas ────────────────────────────
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

    if (!ok) {
      setState(() => _isUpdating = false);
      return;
    }

    // Fetch ulang invoice dari server supaya dapat tanggalLunas akurat
    final updated = await provider.fetchInvoice(widget.invoice.idTransaksi);

    setState(() {
      _isUpdating = false;
      _sudahLunas = true;
      _invoiceUpdated = updated;
    });

    if (!mounted) return;
    widget.onLunas();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pembayaran dikonfirmasi ✓'),
        backgroundColor: _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = _invoiceUpdated ?? widget.invoice;

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

                          // ── TAMBAH: blok lunas ──────────────
                          if (_sudahLunas) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _success.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _success.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: _success,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Pembayaran Lunas',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _InfoRow(
                                    label: 'Tgl Lunas',
                                    value: inv.tanggalLunas != null
                                        ? _formatTanggal(inv.tanggalLunas!)
                                        : _formatTanggal(
                                            DateTime.now().toIso8601String(),
                                          ),
                                  ),
                                  if (inv.jumlahBayar > 0)
                                    _InfoRow(
                                      label: 'Dibayar',
                                      value: _formatRupiah(inv.jumlahBayar),
                                    ),
                                  if (inv.jumlahDp > 0)
                                    _InfoRow(
                                      label: 'DP Sebelumnya',
                                      value: _formatRupiah(inv.jumlahDp),
                                    ),
                                  if (inv.kembalian > 0)
                                    _InfoRow(
                                      label: 'Kembalian',
                                      value: _formatRupiah(inv.kembalian),
                                    ),
                                ],
                              ),
                            ),
                          ],

                          // ── END blok lunas ───────────────────
                          if (inv.infoPembayaran != null && !_sudahLunas) ...[
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

class _StatusTracker extends StatelessWidget {
  final String currentStatus;
  const _StatusTracker({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _urutanStatus.asMap().entries.map((entry) {
        final idx = entry.key;
        final status = entry.value;
        final cfg = _statusConfig[status]!;
        final color = Color(cfg['color'] as int);
        final icon = cfg['icon'] as IconData;
        final label = cfg['label'] as String;

        final currentIdx = _urutanStatus.indexOf(currentStatus);
        final isDone = idx < currentIdx;
        final isCurrent = idx == currentIdx;
        final isPending = idx > currentIdx;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone
                        ? _success
                        : isCurrent
                        ? color
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? Icons.check : icon,
                    size: 14,
                    color: isPending ? Colors.grey.shade400 : Colors.white,
                  ),
                ),
                if (idx < _urutanStatus.length - 1)
                  Container(
                    width: 2,
                    height: 22,
                    color: isDone
                        ? _success.withOpacity(0.4)
                        : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isPending ? Colors.grey.shade400 : _textPrimary,
                    ),
                  ),
                  if (isCurrent)
                    Text(
                      'Status saat ini',
                      style: TextStyle(fontSize: 10, color: color),
                    ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
