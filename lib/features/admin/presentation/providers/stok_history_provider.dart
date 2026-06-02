import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';

// ── Model ──────────────────────────────────────────────────
class StokHistoryModel {
  final String idHistory;
  final String idProduk;
  final String namaProduk;
  final String idUser;
  final String namaUser;
  final String jenis;
  final int jumlah;
  final int stokSebelum;
  final int stokSesudah;
  final String keterangan;
  final double nilaiRugi;
  final DateTime tanggal;

  const StokHistoryModel({
    required this.idHistory,
    required this.idProduk,
    required this.namaProduk,
    required this.idUser,
    required this.namaUser,
    required this.jenis,
    required this.jumlah,
    required this.stokSebelum,
    required this.stokSesudah,
    required this.keterangan,
    required this.nilaiRugi,
    required this.tanggal,
  });

  factory StokHistoryModel.fromJson(Map<String, dynamic> json) {
    // Helper aman untuk parse int — handle String, int, double
    int safeInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return StokHistoryModel(
      idHistory:   json['id_history']?.toString() ?? '',
      idProduk:    json['id_produk']?.toString() ?? '',
      namaProduk:  json['nama_produk']?.toString() ?? '',
      idUser:      json['id_user']?.toString() ?? '',
      namaUser:    json['nama_user']?.toString() ?? '',
      jenis:       json['jenis']?.toString() ?? '',
      jumlah:      safeInt(json['jumlah']),
      stokSebelum: safeInt(json['stok_sebelum']),
      stokSesudah: safeInt(json['stok_sesudah']),
      keterangan:  json['keterangan']?.toString() ?? '',
      nilaiRugi:   (json['nilai_rugi'] as num?)?.toDouble() ?? 0.0,
      tanggal:     DateTime.tryParse(json['tanggal']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ── Status ─────────────────────────────────────────────────
enum StokHistoryStatus { initial, loading, loaded, error }

// ── Provider ───────────────────────────────────────────────
class StokHistoryProvider extends ChangeNotifier {
  StokHistoryStatus _status = StokHistoryStatus.initial;
  List<StokHistoryModel> _histories = [];
  String? _error;

  StokHistoryStatus get status => _status;
  List<StokHistoryModel> get histories => _histories;
  String? get error => _error;
  bool get isLoading => _status == StokHistoryStatus.loading;

  // ── GET ALL ──────────────────────────────────────────────
  Future<void> fetchAll({String? idProduk}) async {
    _status = StokHistoryStatus.loading;
    notifyListeners();

    try {
      final String endpoint = idProduk != null
          ? '${ApiConstants.stokHistory}?id_produk=$idProduk'
          : ApiConstants.stokHistory;

      final response = await DioClient.instance.get(endpoint);

      final List<dynamic> data = response.data['data'] as List<dynamic>;
      _histories = data
          .map((e) => StokHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _status = StokHistoryStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] as String? ??
          'Gagal memuat riwayat stok';
      _status = StokHistoryStatus.error;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
      _status = StokHistoryStatus.error;
    }

    notifyListeners();
  }

  // ── CREATE ───────────────────────────────────────────────
  Future<bool> create({
    required String idProduk,
    required String jenis,
    required int jumlah,
    String keterangan = '',
  }) async {
    try {
      await DioClient.instance.post(
        ApiConstants.stokHistory,
        data: {
          'id_produk':  idProduk,
          'jenis':      jenis,
          'jumlah':     jumlah,
          'keterangan': keterangan,
        },
      );
      await fetchAll();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] as String? ??
          'Gagal mencatat perubahan stok';
      notifyListeners();
      return false;
    }
  }
}