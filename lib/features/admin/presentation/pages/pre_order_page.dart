import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/transaksi_provider.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/transaksi_pending_page.dart';

const _primary = Color(0xFFE91E8C);
const _surface = Color(0xFFFFF0F7);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);
const _success = Color(0xFF10B981);
const _danger = Color(0xFFEF4444);
const _warning = Color(0xFFF59E0B);

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
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return raw;
  }
}

// ── Status order config ────────────────────────────────────
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

// Status berikutnya
String? _nextStatus(String current) {
  final idx = _urutanStatus.indexOf(current);
  if (idx == -1 || idx >= _urutanStatus.length - 1) return null;
  return _urutanStatus[idx + 1];
}

// ══════════════════════════════════════════════════════════
//  PreOrderPage — list semua pre order aktif
// ══════════════════════════════════════════════════════════
class PreOrderPage extends StatefulWidget {
  const PreOrderPage({super.key});

  @override
  State<PreOrderPage> createState() => _PreOrderPageState();
}

class _PreOrderPageState extends State<PreOrderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransaksiProvider>().fetchPreOrderAktif();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransaksiProvider>();

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Pre Order Aktif',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => provider.fetchPreOrderAktif(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${provider.preOrders.length} pesanan aktif',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: provider.isLoadingPreOrder
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : provider.preOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada pre order aktif',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: _primary,
                    onRefresh: () => provider.fetchPreOrderAktif(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: provider.preOrders.length,
                      itemBuilder: (ctx, i) {
                        final po = provider.preOrders[i];
                        return _PreOrderCard(
                          preOrder: po,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: provider,
                                child: PreOrderDetailPage(preOrder: po),
                              ),
                            ),
                          ).then((_) => provider.fetchPreOrderAktif()),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Card pre order di list ─────────────────────────────────
class _PreOrderCard extends StatelessWidget {
  final PreOrderItem preOrder;
  final VoidCallback onTap;

  const _PreOrderCard({required this.preOrder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cfg =
        _statusConfig[preOrder.statusOrder] ??
        _statusConfig['menunggu_diproses']!;
    final color = Color(cfg['color'] as int);
    final icon = cfg['icon'] as IconData;
    final label = cfg['label'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              children: [
                // ID & tanggal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preOrder.idTransaksi,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _primary,
                        ),
                      ),
                      Text(
                        _formatTanggal(preOrder.tanggalTransaksi),
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Customer & total
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: _textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    preOrder.namaCustomer,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatRupiah(preOrder.totalPenjualan),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Item list ringkas
            Text(
              preOrder.detail
                  .map((d) => '${d.namaProduk} x${d.qty}')
                  .join(', '),
              style: const TextStyle(fontSize: 12, color: _textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (preOrder.catatan.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.notes, size: 13, color: Colors.orange.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      preOrder.catatan,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // Tap hint
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Lihat detail & update status',
                  style: TextStyle(fontSize: 11, color: _primary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 11, color: _primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  PreOrderDetailPage — detail + update status
// ══════════════════════════════════════════════════════════
class PreOrderDetailPage extends StatefulWidget {
  final PreOrderItem preOrder;
  const PreOrderDetailPage({super.key, required this.preOrder});

  @override
  State<PreOrderDetailPage> createState() => _PreOrderDetailPageState();
}

class _PreOrderDetailPageState extends State<PreOrderDetailPage> {
  bool _isUpdating = false;
  late PreOrderItem _po;

  @override
  void initState() {
    super.initState();
    _po = widget.preOrder;
  }

  // ── Update status order
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
    final provider = context.read<TransaksiProvider>();
    final ok = await provider.updateStatusOrder(
      idTransaksi: _po.idTransaksi, // ← pakai _po bukan widget.preOrder
      statusOrder: nextStatus,
    );
    setState(() => _isUpdating = false);

    if (!mounted) return;

    if (ok) {
      // Kalau sudah selesai atau dibatalkan → pop halaman
      if (nextStatus == 'selesai' || nextStatus == 'dibatalkan') {
        Navigator.pop(context);
      } else {
        // Status masih di tengah → update lokal, JANGAN pop
        setState(() {
          _po = PreOrderItem(
            idTransaksi: _po.idTransaksi,
            tanggalTransaksi: _po.tanggalTransaksi,
            namaCustomer: _po.namaCustomer,
            metodePembayaran: _po.metodePembayaran,
            statusPembayaran: _po.statusPembayaran,
            jumlahDp: _po.jumlahDp,
            statusOrder: nextStatus, // ← maju ke status berikutnya
            catatan: _po.catatan,
            totalPenjualan: _po.totalPenjualan,
            totalItem: _po.totalItem,
            detail: _po.detail,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status diupdate ke "${_statusConfig[nextStatus]?['label']}" ✓',
            ),
            backgroundColor: _success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal update status'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Batalkan pesanan
  Future<void> _batalkan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pre Order?'),
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
    final provider = context.read<TransaksiProvider>();
    final ok = await provider.updateStatusOrder(
      idTransaksi: _po.idTransaksi,
      statusOrder: 'dibatalkan',
    );
    setState(() => _isUpdating = false);

    if (!mounted) return;
    if (ok) Navigator.pop(context); // ← batalkan → langsung pop
  }

  // ── Bayar DP 50%
  Future<void> _bayarDp() async {
    final dp50 = _po.totalPenjualan * 0.5; // ← pakai _po
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
      idTransaksi: _po.idTransaksi, // ← pakai _po
      jumlahDp: jumlahDp,
    );
    setState(() => _isUpdating = false);

    if (!mounted) return;

    if (ok) {
      // Update lokal, JANGAN pop — admin masih perlu update status order
      setState(() {
        _po = PreOrderItem(
          idTransaksi: _po.idTransaksi,
          tanggalTransaksi: _po.tanggalTransaksi,
          namaCustomer: _po.namaCustomer,
          metodePembayaran: _po.metodePembayaran,
          statusPembayaran: 'DP', // ← update status bayar
          jumlahDp: jumlahDp, // ← simpan nilai DP baru
          statusOrder: _po.statusOrder,
          catatan: _po.catatan,
          totalPenjualan: _po.totalPenjualan,
          totalItem: _po.totalItem,
          detail: _po.detail,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'DP berhasil dicatat ✓  Lunasi saat pesanan siap diantar',
          ),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mencatat DP'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Lunasi sisa pembayaran
  Future<void> _lunasi() async {
    final sisaBayar = _po.totalPenjualan - _po.jumlahDp; // ← pakai _po
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
      idTransaksi: _po.idTransaksi, 
      jumlahBayar: jumlahBayar,
      jumlahDp: _po.jumlahDp,
    );
    setState(() => _isUpdating = false);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal melunasi'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // ✅ 1. Update state lokal dulu
    setState(() {
      _po = PreOrderItem(
        idTransaksi: _po.idTransaksi,
        tanggalTransaksi: _po.tanggalTransaksi,
        namaCustomer: _po.namaCustomer,
        metodePembayaran: _po.metodePembayaran,
        statusPembayaran: 'Lunas',
        jumlahDp: _po.totalPenjualan,
        statusOrder: _po.statusOrder,
        catatan: _po.catatan,
        totalPenjualan: _po.totalPenjualan,
        totalItem: _po.totalItem,
        detail: _po.detail,
      );
    });

    // ✅ 2. Fetch invoice dari server
    InvoiceResult? invoice;
    try {
      final response = await DioClient.instance.get(
        '${ApiConstants.transaksi}/${_po.idTransaksi}/invoice',
      );
      final data = response.data['data'] as Map<String, dynamic>;
      invoice = InvoiceResult.fromJson(data);
    } catch (e) {
      debugPrint('Gagal fetch invoice pre order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lunas ✓ tapi gagal memuat invoice'),
            backgroundColor: _warning,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    //  3. Tampilkan dialog invoice lunas
    // JANGAN pop halaman — dialog ditampilkan di atas PreOrderDetailPage
    // supaya setelah tutup invoice, admin masih bisa update status order
    await showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TransaksiProvider>(),
        child: InvoicePendingDialog(
          invoice: invoice!,
          onLunas: () {}, // sudah lunas, tidak perlu aksi tambahan
          initialSudahLunas: true, // langsung tampil sebagai "Lunas"
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final po = _po; // ← pakai _po, bukan widget.preOrder
    final cfg =
        _statusConfig[po.statusOrder] ?? _statusConfig['menunggu_diproses']!;
    final statusColor = Color(cfg['color'] as int);
    final nextStatus = _nextStatus(po.statusOrder);
    final sudahSelesai =
        po.statusOrder == 'selesai' || po.statusOrder == 'dibatalkan';

    // Cek apakah boleh advance ke selesai (harus lunas dulu)
    final bolehAdvance =
        nextStatus != null &&
        !(nextStatus == 'selesai' && po.statusPembayaran != 'Lunas');

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          po.idTransaksi,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status order tracker ──────────────────────
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusTracker(currentStatus: po.statusOrder),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Info customer ─────────────────────────────
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
                    'Info Pesanan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Customer', value: po.namaCustomer),
                  _InfoRow(
                    label: 'Tanggal',
                    value: _formatTanggal(po.tanggalTransaksi),
                  ),
                  _InfoRow(label: 'Metode Bayar', value: po.metodePembayaran),
                  _InfoRow(
                    label: 'Status Bayar',
                    value: po.statusPembayaran,
                    valueColor: po.statusPembayaran == 'Lunas'
                        ? _success
                        : _warning,
                  ),
                  if (po.catatan.isNotEmpty)
                    _InfoRow(label: 'Catatan', value: po.catatan),
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
                  ...po.detail.map(
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
                        _formatRupiah(po.totalPenjualan),
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
            const SizedBox(height: 24),

            // ── Tombol aksi ───────────────────────────────
            if (!sudahSelesai) ...[
              // 1. Tombol Bayar DP (muncul kalau masih Pending)
              if (po.statusPembayaran == 'Pending') ...[
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

              // 2. Info DP + tombol Lunasi (muncul kalau status DP)
              if (po.statusPembayaran == 'DP') ...[
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
                          'DP terbayar: ${_formatRupiah(po.jumlahDp)}  •  Sisa: ${_formatRupiah(po.totalPenjualan - po.jumlahDp)}',
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

              // 3. Tombol update status order
              if (nextStatus != null) ...[
                // Warning kalau mau selesai tapi belum lunas
                if (!bolehAdvance) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _danger.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, size: 16, color: _danger),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lunasi pembayaran terlebih dahulu sebelum menyelesaikan pesanan',
                            style: TextStyle(
                              fontSize: 12,
                              color: _danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
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
              ],

              // 4. Tombol Batalkan
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
              // Sudah selesai/batal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: po.statusOrder == 'selesai'
                      ? _success.withOpacity(0.1)
                      : _danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: po.statusOrder == 'selesai'
                        ? _success.withOpacity(0.3)
                        : _danger.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      po.statusOrder == 'selesai'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: po.statusOrder == 'selesai' ? _success : _danger,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      po.statusOrder == 'selesai'
                          ? 'Pesanan Selesai'
                          : 'Pesanan Dibatalkan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: po.statusOrder == 'selesai' ? _success : _danger,
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

// ── Status Tracker Widget ──────────────────────────────────
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
            // Dot + line
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
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
                    size: 16,
                    color: isPending ? Colors.grey.shade400 : Colors.white,
                  ),
                ),
                if (idx < _urutanStatus.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: isDone
                        ? _success.withOpacity(0.4)
                        : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                      color: isPending ? Colors.grey.shade400 : _textPrimary,
                    ),
                  ),
                  if (isCurrent)
                    Text(
                      'Status saat ini',
                      style: TextStyle(fontSize: 11, color: color),
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

// ── Info Row ───────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ),
          const Text(': ', style: TextStyle(color: _textSecondary)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
