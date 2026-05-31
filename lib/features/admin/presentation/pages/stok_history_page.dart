import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/stok_history_provider.dart';
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

class StokHistoryPage extends StatefulWidget {
  const StokHistoryPage({super.key});

  @override
  State<StokHistoryPage> createState() => _StokHistoryPageState();
}

class _StokHistoryPageState extends State<StokHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterJenis = 'Semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StokHistoryProvider>().fetchAll();
      context.read<ProdukProvider>().fetchProduks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StokHistoryProvider>();

    // Filter berdasarkan jenis
    final filtered = provider.histories.where((h) {
      if (_filterJenis == 'Semua') return true;
      return h.jenis == _filterJenis;
    }).toList();

    return Scaffold(
      backgroundColor: _surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── App Bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
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
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20, bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Riwayat Stok',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${provider.histories.length} perubahan tercatat',
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
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Catat Perubahan Stok',
                onPressed: () => _showFormSheet(context),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Stat Cards ───────────────────────────────────
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
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Total Catatan',
                      value: '${provider.histories.length}',
                      icon: Icons.history_outlined,
                      color: _primary,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Penambahan',
                      value: '${provider.histories.where((h) => h.jenis == 'penambahan').length}',
                      icon: Icons.add_box_outlined,
                      color: _success,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Pengurangan',
                      value: '${provider.histories.where((h) => h.jenis == 'pengurangan').length}',
                      icon: Icons.indeterminate_check_box_outlined,
                      color: _danger,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter Chip ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    isSelected: _filterJenis == 'Semua',
                    onTap: () => setState(() => _filterJenis = 'Semua'),
                    color: _primary,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Penambahan',
                    isSelected: _filterJenis == 'penambahan',
                    onTap: () => setState(() => _filterJenis = 'penambahan'),
                    color: _success,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pengurangan',
                    isSelected: _filterJenis == 'pengurangan',
                    onTap: () => setState(() => _filterJenis = 'pengurangan'),
                    color: _danger,
                  ),
                ],
              ),
            ),
          ),
        ],

        // ── List Riwayat ─────────────────────────────────
        body: () {
          switch (provider.status) {
            case StokHistoryStatus.initial:
            case StokHistoryStatus.loading:
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            case StokHistoryStatus.error:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 56, color: _primary),
                    const SizedBox(height: 12),
                    Text(provider.error ?? 'Gagal memuat data',
                        style: const TextStyle(color: _textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchAll(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            case StokHistoryStatus.loaded:
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Belum ada riwayat stok',
                          style: TextStyle(
                              color: _textSecondary, fontSize: 14)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showFormSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Catat Perubahan Stok'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: _primary,
                onRefresh: () => provider.fetchAll(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _HistoryCard(history: filtered[i]),
                ),
              );
          }
        }(),
      ),

      // ── FAB ─────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormSheet(context),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.edit_note_outlined),
        label: const Text('Catat Stok',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showFormSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _StokFormSheet(),
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
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: _textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _textSecondary,
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── History Card ───────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final StokHistoryModel history;

  const _HistoryCard({required this.history});

  bool get _isPenambahan => history.jenis == 'penambahan';

  String _formatTanggal(DateTime tanggal) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${tanggal.day} ${months[tanggal.month]} ${tanggal.year} '
        '${tanggal.hour.toString().padLeft(2, '0')}:'
        '${tanggal.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _isPenambahan ? _success : _danger;
    final icon = _isPenambahan
        ? Icons.add_circle_outline
        : Icons.remove_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon jenis
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
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
                          history.namaProduk,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge jenis
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          _isPenambahan ? '+ ${history.jumlah}' : '- ${history.jumlah}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Stok sebelum → sesudah
                  Row(
                    children: [
                      Text(
                        'Stok: ',
                        style: const TextStyle(
                            fontSize: 12, color: _textSecondary),
                      ),
                      Text(
                        '${history.stokSebelum}',
                        style: const TextStyle(
                            fontSize: 12, color: _textSecondary),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 12, color: _textSecondary),
                      Text(
                        '${history.stokSesudah}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Keterangan
                  if (history.keterangan.isNotEmpty)
                    Text(
                      history.keterangan,
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 6),

                  // Footer: user & tanggal
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        history.namaUser,
                        style: const TextStyle(
                            fontSize: 11, color: _textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time,
                          size: 12, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatTanggal(history.tanggal),
                        style: const TextStyle(
                            fontSize: 11, color: _textSecondary),
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

// ── Form Sheet ─────────────────────────────────────────────
class _StokFormSheet extends StatefulWidget {
  const _StokFormSheet();

  @override
  State<_StokFormSheet> createState() => _StokFormSheetState();
}

class _StokFormSheetState extends State<_StokFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  String? _selectedProdukId;
  String _selectedJenis = 'penambahan';
  bool _isLoading = false;

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProdukId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih produk terlebih dahulu'),
          backgroundColor: _warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final ok = await context.read<StokHistoryProvider>().create(
          idProduk: _selectedProdukId!,
          jenis: _selectedJenis,
          jumlah: int.parse(_jumlahCtrl.text),
          keterangan: _keteranganCtrl.text.trim(),
        );

    setState(() => _isLoading = false);
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Stok berhasil diperbarui ✓'
            : 'Gagal memperbarui stok'),
        backgroundColor: ok ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final produks = context.watch<ProdukProvider>().produks;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Cari stok produk yang dipilih untuk preview
    final selectedProduk = _selectedProdukId != null
        ? produks.firstWhere(
            (p) => p.idProduk == _selectedProdukId,
            orElse: () => produks.first,
          )
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40, height: 4,
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
                child: const Icon(Icons.edit_note_outlined,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Catat Perubahan Stok',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pilih jenis (toggle)
                    Row(
                      children: [
                        Expanded(
                          child: _JenisButton(
                            label: 'Penambahan',
                            icon: Icons.add_circle_outline,
                            color: _success,
                            isSelected: _selectedJenis == 'penambahan',
                            onTap: () => setState(
                                () => _selectedJenis = 'penambahan'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _JenisButton(
                            label: 'Pengurangan',
                            icon: Icons.remove_circle_outline,
                            color: _danger,
                            isSelected: _selectedJenis == 'pengurangan',
                            onTap: () => setState(
                                () => _selectedJenis = 'pengurangan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Dropdown Produk
                    DropdownButtonFormField<String>(
                      value: _selectedProdukId,
                      decoration: InputDecoration(
                        labelText: 'Pilih Produk',
                        prefixIcon: const Icon(Icons.cake_outlined,
                            color: _primary, size: 20),
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
                            horizontal: 12, vertical: 14),
                      ),
                      items: produks
                          .map((p) => DropdownMenuItem(
                                value: p.idProduk,
                                child: Text(
                                  '${p.namaProduk} (Stok: ${p.stok})',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedProdukId = v),
                      validator: (v) =>
                          v == null ? 'Pilih produk' : null,
                    ),

                    // Preview stok saat ini
                    if (selectedProduk != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                color: _primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Stok saat ini: ',
                              style: const TextStyle(
                                  fontSize: 12, color: _textSecondary),
                            ),
                            Text(
                              '${selectedProduk.stok}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Jumlah
                    TextFormField(
                      controller: _jumlahCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Jumlah',
                        hintText: 'Masukkan jumlah stok',
                        prefixIcon: Icon(
                          _selectedJenis == 'penambahan'
                              ? Icons.add_box_outlined
                              : Icons.indeterminate_check_box_outlined,
                          color: _selectedJenis == 'penambahan'
                              ? _success
                              : _danger,
                          size: 20,
                        ),
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
                            horizontal: 12, vertical: 14),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Wajib diisi';
                        if (int.tryParse(v!) == null || int.parse(v) < 1) {
                          return 'Jumlah minimal 1';
                        }
                        // Validasi jika pengurangan melebihi stok
                        if (_selectedJenis == 'pengurangan' &&
                            selectedProduk != null &&
                            int.parse(v) > selectedProduk.stok) {
                          return 'Melebihi stok tersedia (${selectedProduk.stok})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Keterangan
                    TextFormField(
                      controller: _keteranganCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Keterangan',
                        hintText: _selectedJenis == 'penambahan'
                            ? 'Contoh: Restock dari supplier'
                            : 'Contoh: Produk rusak, expired...',
                        prefixIcon: const Icon(Icons.notes_outlined,
                            color: _primary, size: 20),
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
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedJenis == 'penambahan'
                              ? _success
                              : _danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selectedJenis == 'penambahan'
                                        ? Icons.add_circle_outline
                                        : Icons.remove_circle_outline,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedJenis == 'penambahan'
                                        ? 'Tambah Stok'
                                        : 'Kurangi Stok',
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
}

// ── Jenis Button (Toggle) ──────────────────────────────────
class _JenisButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _JenisButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.grey.shade400,
                size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.grey.shade500,
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}