class JabatanModel {
  final String idJabatan;
  final String namaJabatan;
  final double gaji;

  const JabatanModel({
    required this.idJabatan,
    required this.namaJabatan,
    required this.gaji,
  });

  factory JabatanModel.fromJson(Map<String, dynamic> json) => JabatanModel(
        idJabatan: json['id_jabatan'] as String,
        namaJabatan: json['nama_jabatan'] as String,
        gaji: (json['gaji'] as num).toDouble(),
      );
}

class UserModel {
  final String idUser;
  final String namaUser;
  final String email;
  final String rekPembayaran;
  final String whatsapp;
  final JabatanModel jabatan;

  const UserModel({
    required this.idUser,
    required this.namaUser,
    required this.email,
    required this.rekPembayaran,
    required this.whatsapp,
    required this.jabatan,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        idUser: json['id_user'] as String,
        namaUser: json['nama_user'] as String,
        email: json['email'] as String,
        rekPembayaran: json['rek_pembayaran'] as String? ?? '',
        whatsapp: json['whatsapp'] as String? ?? '',
        jabatan: JabatanModel.fromJson(
          json['jabatan'] as Map<String, dynamic>,
        ),
      );
}

class AuthResponseModel {
  final bool success;
  final String message;
  final String token;
  final UserModel user;

  const AuthResponseModel({
    required this.success,
    required this.message,
    required this.token,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}