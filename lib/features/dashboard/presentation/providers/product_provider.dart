import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';
import 'package:dannisa_sweet_pos/features/dashboard/data/models/product_model.dart';

enum ProductStatus { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  ProductStatus _status = ProductStatus.initial;
  List<ProductModel> _products = [];
  String? _error;

  ProductStatus get status => _status;
  List<ProductModel> get products => _products;
  String? get error => _error;
  bool get isLoading => _status == ProductStatus.loading;

  // ── GET ALL ────────────────────────────────────────────────
  Future<void> fetchProducts() async {
    _status = ProductStatus.loading;
    notifyListeners();

    try {
      final response = await DioClient.instance.get(ApiConstants.produk);
      final List<dynamic> data = response.data['data'];
      _products = data.map((e) => ProductModel.fromJson(e)).toList();
      _status = ProductStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal memuat produk';
      _status = ProductStatus.error;
    }

    notifyListeners();
  }

  // ── CREATE ─────────────────────────────────────────────────
  Future<bool> createProduct({
    required String idProduk,
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
          'id_produk': idProduk,
          'nama_produk': namaProduk,
          'harga_modal': hargaModal,
          'harga_jual': hargaJual,
          'stok': stok,
          'id_kategori': idKategori,
        },
      );
      await fetchProducts(); // refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal menambah produk';
      notifyListeners();
      return false;
    }
  }

  // ── UPDATE ─────────────────────────────────────────────────
  Future<bool> updateProduct({
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
      await fetchProducts(); // refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal update produk';
      notifyListeners();
      return false;
    }
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<bool> deleteProduct(String idProduk) async {
    try {
      await DioClient.instance.delete('${ApiConstants.produk}/$idProduk');
      await fetchProducts(); // refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal hapus produk';
      notifyListeners();
      return false;
    }
  }
}