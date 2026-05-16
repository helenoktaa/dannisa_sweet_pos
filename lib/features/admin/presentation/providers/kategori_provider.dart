import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';

class KategoriModel {
  final String idKategori;
  final String namaKategori;

  const KategoriModel({required this.idKategori, required this.namaKategori});

  factory KategoriModel.fromJson(Map<String, dynamic> json) => KategoriModel(
        idKategori: json['id_kategori'] as String,
        namaKategori: json['nama_kategori'] as String,
      );
}

enum KategoriStatus { initial, loading, loaded, error }

class KategoriProvider extends ChangeNotifier {
  KategoriStatus _status = KategoriStatus.initial;
  List<KategoriModel> _kategoris = [];
  String? _error;

  KategoriStatus get status => _status;
  List<KategoriModel> get kategoris => _kategoris;
  String? get error => _error;
  bool get isLoading => _status == KategoriStatus.loading;

  // ── GET ALL ────────────────────────────────────────────────
  Future<void> fetchKategoris() async {
    _status = KategoriStatus.loading;
    notifyListeners();

    try {
      final response = await DioClient.instance.get(ApiConstants.kategori);
      final List<dynamic> data = response.data['data'];
      _kategoris = data.map((e) => KategoriModel.fromJson(e)).toList();
      _status = KategoriStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal memuat kategori';
      _status = KategoriStatus.error;
    }

    notifyListeners();
  }

  // ── CREATE ─────────────────────────────────────────────────
  Future<bool> createKategori(String namaKategori) async {
    try {
      await DioClient.instance.post(
        ApiConstants.kategori,
        data: {'nama_kategori': namaKategori},
      );
      await fetchKategoris();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal menambah kategori';
      notifyListeners();
      return false;
    }
  }

  // ── UPDATE ─────────────────────────────────────────────────
  Future<bool> updateKategori(String idKategori, String namaKategori) async {
    try {
      await DioClient.instance.put(
        '${ApiConstants.kategori}/$idKategori',
        data: {'nama_kategori': namaKategori},
      );
      await fetchKategoris();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal update kategori';
      notifyListeners();
      return false;
    }
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<bool> deleteKategori(String idKategori) async {
    try {
      await DioClient.instance.delete('${ApiConstants.kategori}/$idKategori');
      await fetchKategoris();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal hapus kategori';
      notifyListeners();
      return false;
    }
  }
}