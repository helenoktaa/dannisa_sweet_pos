import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:dannisa_sweet_pos/core/routes/app_router.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/widgets/auth_header.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/widgets/custom_button.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/widgets/loading_overlay.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _idUserCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  final _rekCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  bool _showPass = false;

  // ID Jabatan default Kasir = JAB002, Admin = JAB001
  String _selectedJabatan = 'JAB002';

  @override
  void dispose() {
    _idUserCtrl.dispose();
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _rekCtrl.dispose();
    _waCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      idUser: _idUserCtrl.text.trim(),
      namaUser: _namaCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      idJabatan: _selectedJabatan,
      rekPembayaran: _rekCtrl.text.trim(),
      whatsapp: _waCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dibuat! Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRouter.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Pendaftaran gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Mendaftarkan akun...',
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const AuthHeader(
                    icon: Icons.person_add_alt_1,
                    title: 'Buat Akun Baru',
                    subtitle: 'Lengkapi data diri untuk mendaftar',
                  ),
                  const SizedBox(height: 32),

                  // ID User
                  CustomTextField(
                    label: 'ID User',
                    hint: 'Contoh: USR001',
                    controller: _idUserCtrl,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'ID User wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Nama Lengkap
                  CustomTextField(
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap',
                    controller: _namaCtrl,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  CustomTextField(
                    label: 'Email',
                    hint: 'contoh@email.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Email wajib diisi';
                      if (!EmailValidator.validate(v!)) {
                        return 'Format email salah';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  CustomTextField(
                    label: 'Password',
                    hint: 'Minimal 6 karakter',
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                    validator: (v) => (v?.length ?? 0) < 6
                        ? 'Password minimal 6 karakter'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Konfirmasi Password
                  CustomTextField(
                    label: 'Konfirmasi Password',
                    hint: 'Ulangi password',
                    controller: _pass2Ctrl,
                    obscureText: !_showPass,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (v) =>
                        v != _passCtrl.text ? 'Password tidak cocok' : null,
                  ),
                  const SizedBox(height: 16),

                  // Rekening Pembayaran (opsional)
                  CustomTextField(
                    label: 'Rekening Pembayaran (opsional)',
                    hint: 'Contoh: BCA 1234567890',
                    controller: _rekCtrl,
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp (opsional)
                  CustomTextField(
                    label: 'WhatsApp (opsional)',
                    hint: 'Contoh: 081234567890',
                    controller: _waCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: 16),

                  // Pilih Jabatan
                  DropdownButtonFormField<String>(
                    value: _selectedJabatan,
                    decoration: const InputDecoration(
                      labelText: 'Jabatan',
                      prefixIcon: Icon(Icons.work_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'JAB001', child: Text('Admin')),
                      DropdownMenuItem(value: 'JAB002', child: Text('Kasir')),
                    ],
                    onChanged: (v) => setState(() => _selectedJabatan = v!),
                  ),
                  const SizedBox(height: 28),

                  CustomButton(
                    label: 'Daftar Sekarang',
                    onPressed: _register,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun? '),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRouter.login,
                        ),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}