import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/utils/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    try {
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
      if (mounted) {
        showSuccessSnackBar(context, 'Tautan pemulihan kata sandi telah dikirim ke email Anda.');
        Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Lupa Password')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Masukkan email Anda yang terdaftar untuk menerima tautan pemulihan kata sandi.'),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _resetPassword, child: const Text('KIRIM TAUTAN')),
        ],
      ),
    );
  }
}
