// lib/screens/admin/create_student_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/utils/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateStudentScreen extends StatefulWidget {
  const CreateStudentScreen({super.key});

  @override
  State<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentNameController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sppController = TextEditingController(text: '350000'); // Default SPP
  String? _selectedClass;
  bool _isLoading = false;

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      final userId = authResponse.user!.id;

      final studentResponse =
          await supabase
              .from('students')
              .insert({
                'parent_name': _parentNameController.text.trim(),
                'full_name': _studentNameController.text.trim(),
                'class_name': _selectedClass,
                'spp_amount': double.parse(_sppController.text),
              })
              .select()
              .single();
      final studentId = studentResponse['id'];

      await supabase
          .from('profiles')
          .update({
            'full_name': _parentNameController.text.trim(),
            'student_id': studentId,
            'role': 'user',
          })
          .eq('id', userId);

      final sppAmount = double.parse(_sppController.text);
      final now = DateTime.now();
      // Tahun ajaran dimulai Juli. Jika bulan saat ini sebelum Juli, tahun ajaran dimulai tahun lalu.
      final startYear = now.month < 7 ? now.year - 1 : now.year;
      final months = [
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
      ];

      List<Map<String, dynamic>> paymentsToInsert = [];
      for (int i = 0; i < months.length; i++) {
        final month = months[i];
        final paymentYear = (i < 6) ? startYear : startYear + 1;
        paymentsToInsert.add({
          'student_id': studentId,
          'month': month,
          'year': paymentYear,
          'amount': sppAmount,
          'status': 'unpaid',
        });
      }
      await supabase.from('payments').insert(paymentsToInsert);

      if (mounted) {
        showSuccessSnackBar(context, 'Akun siswa berhasil dibuat!');
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Terjadi kesalahan: $e');
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _studentNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _sppController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun Siswa Baru')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _parentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Orang Tua/Wali',
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Siswa',
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Wali Murid',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator:
                          (v) =>
                              v!.isEmpty || v.length < 6
                                  ? 'Minimal 6 karakter'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(labelText: 'Kelas'),
                      items:
                          ['A', 'B'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text('Kelas $value'),
                            );
                          }).toList(),
                      onChanged:
                          (newValue) =>
                              setState(() => _selectedClass = newValue),
                      validator: (v) => v == null ? 'Pilih kelas' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sppController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah SPP per Bulan',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _createAccount,
                      child: const Text('BUAT AKUN'),
                    ),
                  ],
                ),
              ),
    );
  }
}

// Dummy class untuk localization. Anda bisa menggunakan package intl_utils.
class S {
  static const delegate = _SDelegate();
  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  final Locale locale;
  S(this.locale);

  // ... tambahkan string lain di sini
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  get supportedLocales => null;

  @override
  bool isSupported(Locale locale) => ['en', 'id'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async {
    // Inisialisasi format Indonesia
    await initializeDateFormatting(locale.toLanguageTag(), null);
    return S(locale);
  }

  @override
  bool shouldReload(_SDelegate old) => false;
}
