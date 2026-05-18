class ProdukModel {
  final String idProduk;
  final String namaProduk;
  final double hargaModal;
  final double hargaJual;
  final int stok;
  final String idKategori;
  final String? namaKategori; // dari JOIN di backend
 
  const ProdukModel({
    required this.idProduk,
    required this.namaProduk,
    required this.hargaModal,
    required this.hargaJual,
    required this.stok,
    required this.idKategori,
    this.namaKategori,
  });
 
  factory ProdukModel.fromJson(Map<String, dynamic> json) => ProdukModel(
        idProduk: json['id_produk'] as String,
        namaProduk: json['nama_produk'] as String,
        hargaModal: (json['harga_modal'] as num).toDouble(),
        hargaJual: (json['harga_jual'] as num).toDouble(),
        stok: (json['stok'] as num).toInt(),
        idKategori: json['id_kategori'] as String,
        namaKategori: json['nama_kategori'] as String?,
      );
}