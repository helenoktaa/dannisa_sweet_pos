class ApiConstants {
  static const String baseUrl = 'http://192.168.100.6:8080/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';

  // Produk endpoints
  static const String produk = '/produk';

  // Transaksi endpoints
  static const String transaksi = '/transaksi';

  // Kategori endpoints
  static const String kategori = '/kategori';

  // User endpoints
  static const String users = '/users';

  // Jabatan endpoints
  static const String jabatan = '/jabatan';

  // Laporan endpoints
  static const String laporan = '/transaksi/laporan';

  //Laporan status pending
  static const String transaksiPending = '/transaksi?status=Pending';

  //Main dashboard admin
  static const String dashboard = '/dashboard';

  static const String stokHistory = '/stok-history';

  static const String dashboardHarian = '/dashboard/harian';

  // Timeout
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
