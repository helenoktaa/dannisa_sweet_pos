import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';

// ── Models ─────────────────────────────────────────────────

class TransaksiPendingModel {
  final String idTransaksi;
  final String namaCustomer;
  final double jumlahBayar;
  final String metodePembayaran;
  final String tanggalTransaksi;
  final int hariMenunggu;
  final bool sudahLewat3Hari;

  const TransaksiPendingModel({
    required this.idTransaksi,
    required this.namaCustomer,
    required this.jumlahBayar,
    required this.metodePembayaran,
    required this.tanggalTransaksi,
    required this.hariMenunggu,
    required this.sudahLewat3Hari,
  });

  factory TransaksiPendingModel.fromJson(Map<String, dynamic> json) =>
      TransaksiPendingModel(
        idTransaksi: json['id_transaksi'] as String,
        namaCustomer: json['nama_customer'] as String,
        jumlahBayar: (json['jumlah_bayar'] as num).toDouble(),
        metodePembayaran: json['metode_pembayaran'] as String,
        tanggalTransaksi: json['tanggal_transaksi'] as String,
        hariMenunggu: json['hari_menunggu'] as int,
        sudahLewat3Hari: json['sudah_lewat_3_hari'] as bool,
      );
}

class ProdukExpiredModel {
  final String idProduk;
  final String namaProduk;
  final int stok;
  final String expiredDate;
  final int sisaHari;

  const ProdukExpiredModel({
    required this.idProduk,
    required this.namaProduk,
    required this.stok,
    required this.expiredDate,
    required this.sisaHari,
  });

  factory ProdukExpiredModel.fromJson(Map<String, dynamic> json) =>
      ProdukExpiredModel(
        idProduk: json['id_produk'] as String,
        namaProduk: json['nama_produk'] as String,
        stok: json['stok'] as int,
        expiredDate: json['expired_date'] as String,
        sisaHari: json['sisa_hari'] as int,
      );
}

class ProdukStokModel {
  final String idProduk;
  final String namaProduk;
  final int stok;
  final String statusProduk;

  const ProdukStokModel({
    required this.idProduk,
    required this.namaProduk,
    required this.stok,
    required this.statusProduk,
  });

  factory ProdukStokModel.fromJson(Map<String, dynamic> json) =>
      ProdukStokModel(
        idProduk: json['id_produk'] as String,
        namaProduk: json['nama_produk'] as String,
        stok: json['stok'] as int,
        statusProduk: json['status_produk'] as String? ?? 'ready_stock',
      );
}

class DashboardModel {
  final int totalPending;
  final List<TransaksiPendingModel> transaksiPending;
  final int totalMendekatiExpired;
  final List<ProdukExpiredModel> produkMendekatiExpired;
  final int totalStokMenipis;
  final List<ProdukStokModel> produkStokMenipis;

  const DashboardModel({
    required this.totalPending,
    required this.transaksiPending,
    required this.totalMendekatiExpired,
    required this.produkMendekatiExpired,
    required this.totalStokMenipis,
    required this.produkStokMenipis,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
  totalPending: (json['total_pending'] as num).toInt(),
  transaksiPending: (json['transaksi_pending'] as List<dynamic>? ?? [])
      .map((e) => TransaksiPendingModel.fromJson(e)).toList(),
  totalMendekatiExpired: (json['total_mendekati_expired'] as num).toInt(),
  produkMendekatiExpired: (json['produk_mendekati_expired'] as List<dynamic>? ?? [])
      .map((e) => ProdukExpiredModel.fromJson(e)).toList(),
  totalStokMenipis: (json['total_stok_menipis'] as num).toInt(),
  produkStokMenipis: (json['produk_stok_menipis'] as List<dynamic>? ?? [])
      .map((e) => ProdukStokModel.fromJson(e)).toList(),
);
}

// ── Status ─────────────────────────────────────────────────
enum DashboardStatus { initial, loading, loaded, error }

// ── Provider ───────────────────────────────────────────────
class DashboardProvider extends ChangeNotifier {
  DashboardStatus _status = DashboardStatus.initial;
  DashboardModel? _data;
  String? _error;

  DashboardStatus get status => _status;
  DashboardModel? get data => _data;
  String? get error => _error;
  bool get isLoading => _status == DashboardStatus.loading;

  // ── GET Dashboard ────────────────────────────────────────
  Future<void> fetchDashboard() async {
    _status = DashboardStatus.loading;
    notifyListeners();

    try {
      final response =
          await DioClient.instance.get(ApiConstants.dashboard);
      _data = DashboardModel.fromJson(response.data['data']);
      _status = DashboardStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal memuat dashboard';
      _status = DashboardStatus.error;
    }

    notifyListeners();
  }

  // Refresh — dipanggil saat pull to refresh
  Future<void> refresh() => fetchDashboard();
}