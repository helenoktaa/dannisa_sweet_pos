import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/features/dashboard/data/models/product_model.dart';
import 'package:dannisa_sweet_pos/features/dashboard/presentation/providers/product_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/kategori_provider.dart';

class KelolaProdukPage extends StatefulWidget {
  const KelolaProdukPage({super.key});

  @override
  State<KelolaProdukPage> createState() => _KelolaProdukPageState();
}

class _KelolaProdukPageState extends State<KelolaProdukPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<KategoriProvider>().fetchKategoris();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    // Filter produk berdasarkan search
    final filtered = provider.products
        .where((p) =>
            p.namaProduk.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Produk',
            onPressed: () => _showFormDialog(context),
          ),
        ],
      ),

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // List produk
          Expanded(
            child: switch (provider.status) {
              ProductStatus.loading || ProductStatus.initial => const Center(
                  child: CircularProgressIndicator(),
                ),
              ProductStatus.error => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(provider.error ?? 'Terjadi kesalahan'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => provider.fetchProducts(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ProductStatus.loaded => filtered.isEmpty
                  ? const Center(child: Text('Tidak ada produk ditemukan'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        return _ProdukCard(
                          produk: p,
                          onEdit: () => _showFormDialog(context, produk: p),
                          onDelete: () => _confirmDelete(context, p),
                        );
                      },
                    ),
            },
          ),
        ],
      ),
    );
  }

  // ── Form Dialog Tambah/Edit ────────────────────────────────
  void _showFormDialog(BuildContext context, {ProductModel? produk}) {
    showDialog(
      context: context,
      builder: (_) => _ProdukFormDialog(produk: produk),
    );
  }

  // ── Confirm Delete ─────────────────────────────────────────
  void _confirmDelete(BuildContext context, ProductModel produk) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin hapus "${produk.namaProduk}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context
                  .read<ProductProvider>()
                  .deleteProduct(produk.idProduk);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Produk berhasil dihapus' : 'Gagal hapus produk'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Card Produk ────────────────────────────────────────────
class _ProdukCard extends StatelessWidget {
  final ProductModel produk;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProdukCard({
    required this.produk,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cake_outlined, color: Color(0xFF1565C0)),
        ),
        title: Text(
          produk.namaProduk,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Harga Jual: Rp ${produk.hargaJual.toStringAsFixed(0)}'),
            Text('Modal: Rp ${produk.hargaModal.toStringAsFixed(0)}'),
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: produk.stok > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stok: ${produk.stok}',
                  style: TextStyle(
                    color: produk.stok > 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    produk.kategori?.namaKategori ?? '-',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0)),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.orange),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form Dialog ────────────────────────────────────────────
class _ProdukFormDialog extends StatefulWidget {
  final ProductModel? produk;

  const _ProdukFormDialog({this.produk});

  @override
  State<_ProdukFormDialog> createState() => _ProdukFormDialogState();
}

class _ProdukFormDialogState extends State<_ProdukFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _hargaModalCtrl;
  late final TextEditingController _hargaJualCtrl;
  late final TextEditingController _stokCtrl;
  String? _selectedKategori;
  bool _isLoading = false;

  bool get _isEdit => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _idCtrl = TextEditingController(text: p?.idProduk ?? '');
    _namaCtrl = TextEditingController(text: p?.namaProduk ?? '');
    _hargaModalCtrl = TextEditingController(
      text: p?.hargaModal.toStringAsFixed(0) ?? '',
    );
    _hargaJualCtrl = TextEditingController(
      text: p?.hargaJual.toStringAsFixed(0) ?? '',
    );
    _stokCtrl = TextEditingController(text: p?.stok.toString() ?? '');
    _selectedKategori = p?.idKategori;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _namaCtrl.dispose();
    _hargaModalCtrl.dispose();
    _hargaJualCtrl.dispose();
    _stokCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<ProductProvider>();

    bool ok;
    if (_isEdit) {
      ok = await provider.updateProduct(
        idProduk: _idCtrl.text.trim(),
        namaProduk: _namaCtrl.text.trim(),
        hargaModal: double.parse(_hargaModalCtrl.text),
        hargaJual: double.parse(_hargaJualCtrl.text),
        stok: int.parse(_stokCtrl.text),
        idKategori: _selectedKategori!,
      );
    } else {
      ok = await provider.createProduct(
        idProduk: _idCtrl.text.trim(),
        namaProduk: _namaCtrl.text.trim(),
        hargaModal: double.parse(_hargaModalCtrl.text),
        hargaJual: double.parse(_hargaJualCtrl.text),
        stok: int.parse(_stokCtrl.text),
        idKategori: _selectedKategori!,
      );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? _isEdit ? 'Produk berhasil diupdate' : 'Produk berhasil ditambah'
            : _isEdit ? 'Gagal update produk' : 'Gagal tambah produk'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kategoris = context.watch<KategoriProvider>().kategoris;

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ID Produk (disabled saat edit)
              TextFormField(
                controller: _idCtrl,
                enabled: !_isEdit,
                decoration: const InputDecoration(
                  labelText: 'ID Produk',
                  hintText: 'Contoh: DS031',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _hargaModalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Modal',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _hargaJualCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Jual',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _stokCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Dropdown Kategori
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: kategoris
                    .map((k) => DropdownMenuItem(
                          value: k.idKategori,
                          child: Text(k.namaKategori),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedKategori = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isEdit ? 'Update' : 'Tambah',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}