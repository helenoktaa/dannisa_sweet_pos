import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';
import 'package:dannisa_sweet_pos/features/admin/data/models/produk_model.dart';

enum ProdukStatus { initial, loading, loaded, error }

class ProdukProvider extends ChangeNotifier {
  ProdukStatus _status = ProdukStatus.initial;
  List<ProdukModel> _produks = [];
  String? _error;

  ProdukStatus get status => _status;
  List<ProdukModel> get produks => _produks;
  String? get error => _error;
  bool get isLoading => _status == ProdukStatus.loading;

  // ── GET ALL ────────────────────────────────────────────────
  Future<void> fetchProduks() async {
    _status = ProdukStatus.loading;
    notifyListeners();

    try {
      final response = await DioClient.instance.get(ApiConstants.produk);
      final List<dynamic> data = response.data['data'];
      _produks = data.map((e) => ProdukModel.fromJson(e)).toList();
      _status = ProdukStatus.loaded;

      debugPrint('=== DATA PRODUK (${_produks.length} item) ===');
      for (final p in _produks) {
        debugPrint('  ${p.namaProduk} → [${p.statusProduk}] stok: ${p.stok}');
      }
      debugPrint('============================================');
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal memuat produk';
      _status = ProdukStatus.error;
    }

    notifyListeners();
  }

  // ── CREATE ─────────────────────────────────────────────────
  Future<bool> createProduk({
    required String idProduk,
    required String namaProduk,
    required double hargaModal,
    required double hargaJual,
    required int stok,
    required String idKategori,
    required String statusProduk,
    String? expiredDate,
    File? imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'id_produk': idProduk,
        'nama_produk': namaProduk,
        'harga_modal': hargaModal.toString(),
        'harga_jual': hargaJual.toString(),
        'stok': stok.toString(),
        'id_kategori': idKategori,
        'status_produk': statusProduk,
        'expired_date': expiredDate ?? '',
        if (imageFile != null)
          'image': await MultipartFile.fromFile(imageFile.path),
      });

      await DioClient.instance.post(ApiConstants.produk, data: formData);
      await fetchProduks();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal menambah produk';
      notifyListeners();
      return false;
    }
  }

  // ── UPDATE ─────────────────────────────────────────────────
  Future<bool> updateProduk({
    required String idProduk,
    required String namaProduk,
    required double hargaModal,
    required double hargaJual,
    required int stok,
    required String idKategori,
    required String statusProduk,
    String? expiredDate,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    try {
      final formData = FormData.fromMap({
        'nama_produk': namaProduk,
        'harga_modal': hargaModal.toString(),
        'harga_jual': hargaJual.toString(),
        'stok': stok.toString(),
        'id_kategori': idKategori,
        'status_produk': statusProduk,
        'expired_date': expiredDate ?? '',
        'image_url': existingImageUrl ?? '',
        if (imageFile != null)
          'image': await MultipartFile.fromFile(imageFile.path),
      });

      await DioClient.instance.put(
        '${ApiConstants.produk}/$idProduk',
        data: formData,
      );
      await fetchProduks();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal update produk';
      notifyListeners();
      return false;
    }
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<bool> deleteProduk(String idProduk) async {
    try {
      await DioClient.instance.delete('${ApiConstants.produk}/$idProduk');
      _produks.removeWhere((p) => p.idProduk == idProduk);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal hapus produk';
      notifyListeners();
      return false;
    }
  }

  // ── UPDATE STOK (dipakai setelah transaksi) ────────────────
  void updateStokLokal(String idProduk, int selisih) {
    final idx = _produks.indexWhere((p) => p.idProduk == idProduk);
    if (idx == -1) return;
    final p = _produks[idx];
    _produks[idx] = ProdukModel(
      idProduk: p.idProduk,
      namaProduk: p.namaProduk,
      hargaModal: p.hargaModal,
      hargaJual: p.hargaJual,
      hargaDiskon: p.hargaDiskon,
      porsenDiskon: p.porsenDiskon,
      sumberDiskon: p.sumberDiskon,
      stok: (p.stok - selisih).clamp(0, 999999),
      idKategori: p.idKategori,
      namaKategori: p.namaKategori,
      statusProduk: p.statusProduk,
      expiredDate: p.expiredDate,
    );
    notifyListeners();
  }

  String generateIdProduk() {
    if (_produks.isEmpty) return 'DS001';

    final numbers = _produks
        .map(
          (p) =>
              int.tryParse(p.idProduk.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        )
        .toList();

    final maxNumber = numbers.reduce((a, b) => a > b ? a : b);
    return 'DS${(maxNumber + 1).toString().padLeft(3, '0')}';
  }
}
