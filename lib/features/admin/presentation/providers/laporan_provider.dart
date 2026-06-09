import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';

// ── Model Rugi Stok ────────────────────────────────────────
class RugiStokItem {
  final String namaProduk;
  final int jumlah;
  final double nilaiRugi;
  final String keterangan;
  final DateTime tanggal;

  const RugiStokItem({
    required this.namaProduk,
    required this.jumlah,
    required this.nilaiRugi,
    required this.keterangan,
    required this.tanggal,
  });

  factory RugiStokItem.fromJson(Map<String, dynamic> json) => RugiStokItem(
    namaProduk: json['nama_produk']?.toString() ?? '',
    jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
    nilaiRugi: (json['nilai_rugi'] as num?)?.toDouble() ?? 0,
    keterangan: json['keterangan']?.toString() ?? '',
    tanggal:
        DateTime.tryParse(json['tanggal']?.toString() ?? '') ?? DateTime.now(),
  );
}

class RugiStokData {
  final double totalRugi;
  final int totalItem;
  final List<RugiStokItem> items;

  const RugiStokData({
    required this.totalRugi,
    required this.totalItem,
    required this.items,
  });
}

// ─────────────────────────────────────────────────────────────
//  Model: ProdukDetail (nested di dalam detail transaksi)
// ─────────────────────────────────────────────────────────────
class ProdukDetail {
  final String idProduk;
  final String namaProduk;
  final double hargaModal;
  final double hargaJual;
  final int stok;
  final String namaKategori;

  const ProdukDetail({
    required this.idProduk,
    required this.namaProduk,
    required this.hargaModal,
    required this.hargaJual,
    required this.stok,
    required this.namaKategori,
  });

  factory ProdukDetail.fromJson(Map<String, dynamic> json) {
    final kategori = json['kategori'] as Map<String, dynamic>? ?? {};
    return ProdukDetail(
      idProduk: json['id_produk'] as String? ?? '',
      namaProduk: json['nama_produk'] as String? ?? '',
      hargaModal: (json['harga_modal'] as num?)?.toDouble() ?? 0,
      hargaJual: (json['harga_jual'] as num?)?.toDouble() ?? 0,
      stok: (json['stok'] as num?)?.toInt() ?? 0,
      namaKategori: kategori['nama_kategori'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Model: DetailLaporan
// ─────────────────────────────────────────────────────────────
class DetailLaporan {
  final String idTransaksi;
  final String idProduk;
  final int qty;
  final double hargaJual;
  final double subTotal;
  final ProdukDetail produk;

  double get modal => produk.hargaModal * qty;

  const DetailLaporan({
    required this.idTransaksi,
    required this.idProduk,
    required this.qty,
    required this.hargaJual,
    required this.subTotal,
    required this.produk,
  });

  factory DetailLaporan.fromJson(Map<String, dynamic> json) => DetailLaporan(
    idTransaksi: json['id_transaksi'] as String? ?? '',
    idProduk: json['id_produk'] as String? ?? '',
    qty: (json['qty'] as num?)?.toInt() ?? 0,
    hargaJual: (json['harga_jual'] as num?)?.toDouble() ?? 0,
    subTotal: (json['sub_total'] as num?)?.toDouble() ?? 0,
    produk: ProdukDetail.fromJson(
      json['produk'] as Map<String, dynamic>? ?? {},
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Model: TransaksiLaporan
// ─────────────────────────────────────────────────────────────
class TransaksiLaporan {
  final String idTransaksi;
  final String tanggalTransaksi;
  final String? tanggalLunas;
  final String namaCustomer;
  final double jumlahBayar;
  final String metodePembayaran;
  final String statusPembayaran;
  final int totalItem;
  final double totalPenjualan;
  final List<DetailLaporan> detail;

  // Hitung modal dari detail produk
  double get totalModal => detail.fold(0, (sum, d) => sum + d.modal);

  double get laba => totalPenjualan - totalModal;

  const TransaksiLaporan({
    required this.idTransaksi,
    required this.tanggalTransaksi,
    this.tanggalLunas,
    required this.namaCustomer,
    required this.jumlahBayar,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.totalItem,
    required this.totalPenjualan,
    required this.detail,
  });

  factory TransaksiLaporan.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawDetail = json['detail'] as List<dynamic>? ?? [];
    return TransaksiLaporan(
      idTransaksi: json['id_transaksi'] as String? ?? '',
      tanggalTransaksi: json['tanggal_transaksi'] as String? ?? '',
      tanggalLunas: json['tanggal_lunas'] as String?,
      namaCustomer: json['nama_customer'] as String? ?? '',
      jumlahBayar: (json['jumlah_bayar'] as num?)?.toDouble() ?? 0,
      metodePembayaran: json['metode_pembayaran'] as String? ?? '',
      statusPembayaran: json['status_pembayaran'] as String? ?? '',
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      totalPenjualan: (json['total_penjualan'] as num?)?.toDouble() ?? 0,
      detail: rawDetail
          .map((e) => DetailLaporan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Model: LaporanData
// ─────────────────────────────────────────────────────────────
class LaporanData {
  final String tanggalMulai;
  final String tanggalAkhir;
  final int totalTransaksi;
  final double totalPenjualan; // dari backend: total_penjualan
  final double totalModal;
  final double totalLaba;
  final List<TransaksiLaporan> transaksis; // key: transaksis (pakai s)

  const LaporanData({
    required this.tanggalMulai,
    required this.tanggalAkhir,
    required this.totalTransaksi,
    required this.totalPenjualan,
    required this.totalModal,
    required this.totalLaba,
    required this.transaksis,
  });

  factory LaporanData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTransaksis =
        json['transaksis'] as List<dynamic>? ?? [];
    return LaporanData(
      tanggalMulai: json['tanggal_mulai'] as String? ?? '',
      tanggalAkhir: json['tanggal_akhir'] as String? ?? '',
      totalTransaksi: (json['total_transaksi'] as num?)?.toInt() ?? 0,
      totalPenjualan: (json['total_penjualan'] as num?)?.toDouble() ?? 0,
      totalModal: (json['total_modal'] as num?)?.toDouble() ?? 0,
      totalLaba: (json['total_laba'] as num?)?.toDouble() ?? 0,
      transaksis: rawTransaksis
          .map((e) => TransaksiLaporan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Status Enum
// ─────────────────────────────────────────────────────────────
enum LaporanStatus { initial, loading, loaded, error }

// ─────────────────────────────────────────────────────────────
//  LaporanProvider
//  Query param backend: tanggal_mulai & tanggal_akhir
// ─────────────────────────────────────────────────────────────
class LaporanProvider extends ChangeNotifier {
  LaporanStatus _status = LaporanStatus.initial;
  LaporanData? _laporan;
  RugiStokData? _rugiStok;
  String? _error;

  LaporanStatus get status => _status;
  LaporanData? get laporan => _laporan;
  RugiStokData? get rugiStok => _rugiStok;
  String? get error => _error;
  bool get isLoading => _status == LaporanStatus.loading;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> fetchHarian(DateTime tanggal) async {
    await _fetch(mulai: tanggal, akhir: tanggal);
  }

  Future<void> fetchBulanan(DateTime bulan) async {
    final mulai = DateTime(bulan.year, bulan.month, 1);
    final akhir = DateTime(bulan.year, bulan.month + 1, 0);
    await _fetch(mulai: mulai, akhir: akhir);
  }

  Future<void> fetchRentang(DateTime dari, DateTime sampai) async {
    await _fetch(mulai: dari, akhir: sampai);
  }

  Future<void> _fetch({
    required DateTime mulai,
    required DateTime akhir,
  }) async {
    _status = LaporanStatus.loading;
    notifyListeners();

    try {
      // Fetch paralel
      final results = await Future.wait([
        DioClient.instance.get(
          ApiConstants.laporan,
          queryParameters: {
            'tanggal_mulai': _fmt(mulai),
            'tanggal_akhir': _fmt(akhir),
          },
        ),
        DioClient.instance.get(
          ApiConstants.stokHistory,
          queryParameters: {
            'jenis': 'pengurangan',
            'tanggal_mulai': _fmt(mulai),
            'tanggal_akhir': _fmt(akhir),
          },
        ),
      ]);

      // Parse laporan transaksi
      final raw = results[0].data['data'] as Map<String, dynamic>;
      _laporan = LaporanData.fromJson(raw);

      // Parse rugi stok
      final rawStok = results[1].data['data'] as List<dynamic>? ?? [];
      final items = rawStok
          .map((e) => RugiStokItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _rugiStok = RugiStokData(
        totalRugi: items.fold(0, (sum, e) => sum + e.nilaiRugi),
        totalItem: items.length,
        items: items,
      );

      _status = LaporanStatus.loaded;
    } on DioException catch (e) {
      debugPrint('=== ERROR LAPORAN: ${e.response?.data} ===');
      _error = e.response?.data['message'] ?? 'Gagal memuat laporan';
      _status = LaporanStatus.error;
    }

    notifyListeners();
  }
}
