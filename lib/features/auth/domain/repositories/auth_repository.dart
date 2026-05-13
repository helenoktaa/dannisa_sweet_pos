abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register({
    required String idUser,
    required String namaUser,
    required String email,
    required String password,
    required String idJabatan,
    String? rekPembayaran,
    String? whatsapp,
  });
}
