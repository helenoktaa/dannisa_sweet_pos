import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/laporan_provider.dart';

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

// ── Helpers ────────────────────────────────────────────────
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
    const bulan = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  } catch (_) {
    return raw;
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

String _fmtDateDisplay(DateTime d) {
  const bulan = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
  return '${d.day} ${bulan[d.month]} ${d.year}';
}

// ══════════════════════════════════════════════════════════
//  LaporanTransaksiPage
// ══════════════════════════════════════════════════════════
class LaporanTransaksiPage extends StatefulWidget {
  const LaporanTransaksiPage({super.key});

  @override
  State<LaporanTransaksiPage> createState() => _LaporanTransaksiPageState();
}

class _LaporanTransaksiPageState extends State<LaporanTransaksiPage> {
  // Default: 7 hari terakhir
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<LaporanProvider>().fetchRentang(_range.start, _range.end);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _range = picked);
      _loadData();
    }
  }

  String get _rangeLabel =>
      '${_fmtDateDisplay(_range.start)}  –  ${_fmtDateDisplay(_range.end)}';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LaporanProvider>();

    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primary,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadData,
                tooltip: 'Refresh',
              ),
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
                      right: -30, top: -20,
                      child: Container(
                        width: 160, height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 20, bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Laporan Transaksi',
                              style: TextStyle(
                                color: Colors.white, fontSize: 22,
                                fontWeight: FontWeight.w800, letterSpacing: -0.5,
                              )),
                          SizedBox(height: 4),
                          Text('Rekap penjualan & laba',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter bar ─────────────────────────────────────
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
                child: GestureDetector(
                  onTap: _pickRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.1),
                          blurRadius: 10, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.date_range_outlined, color: _primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Periode',
                                  style: TextStyle(fontSize: 11, color: _textSecondary)),
                              Text(_rangeLabel,
                                  style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  )),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Text('Ubah',
                                  style: TextStyle(
                                    fontSize: 12, color: _primary, fontWeight: FontWeight.w600,
                                  )),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, color: _primary, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Loading ────────────────────────────────────────
          if (provider.status == LaporanStatus.loading ||
              provider.status == LaporanStatus.initial)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _primary)),
            )

          // ── Error ──────────────────────────────────────────
          else if (provider.status == LaporanStatus.error)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 56, color: _primary),
                    const SizedBox(height: 12),
                    Text(provider.error ?? 'Terjadi kesalahan',
                        style: const TextStyle(color: _textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary, foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )

          // ── Data loaded ────────────────────────────────────
          else if (provider.laporan != null) ...[
            // Summary cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _SummarySection(laporan: provider.laporan!),
              ),
            ),

            // Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, color: _primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('Riwayat Transaksi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16, color: _textPrimary,
                        )),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${provider.laporan!.transaksis.length} transaksi',
                        style: const TextStyle(
                          fontSize: 12, color: _primary, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Empty state
            if (provider.laporan!.transaksis.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFD1D5DB)),
                        SizedBox(height: 12),
                        Text('Belum ada transaksi pada periode ini',
                            style: TextStyle(color: _textSecondary)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final t = provider.laporan!.transaksis[i];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        16, 0, 16,
                        i == provider.laporan!.transaksis.length - 1 ? 24 : 10,
                      ),
                      child: _TransaksiCard(transaksi: t),
                    );
                  },
                  childCount: provider.laporan!.transaksis.length,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Summary Section
// ══════════════════════════════════════════════════════════
class _SummarySection extends StatelessWidget {
  final LaporanData laporan;
  const _SummarySection({required this.laporan});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _SummaryCard(
              label: 'Total Transaksi',
              value: '${laporan.totalTransaksi}',
              icon: Icons.receipt_long_outlined,
              color: _primary,
              isCurrency: false,
            ),
            const SizedBox(width: 10),
            _SummaryCard(
              label: 'Penjualan',
              value: _formatRupiah(laporan.totalPenjualan),
              icon: Icons.payments_outlined,
              color: _success,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _SummaryCard(
              label: 'Modal',
              value: _formatRupiah(laporan.totalModal),
              icon: Icons.account_balance_wallet_outlined,
              color: _warning,
            ),
            const SizedBox(width: 10),
            _SummaryCard(
              label: 'Laba',
              value: _formatRupiah(laporan.totalLaba),
              icon: Icons.trending_up_outlined,
              color: laporan.totalLaba >= 0 ? _info : _danger,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isCurrency;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 10, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: Text(label,
                      style: const TextStyle(fontSize: 11, color: _textSecondary),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: isCurrency ? 13 : 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Transaksi Card (expandable)
// ══════════════════════════════════════════════════════════
class _TransaksiCard extends StatefulWidget {
  final TransaksiLaporan transaksi;
  const _TransaksiCard({required this.transaksi});

  @override
  State<_TransaksiCard> createState() => _TransaksiCardState();
}

class _TransaksiCardState extends State<_TransaksiCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _ctrl.forward() : _ctrl.reverse();
  }

  Color get _metodColor {
    switch (widget.transaksi.metodePembayaran) {
      case 'Tunai': return _success;
      case 'Transfer': return _info;
      case 'QRIS': return const Color(0xFF8B5CF6);
      default: return _textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaksi;
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.receipt_long_outlined, color: _primary, size: 22),
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
                              child: Text(t.namaCustomer,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15, color: _textPrimary,
                                  )),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _metodColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(t.metodePembayaran,
                                  style: TextStyle(
                                    fontSize: 11, color: _metodColor, fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(_formatTanggal(t.tanggalTransaksi),
                            style: const TextStyle(fontSize: 11, color: _textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(t.idTransaksi,
                                style: const TextStyle(fontSize: 11, color: _textSecondary)),
                            const Spacer(),
                            Text(_formatRupiah(t.totalPenjualan),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15, color: _primary,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Expandable detail
          SizeTransition(
            sizeFactor: _anim,
            child: Column(
              children: [
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: Colors.grey.shade100,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    children: [
                      // Item list
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: t.detail.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: _primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('${d.produk.namaProduk} x${d.qty}',
                                      style: const TextStyle(fontSize: 13, color: _textPrimary)),
                                ),
                                Text(_formatRupiah(d.subTotal),
                                    style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Modal / Laba / Item
                      Row(
                        children: [
                          _MiniStat(label: 'Modal', value: _formatRupiah(t.totalModal), color: _warning),
                          const SizedBox(width: 8),
                          _MiniStat(label: 'Laba', value: _formatRupiah(t.laba), color: _success),
                          const SizedBox(width: 8),
                          _MiniStat(label: 'Item', value: '${t.totalItem} pcs', color: _info),
                        ],
                      ),
                    ],
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

// ── Mini Stat ──────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: _textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}