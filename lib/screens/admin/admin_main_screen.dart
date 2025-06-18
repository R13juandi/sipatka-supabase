// lib/screens/admin/admin_main_screen.dart
import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/screens/admin/create_student_screen.dart';
import 'package:sipatka/screens/admin/dashboard_screen.dart';
import 'package:sipatka/screens/admin/financial_report_screen.dart';
import 'package:sipatka/screens/admin/payment_confirmation_screen.dart';
import 'package:sipatka/screens/admin/student_management_screen.dart';
import 'package:sipatka/screens/auth/login_screen.dart';

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
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Buat Akun Siswa',
            onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateStudentScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if(mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
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
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Siswa'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Konfirmasi'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Laporan'),
        ],
      ),
    );
  }
}