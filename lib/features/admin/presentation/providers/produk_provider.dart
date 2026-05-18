import 'package:flutter/material.dart';
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
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal memuat produk';
      _status = ProdukStatus.error;
    }

    notifyListeners();
  }

  // ── CREATE ─────────────────────────────────────────────────
  Future<bool> createProduk({
    required String namaProduk,
    required double hargaModal,
    required double hargaJual,
    required int stok,
    required String idKategori,
  }) async {
    try {
      await DioClient.instance.post(
        ApiConstants.produk,
        data: {
          'nama_produk': namaProduk,
          'harga_modal': hargaModal,
          'harga_jual': hargaJual,
          'stok': stok,
          'id_kategori': idKategori,
        },
      );
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
  }) async {
    try {
      await DioClient.instance.put(
        '${ApiConstants.produk}/$idProduk',
        data: {
          'nama_produk': namaProduk,
          'harga_modal': hargaModal,
          'harga_jual': hargaJual,
          'stok': stok,
          'id_kategori': idKategori,
        },
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
      stok: (p.stok - selisih).clamp(0, 999999),
      idKategori: p.idKategori,
      namaKategori: p.namaKategori,
    );
    notifyListeners();
  }
}