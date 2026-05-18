import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/user_provider.dart';

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

class KelolaUserPage extends StatefulWidget {
  const KelolaUserPage({super.key});

  @override
  State<KelolaUserPage> createState() => _KelolaUserPageState();
}

class _KelolaUserPageState extends State<KelolaUserPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterJabatan = 'Semua';
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
      context.read<UserProvider>().fetchJabatans();
    });
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    final filtered = provider.users.where((u) {
      final matchSearch =
          u.namaUser.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              u.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchJabatan = _filterJabatan == 'Semua' ||
          u.namaJabatan == _filterJabatan;
      return matchSearch && matchJabatan;
    }).toList();

    final totalAdmin =
        provider.users.where((u) => u.namaJabatan == 'Admin').length;
    final totalKasir =
        provider.users.where((u) => u.namaJabatan == 'Kasir').length;

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
                            'Kelola User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${provider.users.length} user terdaftar',
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
                icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                tooltip: 'Tambah User',
                onPressed: () => _showFormDialog(context),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Stat & Filter ────────────────────────────────────
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
                    // Stats row
                    Row(
                      children: [
                        _StatCard(
                          label: 'Total User',
                          value: '${provider.users.length}',
                          icon: Icons.people_outline,
                          color: _primary,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Admin',
                          value: '$totalAdmin',
                          icon: Icons.admin_panel_settings_outlined,
                          color: _info,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Kasir',
                          value: '$totalKasir',
                          icon: Icons.point_of_sale_outlined,
                          color: _success,
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
                          hintText: 'Cari nama atau email...',
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

                    // Filter chips jabatan
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['Semua', 'Admin', 'Kasir'].map((label) {
                          final isActive = _filterJabatan == label;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _filterJabatan = label),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive ? _primary : _cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? _primary
                                      : Colors.grey.shade300,
                                ),
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
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
        ],

        // ── List User ────────────────────────────────────────
        body: switch (provider.status) {
          UserStatus.loading || UserStatus.initial => const Center(
              child: CircularProgressIndicator(color: _primary),
            ),
          UserStatus.error => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 56, color: _primary),
                  const SizedBox(height: 12),
                  Text(provider.error ?? 'Terjadi kesalahan',
                      style: const TextStyle(color: _textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchUsers(),
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
          UserStatus.loaded => filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'User "$_searchQuery" tidak ditemukan'
                            : 'Belum ada user',
                        style:
                            TextStyle(color: _textSecondary, fontSize: 14),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showFormDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah User Pertama'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final u = filtered[i];
                    return _UserCard(
                      user: u,
                      index: i,
                      onEdit: () => _showFormDialog(context, user: u),
                      onDelete: () => _confirmDelete(context, u),
                    );
                  },
                ),
        },
      ),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () => _showFormDialog(context),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text(
            'Tambah User',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showFormDialog(BuildContext context, {UserModel? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<UserProvider>(),
        child: _UserFormSheet(user: user),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: _danger),
            SizedBox(width: 8),
            Text('Hapus User',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _danger.withOpacity(0.15),
                    radius: 20,
                    child: Text(
                      user.namaUser.isNotEmpty
                          ? user.namaUser[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: _danger, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.namaUser,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(user.email,
                            style: const TextStyle(
                                color: _textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aksi ini tidak dapat dibatalkan. User yang dihapus tidak bisa login kembali.',
              style: TextStyle(color: _textSecondary, fontSize: 13),
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
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context
                  .read<UserProvider>()
                  .deleteUser(user.idUser);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? '${user.namaUser} berhasil dihapus'
                      : 'Gagal menghapus user'),
                  backgroundColor: ok ? _success : _danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
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
            Column(
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
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: _textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── User Card ──────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _jabatanColor =>
      user.namaJabatan == 'Admin' ? _info : _success;

  Color get _avatarColor {
    final colors = [
      _primary,
      _info,
      const Color(0xFF8B5CF6),
      _success,
      _warning,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          // ── Main content ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_avatarColor, _avatarColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      user.namaUser.isNotEmpty
                          ? user.namaUser[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.namaUser,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                            fontSize: 12, color: _textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Badge jabatan
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _jabatanColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.namaJabatan == 'Admin'
                                      ? Icons.admin_panel_settings_outlined
                                      : Icons.point_of_sale_outlined,
                                  size: 11,
                                  color: _jabatanColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.namaJabatan,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _jabatanColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (user.whatsapp != null &&
                              user.whatsapp!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_outlined,
                                      size: 11, color: _success),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.whatsapp!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (user.rekPembayaran != null &&
                          user.rekPembayaran!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.account_balance_outlined,
                                size: 12, color: _textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              user.rekPembayaran!,
                              style: const TextStyle(
                                  fontSize: 11, color: _textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Action buttons ───────────────────────────────
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
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: Colors.orange),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
                Container(
                    width: 1, height: 30, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: _danger),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(
                        color: _danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10)),
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

// ── Form Bottom Sheet ──────────────────────────────────────
class _UserFormSheet extends StatefulWidget {
  final UserModel? user;
  const _UserFormSheet({this.user});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _rekCtrl;
  late final TextEditingController _waCtrl;
  String? _selectedJabatanId;
  bool _isLoading = false;
  bool _obscurePass = true;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _namaCtrl =
        TextEditingController(text: widget.user?.namaUser ?? '');
    _emailCtrl =
        TextEditingController(text: widget.user?.email ?? '');
    _passCtrl = TextEditingController();
    _rekCtrl =
        TextEditingController(text: widget.user?.rekPembayaran ?? '');
    _waCtrl =
        TextEditingController(text: widget.user?.whatsapp ?? '');
    _selectedJabatanId = widget.user?.idJabatan;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _rekCtrl.dispose();
    _waCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<UserProvider>();
    bool ok;

    if (_isEdit) {
      ok = await provider.updateUser(
        idUser: widget.user!.idUser,
        namaUser: _namaCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.isNotEmpty ? _passCtrl.text : null,
        idJabatan: _selectedJabatanId!,
        rekPembayaran: _rekCtrl.text.trim(),
        whatsapp: _waCtrl.text.trim(),
      );
    } else {
      ok = await provider.createUser(
        namaUser: _namaCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        idJabatan: _selectedJabatanId!,
        rekPembayaran: _rekCtrl.text.trim(),
        whatsapp: _waCtrl.text.trim(),
      );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? _isEdit
                ? 'User berhasil diupdate ✓'
                : 'User berhasil ditambahkan ✓'
            : 'Gagal menyimpan user'),
        backgroundColor: ok ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: _primary, size: 20),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
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
                  child: Icon(
                    _isEdit
                        ? Icons.edit_outlined
                        : Icons.person_add_outlined,
                    color: _primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Edit User' : 'Tambah User Baru',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Nama User
                  TextFormField(
                    controller: _namaCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      label: 'Nama Lengkap',
                      hint: 'Contoh: Anisa Dian Utami',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Nama wajib diisi';
                      if (v!.length < 2) return 'Minimal 2 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      label: 'Email',
                      hint: 'contoh@email.com',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Email wajib diisi';
                      if (!v!.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    decoration: _inputDecoration(
                      label: _isEdit
                          ? 'Password Baru (opsional)'
                          : 'Password',
                      hint: _isEdit
                          ? 'Kosongkan jika tidak ingin diubah'
                          : 'Min. 6 karakter',
                      prefixIcon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) {
                      if (!_isEdit && (v?.isEmpty ?? true)) {
                        return 'Password wajib diisi';
                      }
                      if (v != null &&
                          v.isNotEmpty &&
                          v.length < 6) {
                        return 'Minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Jabatan
                  DropdownButtonFormField<String>(
                    value: _selectedJabatanId,
                    decoration: _inputDecoration(
                      label: 'Jabatan',
                      hint: 'Pilih jabatan',
                      prefixIcon: Icons.work_outline,
                    ),
                    items: provider.jabatans.map((j) {
                      return DropdownMenuItem(
                        value: j.idJabatan,
                        child: Text(j.namaJabatan),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _selectedJabatanId = v),
                    validator: (v) =>
                        v == null ? 'Jabatan wajib dipilih' : null,
                  ),
                  const SizedBox(height: 14),

                  // Rekening Pembayaran (opsional)
                  TextFormField(
                    controller: _rekCtrl,
                    decoration: _inputDecoration(
                      label: 'Rekening Pembayaran (opsional)',
                      hint: 'Contoh: BCA 8880587898',
                      prefixIcon: Icons.account_balance_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // WhatsApp (opsional)
                  TextFormField(
                    controller: _waCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      label: 'WhatsApp (opsional)',
                      hint: 'Contoh: 08512345678',
                      prefixIcon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol submit
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                          : Text(
                              _isEdit ? 'Simpan Perubahan' : 'Tambah User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
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