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

class LaporanTransaksiPage extends StatefulWidget {
  const LaporanTransaksiPage({super.key});

  @override
  State<LaporanTransaksiPage> createState() => _LaporanTransaksiPageState();
}

class _LaporanTransaksiPageState extends State<LaporanTransaksiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadData();
    });
    // Load data harian saat pertama buka
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final provider = context.read<LaporanProvider>();
    switch (_tabController.index) {
      case 0:
        provider.fetchHarian(_selectedDate);
        break;
      case 1:
        provider.fetchBulanan(_selectedMonth);
        break;
      case 2:
        if (_selectedRange != null) {
          provider.fetchRentang(_selectedRange!.start, _selectedRange!.end);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 155,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primary,
            systemOverlayStyle: SystemUiOverlayStyle.light,

            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.65),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Harian'),
                    Tab(text: 'Bulanan'),
                    Tab(text: 'Rentang'),
                  ],
                ),
              ),
            ),

            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
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
                    // bubble kanan
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

                    // text header
                    Positioned(
                      left: 35,
                      right: 24,
                      bottom: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Laporan Transaksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Rekap penjualan & laba',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 13,
                              height: 1.2,
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
        ],

        body: TabBarView(
          controller: _tabController,
          children: [
            _TabContent(
              dateSelector: _buildHarianSelector(),
              onLoad: _loadData,
            ),
            _TabContent(
              dateSelector: _buildBulananSelector(),
              onLoad: _loadData,
            ),
            _TabContent(
              dateSelector: _buildRentangSelector(),
              onLoad: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  // ── Date Selector: Harian ──────────────────────────────────
  Widget _buildHarianSelector() {
    const namaBulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return _DateSelectorBar(
      label:
          '${_selectedDate.day} ${namaBulan[_selectedDate.month]} ${_selectedDate.year}',
      icon: Icons.calendar_today_outlined,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(
              ctx,
            ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
          _loadData();
        }
      },
    );
  }

  // ── Date Selector: Bulanan ─────────────────────────────────
  Widget _buildBulananSelector() {
    const namaBulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return _DateSelectorBar(
      label: '${namaBulan[_selectedMonth.month]} ${_selectedMonth.year}',
      icon: Icons.date_range_outlined,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedMonth,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(
              ctx,
            ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => _selectedMonth = DateTime(picked.year, picked.month));
          _loadData();
        }
      },
    );
  }

  // ── Date Selector: Rentang ─────────────────────────────────
  Widget _buildRentangSelector() {
    String label = 'Pilih rentang tanggal';
    if (_selectedRange != null) {
      final s = _selectedRange!.start;
      final e = _selectedRange!.end;
      label = '${s.day}/${s.month}/${s.year} – ${e.day}/${e.month}/${e.year}';
    }
    return _DateSelectorBar(
      label: label,
      icon: Icons.tune_outlined,
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          initialDateRange: _selectedRange,
          builder: (ctx, child) => Theme(
            data: Theme.of(
              ctx,
            ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => _selectedRange = picked);
          _loadData();
        }
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Tab Content
// ══════════════════════════════════════════════════════════
class _TabContent extends StatelessWidget {
  final Widget dateSelector;
  final VoidCallback onLoad;

  const _TabContent({required this.dateSelector, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LaporanProvider>();

    return switch (provider.status) {
      LaporanStatus.loading || LaporanStatus.initial => Column(
        children: [
          _HeaderArea(dateSelector: dateSelector),
          const Expanded(
            child: Center(child: CircularProgressIndicator(color: _primary)),
          ),
        ],
      ),
      LaporanStatus.error => Column(
        children: [
          _HeaderArea(dateSelector: dateSelector),
          Expanded(
            child: Center(
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
                    onPressed: onLoad,
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
          ),
        ],
      ),
      LaporanStatus.loaded => _LaporanContent(
        dateSelector: dateSelector,
        laporan: provider.laporan!,
      ),
    };
  }
}

// ── Header area (date selector + stats) ───────────────────
class _HeaderArea extends StatelessWidget {
  final Widget dateSelector;
  const _HeaderArea({required this.dateSelector});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: dateSelector,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Laporan Content (loaded state)
// ══════════════════════════════════════════════════════════
class _LaporanContent extends StatelessWidget {
  final Widget dateSelector;
  final LaporanData laporan;

  const _LaporanContent({required this.dateSelector, required this.laporan});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header + stats ───────────────────────────────────
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
                  dateSelector,
                  const SizedBox(height: 14),

                  // Periode info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 14,
                          color: _primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${laporan.tanggalMulai}  →  ${laporan.tanggalAkhir}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Summary cards row 1
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
                        label: 'Total Penjualan',
                        value: _formatRupiah(laporan.totalPenjualan),
                        icon: Icons.payments_outlined,
                        color: _success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Summary cards row 2
                  Row(
                    children: [
                      _SummaryCard(
                        label: 'Total Modal',
                        value: _formatRupiah(laporan.totalModal),
                        icon: Icons.account_balance_wallet_outlined,
                        color: _warning,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Total Laba',
                        value: _formatRupiah(laporan.totalLaba),
                        icon: Icons.trending_up_outlined,
                        color: laporan.totalLaba >= 0 ? _info : _danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Section title ────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: _primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${laporan.transaksis.length} transaksi',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── List transaksi ───────────────────────────────────
        laporan.transaksis.isEmpty
            ? const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: Color(0xFFD1D5DB),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada transaksi pada periode ini',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final t = laporan.transaksis[i];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      i == laporan.transaksis.length - 1 ? 24 : 10,
                    ),
                    child: _TransaksiCard(transaksi: t),
                  );
                }, childCount: laporan.transaksis.length),
              ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Date Selector Bar
// ══════════════════════════════════════════════════════════
class _DateSelectorBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DateSelectorBar({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _primary, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Summary Card
// ══════════════════════════════════════════════════════════
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
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: _textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
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
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
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
      case 'Tunai':
        return _success;
      case 'Transfer':
        return _info;
      case 'QRIS':
        return const Color(0xFF8B5CF6);
      default:
        return _textSecondary;
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────
          GestureDetector(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: _primary,
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
                                color: _metodColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t.metodePembayaran,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _metodColor,
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
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable detail ─────────────────────────────
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
                      // Detail items
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: t.detail.map((d) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: _primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${d.produk.namaProduk} x${d.qty}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatRupiah(d.subTotal),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Modal & Laba
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Modal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatRupiah(t.totalModal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Laba',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatRupiah(t.laba),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Item',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${t.totalItem} pcs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _info,
                                    ),
                                  ),
                                ],
                              ),
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
        ],
      ),
    );
  }
}
