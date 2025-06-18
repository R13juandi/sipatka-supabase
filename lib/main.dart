// main.dart
// Catatan: Ini adalah file tunggal yang menggabungkan semua logika.
// Dalam proyek nyata, Anda akan membagi ini menjadi beberapa file di folder (screens, widgets, models, services).
// Struktur komentar di bawah ini mensimulasikan struktur file tersebut.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ====================================================================
// PENTING: Ganti dengan URL dan Kunci Anon Supabase Anda!
// Anda bisa mendapatkannya dari Pengaturan -> API di dasbor Supabase Anda.
// ====================================================================
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const SipatkaApp());
}

// -------------------- APP THEME AND CORE --------------------
class SipatkaApp extends StatelessWidget {
  const SipatkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sipatka',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthRedirect(),
    );
  }
}

class AuthRedirect extends StatefulWidget {
  const AuthRedirect({super.key});

  @override
  State<AuthRedirect> createState() => _AuthRedirectState();
}

class _AuthRedirectState extends State<AuthRedirect> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    final session = supabase.auth.currentSession;
    if (!mounted) return;

    if (session == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } else {
      try {
        final userId = supabase.auth.currentUser!.id;
        final response = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();

        if (response['role'] == 'admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminMainScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const UserMainScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Jika gagal mendapatkan role, logout saja untuk keamanan
        await supabase.auth.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// -------------------- UTILS & HELPERS --------------------
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

// -------------------- SCREENS: AUTH --------------------
// lib/screens/auth/login_screen.dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        if (!mounted) return;
        final userId = response.user!.id;
        final roleResponse = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();

        if (!mounted) return;
        if (roleResponse['role'] == 'admin') {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminMainScreen()),
              (route) => false);
        } else {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const UserMainScreen()),
              (route) => false);
        }
      }
    } on AuthException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (e) {
      if (mounted)
        showErrorSnackBar(context, 'Terjadi kesalahan tidak terduga.');
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.payment, size: 80, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'Selamat Datang di Sipatka',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Sistem Pembayaran SPP TK An-Naafi Nur',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signIn,
                      child: const Text('MASUK'),
                    ),
              TextButton(
                onPressed: () {
                  // TODO: Implement Forgot Password
                  showErrorSnackBar(
                      context, 'Fitur ini belum diimplementasikan.');
                },
                child: const Text('Lupa Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- SCREENS: USER (WALI MURID) --------------------
// lib/screens/user/user_main_screen.dart
class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const UserHomeScreen(),
    const UserPaymentScreen(),
    const UserHistoryScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Bayar'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// lib/screens/user/home_screen.dart
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  Future<Map<String, dynamic>>? _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final userId = supabase.auth.currentUser!.id;
    final profileData = await supabase
        .from('profiles')
        .select('full_name, student_id')
        .eq('id', userId)
        .single();

    final studentId = profileData['student_id'];
    if (studentId == null) {
      throw 'Profil pengguna tidak tertaut ke siswa manapun.';
    }

    final studentData = await supabase
        .from('students')
        .select('full_name, class_name')
        .eq('id', studentId)
        .single();

    final currentMonth = DateFormat('MMMM', 'id_ID').format(DateTime.now());
    final currentYear = DateTime.now().year;

    final paymentStatus = await supabase
        .from('payments')
        .select('status')
        .eq('student_id', studentId)
        .eq('month', currentMonth)
        .eq('year', currentYear)
        .maybeSingle();

    return {
      'parent_name': profileData['full_name'],
      'student_name': studentData['full_name'],
      'class_name': studentData['class_name'],
      'payment_status': paymentStatus?['status'] ?? 'unpaid',
      'current_month': currentMonth,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data tidak ditemukan.'));
          }

          final data = snapshot.data!;
          final bool isPaid = data['payment_status'] == 'paid' ||
              data['payment_status'] == 'confirmed';
          final String statusText = isPaid
              ? 'Pembayaran SPP bulan ${data['current_month']} sudah LUNAS.'
              : 'SPP bulan ${data['current_month']} BELUM LUNAS.';
          final Color statusColor =
              isPaid ? Colors.green.shade100 : Colors.orange.shade100;
          final Color iconColor = isPaid ? Colors.green : Colors.orange;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _userDataFuture = _fetchUserData();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Selamat Datang, ${data['parent_name'] ?? 'Wali Murid'}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Siswa: ${data['student_name'] ?? '-'} | Kelas: ${data['class_name'] ?? '-'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: statusColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(isPaid ? Icons.check_circle : Icons.warning,
                            color: iconColor, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Notifikasi Pembayaran',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(statusText,
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // TODO: Add more widgets like announcements, etc.
              ],
            ),
          );
        },
      ),
    );
  }
}

// lib/screens/user/payment_screen.dart
class UserPaymentScreen extends StatefulWidget {
  const UserPaymentScreen({super.key});

  @override
  State<UserPaymentScreen> createState() => _UserPaymentScreenState();
}

class _UserPaymentScreenState extends State<UserPaymentScreen> {
  Future<List<Map<String, dynamic>>>? _paymentsFuture;
  final Map<String, bool> _selectedMonths = {};
  double _totalAmount = 0.0;
  double _sppAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _fetchPayments();
  }

  Future<List<Map<String, dynamic>>> _fetchPayments() async {
    final userId = supabase.auth.currentUser!.id;
    final profile = await supabase
        .from('profiles')
        .select('student_id')
        .eq('id', userId)
        .single();
    final studentId = profile['student_id'];

    if (studentId == null) {
      throw 'Siswa tidak ditemukan';
    }

    final studentData = await supabase
        .from('students')
        .select('spp_amount')
        .eq('id', studentId)
        .single();
    _sppAmount = (studentData['spp_amount'] as num).toDouble();

    final response =
        await supabase.from('payments').select().eq('student_id', studentId);

    // Sort by month order
    final monthOrder = [
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
      'Juni'
    ];
    response.sort((a, b) {
      int yearComp = a['year'].compareTo(b['year']);
      if (yearComp != 0) return yearComp;
      return monthOrder
          .indexOf(a['month'])
          .compareTo(monthOrder.indexOf(b['month']));
    });

    return response;
  }

  void _onMonthSelected(bool? value, String monthId) {
    setState(() {
      _selectedMonths[monthId] = value ?? false;
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0;
    _selectedMonths.forEach((monthId, isSelected) {
      if (isSelected) {
        total += _sppAmount;
      }
    });
    setState(() {
      _totalAmount = total;
    });
  }

  void _showPaymentInstructions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Instruksi Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text('Silakan transfer sejumlah:'),
              Text(
                NumberFormat.currency(
                        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                    .format(_totalAmount),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text('Ke salah satu rekening berikut:'),
              const ListTile(
                  leading: Icon(Icons.account_balance),
                  title: Text('BCA'),
                  subtitle: Text('7295237082 (a/n Yayasan)')),
              const ListTile(
                  leading: Icon(Icons.account_balance),
                  title: Text('Mandiri'),
                  subtitle: Text('11221400941 (a/n Yayasan)')),
              const ListTile(
                  leading: Icon(Icons.phone_android),
                  title: Text('DANA'),
                  subtitle: Text('081290589185 (a/n Heni Rizki Amalia)')),
              const SizedBox(height: 16),
              const Text('Setelah transfer, unggah bukti pembayaran.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _uploadProof,
                icon: const Icon(Icons.upload_file),
                label: const Text('Unggah Bukti Bayar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadProof() async {
    final picker = ImagePicker();
    final imageFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (imageFile == null) return;

    Navigator.pop(context); // Close the bottom sheet

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Mengunggah bukti...')));

    try {
      final userId = supabase.auth.currentUser!.id;
      final file = File(imageFile.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
      final filePath = '$userId/$fileName';

      await supabase.storage.from('payment_proofs').upload(filePath, file);
      final imageUrl =
          supabase.storage.from('payment_proofs').getPublicUrl(filePath);

      // Update payment records
      final selectedPaymentIds = _selectedMonths.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      for (var paymentId in selectedPaymentIds) {
        await supabase.from('payments').update({
          'status': 'pending',
          'proof_of_payment_url': imageUrl,
          'paid_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentId);
      }

      if (mounted) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Upload Berhasil'),
                  content: const Text(
                      'Pembayaran Anda sedang diproses oleh tim admin. Silakan cek statusnya secara berkala di halaman Riwayat.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _paymentsFuture = _fetchPayments();
                          _selectedMonths.clear();
                          _calculateTotal();
                        });
                      },
                      child: const Text('OK'),
                    )
                  ],
                ));
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Gagal mengunggah bukti: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bayar SPP')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Data pembayaran tidak ditemukan.'));
          }

          final payments = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final String monthId = payment['id'];
                    final bool isPaid = payment['status'] == 'paid' ||
                        payment['status'] == 'confirmed';
                    final bool isPending = payment['status'] == 'pending';
                    final bool isSelectable = !(isPaid || isPending);

                    return Card(
                      color: isPaid
                          ? Colors.teal.shade50
                          : (isPending ? Colors.amber.shade50 : Colors.white),
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: CheckboxListTile(
                        title: Text('${payment['month']} ${payment['year']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Status: ${payment['status']}'),
                        secondary: Text(NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0)
                            .format(payment['amount'])),
                        value: isSelectable
                            ? (_selectedMonths[monthId] ?? false)
                            : true,
                        onChanged: isSelectable
                            ? (value) => _onMonthSelected(value, monthId)
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.teal,
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Tagihan Dipilih:',
                            style: TextStyle(color: Colors.grey)),
                        Text(
                          NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0)
                              .format(_totalAmount),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed:
                          _totalAmount > 0 ? _showPaymentInstructions : null,
                      child: const Text('BAYAR SEKARANG'),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

// lib/screens/user/history_screen.dart
class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  Stream<List<Map<String, dynamic>>>? _historyStream;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final userId = supabase.auth.currentUser!.id;
    _historyStream = supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('student_id',
            (supabase.from('profiles').select('student_id').eq('id', userId)))
        .where('status', 'in', ['paid', 'pending', 'confirmed'])
        .map((maps) => List<Map<String, dynamic>>.from(maps));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembayaran')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat pembayaran.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final payments = snapshot.data!;
          final totalPaid = payments
              .where((p) => p['status'] == 'paid' || p['status'] == 'confirmed')
              .fold(0.0, (sum, item) => sum + (item['amount'] as num));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Terbayar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0)
                              .format(totalPaid),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    IconData statusIcon;
                    Color statusColor;
                    switch (payment['status']) {
                      case 'paid':
                      case 'confirmed':
                        statusIcon = Icons.check_circle;
                        statusColor = Colors.green;
                        break;
                      case 'pending':
                        statusIcon = Icons.hourglass_top;
                        statusColor = Colors.orange;
                        break;
                      default:
                        statusIcon = Icons.error;
                        statusColor = Colors.red;
                    }
                    return ListTile(
                      leading: Icon(statusIcon, color: statusColor),
                      title: Text('${payment['month']} ${payment['year']}'),
                      subtitle: Text(
                          'Status: ${payment['status']}\nDibayar pada: ${DateFormat.yMMMMd('id_ID').add_Hm().format(DateTime.parse(payment['paid_at']))}'),
                      trailing: Text(NumberFormat.currency(
                              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                          .format(payment['amount'])),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// lib/screens/user/profile_screen.dart
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Future<Map<String, dynamic>>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final userId = supabase.auth.currentUser!.id;
    final profileData = await supabase
        .from('profiles')
        .select('full_name, student_id')
        .eq('id', userId)
        .single();

    if (profileData['student_id'] == null) {
      throw 'Siswa tidak terkait.';
    }

    final studentData = await supabase
        .from('students')
        .select()
        .eq('id', profileData['student_id'])
        .single();

    return {
      'profile': profileData,
      'student': studentData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada data.'));
          }

          final data = snapshot.data!;
          final student = data['student'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Data Siswa'),
              _buildProfileCard([
                _buildInfoRow('Nama Lengkap', student['full_name']),
                _buildInfoRow('Nama Orang Tua/Wali', student['parent_name']),
                _buildInfoRow('Kelas', student['class_name']),
                _buildInfoRow(
                    'SPP per Bulan',
                    NumberFormat.currency(
                            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                        .format(student['spp_amount'])),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Informasi Sekolah'),
              _buildProfileCard([
                _buildInfoRow('Nama Sekolah', 'TK An-Naafi Nur'),
                _buildInfoRow('NPSN', '69909283'),
                _buildInfoRow('Akreditasi', 'B'),
                _buildInfoRow('Kepala Sekolah', 'MUHAMMAD RIZQI DJUWANDI'),
                _buildInfoRow('Alamat',
                    'Perum Orchid Park Blok D-1 No 1 Gebang Raya Periuk Kota Tangerang, Banten 15132'),
              ]),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LiveChatScreen()));
                },
                icon: const Icon(Icons.chat),
                label: const Text('Live Chat dengan Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// lib/screens/user/live_chat_screen.dart
class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  Stream<List<Map<String, dynamic>>>? _messagesStream;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      _messagesStream = supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .map((maps) => List<Map<String, dynamic>>.from(maps));
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final userId = supabase.auth.currentUser!.id;
    try {
      await supabase.from('messages').insert({
        'user_id': userId,
        'content': text,
        'sender_role': 'user',
      });
      _textController.clear();
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Gagal mengirim pesan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Mulai percakapan dengan admin.'));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message['sender_role'] == 'user';
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.teal.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(message['content'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFFF5F5F5)),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.teal),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- SCREENS: ADMIN --------------------
// lib/screens/admin/admin_main_screen.dart
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const AdminDashboardScreen(),
    const StudentManagementScreen(),
    const PaymentConfirmationScreen(),
    const FinancialReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Buat Akun Siswa',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateStudentScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false);
              }
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Siswa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Konfirmasi'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: 'Laporan'),
        ],
      ),
    );
  }
}

// lib/screens/admin/dashboard_screen.dart
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Dummy data for now. Replace with actual Supabase calls.
  Future<Map<String, int>> _fetchDashboardData() async {
    final students =
        await supabase.from('students').select('id', const CountOptions());
    final pendingPayments = await supabase
        .from('payments')
        .select('id', const CountOptions())
        .eq('status', 'pending');
    return {
      'total_students': students.count,
      'pending_payments': pendingPayments.count,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchDashboardData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Selamat Datang, Admin!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildDashboardCard(
                        'Total Siswa',
                        '${data['total_students']}',
                        Icons.people,
                        Colors.blue)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildDashboardCard(
                        'Pembayaran Pending',
                        '${data['pending_payments']}',
                        Icons.hourglass_top,
                        Colors.orange)),
              ],
            ),
            // Add more dashboard items here
          ],
        );
      },
    );
  }

  Widget _buildDashboardCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// lib/screens/admin/student_management_screen.dart
class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  late final Stream<List<Map<String, dynamic>>> _studentsStream;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _studentsStream =
        supabase.from('students').stream(primaryKey: ['id']).order('full_name');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Cari Nama Siswa...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _studentsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final students = snapshot.data!
                  .where((s) => s['full_name']
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()))
                  .toList();
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(student['full_name']),
                    subtitle: Text('Kelas: ${student['class_name']}'),
                    onTap: () {
                      // TODO: Navigate to student detail / chat
                      showErrorSnackBar(
                          context, 'Detail siswa belum diimplementasikan.');
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// lib/screens/admin/payment_confirmation_screen.dart
class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({super.key});

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  late Stream<List<Map<String, dynamic>>> _pendingPaymentsStream;

  @override
  void initState() {
    super.initState();
    _pendingPaymentsStream = supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at');
  }

  Future<void> _updatePaymentStatus(String paymentId, String newStatus) async {
    try {
      await supabase
          .from('payments')
          .update({'status': newStatus}).eq('id', paymentId);
      if (mounted)
        showSuccessSnackBar(context, 'Status pembayaran berhasil diperbarui.');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Gagal memperbarui status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _pendingPaymentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments = snapshot.data!;
        if (payments.isEmpty) {
          return const Center(
              child: Text('Tidak ada pembayaran yang perlu dikonfirmasi.'));
        }

        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${payment['month']} ${payment['year']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    // You need to join with students table to get name
                    // Text('Siswa: ${payment['student_id']}'),
                    const SizedBox(height: 8),
                    Text(
                        'Tanggal Upload: ${DateFormat.yMd('id_ID').add_Hms().format(DateTime.parse(payment['created_at']))}'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Lihat Bukti Bayar'),
                      onPressed: () {
                        if (payment['proof_of_payment_url'] != null) {
                          showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                  child: Image.network(
                                      payment['proof_of_payment_url'])));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _updatePaymentStatus(payment['id'], 'rejected'),
                          child: const Text('Tolak',
                              style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _updatePaymentStatus(payment['id'], 'paid'),
                          child: const Text('Konfirmasi'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// lib/screens/admin/financial_report_screen.dart
class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchConfirmedPayments() async {
    return await supabase.from('payments').select().eq('status', 'paid');
  }

  // TODO: Implement PDF generation using 'pdf' and 'printing' packages.
  void _printReport(List<Map<String, dynamic>> payments) {
    // This is a placeholder
    print('Printing report...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Call the PDF function
          showErrorSnackBar(
              context, 'Fitur Cetak PDF belum diimplementasikan.');
        },
        child: const Icon(Icons.print),
        tooltip: 'Cetak Laporan',
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchConfirmedPayments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final payments = snapshot.data!;
          final totalIncome = payments.fold<double>(
              0, (sum, item) => sum + (item['amount'] as num));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Pemasukan Terkonfirmasi: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalIncome)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return ListTile(
                      title: Text('${payment['month']} ${payment['year']}'),
                      subtitle: Text(
                          'Siswa ID: ${payment['student_id']}'), // Join to get name
                      trailing: Text(NumberFormat.currency(
                              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                          .format(payment['amount'])),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

// lib/screens/admin/create_student_screen.dart
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
  final _sppController = TextEditingController(text: '150000'); // Default SPP
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

      // 1. Create auth user
      final authResponse =
          await supabase.auth.signUp(email: email, password: password);
      final userId = authResponse.user!.id;

      // 2. Create student record
      final studentResponse = await supabase
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

      // 3. Create profile record and link it
      await supabase.from('profiles').update({
        'full_name': _parentNameController.text.trim(),
        'student_id': studentId,
        'role': 'user',
      }).eq('id', userId);

      // 4. Create 12 months of payments
      final sppAmount = double.parse(_sppController.text);
      final year = DateTime.now().year;
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
        'Juni'
      ];

      List<Map<String, dynamic>> paymentsToInsert = [];
      for (int i = 0; i < months.length; i++) {
        final month = months[i];
        // Handle school year transition
        final paymentYear = (i < 6) ? year : year + 1;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun Siswa Baru')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                      controller: _parentNameController,
                      decoration: const InputDecoration(
                          labelText: 'Nama Orang Tua/Wali'),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _studentNameController,
                      decoration: const InputDecoration(
                          labelText: 'Nama Lengkap Siswa'),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _emailController,
                      decoration:
                          const InputDecoration(labelText: 'Email Wali Murid'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (v) => v!.isEmpty || v.length < 6
                          ? 'Minimal 6 karakter'
                          : null),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(labelText: 'Kelas'),
                    items: ['A', 'B'].map((String value) {
                      return DropdownMenuItem<String>(
                          value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) =>
                        setState(() => _selectedClass = newValue),
                    validator: (v) => v == null ? 'Pilih kelas' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _sppController,
                      decoration: const InputDecoration(
                          labelText: 'Jumlah SPP per Bulan'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _createAccount, child: const Text('BUAT AKUN'))
                ],
              ),
            ),
    );
  }
}
