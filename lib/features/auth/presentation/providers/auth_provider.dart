import 'package:flutter/material.dart';
import 'package:dannisa_sweet_pos/core/services/secure_storage.dart';
import 'package:dannisa_sweet_pos/features/auth/data/models/auth_response_model.dart';
import 'package:dannisa_sweet_pos/features/auth/data/models/auth_repository_impl.dart';
import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepositoryImpl _authRepo = AuthRepositoryImpl();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ── Login ──────────────────────────────────────────────────
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final responseData = await _authRepo.login(email, password);

      debugPrint('=== RESPONSE LOGIN: $responseData ===');

      final authResponse = AuthResponseModel.fromJson(responseData);

      debugPrint('=== USER: ${authResponse.user.namaUser} ===');
      debugPrint('=== JABATAN: ${authResponse.user.jabatan.namaJabatan} ===');

      // Simpan token ke secure storage
      await SecureStorageService.saveToken(authResponse.token);

      _token = authResponse.token;
      _user = authResponse.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error login: $e');
      _setError('Email atau password salah');
      return false;
    }
  }

  // ── Register ───────────────────────────────────────────────
  Future<bool> register({
    required String idUser,
    required String namaUser,
    required String email,
    required String password,
    required String idJabatan,
    String? rekPembayaran,
    String? whatsapp,
  }) async {
    _setLoading();
    try {
      await _authRepo.register(
        idUser: idUser,
        namaUser: namaUser,
        email: email,
        password: password,
        idJabatan: idJabatan,
        rekPembayaran: rekPembayaran,
        whatsapp: whatsapp,
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error register: $e');
      _setError('Gagal membuat akun. Coba lagi.');
      return false;
    }
  }

  // ── Check token saat app start (SplashScreen) ──────────────
  Future<void> checkAuthStatus() async {
  _setLoading();
  try {
    final token = await SecureStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      _token = token;
      // Fetch profile untuk dapat data user + role
      final response = await DioClient.instance.get(ApiConstants.profile);
      final data = response.data['data'] as Map<String, dynamic>;
      _user = UserModel.fromJson(data['user'] ?? data);
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
  } catch (e) {
    // Token expired → clear dan paksa login ulang
    await SecureStorageService.clearAll();
    _status = AuthStatus.unauthenticated;
  }
  notifyListeners();
}
  // ── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    await SecureStorageService.clearAll();
    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
