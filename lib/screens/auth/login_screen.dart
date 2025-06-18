import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/services/notification_service.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Masuk ke akun SIPATKA Anda',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Email tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Masuk', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Belum punya akun? Daftar di sini'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FUNGSI LOGIN DENGAN DEBUG PRINT ---
  Future<void> _login() async {
    // Langkah 1: Validasi form
    print("[DEBUG] Tombol login ditekan.");
    if (!_formKey.currentState!.validate()) {
      print("[DEBUG] Form tidak valid, proses berhenti.");
      return;
    }
    print("[DEBUG] Form valid.");

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    print("[DEBUG] Mencoba login dengan email: $email");

    // Langkah 2: Memanggil provider
    final authProvider = context.read<AuthProvider>();
    print("[DEBUG] SEBELUM memanggil authProvider.login()...");

    final bool success = await authProvider.login(email, password);

    print("[DEBUG] SETELAH memanggil authProvider.login(). Hasil 'success': $success");

    // Langkah 3: Pengecekan setelah login
    if (!mounted) {
      print("[DEBUG] Widget sudah tidak ter-mount. Menghentikan proses.");
      return;
    }

    setState(() => _isLoading = false);

    if (success) {
      print("[DEBUG] Login di UI dianggap BERHASIL (success == true).");
      final userRole = authProvider.userRole;
      print("[DEBUG] Role pengguna yang didapat dari provider: '$userRole'");

      // Langkah 4: Simpan Token Notifikasi
      if (authProvider.userModel != null) {
        print("[DEBUG] Mencoba menyimpan token notifikasi...");
        await NotificationService()
            .saveTokenToFirestore(authProvider.userModel!.uid);
        print("[DEBUG] Selesai menyimpan token notifikasi.");
      } else {
        print("[DEBUG] Gagal menyimpan token, userModel null.");
      }

      // Langkah 5: Navigasi berdasarkan Role
      if (userRole == 'admin') {
        print("[DEBUG] Role adalah 'admin'. Menavigasi ke /admin_dashboard...");
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        print("[DEBUG] Role BUKAN 'admin'. Menavigasi ke /dashboard...");
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      print("[DEBUG] Login di UI dianggap GAGAL (success == false). Tetap di halaman login.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Login gagal. Periksa kembali kredensial Anda.')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}