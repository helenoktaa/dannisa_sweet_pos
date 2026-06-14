import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/providers/produk_provider.dart';
import 'package:dannisa_sweet_pos/features/admin/data/models/produk_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ─────────────────────────────────────────────────────────────
//  Model: CartItem
// ─────────────────────────────────────────────────────────────
class CartItem {
  final ProdukModel produk;
  int qty;

  CartItem({required this.produk, this.qty = 1});

  double get subtotal => produk.hargaTampil * qty;
}

// ─────────────────────────────────────────────────────────────
//  Model: DetailTransaksi
// ─────────────────────────────────────────────────────────────
class DetailTransaksi {
  final String idProduk;
  final String namaProduk;
  final int qty;
  final double hargaJual;
  final double subTotal;

  const DetailTransaksi({
    required this.idProduk,
    required this.namaProduk,
    required this.qty,
    required this.hargaJual,
    required this.subTotal,
  });

  factory DetailTransaksi.fromJson(Map<String, dynamic> json) {
    final produk = json['produk'] as Map<String, dynamic>? ?? {};
    return DetailTransaksi(
      idProduk: json['id_produk'] as String? ?? '',
      namaProduk: produk['nama_produk'] as String? ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      hargaJual: (json['harga_jual'] as num?)?.toDouble() ?? 0,
      subTotal: (json['sub_total'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Model: InfoPembayaran
// ─────────────────────────────────────────────────────────────
class InfoPembayaran {
  final String namaRekening;
  final String noRekening;
  final String whatsapp;
  final String catatan;

  const InfoPembayaran({
    required this.namaRekening,
    required this.noRekening,
    required this.whatsapp,
    required this.catatan,
  });

  factory InfoPembayaran.fromJson(Map<String, dynamic> json) => InfoPembayaran(
    namaRekening: json['nama_rekening'] as String? ?? '',
    noRekening: json['no_rekening'] as String? ?? '',
    whatsapp: json['whatsapp'] as String? ?? '',
    catatan: json['catatan'] as String? ?? '',
  );
}

// ─────────────────────────────────────────────────────────────
//  Model: TransaksiResult (response POST /v1/transaksi)
// ─────────────────────────────────────────────────────────────
class TransaksiResult {
  final String idTransaksi;
  final String tanggalTransaksi;
  final String namaCustomer;
  final double jumlahBayar;
  final String metodePembayaran;
  final String statusPembayaran;
  final int totalItem;
  final double totalPenjualan;
  final List<DetailTransaksi> detail;

  // Nomor WA customer — diisi dari Flutter, tidak dari backend
  String waCustomer;

  TransaksiResult({
    required this.idTransaksi,
    required this.tanggalTransaksi,
    required this.namaCustomer,
    required this.jumlahBayar,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.totalItem,
    required this.totalPenjualan,
    required this.detail,
    this.waCustomer = '',
  });

  factory TransaksiResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawDetail = json['detail'] as List<dynamic>? ?? [];
    return TransaksiResult(
      idTransaksi: json['id_transaksi'] as String? ?? '',
      tanggalTransaksi: json['tanggal_transaksi'] as String? ?? '',
      namaCustomer: json['nama_customer'] as String? ?? '',
      jumlahBayar: (json['jumlah_bayar'] as num?)?.toDouble() ?? 0,
      metodePembayaran: json['metode_pembayaran'] as String? ?? '',
      statusPembayaran: json['status_pembayaran'] as String? ?? '',
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      totalPenjualan: (json['total_penjualan'] as num?)?.toDouble() ?? 0,
      detail: rawDetail
          .map((e) => DetailTransaksi.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Model: InvoiceResult (response GET /v1/transaksi/:id/invoice)
// ─────────────────────────────────────────────────────────────
class InvoiceResult {
  final String idTransaksi;
  final String tanggalTransaksi;
  final String namaCustomer;
  final String namaKasir;
  final String metodePembayaran;
  final String statusPembayaran;
  final int totalItem;
  final double totalPenjualan;
  final double jumlahBayar;
  final double kembalian;
  final List<DetailTransaksi> detail;
  final InfoPembayaran? infoPembayaran;
  final double jumlahDp;
  final String? tanggalLunas;
  final String jenisOrder;

  // Nomor WA customer
  String waCustomer;

  InvoiceResult({
    required this.idTransaksi,
    required this.tanggalTransaksi,
    required this.namaCustomer,
    required this.namaKasir,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.totalItem,
    required this.totalPenjualan,
    required this.jumlahBayar,
    required this.kembalian,
    required this.detail,
    this.infoPembayaran,
    this.waCustomer = '',
    required this.jumlahDp,
    this.tanggalLunas,
    this.jenisOrder = 'ready_stock',
  });

  factory InvoiceResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawDetail = json['detail'] as List<dynamic>? ?? [];
    final rawInfo = json['info_pembayaran'] as Map<String, dynamic>?;
    return InvoiceResult(
      idTransaksi: json['id_transaksi'] as String? ?? '',
      tanggalTransaksi: json['tanggal_transaksi'] as String? ?? '',
      namaCustomer: json['nama_customer'] as String? ?? '',
      namaKasir: json['nama_kasir'] as String? ?? '',
      metodePembayaran: json['metode_pembayaran'] as String? ?? '',
      statusPembayaran: json['status_pembayaran'] as String? ?? '',
      jumlahDp: (json['jumlah_dp'] as num?)?.toDouble() ?? 0,
      tanggalLunas: json['tanggal_lunas'] as String?,
      jenisOrder: json['jenis_order'] as String? ?? 'ready_stock',
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      totalPenjualan: (json['total_penjualan'] as num?)?.toDouble() ?? 0,
      jumlahBayar: (json['jumlah_bayar'] as num?)?.toDouble() ?? 0,
      kembalian: (json['kembalian'] as num?)?.toDouble() ?? 0,
      detail: rawDetail
          .map((e) => DetailTransaksi.fromJson(e as Map<String, dynamic>))
          .toList(),
      infoPembayaran: rawInfo != null ? InfoPembayaran.fromJson(rawInfo) : null,
    );
  }
}

// Model: PreOrderItem — satu transaksi pre order
class PreOrderItem {
  final String idTransaksi;
  final String tanggalTransaksi;
  final String namaCustomer;
  final String metodePembayaran;
  final String statusPembayaran;
  final double jumlahDp;
  final String statusOrder;
  final String catatan;
  final double totalPenjualan;
  final int totalItem;
  final List<DetailTransaksi> detail;

  const PreOrderItem({
    required this.idTransaksi,
    required this.tanggalTransaksi,
    required this.namaCustomer,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.jumlahDp,
    required this.statusOrder,
    required this.catatan,
    required this.totalPenjualan,
    required this.totalItem,
    required this.detail,
  });

  factory PreOrderItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawDetail = json['detail'] as List<dynamic>? ?? [];
    return PreOrderItem(
      idTransaksi: json['id_transaksi'] as String? ?? '',
      tanggalTransaksi: json['tanggal_transaksi'] as String? ?? '',
      namaCustomer: json['nama_customer'] as String? ?? '',
      metodePembayaran: json['metode_pembayaran'] as String? ?? '',
      statusPembayaran: json['status_pembayaran'] as String? ?? '',
      jumlahDp: (json['jumlah_dp'] as num?)?.toDouble() ?? 0,
      statusOrder: json['status_order'] as String? ?? '',
      catatan: json['catatan'] as String? ?? '',
      totalPenjualan: (json['total_penjualan'] as num?)?.toDouble() ?? 0,
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      detail: rawDetail
          .map((e) => DetailTransaksi.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TransaksiProvider
// ─────────────────────────────────────────────────────────────
class TransaksiProvider extends ChangeNotifier {
  List<CartItem> _keranjang = [];
  String _idUser = '';
  bool _isLoading = false;
  String? _error;

  List<CartItem> get keranjang => List.unmodifiable(_keranjang);
  String get idUser => _idUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setIdUser(String id) {
    _idUser = id;
  }

  int get totalItem => _keranjang.fold(0, (sum, i) => sum + i.qty);
  double get totalHarga => _keranjang.fold(0, (sum, i) => sum + i.subtotal);

  int getQty(String idProduk) {
    final idx = _keranjang.indexWhere((i) => i.produk.idProduk == idProduk);
    return idx != -1 ? _keranjang[idx].qty : 0;
  }

  void tambahItem(ProdukModel produk) {
    final idx = _keranjang.indexWhere(
      (i) => i.produk.idProduk == produk.idProduk,
    );
    if (idx != -1) {
      final isPreOrder = produk.statusProduk == 'preorder';
      if (isPreOrder || _keranjang[idx].qty < produk.stok) {
        _keranjang[idx].qty++;
      }
    } else {
      _keranjang.add(CartItem(produk: produk));
    }
    notifyListeners();
    _saveKeranjang();
  }

  void kurangiItem(String idProduk) {
    final idx = _keranjang.indexWhere((i) => i.produk.idProduk == idProduk);
    if (idx == -1) return;
    if (_keranjang[idx].qty > 1) {
      _keranjang[idx].qty--;
    } else {
      _keranjang.removeAt(idx);
    }
    notifyListeners();
    _saveKeranjang();
  }

  void hapusItem(String idProduk) {
    _keranjang.removeWhere((i) => i.produk.idProduk == idProduk);
    notifyListeners();
    _saveKeranjang();
  }

  void clearKeranjang() {
    _keranjang.clear();
    notifyListeners();
    _saveKeranjang();
  }

  static const _keranjangKey = 'keranjang_cache';

  Future<void> _saveKeranjang() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _keranjang
        .map(
          (item) => {
            'qty': item.qty,
            'produk': {
              'id_produk': item.produk.idProduk,
              'nama_produk': item.produk.namaProduk,
              'harga_jual': item.produk.hargaJual,
              'harga_modal': item.produk.hargaModal,
              'harga_diskon': item.produk.hargaDiskon,
              'persen_diskon': item.produk.porsenDiskon,
              'sumber_diskon': item.produk.sumberDiskon,
              'status_produk': item.produk.statusProduk,
              'stok': item.produk.stok,
              'id_kategori': item.produk.idKategori,
              'nama_kategori': item.produk.namaKategori,
              'expired_date': item.produk.expiredDate?.toIso8601String(),
            },
          },
        )
        .toList();
    await prefs.setString(_keranjangKey, jsonEncode(data));
  }

  Future<void> loadKeranjang() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keranjangKey);
    if (raw == null) return;
    try {
      final List decoded = jsonDecode(raw);
      _keranjang = decoded.map((e) {
        final p = e['produk'] as Map<String, dynamic>;
        final produk = ProdukModel.fromJson(p);
        return CartItem(produk: produk, qty: e['qty'] as int);
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  // ── POST /v1/transaksi ─────────────────────────────────────
  Future<TransaksiResult?> checkout({
    required String namaCustomer,
    required double jumlahBayar,
    required String metodePembayaran,
    String waCustomer = '',
    String catatan = '',
  }) async {
    if (_keranjang.isEmpty) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final items = _keranjang
          .map((i) => {'id_produk': i.produk.idProduk, 'qty': i.qty})
          .toList();

      final hasPreOrder = _keranjang.any(
        (i) => i.produk.statusProduk == "preorder",
      );

      final response = await DioClient.instance.post(
        ApiConstants.transaksi,
        data: {
          'nama_customer': namaCustomer,
          'metode_pembayaran': metodePembayaran,

          'jumlah_bayar': metodePembayaran == 'Tunai' ? jumlahBayar : 0,

          'catatan': catatan,

          'jenis_order': hasPreOrder ? 'pre_order' : 'ready_stock',

          'detail': items,
        },
      );

      debugPrint('=== RESPONSE TRANSAKSI: ${response.data} ===');

      final data = response.data['data'] as Map<String, dynamic>;
      final result = TransaksiResult.fromJson(data);

      // Simpan nomor WA customer ke result
      result.waCustomer = waCustomer;

      _isLoading = false;
      notifyListeners();
      return result;
    } on DioException catch (e) {
      debugPrint('=== ERROR TRANSAKSI: ${e.response?.data} ===');
      _error = e.response?.data['message'] ?? 'Gagal membuat transaksi';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ── GET /v1/transaksi/:id/invoice ──────────────────────────
  Future<InvoiceResult?> fetchInvoice(
    String idTransaksi, {
    String waCustomer = '',
  }) async {
    try {
      final response = await DioClient.instance.get(
        '${ApiConstants.transaksi}/$idTransaksi/invoice',
      );

      debugPrint('=== RESPONSE INVOICE: ${response.data} ===');

      final data = response.data['data'] as Map<String, dynamic>;
      final invoice = InvoiceResult.fromJson(data);

      // Simpan nomor WA customer
      invoice.waCustomer = waCustomer;

      return invoice;
    } on DioException catch (e) {
      debugPrint('=== ERROR INVOICE: ${e.response?.data} ===');
      return null;
    }
  }

  // ── PUT /v1/transaksi/:id/status ───────────────────────────
  Future<bool> updateStatusPembayaran({
    required String idTransaksi,
    required double jumlahBayar,
    String statusPembayaran = 'Lunas',
    double jumlahDp = 0,
    DateTime? tanggalLunas, // ← tambah
  }) async {
    try {
      final Map<String, dynamic> body = {
        'status_pembayaran': statusPembayaran,
        'jumlah_bayar': jumlahBayar,
        'jumlah_dp': jumlahDp,
      };

      if (tanggalLunas != null) {
        body['tanggal_lunas'] = tanggalLunas.toIso8601String();
      }

      await DioClient.instance.put(
        '${ApiConstants.transaksi}/$idTransaksi/status',
        data: body,
      );
      return true;
    } on DioException catch (e) {
      debugPrint('=== ERROR UPDATE STATUS: ${e.response?.data} ===');
      _error = e.response?.data['message'] ?? 'Gagal update status';
      notifyListeners();
      return false;
    }
  }

  // Tambah state
  List<PreOrderItem> _preOrders = [];
  bool _isLoadingPreOrder = false;

  List<PreOrderItem> get preOrders => _preOrders;
  bool get isLoadingPreOrder => _isLoadingPreOrder;

  // Tambah method fetchPreOrderAktif
  Future<void> fetchPreOrderAktif() async {
    _isLoadingPreOrder = true;
    notifyListeners();
    try {
      final response = await DioClient.instance.get(
        '${ApiConstants.transaksi}/pre-order/aktif',
      );
      final List<dynamic> data = response.data['data'] as List<dynamic>? ?? [];
      _preOrders = data.map((e) => PreOrderItem.fromJson(e)).toList();
    } on DioException catch (e) {
      debugPrint('Error fetch pre order: ${e.response?.data}');
    }
    _isLoadingPreOrder = false;
    notifyListeners();
  }

  // Tambah method updateStatusOrder
  Future<bool> updateStatusOrder({
    required String idTransaksi,
    required String statusOrder,
    String catatan = '',
  }) async {
    try {
      await DioClient.instance.patch(
        '${ApiConstants.transaksi}/$idTransaksi/status-order',
        data: {'status_order': statusOrder, 'catatan': catatan},
      );
      return true;
    } on DioException catch (e) {
      debugPrint('Error update status order: ${e.response?.data}');
      _error = e.response?.data['message'] ?? 'Gagal update status';
      notifyListeners();
      return false;
    }
  }

  // Tambah di TransaksiProvider

  Future<bool> bayarDp({
    required String idTransaksi,
    required double jumlahDp,
  }) async {
    try {
      await DioClient.instance.put(
        '${ApiConstants.transaksi}/$idTransaksi/status',
        data: {
          'status_pembayaran': 'DP',
          'jumlah_dp': jumlahDp,
          'jumlah_bayar': 0,
        },
      );
      return true;
    } on DioException catch (e) {
      debugPrint('Error bayar DP: ${e.response?.data}');
      _error = e.response?.data['message'] ?? 'Gagal bayar DP';
      notifyListeners();
      return false;
    }
  }

  Future<bool> lunasi({
    required String idTransaksi,
    required double jumlahBayar,
    double jumlahDp = 0,
  }) async {
    try {
      await DioClient.instance.put(
        '${ApiConstants.transaksi}/$idTransaksi/status',
        data: {
          'status_pembayaran': 'Lunas',
          'jumlah_bayar': jumlahBayar,
          'jumlah_dp': 0,
        },
      );
      return true;
    } on DioException catch (e) {
      debugPrint('Error lunasi: ${e.response?.data}');
      _error = e.response?.data['message'] ?? 'Gagal melunasi';
      notifyListeners();
      return false;
    }
  }
}
