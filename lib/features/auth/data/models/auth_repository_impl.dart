import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';
import 'package:dannisa_sweet_pos/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await DioClient.instance.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> register({
    required String idUser,
    required String namaUser,
    required String email,
    required String password,
    required String idJabatan,
    String? rekPembayaran,
    String? whatsapp,
  }) async {
    final response = await DioClient.instance.post(
      ApiConstants.register,
      data: {
        'id_user': idUser,
        'nama_user': namaUser,
        'email': email,
        'password': password,
        'id_jabatan': idJabatan,
        'rek_pembayaran': rekPembayaran ?? '',
        'whatsapp': whatsapp ?? '',
      },
    );
    return response.data as Map<String, dynamic>;
  }
}