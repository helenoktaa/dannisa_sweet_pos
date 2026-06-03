class ProdukModel {
  final String idProduk;
  final String namaProduk;
  final double hargaModal;
  final double hargaJual;
   final double? hargaDiskon;   
  final double? porsenDiskon;  
  final String? sumberDiskon; 
  final int stok;
  final String idKategori;
  final String? namaKategori;
  final KategoriModel? kategori;
  final String statusProduk;
  final DateTime? expiredDate;

  const ProdukModel({
    required this.idProduk,
    required this.namaProduk,
    required this.hargaModal,
    required this.hargaJual,
    this.hargaDiskon,
    this.porsenDiskon,
    this.sumberDiskon,
    required this.stok,
    required this.idKategori,
    this.kategori,
    this.namaKategori,
    required this.statusProduk,
    required this.expiredDate,
  });

double get hargaTampil => hargaDiskon ?? hargaJual;
  bool get adaDiskon => hargaDiskon != null && hargaDiskon! < hargaJual;

  factory ProdukModel.fromJson(Map<String, dynamic> json) {
    final kategoriJson = json['kategori'] as Map<String, dynamic>?;

    return ProdukModel(
      idProduk: json['id_produk']?.toString() ?? '',
      namaProduk: json['nama_produk']?.toString() ?? '',
      hargaModal: (json['harga_modal'] as num).toDouble(),
      hargaJual: (json['harga_jual'] as num).toDouble(),
      hargaDiskon: json['harga_diskon'] != null
          ? (json['harga_diskon'] as num).toDouble()
          : null,
      porsenDiskon: json['persen_diskon'] != null
          ? (json['persen_diskon'] as num).toDouble()
          : null,
      sumberDiskon: json['sumber_diskon']?.toString(),
      stok: (json['stok'] as num).toInt(),
      // Coba root dulu, kalau kosong ambil dari nested kategori
      idKategori: json['id_kategori']?.toString().isNotEmpty == true
          ? json['id_kategori'].toString()
          : kategoriJson?['id_kategori']?.toString() ?? '',
      namaKategori:
          kategoriJson?['nama_kategori']?.toString() ??
          json['nama_kategori']?.toString(),
      kategori: kategoriJson != null
          ? KategoriModel.fromJson(kategoriJson)
          : null,
      statusProduk: json['status_produk']?.toString() ?? 'ready',
      expiredDate: json['expired_date'] != null
          ? DateTime.tryParse(json['expired_date'].toString())
          : null,
    );
  }
}

class KategoriModel {
  final String idKategori;
  final String namaKategori;

  const KategoriModel({required this.idKategori, required this.namaKategori});

  factory KategoriModel.fromJson(Map<String, dynamic> json) => KategoriModel(
    idKategori: json['id_kategori']?.toString() ?? '',
    namaKategori: json['nama_kategori']?.toString() ?? '',
  );
}
