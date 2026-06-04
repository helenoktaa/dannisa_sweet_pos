import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';

// ─────────────────────────────────────────────────────────────
//  Model: JabatanModel
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
//  Model: UserModel
// ─────────────────────────────────────────────────────────────
class UserModel {
  final String idUser;
  final String namaUser;
  final String email;
  final String? rekPembayaran;
  final String? whatsapp;
  final String idJabatan;
  final String namaJabatan; // dari JOIN di backend
  final List<String> menuKeys;

  const UserModel({
    required this.idUser,
    required this.namaUser,
    required this.email,
    this.rekPembayaran,
    this.whatsapp,
    required this.idJabatan,
    required this.namaJabatan,
    this.menuKeys = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Ambil nested object jabatan
    final jabatan = json['jabatan'] as Map<String, dynamic>? ?? {};

    return UserModel(
      idUser: json['id_user'] as String,
      namaUser: json['nama_user'] as String,
      email: json['email'] as String,
      rekPembayaran: json['rek_pembayaran'] as String?,
      whatsapp: json['whatsapp'] as String?,
      idJabatan: jabatan['id_jabatan'] as String? ?? '', // ← dari nested
      namaJabatan: jabatan['nama_jabatan'] as String? ?? '', // ← dari nested
      menuKeys: (json['menu_keys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Status Enum
// ─────────────────────────────────────────────────────────────
enum UserStatus { initial, loading, loaded, error }

// ─────────────────────────────────────────────────────────────
//  UserProvider
// ─────────────────────────────────────────────────────────────
class UserProvider extends ChangeNotifier {
  UserStatus _status = UserStatus.initial;
  List<UserModel> _users = [];
  List<JabatanModel> _jabatans = [];
  String? _error;

  UserStatus get status => _status;
  List<UserModel> get users => _users;
  List<JabatanModel> get jabatans => _jabatans;
  String? get error => _error;
  bool get isLoading => _status == UserStatus.loading;

  // ── GET ALL USERS ──────────────────────────────────────────
  Future<void> fetchUsers() async {
    _status = UserStatus.loading;
    notifyListeners();

    try {
      final response = await DioClient.instance.get(ApiConstants.users);
      final List<dynamic> data = response.data['data'];
      _users = data.map((e) => UserModel.fromJson(e)).toList();
      _status = UserStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal memuat data user';
      _status = UserStatus.error;
    }

    notifyListeners();
  }

  // ── GET ALL JABATAN (untuk dropdown form) ──────────────────
  Future<void> fetchJabatans() async {
    try {
      final response = await DioClient.instance.get(ApiConstants.jabatan);
      final List<dynamic> data = response.data['data'];
      _jabatans = data.map((e) => JabatanModel.fromJson(e)).toList();
      notifyListeners();
    } on DioException catch (_) {
      // Jabatan gagal fetch, tidak perlu ubah status utama
    }
  }

  // ── CREATE ─────────────────────────────────────────────────
  Future<bool> createUser({
    required String namaUser,
    required String email,
    required String password,
    required String idJabatan,
    String? rekPembayaran,
    String? whatsapp,
    List<String> menuKeys = const [],
  }) async {
    try {
      await DioClient.instance.post(
        ApiConstants.users,
        data: {
          'nama_user': namaUser,
          'email': email,
          'password': password,
          'id_jabatan': idJabatan,
          'menu_keys': menuKeys,
          if (rekPembayaran != null && rekPembayaran.isNotEmpty)
            'rek_pembayaran': rekPembayaran,
          if (whatsapp != null && whatsapp.isNotEmpty) 'whatsapp': whatsapp,
        },
      );
      await fetchUsers();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal menambah user';
      notifyListeners();
      return false;
    }
  }

  // ── UPDATE ─────────────────────────────────────────────────
  Future<bool> updateUser({
    required String idUser,
    required String namaUser,
    required String email,
    String? password, // null = tidak ganti password
    required String idJabatan,
    String? rekPembayaran,
    String? whatsapp,
    List<String>? menuKeys,
  }) async {
    try {
      await DioClient.instance.put(
        '${ApiConstants.users}/$idUser',
        data: {
          'nama_user': namaUser,
          'email': email,
          'id_jabatan': idJabatan,
          if (rekPembayaran != null && rekPembayaran.isNotEmpty)
            'rek_pembayaran': rekPembayaran,
          if (whatsapp != null && whatsapp.isNotEmpty) 'whatsapp': whatsapp,
          // Hanya kirim password jika diisi
          if (password != null && password.isNotEmpty) 'password': password,
          if (menuKeys != null) 'menu_keys': menuKeys,
        },
      );
      await fetchUsers();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal update user';
      notifyListeners();
      return false;
    }
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<bool> deleteUser(String idUser) async {
    try {
      await DioClient.instance.delete('${ApiConstants.users}/$idUser');
      _users.removeWhere((u) => u.idUser == idUser);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal hapus user';
      notifyListeners();
      return false;
    }
  }
}
