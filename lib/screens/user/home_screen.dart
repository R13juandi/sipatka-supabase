// lib/screens/user/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/screens/auth/login_screen.dart';


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
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
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
          final bool isPaid = data['payment_status'] == 'paid' || data['payment_status'] == 'confirmed';
          final String statusText = isPaid
              ? 'Pembayaran SPP bulan ${data['current_month']} sudah LUNAS.'
              : 'SPP bulan ${data['current_month']} BELUM LUNAS.';
          final Color statusColor = isPaid ? Colors.green.shade100 : Colors.orange.shade100;
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Siswa: ${data['student_name'] ?? '-'} | Kelas: ${data['class_name'] ?? '-'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: statusColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(isPaid ? Icons.check_circle : Icons.warning, color: iconColor, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Notifikasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(statusText, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}