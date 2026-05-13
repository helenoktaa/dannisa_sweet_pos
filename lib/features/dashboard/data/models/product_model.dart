import 'package:equatable/equatable.dart';

class KategoriModel extends Equatable {
  final String idKategori;
  final String namaKategori;

  const KategoriModel({
    required this.idKategori,
    required this.namaKategori,
  });

  factory KategoriModel.fromJson(Map<String, dynamic> json) => KategoriModel(
        idKategori: json['id_kategori'] as String,
        namaKategori: json['nama_kategori'] as String,
      );

  @override
  List<Object?> get props => [idKategori, namaKategori];
}

class ProductModel extends Equatable {
  final String idProduk;
  final String namaProduk;
  final double hargaModal;
  final double hargaJual;
  final int stok;
  final String idKategori;
  final KategoriModel? kategori;

  const ProductModel({
    required this.idProduk,
    required this.namaProduk,
    required this.hargaModal,
    required this.hargaJual,
    required this.stok,
    required this.idKategori,
    this.kategori,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        idProduk: json['id_produk'] as String,
        namaProduk: json['nama_produk'] as String,
        hargaModal: (json['harga_modal'] as num).toDouble(),
        hargaJual: (json['harga_jual'] as num).toDouble(),
        stok: json['stok'] as int,
        idKategori: json['id_kategori'] as String,
        kategori: json['kategori'] != null
            ? KategoriModel.fromJson(json['kategori'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [idProduk, namaProduk, hargaJual, stok];
}