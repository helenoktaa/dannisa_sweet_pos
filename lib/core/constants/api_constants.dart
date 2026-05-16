class ApiConstants {
 static const String baseUrl = 'http://10.0.2.2:8080/v1';

  // Auth endpoints
  static const String login    = '/auth/login';    
  static const String register = '/auth/register'; 
  static const String profile  = '/auth/profile';  

  // Produk endpoints
  static const String produk   = '/produk';        

  // Transaksi endpoints
  static const String transaksi = '/transaksi';    

  // Kategori endpoints
  static const String kategori = '/kategori';      
  // Timeout
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}