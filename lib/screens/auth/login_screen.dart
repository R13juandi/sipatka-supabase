import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/screens/admin/admin_main_screen.dart';
import 'package:sipatka/screens/auth/forgot_password_screen.dart';
import 'package:sipatka/screens/user/user_main_screen.dart';
import 'package:sipatka/utils/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null && mounted) {
        final userId = response.user!.id;
        
        final roleResponse = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        if (roleResponse == null) {
          if (mounted) {
            showErrorSnackBar(context, 'Data profil pengguna tidak ditemukan. Silakan hubungi admin.');
            await supabase.auth.signOut();
          }
          setState(() => _isLoading = false);
          return;
        }
        
        if (!mounted) return;
        if (roleResponse['role'] == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminMainScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserMainScreen()));
        }
      }
    } on AuthException catch (e) {
        if(mounted) showErrorSnackBar(context, e.message);
    } catch (e) {
        if(mounted) showErrorSnackBar(context, 'Terjadi kesalahan tidak terduga.');
    } finally {
        if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // Menggunakan Icon karena logo.png tidak ada di proyek
                const Icon(Icons.payment, size: 100, color: Colors.teal),
                const SizedBox(height: 20),
                const Text(
                  'Selamat Datang di SIPATKA',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Masuk untuk melanjutkan',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator:
                      (val) => val!.isEmpty ? 'Email tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                  validator:
                      (val) =>
                          val!.isEmpty ? 'Password tidak boleh kosong' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                            : const Text('Masuk'),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Mengalami masalah? ',
                      style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                      children: [
                        TextSpan(
                          text: 'Lupa Password',
                          style: const TextStyle(
                            color: Colors.teal, // Menggunakan warna tema
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}