import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/features/admin/data/models/produk_model.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/produk_provider.dart';

const _primary = Color(0xFFE91E8C);
const _primaryDark = Color(0xFFC2185B);
const _surface = Color(0xFFFFF0F7);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);
const _success = Color(0xFF10B981);
const _danger = Color(0xFFEF4444);
const _warning = Color(0xFFF59E0B);

class MarkdownPricingPage extends StatefulWidget {
  const MarkdownPricingPage({super.key});

  @override
  State<MarkdownPricingPage> createState() => _MarkdownPricingPageState();
}

class _MarkdownPricingPageState extends State<MarkdownPricingPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Hanya fetch kalau belum ada data
      final provider = context.read<ProdukProvider>();
      if (provider.produks.isEmpty) {
        provider.fetchProduks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProdukProvider>();

    // Hanya produk ready (bukan preorder) yang bisa di-diskon
    final filtered = provider.produks
    .where(
      (p) =>
          p.statusProduk == 'ready' &&
          p.expiredDate != null &&
          p.expiredDate!.difference(DateTime.now()).inDays <= 7 && 
          p.expiredDate!.isAfter(DateTime.now()) && 
          p.namaProduk.toLowerCase().contains(_searchQuery.toLowerCase()),
    )
    .toList();

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Kelola Diskon Expired',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info banner
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _warning, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Diskon otomatis aktif 2 hari sebelum expired. '
                            'Kamu bisa set diskon manual atau nonaktifkan per produk.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        hintStyle: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: _primary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List produk
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.discount_outlined,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada produk dengan expired date',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _MarkdownCard(
                      produk: filtered[i],
                      onRefresh: () => provider.fetchProduks(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Card per produk ────────────────────────────────────────
class _MarkdownCard extends StatelessWidget {
  final ProdukModel produk;
  final VoidCallback onRefresh;

  const _MarkdownCard({required this.produk, required this.onRefresh});

  int get _sisaHari {
    if (produk.expiredDate == null) return 999;
    return produk.expiredDate!.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final sisaHari = _sisaHari;
    final adaDiskon = produk.adaDiskon;
    final punyaExpiredDate = produk.expiredDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: adaDiskon ? Border.all(color: _danger.withOpacity(0.3)) : null,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
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
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 13,
                            color: sisaHari <= 2 ? _danger : _warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sisaHari <= 0
                                ? 'Sudah expired'
                                : '$sisaHari hari lagi expired',
                            style: TextStyle(
                              fontSize: 12,
                              color: sisaHari <= 2 ? _danger : _warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge diskon aktif
                if (adaDiskon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${produk.porsenDiskon?.toStringAsFixed(0)}% '
                      '${produk.sumberDiskon == "manual" ? "(Manual)" : "(Auto)"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Info harga
            Row(
              children: [
                _PriceChip(
                  label: 'Harga Asli',
                  value: 'Rp ${_fmt(produk.hargaJual)}',
                  color: _textSecondary,
                ),
                const SizedBox(width: 8),
                if (adaDiskon)
                  _PriceChip(
                    label: 'Harga Diskon',
                    value: 'Rp ${_fmt(produk.hargaTampil)}',
                    color: _danger,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                // Set/Edit diskon manual
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSetDiskonDialog(context),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(
                      adaDiskon && produk.sumberDiskon == 'manual'
                          ? 'Edit Diskon'
                          : 'Set Diskon Manual',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Hapus diskon manual
                if (adaDiskon && produk.sumberDiskon == 'manual')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _hapusDiskon(context),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text(
                        'Hapus Diskon',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _danger,
                        side: const BorderSide(color: _danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }

  void _showSetDiskonDialog(BuildContext context) {
    final porsenCtrl = TextEditingController(
      text: produk.porsenDiskon?.toStringAsFixed(0) ?? '20',
    );
    final sampaiCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Set Diskon Manual',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: porsenCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Persen Diskon (%)',
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: sampaiCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Aktif Sampai',
                prefixIcon: const Icon(Icons.calendar_today, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  sampaiCtrl.text = picked.toIso8601String().split('T')[0];
                }
              },
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
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (porsenCtrl.text.isEmpty || sampaiCtrl.text.isEmpty) return;
              Navigator.pop(context);
              await _kirimOverride(
                context,
                double.parse(porsenCtrl.text),
                sampaiCtrl.text,
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _kirimOverride(
    BuildContext context,
    double persen,
    String sampai,
  ) async {
    try {
      // 1. Buat config dulu, abaikan kalau sudah ada (409)
      try {
        await DioClient.instance.post(
          '${ApiConstants.baseUrl}/markdown',
          data: {
            'id_produk': produk.idProduk,
            'threshold_hari': 2,
            'persen_diskon': 20.0,
            'aktif_otomatis': true,
          },
        );
      } on DioException catch (e) {
        // 409 = config sudah ada, lanjut saja
        if (e.response?.statusCode != 409) rethrow;
      }

      // 2. Set override manual
      await DioClient.instance.patch(
        '${ApiConstants.baseUrl}/markdown/${produk.idProduk}/override',
        data: {'manual_persen': persen, 'manual_aktif_sampai': sampai},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Diskon ${persen.toStringAsFixed(0)}% berhasil diset',
            ),
            backgroundColor: _success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        onRefresh();
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['message'] ?? 'Gagal set diskon'),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _hapusDiskon(BuildContext context) async {
    try {
      await DioClient.instance.delete(
        '${ApiConstants.baseUrl}/v1/markdown/${produk.idProduk}/override',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diskon manual berhasil dihapus'),
            backgroundColor: _success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        onRefresh();
      }
    } on DioException catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal hapus diskon'),
            backgroundColor: _danger,
          ),
        );
      }
    }
  }
}

// ── Price Chip ─────────────────────────────────────────────
class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: _textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
